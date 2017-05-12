package Dwimmer::Admin;
use Dancer ':syntax';

use 5.008005;

our $VERSION = '0.32';

use Data::Dumper qw(Dumper);
use Email::Valid   ();
use MIME::Lite     ();
use String::Random ();
use Template       ();

use Dwimmer::DB;
use Dwimmer::Tools qw(sha1_base64 _get_db _get_site save_page create_site read_file trim);


sub include_session {
	my ($data) = @_;

	if ( session->{logged_in} ) {
		foreach my $field (qw(logged_in username userid)) {
			$data->{$field} = session->{$field};
		}
	}

	return;
}

sub render_response {
	my ( $template, $data ) = @_;

	$data ||= {};
	include_session($data);

	debug( 'render_response  ' . request->content_type );
	$data->{dwimmer_version} = $VERSION;

	my ( $site_name, $site ) = _get_site();
	my $db = _get_db();
	my $google_analytics = $db->resultset('SiteConfig')->find( { siteid => $site->id, name => 'google_analytics' } );

	# TODO enable_google_analytics
	if ($google_analytics) {
		$data->{google_analytics} = $google_analytics->value;
	}
	my $getclicky = $db->resultset('SiteConfig')->find( { siteid => $site->id, name => 'getclicky' } );

	# TODO enable_getclicky
	if ($getclicky) {
		$data->{getclicky} = $getclicky->value;
	}


	my $content_type = request->content_type || params->{content_type} || '';
	if ( $content_type =~ /json/ or request->{path} =~ /\.json/ ) {
		content_type 'text/plain';
		debug( 'json', $data );
		return to_json $data, { utf8 => 0, convert_blessed => 1, allow_blessed => 1 };
	} else {
		return template $template, $data;
	}
}

sub get_page_data {
	my ( $site, $path, $revision ) = @_;

	# make it easy to deploy in CGI environment.
	if ( $path eq '/index' or $path eq '/index.html' ) {
		$path = '/';
	}

	my $db = _get_db();
	my $cpage = $db->resultset('Page')->find( { siteid => $site->id, filename => $path } );
	return if not $cpage;

	if ( not defined $revision ) {
		$revision = $cpage->revision;
	}
	my $page =
		$db->resultset('PageHistory')->find( { siteid => $site->id, pageid => $cpage->id, revision => $revision } );

	return if not $page; # TODO that's some serious trouble here!
	return {
		title    => $page->title,
		body     => $page->body,
		author   => $page->author->name,
		filename => $page->filename,
		revision => $revision,
	};


}

###### routes
get '/history.json' => sub {
	my ( $site_name, $site ) = _get_site();
	my $db = _get_db();

	my $path = params->{filename};

	#    my $cpage = $db->resultset('Page')->find( {siteid => $site->id, filename => $path} );
	#    my @history =
	#    die $history;
	my @history =
		reverse
		map { { revision => $_->revision, timestamp => $_->timestamp, author => $_->author->name, filename => $path, } }
		$db->resultset('PageHistory')->search( { siteid => $site->id, filename => $path } ); # sort by revision!?
	return to_json { rows => \@history };
};

get '/page.json' => sub {
	my ( $site_name, $site ) = _get_site();
	my $path = params->{filename};

	my $revision = params->{revision};

	my $data = get_page_data( $site, $path, $revision );
	if ($data) {
		return to_json { page => $data };
	} else {
		return to_json { error => 'page_does_not_exist', details => "$path revision " . ( $revision || '' ) };
	}
};

post '/save_page.json' => sub {
	my ( $site_name, $site ) = _get_site();

	my $filename = params->{filename};
	return to_json { error => "no_file_supplied" } if not $filename;

	return save_page(
		$site->id,
		{   create       => params->{create},
			editor_title => params->{editor_title},
			editor_body  => params->{editor_body},
			author       => session->{userid},
			filename     => $filename,
		}
	);
};

post '/login.json' => sub {
	my $username = params->{username};
	my $password = params->{password};

	return to_json { error => 'missing_username' } if not $username;
	return to_json { error => 'missing_password' } if not $password;

	my $db = _get_db();
	my $user = $db->resultset('User')->find( { name => $username } );
	return to_json { error => 'no_such_user' } if not $user;

	my $sha1 = sha1_base64($password);
	return to_json { error => 'invalid_password' } if $sha1 ne $user->sha1;

	return { error => 'not_verified' } if not $user->verified;

	session username  => $username;
	session userid    => $user->id;
	session logged_in => 1;

	my $data = { success => 1 };
	include_session($data);
	return to_json $data;
};

