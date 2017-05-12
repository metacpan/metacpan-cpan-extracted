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

plan( tests => 9 );

my @pages = (
	{   body     => 'some body',
		title    => 'Welcome to your Dwimmer installation',
		filename => '/',
	},
	{   body     => 'before [[http://www.dwimmer.org/selftest]] between [[https://www.security.org/]] after',
		title    => 'dotspace',
		filename => '/mylinks',
	},
	{   body     => '[[poll://testing-polls]]',
		title    => 'dotspace',
		filename => '/mypoll',
	}
);
my @exp_pages =
	map { { id => $_ + 1, filename => $pages[$_]->{filename}, title => $pages[$_]->{title}, } } 0 .. @pages - 1;
my @links = map { $_->{filename} ? substr( $_->{filename}, 1 ) : '' } @pages;
my @exp_links = map { quotemeta($_) } @links;


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

is_deeply(
	$admin->save_page(
		%{ $pages[1] },
		create => 1,
	),
	{ success => 1 },
	'create new page'
);

# diag(explain($admin->get_pages));
cmp_deeply(
	$admin->get_pages,
	{   rows => [
			$exp_pages[0],
			$exp_pages[1],
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

# diag(explain($admin->get_pages));
cmp_deeply(
	$admin->get_pages,
	{   rows => [
			$exp_pages[0],
			$exp_pages[1],
			$exp_pages[2],
		]
	},
	'get pages'
);

my $w = Test::WWW::Mechanize->new;
$w->get_ok("$url$pages[1]{filename}");
$w->content_like(
	qr{before <a href="http://www.dwimmer.org/selftest">www.dwimmer.org/selftest</a> between <a href="https://www.security.org/">www.security.org/</a> after}
);
$w->get_ok("$url$pages[2]{filename}");

#$w->content_like( qr{.} );
#diag($w->content);
isa_ok( $w->form_id('poll'), 'HTML::Form' );

#diag($w->form_id('poll'));

#my $user = Dwimmer::Client->new( host => $url );

#TODO : copy the json poll file to the test directory
#check if the file could be found
#create the form
