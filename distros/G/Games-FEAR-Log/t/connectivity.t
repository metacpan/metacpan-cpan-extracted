#!perl -T

use Test::More;

# load module to test
use Games::FEAR::Log;

# join all supported drivers into ORed string, trapping in an eval
my $drivers;
eval { $drivers = join '|', Games::FEAR::Log::supported_dbds(); };

# if environment DSN doesnt exist
if( !exists $ENV{DBI_DSN} ) {
  # fail test, we need a DBI_DSN
  plan skip_all => "Skipping connectivity test, DBI_DSN not found";
  exit;
}

# if environment DSN isnt one of the supported drivers
if( $ENV{DBI_DSN} !~ m/\A DBI : (?:$drivers) : /msxi ) {
  # fail test, we need a supported DBI_DSN
  plan skip_all => "Skipping connectivity test, compatible DBI_DSN not found";
  exit;
}

# declare number of tests
plan tests => 99;

# test that no eval error occurred
ok($@ eq '', 'get supported db driver names');

# connect to database for both failing to connect and failing to login
my $dbh;
eval {
  $dbh = DBI->connect($ENV{DBI_DSN}, $ENV{DBI_USER}, $ENV{DBI_PASS},
    {RaiseError => 1, PrintError => 0, PrintWarn => 0, AutoCommit => 0});
};
if ($@) {
  if (defined $DBI::err) {
    BAIL_OUT("error connecting: $DBI::errstr");
  }
  else {
    BAIL_OUT("error connecting: $@");
  }
  exit;
}
ok($@ eq '', 'test connect to database succeeded');

# disconnect from database
eval { $dbh->disconnect; };
if ($@) {
  if (defined $DBI::err) {
    BAIL_OUT("error disconnecting: $DBI::errstr");
  }
  else {
    BAIL_OUT("error disconnecting: $@");
  }
  exit;
}
ok($@ eq '', 'test disconnect from database succeeded');

# create new module object (will create table if it doesnt exist)
eval {
  $log_object = new Games::FEAR::Log( {
    -logfile => \*DATA,
    -dbi => [ $ENV{DBI_DSN}, $ENV{DBI_USER}, $ENV{DBI_PASS} ],
    -table => 'GamesFEARLog_test',
  } );
};
if ($@) {
  BAIL_OUT("error instantiating object: $@");
  exit;
}
ok($@ eq '', 'instantiated new object');

# process provided log data
$log_object->process();

