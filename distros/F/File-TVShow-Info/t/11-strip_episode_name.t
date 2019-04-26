#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;
use Data::Dumper;

unless ( $ENV{DEV_TESTING} ) {
    plan( skip_all => "Author tests not required for installation" );
} else {
  use File::TVShow::Info;
}

subtest "Life.on.Mars.S05E03.Pilot.720p.AMZN.WEB-DL.DDP5.1.H.264-NTb[eztv].mkv" => sub {
  my $obj = File::TVShow::Info->new("Life.on.Mars.S05E03.Pilot.720p.AMZN.WEB-DL.DDP5.1.H.264-NTb[eztv].mkv");
  can_ok($obj, 'strip_episode_name');
  is($obj->strip_episode_name(), "Pilot", " Episode Name: Pilot");
};

subtest "Life.on-Mars.S00E01.So.Far.720p.AMZN.WEB-DL.DDP5.1.H.264-NTb[eztv].mkv" => sub {
  my $obj = File::TVShow::Info->new("Life.on-Mars.S00E01.So.Far.720p.AMZN.WEB-DL.DDP5.1.H.264-NTb[eztv].mkv");
  is($obj->strip_episode_name(), "So Far", "Episode Name: So Far");
};

subtest "Life.on-Mars.S00E01.So-Far.720p.AMZN.WEB-DL.DDP5.1.H.264-NTb[eztv].mkv" => sub {
  my $obj = File::TVShow::Info->new("Life.on-Mars.S00E01.So-Far.720p.AMZN.WEB-DL.DDP5.1.H.264-NTb[eztv].mkv");
  is($obj->strip_episode_name(), "So Far", "Episode Name: So Far");
};

subtest "Life.on-Mars.S00E01.So-Far.AMZN.WEB-DL.DDP5.1.H.264-NTb[eztv].mkv" => sub {
  my $obj = File::TVShow::Info->new("Life.on-Mars.S00E01.So-Far.AMZN.WEB-DL.DDP5.1.H.264-NTb[eztv].mkv");
  is($obj->strip_episode_name(), "So Far", "Episode Name: So Far");
};


done_testing();
