use strict;
use warnings;

use Test::More;
plan skip_all => 'Convert the test to use Plack::Test';
exit;

use t::lib::Dwimmer::Test qw(start $admin_mail @users);

use Cwd qw(abs_path);
use Data::Dumper qw(Dumper);
use JSON qw(from_json);

my $password = 'dwimmer';

my $run = start($password);

eval "use Test::More";
eval "use Test::Deep";
require Test::WWW::Mechanize;
plan( skip_all => 'Unsupported OS' ) if not $run;
diag("Port: $run");

my $url = "http://localhost:$ENV{DWIMMER_PORT}";
my $URL = "$url/";

plan( tests => 63 );

my @pages = (
	{},
	{},
	{   body     => 'File with space and dot',
		title    => 'dotspace',
		filename => '/space and.dot and $@% too',
	}
);
my @exp_pages =
	map { { id => $_ + 1, filename => $pages[$_]->{filename}, title => $pages[$_]->{title}, } } 0 .. @pages - 1;
my @links = map { $_->{filename} ? substr( $_->{filename}, 1 ) : '' } @pages;
my @exp_links = map { quotemeta($_) } @links;

my $w = Test::WWW::Mechanize->new;
$w->get_ok($URL);
$w->content_like( qr{Welcome to your Dwimmer installation}, 'content ok' );
$w->get_ok("$url/other");
$w->content_like( qr{Page does not exist}, 'content of missing pages is ok' );
$w->content_unlike( qr{Would you like to create it}, 'no creation offer' );

require LWP::Simple;
require XML::Simple;

test_rss(
	{
		'dc:creator' => 'admin',
		'link'       => $URL,
		'rdf:about'  => $URL,
		'dc:subject' => 'Welcome to your Dwimmer installation',
		'title'      => 'Welcome to your Dwimmer installation',
		'dc:date'    => ignore(), #'2011-12-07T17:53:48+00:00',
		'description' => '<h1>Dwimmer</h1>'
	},
);

test_sitemap(
		{
			'loc' => $URL
		}
);

my $u = Test::WWW::Mechanize->new;
$u->get_ok($URL);
$u->post_ok(
	"$url/_dwimmer/login.json",
	{   username => 'admin',
		password => $password,
	}
);
is_deeply(
	from_json( $u->content ),
	{   "success"   => 1,
		"userid"    => 1,
		"logged_in" => 1,
		"username"  => "admin",
	},
	'logged in'
);
$u->get_ok("$url/other");
$u->content_like( qr{Page does not exist}, 'content of missing pages is ok' );
$u->content_like( qr{Would you like to <a class="create_page" href="">create</a> it}, 'creation offer' );


use Dwimmer::Client;
my $admin = Dwimmer::Client->new( host => $url );
is_deeply(
	$admin->login( username => 'admin', password => 'xyz' ), { error => 'invalid_password' },
	'invalid_password'
);
is_deeply(
	$admin->login( username => 'admin', password => $password ),
	{   success   => 1,
		username  => 'admin',
		userid    => 1,
		logged_in => 1,
	},
	'login success'
);
is_deeply(
	$admin->list_users, { users => [
			{ id => 1, name => 'admin', }
			] }, 'list_users'
);
cmp_deeply(
	$admin->get_user( id => 1 ),
	{   id          => 1,
		name        => 'admin',
		email       => $admin_mail,
		fname       => undef,
		lname       => undef,
		verified    => 1,
		register_ts => re('^\d{10}$'),
	},
	'show user details'
);

is_deeply(
	$admin->get_user( id => 2 ),
	{   error => 'no_such_user',
	},
	'asking for not existing user'
);

is_deeply( $admin->add_user( %{ $users[0] } ), { error => 'invalid_verify' }, 'no verify field provided' );
$users[0]{verify} = 'abc';
is_deeply( $admin->add_user( %{ $users[0] } ), { error => 'invalid_verify' }, 'really invalid verify field provided' );

