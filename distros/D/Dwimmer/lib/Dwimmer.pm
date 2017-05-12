package Dwimmer;
use Dancer ':syntax';

use 5.008005;

our $VERSION = '0.32';

use Data::Dumper qw(Dumper);
use Dwimmer::DB;
use Dwimmer::Tools qw(_get_db _get_site _get_redirect read_file $SCHEMA_VERSION);

use Encode     qw(decode);
use Fcntl      qw(:flock);
use List::Util qw(min);
use Template;
use XML::RSS;

load_app 'Dwimmer::Admin', prefix => "/_dwimmer";

# list of pages that can be accessed withot any login
my %open = map { $_ => 1 } qw(
	/poll
	/_dwimmer/login.json
	/_dwimmer/session.json
	/_dwimmer/register_email.json /_dwimmer/register_email
	/_dwimmer/validate_email.json /_dwimmer/validate_email
);

hook before => sub {
	my $path = request->path_info;

	# debug(request->uri);

	my $db = _get_db();
	my ($version) = $db->storage->dbh->selectrow_array('PRAGMA user_version');

	#see also do_dbh https://metacpan.org/module/DBIx::Class::Storage::DBI#dbh_do
	if ( $version != $SCHEMA_VERSION ) {
		return halt("Database is currently at version $version while we need version $SCHEMA_VERSION");
	}
	my ( $host, $url ) = _get_redirect();
	if ($host) {
		debug("Redirection to $url");
		return redirect $url;
	}

	my ( $site_name, $site ) = _get_site();
	return halt("Could not find site called '$site_name' in the database") if not $site;

	# TODO send text or json whatever is appropriate
	# return to_json { error => 'no_site_found' } if not $site;

	return if $open{$path};
	return if $path !~ m{/_}; # only the pages starting with /_ are management pages that need restriction

	if ( not session->{logged_in} ) {
		if ( $path =~ /json$/ ) {
			request->path_info('/_dwimmer/needs_login.json');
		} else {
			request->path_info('/_dwimmer/needs_login');
		}
	}
	return;
};

get '/search' => sub {
	my $text = param('text');
	return 'No search term provided'
		if not defined $text or $text =~ /^\s*$/;

	my $results = Dwimmer::Admin::search(text => $text);
	template 'search_results', { results => $results };
};