get '/logout.json' => sub {
	session->destroy;
	return to_json { success => 1 };
};

get '/list_users.json' => sub {
	my $db = _get_db();
	my @users = map { { id => $_->id, name => $_->name } } $db->resultset('User')->all();
	return to_json { users => \@users };
};

any '/needs_login' => sub {
	return render_response 'error', { not_logged_in => 1 };
};
any '/needs_login.json' => sub {
	return render_response 'error', { error => 'not_logged_in' };
};

get '/session.json' => sub {
	my ( $site_name, $site ) = _get_site();
	my $data = {
		logged_in => 0,
		data      => get_site_config_data(),
		site      => {
			name => $site_name,
			id   => $site->id,
		},
	};
	include_session($data);

	return to_json $data;
};

get '/get_user.json' => sub {
	my $id = params->{id};
	return to_json { error => 'no_id' } if not defined $id;
	my $db   = _get_db();
	my $user = $db->resultset('User')->find($id);
	return to_json { error => 'no_such_user' } if not defined $user;
	my @fields = qw(id name email fname lname verified register_ts);
	my %data = map { $_ => $user->$_ } @fields;
	return to_json \%data;
};

post '/add_user.json' => sub {
	my %args = _clean_params(qw(uname fname lname email pw1 pw2 verify));

	#return $args{verify};

	if ( $args{pw1} eq '' and $args{pw2} eq '' ) {
		$args{pw1} = $args{pw2} = String::Random->new->randregex('[a-zA-Z0-9]{10}');
	}
	$args{tos} = 'on'; # TODO not really the right thing, mark in the database that the user was added by the admin

	return to_json { error => 'invalid_verify' } if $args{verify} !~ /^(send_email|verified)$/;

	my $ret = register_user(%args);
	return to_json { error => $ret } if $ret;

	return to_json { success => 1 };
};

get '/register' => sub {
	render_response 'register';
};

post '/register' => sub {
	my %args = _clean_params(qw(uname fname lname email pw1 pw2 verify tos));
	$args{verify} = 'send_email';

	my $ret = register_user(%args);
	return render_response 'error', { $ret => 1 } if $ret;

	redirect '/register_done';
};



sub register_user {
	my %args = @_;

	$args{email} = lc $args{email};

	# for now we force the username to be lower case.
	# later we might allow mixed case usernames but we still want to
	# make sure the lower case versions are unique
	$args{uname} = lc $args{uname};

	# validate
	my $db = _get_db();
	if ( length $args{uname} < 2 or $args{uname} =~ /[^\w.-]/ ) {
		return 'invalid_username';
	}
	my $user = $db->resultset('User')->find( { name => $args{uname} } );
	if ($user) {
		return 'username_taken';
	}
	$user = $db->resultset('User')->find( { email => $args{email} } );
	if ($user) {
		return 'email_used';
	}

	if ( length $args{pw1} < 5 ) {
		return 'short_password';
	}
	if ( $args{pw1} ne $args{pw2} ) {
		return 'passwords_dont_match';
	}
	if ( $args{tos} ne 'on' ) {
		return 'no_tos';
	}

	# insert new user
	my $time = time;
	my $validation_key =
		String::Random->new->randregex('[a-zA-Z0-9]{10}') . $time . String::Random->new->randregex('[a-zA-Z0-9]{10}');
	$user = $db->resultset('User')->create(
		{   name           => $args{uname},
			email          => $args{email},
			sha1           => sha1_base64( $args{pw1} ),
			validation_key => $validation_key,
			verified       => ( $args{verify} eq 'verified' ? 1 : 0 ),
			register_ts    => $time,
		}
	);

	if ( $args{verify} eq 'send_email' ) {
		my $template = read_file( path( config->{appdir}, 'views', 'register_verify_mail.tt' ) );
		if ($user) {
			my $url = 'http://' . request->host . "/finish_registration?uname=$args{uname}&code=$validation_key";
			my $message = '';             # template 'register_verify_mail', { url => $url };
			my $msg     = MIME::Lite->new(
				From    => 'gabor@szabgab.com',
				To      => $args{email},
				Subject => 'Verify your registration to Dwimmer!',
				Data    => $message,
			);
			$msg->send;
		}
	} else {

		# set the verified bit?
	}

	return;
}


get '/get_pages.json' => sub {
	my ( $site_name, $site ) = _get_site();
	my $db = _get_db();

	my @res = $db->resultset('Page')->search( { siteid => $site->id } );

	my @rows = map { { id => $_->id, filename => $_->filename, title => $_->details->title } } @res;

	return to_json { rows => \@rows };
};