__DATA__
1158875318
[Thu Sep 21 17:48:38 2006] 
[Thu Sep 21 17:48:38 2006] ------------------------------------------
[Thu Sep 21 17:48:38 2006] Server started.
[Thu Sep 21 18:12:05 2006] Client connected: Player1
[Thu Sep 21 18:12:26 2006] Client connected: Player2
[Thu Sep 21 18:16:50 2006] Client disconnected: Player2
[Thu Sep 21 18:16:55 2006] Client disconnected: Player1
[Thu Sep 21 18:27:51 2006] 
[Thu Sep 21 18:27:51 2006] *** Results for Map: Worlds\ReleaseMultiplayer\Supercollider
[Thu Sep 21 18:27:51 2006] 
[Thu Sep 21 18:27:51 2006] Team: Team 1
[Thu Sep 21 18:27:51 2006] Score: -2
[Thu Sep 21 18:27:51 2006] 
[Thu Sep 21 18:27:51 2006] Team: Team 2
[Thu Sep 21 18:27:51 2006] Score: 7
[Thu Sep 21 18:27:51 2006] 
[Thu Sep 21 18:27:51 2006] 
[Thu Sep 21 18:31:42 2006] Client connected: Player3
[Thu Sep 21 18:37:10 2006] Client disconnected: Player3
[Thu Sep 21 18:37:22 2006] Client connected: Player4
[Thu Sep 21 18:37:31 2006] Client connected: Player3
[Thu Sep 21 18:38:20 2006] Client connected: Player1
[Thu Sep 21 18:39:18 2006] Client connected: Player5
[Thu Sep 21 18:41:17 2006] Client connected: Player6
[Thu Sep 21 18:41:20 2006] Client disconnected: Player3
[Thu Sep 21 18:41:30 2006] Client connected: Player3
[Thu Sep 21 18:41:53 2006] Client connected: Player7
[Thu Sep 21 18:42:45 2006] Client disconnected: Player3
[Thu Sep 21 18:42:51 2006] Client connected: Player3
[Thu Sep 21 18:44:09 2006] Client disconnected: Player5
[Thu Sep 21 18:44:56 2006] Client disconnected: Player3
[Thu Sep 21 18:45:05 2006] Client connected: Player3
[Thu Sep 21 18:47:15 2006] Client disconnected: Player7
[Thu Sep 21 18:47:20 2006] Client connected: Player8
[Thu Sep 21 18:53:36 2006] 
[Thu Sep 21 18:53:36 2006] *** Results for Map: Worlds\ReleaseMultiplayer\warehouse_hell_v1
[Thu Sep 21 18:53:36 2006] 
[Thu Sep 21 18:53:36 2006] Team: Team 1
[Thu Sep 21 18:53:36 2006] Score: 93
[Thu Sep 21 18:53:36 2006] 
[Thu Sep 21 18:53:36 2006] Player: Player1 (uid: ad7023b74f6271acd31e1bd287613b6d)
[Thu Sep 21 18:53:36 2006] Score: 55
[Thu Sep 21 18:53:36 2006] Kills: 14
[Thu Sep 21 18:53:36 2006] Deaths: 15
[Thu Sep 21 18:53:36 2006] Team Kills: 0
[Thu Sep 21 18:53:36 2006] Suicides: 0
[Thu Sep 21 18:53:36 2006] Objective: 0
[Thu Sep 21 18:53:36 2006] 
[Thu Sep 21 18:53:36 2006] Player: Player6 (uid: 5fdccc5043dc4dac9d7b4afb8469eb4f)
[Thu Sep 21 18:53:36 2006] Score: 38
[Thu Sep 21 18:53:36 2006] Kills: 11
[Thu Sep 21 18:53:36 2006] Deaths: 17
[Thu Sep 21 18:53:36 2006] Team Kills: 0
[Thu Sep 21 18:53:36 2006] Suicides: 0
[Thu Sep 21 18:53:36 2006] Objective: 0
[Thu Sep 21 18:53:36 2006] 
[Thu Sep 21 18:53:36 2006] Team: Team 2
[Thu Sep 21 18:53:36 2006] Score: 135
[Thu Sep 21 18:53:36 2006] 
[Thu Sep 21 18:53:36 2006] Player: Player4 (uid: e9483e8ae76debf1418ab9dfaa4c01e8)
[Thu Sep 21 18:53:36 2006] Score: 61
[Thu Sep 21 18:53:36 2006] Kills: 15
[Thu Sep 21 18:53:36 2006] Deaths: 14
[Thu Sep 21 18:53:36 2006] Team Kills: 0
[Thu Sep 21 18:53:36 2006] Suicides: 0
[Thu Sep 21 18:53:36 2006] Objective: 0
[Thu Sep 21 18:53:36 2006] 
[Thu Sep 21 18:53:36 2006] Player: Player8 (uid: b2ea955c1b3fa5c35ef6a6f576cdf2af)
[Thu Sep 21 18:53:36 2006] Score: 46
[Thu Sep 21 18:53:36 2006] Kills: 10
[Thu Sep 21 18:53:36 2006] Deaths: 4
[Thu Sep 21 18:53:36 2006] Team Kills: 0
[Thu Sep 21 18:53:36 2006] Suicides: 0
[Thu Sep 21 18:53:36 2006] Objective: 0
[Thu Sep 21 18:53:36 2006] 
[Thu Sep 21 18:53:36 2006] 
[Thu Sep 21 18:57:06 2006] Client connected: Player9
[Thu Sep 21 18:57:47 2006] Client disconnected: Player6
[Thu Sep 21 18:58:01 2006] Client disconnected: Player3
[Thu Sep 21 18:58:14 2006] Client connected: Player3
[Thu Sep 21 18:58:17 2006] Client disconnected: Player8
[Thu Sep 21 18:58:55 2006] Client connected: Player6
[Thu Sep 21 18:59:03 2006] Client disconnected: Player1
[Thu Sep 21 18:59:52 2006] Client disconnected: Player3
[Thu Sep 21 18:59:58 2006] Client connected: Player3
[Thu Sep 21 19:00:53 2006] Client disconnected: Player3
[Thu Sep 21 19:01:08 2006] Client connected: Player3
[Thu Sep 21 19:01:55 2006] Client disconnected: Player3
[Thu Sep 21 19:02:11 2006] Client connected: Player3
[Thu Sep 21 19:02:38 2006] Client disconnected: Player3
[Thu Sep 21 19:02:51 2006] Client connected: Player3
[Thu Sep 21 19:03:03 2006] Client disconnected: Player3
[Thu Sep 21 19:03:22 2006] Client connected: Player10
[Thu Sep 21 19:03:27 2006] Client disconnected: Player10
[Thu Sep 21 19:03:31 2006] Client connected: Player3
[Thu Sep 21 19:03:53 2006] Client disconnected: Player3
[Thu Sep 21 19:04:24 2006] Client connected: Player3
[Thu Sep 21 19:06:54 2006] Client disconnected: Player3
[Thu Sep 21 19:07:40 2006] Client connected: Player11
[Thu Sep 21 19:07:50 2006] Client connected: Player3
[Thu Sep 21 19:08:02 2006] Client connected: Player12
[Thu Sep 21 19:09:00 2006] Client disconnected: Player3
[Thu Sep 21 19:10:01 2006] Client connected: Player13
[Thu Sep 21 19:12:22 2006] Client connected: Player14
[Thu Sep 21 19:12:30 2006] Client connected: Player15
[Thu Sep 21 19:12:35 2006] Client disconnected: Player15
[Thu Sep 21 19:13:03 2006] Client connected: Player3
[Thu Sep 21 19:13:04 2006] Client connected: Player16
[Thu Sep 21 19:14:26 2006] Client connected: Player17
[Thu Sep 21 19:15:37 2006] 
[Thu Sep 21 19:15:37 2006] *** Results for Map: Worlds\ReleaseMultiplayer\Q1DM4
[Thu Sep 21 19:15:37 2006] 
[Thu Sep 21 19:15:37 2006] Team: Team 1
[Thu Sep 21 19:15:37 2006] Score: 364
[Thu Sep 21 19:15:37 2006] 
[Thu Sep 21 19:15:37 2006] Player: Player11 (uid: 555f070eda09110864c6fcd812bce54e)
[Thu Sep 21 19:15:37 2006] Score: 136
[Thu Sep 21 19:15:37 2006] Kills: 31
[Thu Sep 21 19:15:37 2006] Deaths: 10
[Thu Sep 21 19:15:37 2006] Team Kills: 0
[Thu Sep 21 19:15:37 2006] Suicides: 3
[Thu Sep 21 19:15:37 2006] Objective: 0
[Thu Sep 21 19:15:37 2006] 
[Thu Sep 21 19:15:37 2006] Player: Player6 (uid: 5fdccc5043dc4dac9d7b4afb8469eb4f)
[Thu Sep 21 19:15:37 2006] Score: 110
[Thu Sep 21 19:15:37 2006] Kills: 27
[Thu Sep 21 19:15:37 2006] Deaths: 22
[Thu Sep 21 19:15:37 2006] Team Kills: 0
[Thu Sep 21 19:15:37 2006] Suicides: 1
[Thu Sep 21 19:15:37 2006] Objective: 0
[Thu Sep 21 19:15:37 2006] 
[Thu Sep 21 19:15:37 2006] Player: Player12 (uid: b178571587dd9c1552813cfdbca10420)
[Thu Sep 21 19:15:37 2006] Score: 91
[Thu Sep 21 19:15:37 2006] Kills: 21
[Thu Sep 21 19:15:37 2006] Deaths: 12
[Thu Sep 21 19:15:37 2006] Team Kills: 0
[Thu Sep 21 19:15:37 2006] Suicides: 1
[Thu Sep 21 19:15:37 2006] Objective: 0
[Thu Sep 21 19:15:37 2006] 
[Thu Sep 21 19:15:37 2006] Player: Player16 (uid: 1833a02539439f87bb92a865ead8e441)
[Thu Sep 21 19:15:37 2006] Score: 27
[Thu Sep 21 19:15:37 2006] Kills: 6
[Thu Sep 21 19:15:37 2006] Deaths: 3
[Thu Sep 21 19:15:37 2006] Team Kills: 0
[Thu Sep 21 19:15:37 2006] Suicides: 1
[Thu Sep 21 19:15:37 2006] Objective: 0
[Thu Sep 21 19:15:37 2006] 
[Thu Sep 21 19:15:37 2006] Team: Team 2
[Thu Sep 21 19:15:37 2006] Score: 136
[Thu Sep 21 19:15:37 2006] 
[Thu Sep 21 19:15:37 2006] Player: Player4 (uid: e9483e8ae76debf1418ab9dfaa4c01e8)
[Thu Sep 21 19:15:37 2006] Score: 65
[Thu Sep 21 19:15:37 2006] Kills: 21
[Thu Sep 21 19:15:37 2006] Deaths: 37
[Thu Sep 21 19:15:37 2006] Team Kills: 0
[Thu Sep 21 19:15:37 2006] Suicides: 1
[Thu Sep 21 19:15:37 2006] Objective: 0
[Thu Sep 21 19:15:37 2006] 
[Thu Sep 21 19:15:37 2006] Player: Player13 (uid: 38efbbdf702bc31ba82ff0ce9055feae)
[Thu Sep 21 19:15:37 2006] Score: 32
[Thu Sep 21 19:15:37 2006] Kills: 10
[Thu Sep 21 19:15:37 2006] Deaths: 15
[Thu Sep 21 19:15:37 2006] Team Kills: 0
[Thu Sep 21 19:15:37 2006] Suicides: 1
[Thu Sep 21 19:15:37 2006] Objective: 0
[Thu Sep 21 19:15:37 2006] 
[Thu Sep 21 19:15:37 2006] Player: Player9 (uid: de3c12249b3a8a0e3abd27dd5873dadf)
[Thu Sep 21 19:15:37 2006] Score: 13
[Thu Sep 21 19:15:37 2006] Kills: 8
[Thu Sep 21 19:15:37 2006] Deaths: 24
[Thu Sep 21 19:15:37 2006] Team Kills: 0
[Thu Sep 21 19:15:37 2006] Suicides: 1
[Thu Sep 21 19:15:37 2006] Objective: 0
[Thu Sep 21 19:15:37 2006] 
[Thu Sep 21 19:15:37 2006] Player: Player14 (uid: 618fb3b0fdb40dd0dabfb4a36b9c2e61)
[Thu Sep 21 19:15:37 2006] Score: 26
[Thu Sep 21 19:15:37 2006] Kills: 8
[Thu Sep 21 19:15:37 2006] Deaths: 9
[Thu Sep 21 19:15:37 2006] Team Kills: 0
[Thu Sep 21 19:15:37 2006] Suicides: 0
[Thu Sep 21 19:15:37 2006] Objective: 0
[Thu Sep 21 19:15:37 2006] 
[Thu Sep 21 19:15:37 2006] 