sub route_index {
	my ( $site_name, $site ) = _get_site();

	my $path = request->path_info;
	my $data = Dwimmer::Admin::get_page_data( $site, $path );

	if ($data) {
		if ( $data->{body} =~ s{\[poll://([^]]+)\]}{} ) {
			my $poll = $1;
			if ( not params->{submitted} ) {
				$data->{body} = _poll($poll);
			}
		}

		# disable special tag processing for now, will need to
		$data->{body} =~ s{\[\[(\w+)://([^]]+)\]\]}{_process($1, $2)}eg;
		$data->{body} =~ s{\[\[([\w .\$@%-]+)\]\]}{<a href="$1">$1</a>}g;

		return Dwimmer::Admin::render_response( 'index', { page => $data } );
	} else {

		# TODO: actually this should check if the user has the right to create a new page
		# on this site
		if ( session->{logged_in} ) {
			return Dwimmer::Admin::render_response( 'error', { page_does_not_exist => 1, creation_offer => 1 } );
		} else {
			return Dwimmer::Admin::render_response( 'error', { page_does_not_exist => 1 } );
		}
	}
};

get '/update.rss' => sub {
	my $db = _get_db();
	my ( $site_name, $site ) = _get_site();

	my $host = request->uri_base;
	my $rss = XML::RSS->new( version => '1.0' );
	my $year = 1900 + (localtime)[5];
	$rss->channel(
		title       => "Dwimmer.org",
		link        => $host,
		description => "A Dwimmer based site",
		dc => {
			language  => 'en-us',
			publisher => 'szabgab@gmail.com',
			rights    => "Copyright $year",
		},
		syn => {
			updatePeriod     => "hourly",
			updateFrequency  => "1",
			updateBase       => "1901-01-01T00:00+00:00",
		}
	);

	my @pages = $db->resultset('Page')->search( { siteid => $site->id } );
	#my @urls = map { { loc => [ $host . $_->filename ] } } @res;

	my $RSS = 10;

	# TODO this whole thing should be a single query and not one for each item!
	foreach my $p (reverse @pages[-min($RSS, scalar @pages) .. -1]) {
		my $page = $db->resultset('PageHistory')->find( { siteid => $site->id, pageid => $p->id, revision => $p->revision } );
		my $text = $page->body;
#        $text =~ s{"/}{"$host/}g;
		$rss->add_item(
			title => decode('utf-8', $page->title),
			link  => $host . $page->filename,
			description => decode('utf-8', $text),
			dc => {
				creator => $page->author->name,
				date    => POSIX::strftime("%Y-%m-%dT%H:%M:%S+00:00", localtime $page->timestamp),     # 2008-05-14T13:43:49+00:00
				subject => $page->title,
			}
		);
    }

    return $rss->as_string;
};


# http://www.sitemaps.org/protocol.html
get '/sitemap.xml' => sub {

	# see also Dwimmer::Admin get_pages.json
	my $db = _get_db();
	my ( $site_name, $site ) = _get_site();
	my @res = $db->resultset('Page')->search( { siteid => $site->id } );

	# lastmode => YYYY-MM-DD
	# changefreq
	# priority
	my $host = request->uri_base;

	my $xml = qq(<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n);
	foreach my $r (@res) {
		$xml .= qq(  <url>\n);
		$xml .= qq(     <loc>$host) . $r->filename . qq(</loc>\n);
		$xml .= qq(  </url>\n);
	}
	$xml .= qq(</urlset>);

	content_type "text/xml";
	return $xml;
};

get qr{^/([a-zA-Z0-9][\w .\$@%-]*)?$} => \&route_index;

# TODO plan:
# when a pages is marked as a "poll" there are going to be two parts of it
# one is a json file describing the actual poll
# the other is the content of the page in the database that will be shown upon posting the poll
# actually this probbaly should be shown only if we get a parmater in the get request.
# and the whole thing will be replaced by the result page once the poll is closed.
post '/poll' => sub {
	my $id = params->{id};
	return Dwimmer::Admin::render_response( 'error', { invalid_poll_id => $id } )
		if $id !~ /^[\w-]+$/;

	my $json_file = path( config->{appdir}, 'polls', "$id.json" );
	return Dwimmer::Admin::render_response( 'error', { poll_not_found => $id } )
		if not -e $json_file;

	my $log_file = path( config->{appdir}, 'polls', "$id.txt" );
	my %data = params();
	$data{IP}  = request->address;
	$data{TS}  = time;
	$data{SID} = session->id;
	if ( open my $fh, '>>', $log_file ) {
		flock( $fh, LOCK_EX );
		print $fh to_json( \%data ), "\n";
		close $fh;
	}
	redirect request->uri_base . "/$id?submitted=1";
};

sub _poll {
	my ($action) = @_;
	if ( $action !~ m{^[\w-]+$} ) {
		return qq{Invalid poll name "$action"};
	}
	my $json_file = path( config->{appdir}, 'polls', "$action.json" );

	if ( not -e $json_file ) {
		debug("File '$json_file' not found");
		return "Poll Not found";
	}
	my $data = eval { from_json scalar read_file $json_file };
	if ($@) {
		debug("Could not read json file '$json_file': $@");
		return "Could not read poll data";
	}

	my $html;
	open my $out, '>', \$html or die;
	my $t = Template->new(
		ABSOLUTE => 1,

		#                encoding:  'utf8'
		START_TAG => '<%',
		END_TAG   => '%>',
	);

	#return path(config->{appdir}, 'views', 'poll.tt') . -s path(config->{appdir}, 'views', 'poll.tt');
	$t->process( path( config->{appdir}, 'views', 'poll.tt' ), { poll => $data }, $out );

	#use Capture::Tiny qw();
	#my ($out, $err) = Capture::Tiny::capture { $t->process(path(config->{appdir}, 'views', 'poll.tt'), {poll => $data}) };
	close $out;
	return $html;
}

sub _process {
	my ( $scheme, $action ) = @_;
	if ( $scheme eq 'http' or $scheme eq 'https' ) {
		return qq{<a href="$scheme://$action">$action</a>};
	}


	return qq{Unknown scheme: "$scheme"};
}

true;

=head1 NAME

Dwimmer - A platform to develop things

=head1 COPYRIGHT

(c) 2011 Gabor Szabo

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl 5 itself.

=cut

# Copyright 2011 Gabor Szabo
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.