$users[0]{verify} = 'verified';
is_deeply( $admin->add_user( %{ $users[0] } ), { error => 'email_used' }, 'try to add user with same mail' );

$users[0]{email} = ucfirst $users[0]{email};
is_deeply(
	$admin->add_user( %{ $users[0] } ), { error => 'email_used' },
	'try to add user with same mail after ucfirst'
);

diag('email is case insensitive and saves as lower case');
$users[0]{email} = uc $users[0]{email};
is_deeply( $admin->add_user( %{ $users[0] } ), { error => 'email_used' }, 'try to add user with same mail after uc' );

$users[0]{email} = 'test2@dwimmer.org';
$users[0]{pw1} = $users[0]{pw2} = $users[0]{password};
is_deeply( $admin->add_user( %{ $users[0] } ), { success => 1 }, 'add user with different mail' );

my %usr = %{ $users[0] };
$usr{uname} = uc $usr{uname};
$usr{email} =  'test3@dwimmer.org';
is_deeply( $admin->add_user( %usr ), { error => 'username_taken' }, 'add user with same username in different case' );

is_deeply(
	$admin->list_users,
	{   users => [
			{ id => 1, name => 'admin', },
			{ id => 2, name => $users[0]{uname} },
		]
	},
	'list_users'
);

cmp_deeply(
	$admin->get_user( id => 1 ),
	{   id          => 1,
		name        => 'admin',
		email       => $admin_mail,
		fname       => undef,
		lname       => undef,
		verified    => 1,
		register_ts => re('^\d{10}$'),
	},
	'show user details'
);
cmp_deeply(
	$admin->get_user( id => 2 ),
	{   id          => 2,
		name        => $users[0]{uname},
		email       => $users[0]{email},
		fname       => undef,
		lname       => undef,
		verified    => 1,
		register_ts => re('^\d{10}$'),
	},
	'show user details'
);



cmp_deeply(
	$admin->get_pages,
	{   rows => [
			{   id       => 1,
				filename => '/',
				title    => 'Welcome to your Dwimmer installation',
			},
		]
	},
	'get pages'
);


is_deeply(
	$admin->page( filename => '/' ),
	{

		#	dwimmer_version => $Dwimmer::Client::VERSION,
		#	userid => 1,
		#	logged_in => 1,
		#	username => 'admin',
		page => {
			body     => '<h1>Dwimmer</h1>',
			title    => 'Welcome to your Dwimmer installation',
			filename => '/',
			author   => 'admin',
			revision => 1,
		},
	},
	'page data'
);

is_deeply(
	$admin->save_page(
		body     => "New text [[link]] here and [[$links[2]]] here",
		title    => 'New main title',
		filename => '/',
	),
	{ success => 1 },
	'save_page'
);
is_deeply(
	$admin->page( filename => '/' ),
	{

		#	dwimmer_version => $Dwimmer::Client::VERSION,
		#	userid => 1,
		#	logged_in => 1,
		#	username => 'admin',
		page => {
			body     => "New text [[link]] here and [[$links[2]]] here",
			title    => 'New main title',
			filename => '/',
			author   => 'admin',
			revision => 2,
		},
	},
	'page data after save'
);

$w->get_ok($URL);

$w->content_like(
	qr{New text <a href="link">link</a> here and <a href="$exp_links[2]">$exp_links[2]</a> here},
	'link markup works'
);

# for creating new page we require a special field to reduce the risk of
# accidental page creation
is_deeply(
	$admin->save_page(
		body     => 'New text',
		title    => 'New title of xyz',
		filename => '/xyz',
	),
	{ error => 'page_does_not_exist', details => '/xyz' },
	'save_page'
);
cmp_deeply(
	$admin->get_pages,
	{   rows => [
			{   id       => 1,
				filename => '/',
				title    => 'New main title',
			},
		]
	},
	'get pages'
);
is_deeply(
	$admin->save_page(
		body     => 'New text',
		title    => 'New title of xyz',
		filename => '/xyz',
		create   => 1,
	),
	{ success => 1 },
	'create new page'
);
cmp_deeply(
	$admin->get_pages,
	{   rows => [
			{   id       => 1,
				filename => '/',
				title    => 'New main title',
			},
			{   id       => 2,
				filename => '/xyz',
				title    => 'New title of xyz',
			},
		]
	},
	'get pages'
);