post '/create_feed_collector.json' => sub {
	my ( $site_name, $site ) = _get_site();
	my $db = _get_db();

	my $name = ( params->{name} || '' );

	return to_json { error => 'no_name_given' } if not $name;

	my $time = time;

	my $collector = $db->resultset('FeedCollector')->find( { name => $name } );
	return to_json { error => 'feed_collector_exists' } if $collector;

	eval {
		my $collector = $db->resultset('FeedCollector')->create(
			{   name       => $name,
				created_ts => $time,
				owner      => session->{userid},
			}
		);
	};

	if ($@) {
		return to_json { error => 'failed' };
	}

	return to_json { success => 1 };
};

get '/feed_collectors.json' => sub {
	my ( $site_name, $site ) = _get_site();
	my $db = _get_db();

	my @result =
		map { { id => $_->id, name => $_->name, ownerid => $_->owner->id, } }
		$db->resultset('FeedCollector')->search( { owner => session->{userid} } );

	return to_json { rows => \@result };
};

post '/add_feed.json' => sub {
	my ( $site_name, $site ) = _get_site();
	my $db = _get_db();

	my %args;
	foreach my $f (qw(title url feed collector)) {
		$args{$f} = ( params->{$f} || '' );
		return to_json { error => "missing_$f" } if not $args{$f};
	}

	my $collector = $db->resultset('FeedCollector')->find( { id => $args{collector} } );
	return to_json { error => 'invalid_collector_id' } if not $collector;

	# is it owned by the same user?

	return to_json { error => 'collector_not_owned_by_user' }
		if $collector->owner->id ne session->{userid};

	eval { my $feed = $db->resultset('Feed')->create( { %args, collector => session->{userid}, } ); };
	if ($@) {
		return to_json { error => $@ };
	}

	return to_json { success => 1 };
};

get '/feeds.json' => sub {
	my ( $site_name, $site ) = _get_site();
	my $db = _get_db();

	my %args;
	foreach my $f (qw(collector)) {
		$args{$f} = ( params->{$f} || '' );
		return to_json { error => "missing_$f" } if not $args{$f};
	}

	# is it owned by the same user?

	my @result =
		map { { id => $_->id, title => $_->title, url => $_->url, feed => $_->feed, } }
		$db->resultset('Feed')->search( { collector => $args{collector} } );

	return to_json { rows => \@result };
};


post '/create_list.json' => sub {
	my ( $site_name, $site ) = _get_site();

	my %params = _clean_params(
		qw(title name from_address
			response_page validation_page validation_response_page)
	);

	return to_json { 'error' => 'no_title' } if not $params{title};
	return to_json { 'error' => 'no_name' }  if not $params{name};
	if ( $params{name} !~ /^[a-z_]{4,}$/ ) {
		return to_json { 'error' => 'invalid_list_name' };
	}
	return to_json { 'error' => 'no_from_address' } if not $params{from_address};

	my $validate_template = params->{'validate_template'} || '';
	my $confirm_template  = params->{'confirm_template'}  || '';
	$validate_template =~ s/\r//g; # is this a work-around for the 010 tests or is this really needed?
	$confirm_template =~ s/\r//g;

	my $db   = _get_db();
	my $list = $db->resultset('MailingList')->create(
		{   owner => session->{userid},
			%params,
			validate_template => $validate_template,
			confirm_template  => $confirm_template,
		}
	);
	return to_json { success => 1, listid => $list->id };
};

get '/fetch_lists.json' => sub {
	my ( $site_name, $site ) = _get_site();

	my $db = _get_db();
	my @list =
		map { { listid => $_->id, owner => $_->owner->id, title => $_->title, name => $_->name } }
		$db->resultset('MailingList')->all();
	return to_json { success => 1, lists => \@list };
};

post '/register_email'     => \&_register_email;
get '/register_email.json' => \&_register_email;

