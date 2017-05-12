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

plan( tests => 6 );


use Dwimmer::Client;
my $user = Dwimmer::Client->new( host => $url );


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
	$admin->create_feed_collector( name => 'Foo Bar' ),
	{   success => 1,
	},
	'feed_collector_created'
);

is_deeply(
	$admin->create_feed_collector( name => 'Foo Bar' ),
	{   error => 'feed_collector_exists',
	},
	'feed_collector_created already exists'
);

#diag(explain($admin->feed_collectors()));
is_deeply(
	$admin->feed_collectors(),
	{   rows => [
			{   id      => 1,
				name    => 'Foo Bar',
				ownerid => 1,
			},
		],
	},
	'list feed collectors of current user'
);


# TODO make sure only the owner can add feeds
is_deeply(
	$admin->add_feed(
		collector => 1,
		title     => 'Title of Feed',
		url       => 'http://dwimmer.org/',
		feed      => 'http://dwimmer.org/feed.rss',
	),
	{ success => 1 },
	'adding a feed'
);

# TODO list feeds in one collector
#diag(explain($admin->feeds( collector => 1 )));
is_deeply(
	$admin->feeds( collector => 1 ),
	{   'rows' => [
			{   'feed'  => 'http://dwimmer.org/feed.rss',
				'id'    => 1,
				'title' => 'Title of Feed',
				'url'   => 'http://dwimmer.org/'
			}
		]
	},
	'feeds'
);



# run feed collection?
#   foreach collector
#      foreach feed
#         process