is_deeply(
	$admin->save_page(
		%{ $pages[2] },
		create => 1,
	),
	{ success => 1 },
	'create new page'
);
cmp_deeply(
	$admin->get_pages,
	{   rows => [
			{   id       => 1,
				filename => '/',
				title    => 'New main title',
			},
			{   id       => 2,
				filename => '/xyz',
				title    => 'New title of xyz',
			},
			$exp_pages[2],
		]
	},
	'get pages'
);
$w->get_ok("$url$pages[2]{filename}");
$w->content_like(qr{$pages[2]{body}});

#diag(explain($admin->search( text => 'xyz' )));


my $user = Dwimmer::Client->new( host => $url );
is_deeply(
	$user->list_users,
	{   dwimmer_version => $Dwimmer::Client::VERSION,
		error           => 'not_logged_in',
	},
	'to list_users page'
);
is_deeply(
	$user->login( username => $users[0]{uname}, password => $users[0]{password} ),
	{   success   => 1,
		username  => $users[0]{uname},
		userid    => 2,
		logged_in => 1,
	},
	'user logged in'
);
cmp_deeply(
	$user->session,
	{   logged_in => 1,
		username  => $users[0]{uname},
		userid    => 2,
		data      => ignore(),
		site      => ignore(),
	},
	'not logged in'
);
cmp_deeply(
	$user->get_user( id => 2 ),
	{   id          => 2,
		name        => $users[0]{uname},
		email       => $users[0]{email},
		fname       => undef,
		lname       => undef,
		verified    => 1,
		register_ts => re('^\d{10}$'),
	},
	'show user own details'
);

# TODO should this user be able to see the list of user?
# TODO this user should NOT be able to add new users

my $pw1 = 'qwerty';
is_deeply(
	$user->change_my_password( new_password => $pw1, old_password => $users[0]{password} ),
	{ success => 1 }, 'password changed'
);

is_deeply( $user->logout, { success => 1 }, 'logout' );
cmp_deeply(
	$user->session,
	{   logged_in => 0,
		data      => ignore(),
		site      => ignore(),

		#	dwimmer_version => $Dwimmer::Client::VERSION,
	},
	'session'
);


#diag(explain($user->get_user(id => 2)));
is_deeply(
	$user->get_user( id => 2 ),
	{   dwimmer_version => $Dwimmer::Client::VERSION,
		error           => 'not_logged_in',
	},
	'cannot get user data afer logout'
);

my $guest = Dwimmer::Client->new( host => $URL );
is_deeply(
	$guest->list_users,
	{   dwimmer_version => $Dwimmer::Client::VERSION,
		error           => 'not_logged_in',
	},
	'to list_users page'
);

#diag(read_file($ENV{DWIMMER_MAIL}));

# TODO configure smtp server for email

my $failed_pw = 'uiop';
is_deeply(
	$user->change_my_password( new_password => $failed_pw, old_password => $pw1 ),
	{   dwimmer_version => $Dwimmer::Client::VERSION,
		error           => 'not_logged_in',
	},
	'need to login to change password'
);

#diag(explain(	$user->login( username => $users[0]{uname}, password => $pw1 ) ));

is_deeply(
	$user->login( username => $users[0]{uname}, password => $pw1 ),
	{   success   => 1,
		username  => $users[0]{uname},
		userid    => 2,
		logged_in => 1,
	},
	'user logged in with new password'
);

diag('Check if admin can change the password of another user based on uid');
my $pw3 = 'dgjkl';
is_deeply(
	$admin->change_password( new_password => $pw3, admin_password => $users[0]{password}, uid => 2 ),
	{ success => 1 }, 'password changed'
);