sub _register_email {
	my ( $site_name, $site ) = _get_site();

	# check e-mail
	my %params = _clean_params(qw(email listid));
	$params{email} = lc $params{email};
	return render_response 'error', { 'no_email' => 1 } if not $params{email};
	return render_response 'error', { 'invalid_email' => 1 }
		if not Email::Valid->address( $params{email} );

	# check list
	return render_response 'error', { 'no_listid' => 1 } if not $params{listid};

	my $db = _get_db();
	my $list = $db->resultset('MailingList')->find( { id => $params{listid} } );
	return render_response 'error', { 'no_such_list' => 1 } if not $list;

	# TODO: change schema
	#return render_response 'error', {'list_not_open' => 1} if not $list->open;

	my $time = time;
	my $validation_code =
		String::Random->new->randregex('[a-zA-Z0-9]{10}') . $time . String::Random->new->randregex('[a-zA-Z0-9]{10}');
	my $url =
		  'http://'
		. request->host
		. "/_dwimmer/validate_email?listid=$params{listid}&email=$params{email}&code=$validation_code";

	my $same_email = $db->resultset('MailingListMember')->find(
		{   listid => $params{listid},
			email  => $params{email},
		}
	);
	return render_response 'error', { 'email_already_registered' => 1 } if $same_email;

	# TODO: send diffrent error if it was already verified and different if it has not been verified yet

	# add member
	eval {
		my $user = $db->resultset('MailingListMember')->create(
			{   listid          => $params{listid},
				email           => $params{email},
				validation_code => $validation_code,
				register_ts     => $time,
				approved        => 0,
			}
		);

		my $subject = $list->title . " registration - email validation";
		my $data    = $list->validate_template;
		$data =~ s/<% url %>/$url/g;
		my $msg = MIME::Lite->new(
			From    => $list->from_address,
			To      => $params{email},
			Subject => $subject,
			Data    => $data,
		);
		$msg->send;
	};
	if ($@) {
		die "ERROR while trying to register ($params{email}) $@";
		return render_response 'error', { 'internal_error_when_subscribing' => 1 };
	}

	if ( request->{path} =~ /\.json/ ) {
		return to_json { success => 1 };
	}

	#    return $list->response_page;
	#    die $list->response_page;
	redirect $list->response_page;

	#    return render_response $list->response_page, { 'success' => 1 };
}

get '/validate_email'      => \&_validate_email;
get '/validate_email.json' => \&_validate_email;

sub _validate_email {
	my ( $site_name, $site ) = _get_site();

	my %params = _clean_params(qw(code email listid));
	$params{email} = lc $params{email};
	return to_json                  { 'error'     => 'no_confirmation_code' } if not $params{code};
	return render_response 'error', { 'no_email'  => 1 }                      if not $params{email};
	return render_response 'error', { 'no_listid' => 1 }                      if not $params{listid};

	my $db = _get_db();
	my $list = $db->resultset('MailingList')->find( { id => $params{listid} } );
	eval {
		my $user =
			$db->resultset('MailingListMember')
			->find( { validation_code => $params{code}, email => $params{email}, listid => $params{listid} } );
		if ( not $user ) {
			return to_json { 'error' => 'invalid_confirmation_code' };
		}
		$user->approved(1);
		$user->update;

		my $subject = $list->title . " - Thank you for subscribing";
		my $data    = $list->confirm_template;

		#$data =~ s/<% url %>/$url/g;
		my $msg = MIME::Lite->new(
			From    => $list->from_address,
			To      => $params{email},
			Subject => $subject,
			Data    => $data,
		);
		$msg->send;

	};
	if ($@) {
		return render_response 'error', { 'internal_error_when_confirming' => 1 };
	}

	if ( request->{path} =~ /\.json/ ) {
		return to_json { success => 1 };
	}

	#die $list->validation_response_page;
	redirect $list->validation_response_page;

	#    return render_response $list->validation_response_page, { 'success' => 1 };
}

get '/list_members.json' => sub {
	my %params = _clean_params(qw(listid));
	return render_response 'error', { 'no_listid' => 1 } if not $params{listid};

	my $db = _get_db();
	my @members =
		map { { id => $_->id, email => $_->email, approved => $_->approved } }
		$db->resultset('MailingListMember')->search( \%params );
	return to_json { members => \@members };
};


post '/create_site.json' => sub {
	my %params = _clean_params(qw(name));

	return to_json { error => 'missing_name' } if not $params{name};

	create_site( $params{name}, $params{name}, session->{userid} );

	return to_json { success => 1 };
};

get '/sites.json' => sub {
	my $db = _get_db();
	my @rows = map { { id => $_->id, name => $_->name, owner => $_->owner->id } } $db->resultset('Site')->all;
	return to_json { rows => \@rows };
};

get '/site_config.json' => sub {
	my $data = get_site_config_data();
	return to_json { data => $data };
};


sub get_site_config_data {

	my %params = _clean_params(qw(siteid));

	# default to current site
	if ( not $params{siteid} ) {
		my ( $site_name, $site ) = _get_site();
		$params{siteid} = $site->id;
	}

	#return render_response 'error', { 'no_siteid' => 1 } if not $params{siteid};

	my $db = _get_db();

	my %data = map { $_->name => $_->value } $db->resultset('SiteConfig')->search( \%params );

	$data{page_size} ||= 10; # default

	return \%data;
}

