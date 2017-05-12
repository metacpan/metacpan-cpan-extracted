use strict;
use warnings;

use Test::More;
plan skip_all => 'Convert the test to use Plack::Test';
exit;


use t::lib::Dwimmer::Test qw(start $admin_mail @users);

use Cwd qw(abs_path);
use Data::Dumper qw(Dumper);

my $password = 'dwimmer';

my $run = start($password);

eval "use Test::More";
eval "use Test::Deep";
require Test::WWW::Mechanize;
plan( skip_all => 'Unsupported OS' ) if not $run;

my $url = "http://localhost:$ENV{DWIMMER_PORT}";

plan( tests => 17 );


my $w = Test::WWW::Mechanize->new;
$w->get_ok($url);
$w->content_like( qr{Welcome to your Dwimmer installation}, 'content ok' );
$w->get_ok("$url/other");
$w->content_like( qr{Page does not exist}, 'content of missing pages is ok' );

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

cmp_deeply(
	$admin->history( filename => '/' ),
	{   rows => [
			{   author    => 'admin',
				revision  => 1,
				timestamp => re('\d'),
				filename  => '/',
			},
		]
	},
	'history'
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
		body     => 'New text [[link]] here',
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
			body     => 'New text [[link]] here',
			title    => 'New main title',
			filename => '/',
			author   => 'admin',
			revision => 2,
		},
	},
	'page data after save'
);

is_deeply(
	$admin->page( filename => '/', revision => 1 ),
	{   page => {
			body     => '<h1>Dwimmer</h1>',
			title    => 'Welcome to your Dwimmer installation',
			filename => '/',
			author   => 'admin',
			revision => 1,
		},
	},
	'page data revision 1'
);

is_deeply(
	$admin->page( filename => '/', revision => 2 ),
	{   page => {
			body     => 'New text [[link]] here',
			title    => 'New main title',
			filename => '/',
			author   => 'admin',
			revision => 2,
		},
	},
	'page data revision 2'
);

cmp_deeply(
	$admin->history( filename => '/' ),
	{   rows => [
			{   author    => 'admin',
				revision  => 2,
				timestamp => re('\d'),
				filename  => '/',
			},
			{   author    => 'admin',
				revision  => 1,
				timestamp => re('\d'),
				filename  => '/',
			},
		]
	},
	'history'
);

$w->get_ok($url);
$w->content_like( qr{New text <a href="link">link</a> here}, 'link markup works' );

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



