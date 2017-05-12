use strict;
use warnings;

use Test::More;
plan skip_all => 'Convert the test to use Plack::Test';
exit;


use t::lib::Dwimmer::Test qw(start $admin_mail @users read_file);

use Cwd qw(abs_path);
use Data::Dumper qw(Dumper);

my $password = 'dwimmer';

my $run = start($password);

eval "use Test::More";
eval "use Test::Deep";
require Test::WWW::Mechanize;
plan( skip_all => 'Unsupported OS' ) if not $run;

my $url = "http://localhost:$ENV{DWIMMER_PORT}";

plan( tests => 30 );

require Test::Differences;

use Dwimmer::Client;

my $admin = Dwimmer::Client->new( host => $url );
is_deeply(
	$admin->login( username => 'admin', password => $password ),
	{   success   => 1,
		username  => 'admin',
		userid    => 1,
		logged_in => 1,
	},
	'login success'
);

# create a mailing list
my $list_title        = 'Test list';
my $list_name         = 'test_list';
my $from_address      = 'admin1@dwimmer.org';
my $validate_template = <<'END_VALIDATE';
Opening: I am ready to send you updates.

-----------------------------------------------------------
CONFIRM BY VISITING THE LINK BELOW:

<% url %>

Click the link above to give me permission to send you
information.  It's fast and easy!  If you cannot click the
full URL above, please copy and paste it into your web
browser.

-----------------------------------------------------------
If you do not want to confirm, simply ignore this message.

Thank You Again!

END_VALIDATE

my $confirm_template = <<'END_CONFIRM';
END_CONFIRM

die if $validate_template =~ /\r/;
is_deeply_full(
	$admin->create_list(
		title                    => $list_title,
		name                     => $list_name,
		from_address             => $from_address,
		validate_template        => $validate_template,
		confirm_template         => $confirm_template,
		response_page            => '/response_page',
		validation_page          => '/validate_page',
		validation_response_page => '/final_page',
	),
	{   listid  => 1,
		success => 1,
	},
	'create_list'
);

# TODO: check identical names
is_deeply_full(
	$admin->create_list(
		title                    => 'Another list',
		name                     => 'another_list',
		from_address             => 'other@dwimmer.org',
		validate_template        => 'validate <% url %>',
		confirm_template         => '<% url %>',
		response_page            => '/response_page',
		validation_page          => '/validate_page',
		validation_response_page => '/final_page',
	),
	{   listid  => 2,
		success => 1,
	},
	'create_list'
);

is_deeply_full(
	$admin->fetch_lists,
	{   success => 1,
		lists   => [
			{   listid => 1,
				title  => $list_title,
				name   => $list_name,
				owner  => 1,
			},
			{   listid => 2,
				title  => 'Another list',
				name   => 'another_list',
				owner  => 1,
			},
		]
	},
	'fetch_lists'
);

# TODO: user sends in subscription via HTTP
# it is saved in database, confirmation e-mail sending
# TODO: user clicks on confirmation
# set the From e-mail

my $user = Dwimmer::Client->new( host => $url );

#diag(explain($user->register_email(email => 't1@dwimmer.org', listid => 1)));
is_deeply_full(
	$user->register_email( email => 't1@dwimmer.org', listid => 1 ),
	{   success => 1,
	},
	"submit registration"
);
our $VAR1;

my ( $t1_code, $t1_link ) = _check_validate_mail('t1');

#diag(explain($admin->list_members(listid => 1)));
is_deeply(
	$admin->list_members( listid => 1 ),
	{   'members' => [
			{   'approved' => 0,
				'email'    => 't1@dwimmer.org',
				'id'       => 1,
			}
		]
	},
	'list of members'
);

is_deeply_full(
	$user->validate_email( listid => 1, email => 't1@dwimmer.org', code => $t1_code ),
	{   success => 1,
	},
	'validate_email'
);

_check_confirm_mail('t1');


is_deeply(
	$admin->list_members( listid => 1 ),
	{   'members' => [
			{   'approved' => 1,
				'email'    => 't1@dwimmer.org',
				'id'       => 1,
			}
		]
	},
	'list of members'
);

is_deeply_full(
	$user->register_email( email => 't1@dwimmer.org', listid => 1 ),
	{   dwimmer_version          => $Dwimmer::Client::VERSION,
		email_already_registered => 1,
	},
	"submit registration with the same e-mail"
);
is_deeply_full(
	$user->register_email( email => 't1@Dwimmer.org', listid => 1 ),
	{   dwimmer_version          => $Dwimmer::Client::VERSION,
		email_already_registered => 1,
	},
	"submit registration with the same e-mail but with different case"
);

# TODO check that e-mail was not sent out again