sub _clean_params {
	my @fields = @_;

	my %args;
	foreach my $field (@fields) {
		$args{$field} = params->{$field};
		$args{$field} = '' if not defined $args{$field};
		trim( $args{$field} );
	}

	return %args;
}

# TODO test this route from the client!
post '/save_site_config.json' => sub {
	my %args = _clean_params(qw(siteid section));
	return to_json { error => 'no_siteid' }  if not $args{siteid};
	return to_json { error => 'no_section' } if not $args{section};

	my %params;
	if ( $args{section} eq 'google_analytics' ) {
		%params = _clean_params(qw(google_analytics enable_google_analytics));
	} elsif ( $args{section} eq 'getclicky' ) {
		%params = _clean_params(qw(getclicky enable_getclicky));
	} elsif ( $args{section} eq 'general' ) {
		%params = _clean_params(qw(page_size no_guest_bar show_experimental_features));
	} else {
		return to_json { error => 'invalid_section' };
	}
	$params{no_guest_bar} = $params{no_guest_bar} eq 'on' ? 1 : 0;
	$params{show_experimental_features} = $params{show_experimental_features} eq 'on' ? 1 : 0;
	foreach my $field ( keys %params ) {
		_set_site_config( siteid => $args{siteid}, name => $field, value => $params{$field} );
	}

	return to_json { success => 1 };
};

post '/set_site_config.json' => sub {
	my %params = _clean_params(qw(siteid name value));
	return render_response 'error', { 'no_siteid' => 1 } if not $params{siteid};
	return render_response 'error', { 'no_name'   => 1 } if not $params{name};
	_set_site_config(%params);

	return to_json { success => 1 };
};


post '/change_password.json' => sub {
	my %params = _clean_params(qw(uid name new_password admin_password));
	return render_response 'error', { 'no_uid_or_name' => 1 }  if not $params{uid} and not $params{name};
	return render_response 'error', { 'no_new_password' => 1 } if not $params{new_password};
	return render_response 'error', { 'no_admin_password' => 1 } if not $params{admin_password};

	my $new_sha1 = sha1_base64( $params{new_password} );
	my $admin_sha1 = sha1_base64( $params{admin_password} );

	my $db = _get_db();
	my $admin = $db->resultset('User')->find( { id => session->{userid} } );

	return render_response 'error', { 'invalid_admin_password' => 1 }
		if $admin->sha1 ne $admin_sha1;

	my $user;
	if ($params{uid}) {
		$user = $db->resultset('User')->find( { id => $params{uid} } );
	} else {
		$user = $db->resultset('User')->find( { name => $params{name} } );
	}

	return render_response 'error', { 'no_user_found' => 1 } if not $user;

	$user->sha1($new_sha1);
	$user->update;

	return to_json { success => 1 };
};

post '/change_my_password.json' => sub {
	my %params = _clean_params(qw(new_password old_password));
	return render_response 'error', { 'no_new_password' => 1 } if not $params{new_password};
	return render_response 'error', { 'no_old_password' => 1 } if not $params{old_password};

	# TODO shall we check some password requirements?

	my $old_sha1 = sha1_base64( $params{old_password} );
	my $new_sha1 = sha1_base64( $params{new_password} );

	my $db = _get_db();
	my $user = $db->resultset('User')->find( { id => session->{userid} } );

	return render_response 'error', { 'no_user_found' => 1 } if not $user;

	return render_response 'error', { 'no_invalid_old_password' => 1 }
		if $user->sha1 ne $old_sha1;

	$user->sha1($new_sha1);
	$user->update;

	return to_json { success => 1 };
};

sub _set_site_config {
	my %args = @_;

	my $db = _get_db();
	my $option = $db->resultset('SiteConfig')->find( { siteid => $args{siteid}, name => $args{name} } );
	if ($option) {
		$option->value( $args{value} );
		$option->update;
	} else {
		my $option = $db->resultset('SiteConfig')->create( \%args );
	}
}

get '/search.json' => sub {
	my %params = _clean_params(qw(text));
	return to_json { error => 'no_search_text' } if not $params{text};

	my $data = search(%params);
	to_json {ok => 1, data => $data};
};

sub search {
	my %params = @_;

	my ($site_name, $site) = _get_site();
	my $db = _get_db();

	debug("sarch for '$params{text}'");
#	title, body, description, abstract, filename
	my @results = map { {
			title => $_->filename,
			filename => $_->filename,
		} }  $db->resultset('Page')->search( {
			siteid => $site->id,
			filename => { like => ('%' . $params{text} . '%') },
			} );
	return \@results;
}


true;