is_deeply( $user->logout, { success => 1 }, 'logout' );
cmp_deeply(
	$user->session,
	{   logged_in => 0,
		data      => ignore(),
		site      => ignore(),

		#	dwimmer_version => $Dwimmer::Client::VERSION,
	},
	'session'
);

is_deeply(
	$user->login( username => $users[0]{uname}, password => $pw3 ),
	{   success   => 1,
		username  => $users[0]{uname},
		userid    => 2,
		logged_in => 1,
	},
	'user logged in with new password'
);


diag('Check if admin can change the password of another user based on name');
my $pw4 = 'ladbhlash';
is_deeply(
	$admin->change_password( new_password => $pw4, admin_password => $users[0]{password}, name => $users[0]{uname} ),
	{ success => 1 }, 'password changed'
);

is_deeply( $user->logout, { success => 1 }, 'logout' );
cmp_deeply(
	$user->session,
	{   logged_in => 0,
		data      => ignore(),
		site      => ignore(),

		#	dwimmer_version => $Dwimmer::Client::VERSION,
	},
	'session'
);

is_deeply(
	$user->login( username => $users[0]{uname}, password => $pw4 ),
	{   success   => 1,
		username  => $users[0]{uname},
		userid    => 2,
		logged_in => 1,
	},
	'user logged in with new password'
);





test_rss([
           {
             'dc:creator' => 'admin',
             'link' => "$url/space and.dot and " . '$@% too',
             'rdf:about' => "$url/space and.dot and " . '$@% too',
             'dc:subject' => 'dotspace',
             'title' => 'dotspace',
             'dc:date' => ignore(),
             'description' => 'File with space and dot'
           },
           {
             'dc:creator' => 'admin',
             'link' => "$url/xyz",
             'rdf:about' => "$url/xyz",
             'dc:subject' => 'New title of xyz',
             'title' => 'New title of xyz',
             'dc:date' => ignore(),
             'description' => 'New text'
           },
           {
             'dc:creator' => 'admin',
             'link' => $URL,
             'rdf:about' => $URL,
             'dc:subject' => 'New main title',
             'title' => 'New main title',
             'dc:date' => ignore(),
             'description' => 'New text [[link]] here and [[space and.dot and $@% too]] here'
           }
]);
test_sitemap([
           {
             'loc' => $URL
           },
           {
             'loc' => "$url/xyz"
           },
           {
             'loc' => "$url/space and.dot and " . '$@% too'
           }
         ]);

exit;

sub test_rss {
	my ($expected_items) = @_;

	local $Test::Builder::Level = $Test::Builder::Level + 1;

	my $rss_str = LWP::Simple::get("$url/update.rss");
	#diag($rss_str);
	my $xml = XML::Simple->new(
		KeepRoot   => 1,
		ForceArray => 0,
		KeyAttr    => { urlset => 'xmlns' },
	);
	my $rss = $xml->XMLin( $rss_str );
#	diag(Dumper $rss);
#	diag(Dumper $rss->{'rdf:RDF'}{channel});
#	diag(Dumper $rss->{'rdf:RDF'}{item});
	cmp_deeply($rss->{'rdf:RDF'}{item}, $expected_items);

	return;
}


sub test_sitemap {
	my ($expected) = @_;

	local $Test::Builder::Level = $Test::Builder::Level + 1;
	my $sitemap_str = LWP::Simple::get("$url/sitemap.xml");
	#diag($sitemap_str);
	my $xml = XML::Simple->new(
		KeepRoot   => 1,
		ForceArray => 0,
		KeyAttr    => { urlset => 'xmlns' },
	);
	my $sitemap = $xml->XMLin( $sitemap_str );
	#diag(Dumper $sitemap);
	#diag(Dumper $sitemap->{urlset}{url});
	cmp_deeply($sitemap->{urlset}{url}, $expected, 'sitemap');

	return;
}