# TODO:
# admin should create a page with the form
# designate a page to be the response page and create it (the same for the validation page)

my $body = <<"END_BODY";
<form action="/_dwimmer/register_email" method="POST" name="mailing_list_form">
<input type="hidden" name="listid" value="1" />
<input name="email" />
<input type="submit" value="Sign up" />
</form>
END_BODY

is_deeply(
	$admin->save_page(
		body     => $body,
		title    => 'New main title',
		filename => '/',
	),
	{ success => 1 },
	'save_page'
);

is_deeply(
	$admin->save_page(
		body     => 'Thanks for subscribing. Please check your mail',
		title    => 'Response',
		filename => '/response_page',
		create   => 1,
	),
	{ success => 1 },
	'save response_page'
);

is_deeply(
	$admin->save_page(
		body     => 'Page with validate form',
		title    => 'Response',
		filename => '/validate_page',
		create   => 1,
	),
	{ success => 1 },
	'save validate_page'
);

is_deeply(
	$admin->save_page(
		body     => 'Thanks for subscribing. We will be in touch.',
		title    => 'Response',
		filename => '/final_page',
		create   => 1,
	),
	{ success => 1 },
	'save final_page'
);


my $web_user = Test::WWW::Mechanize->new;
$web_user->get_ok( $url . '/response_page' );
$web_user->get_ok($url);
$web_user->submit_form_ok(
	{   form_name => 'mailing_list_form',
		fields    => {
			email => 't2@dwimmer.org',
		}
	},
	'submit regisration'
);
$web_user->content_like( qr/Thanks for subscribing. Please check your mail/, 'web site content' );

my ( $t2_code, $t2_link ) = _check_validate_mail('t2');
is_deeply(
	$admin->list_members( listid => 1 ),
	{   'members' => [
			{   'approved' => 1,
				'email'    => 't1@dwimmer.org',
				'id'       => 1,
			},
			{   'approved' => 0,
				'email'    => 't2@dwimmer.org',
				'id'       => 2,
			}
		]
	},
	'list of members'
);

$web_user->get_ok($t2_link);
$web_user->content_like(qr/Thanks for subscribing. We will be in touch/);
_check_confirm_mail('t2');

is_deeply(
	$admin->list_members( listid => 1 ),
	{   'members' => [
			{   'approved' => 1,
				'email'    => 't1@dwimmer.org',
				'id'       => 1,
			},
			{   'approved' => 1,
				'email'    => 't2@dwimmer.org',
				'id'       => 2,
			}
		]
	},
	'list of members'
);



exit;

sub _check_validate_mail {
	my $email = shift;

	local $Test::Builder::Level = $Test::Builder::Level + 1;
	my $validate_mail = read_file( $ENV{DWIMMER_MAIL} );
	eval $validate_mail;

	#diag(explain($VAR1));
	# my $validate = $validate_template;
	my $link       = '';
	my $found_code = '';
	if ( $VAR1->{Data}
		=~ s{(http://localhost:$ENV{DWIMMER_PORT}/_dwimmer/validate_email\?listid=1&email=$email\@dwimmer\.org&code=(\w+))}{<% url %>}
		)
	{
		( $link, $found_code ) = ( $1, $2 );
	}

	my $data = delete $VAR1->{Data};
	Test::Differences::eq_or_diff($data, $validate_template, 'validate e-mail data');
	is_deeply_full(
		$VAR1,
		bless(
			{
				'From'    => $from_address,
				'Subject' => "$list_title registration - email validation",
				'To'      => $email . '@dwimmer.org',
			},
			'MIME::Lite'
		),
		"expected validate e-mail structure for $email"
	);
	$VAR1 = undef;

	diag("code='$found_code' link=$link");

	return ( $found_code, $link );
}

sub _check_confirm_mail {
	my $email = shift;

	local $Test::Builder::Level = $Test::Builder::Level + 1;
	my $confirm_mail = read_file( $ENV{DWIMMER_MAIL} );
	eval $confirm_mail;
	my $data = delete $VAR1->{Data};
	Test::Differences::eq_or_diff($data, $confirm_template, 'confirm e-mail data');
	is_deeply_full(
		$VAR1,
		bless(
			{
				'From'    => $from_address,
				'Subject' => "$list_title - Thank you for subscribing",
				'To'      => $email . '@dwimmer.org',
			},
			'MIME::Lite'
		),
		'expected confirm e-mail structure'
	);

	# TODO test what is the response if incorrect validation happens or if it pressed multiple times
}


sub is_deeply_full {
	my ( $result, $expected, $title ) = @_;
	my $ok = is_deeply( $result, $expected, $title );
	diag( explain($result) ) if not $ok;
	return $ok;
}

# TODO validation web page, error messages

