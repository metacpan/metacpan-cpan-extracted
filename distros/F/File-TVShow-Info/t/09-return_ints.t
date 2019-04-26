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

subtest "Luther.S05E03.720p.AMZN.WEB-DL.DDP5.1.H.264-NTb[eztv].mkv" => sub {
  my $obj = File::TVShow::Info->new("Luther.S05E03.720p.AMZN.WEB-DL.DDP5.1.H.264-NTb[eztv].mkv");
  can_ok($obj, 'season_to_int');
  is($obj->season(), '05', "Season: 05");
  is($obj->season_to_int(), 5, "Season int: 5");
  can_ok($obj, 'episode_to_int');
  is($obj->episode(), '03', "Episode: 03");
  is($obj->episode_to_int() , 3, "Episode int: 3");
};

subtest "Luther.S00E01.720p.AMZN.WEB-DL.DDP5.1.H.264-NTb[eztv].mkv" => sub {
  my $obj = File::TVShow::Info->new("Luther.S00E01.720p.AMZN.WEB-DL.DDP5.1.H.264-NTb[eztv].mkv");
  is($obj->season(), '00', "Season: 00");
  is($obj->season_to_int(), 0, "Season int: 0");
  is($obj->episode(), '01', "Episode: 01");
  is($obj->episode_to_int() , 1, "Episode int: 1");
};
done_testing();
