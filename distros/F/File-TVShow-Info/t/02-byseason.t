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

subtest "test.S01E01.avi" => sub {
  my $obj = File::TVShow::Info->new("test.S01E01.avi");
  is($obj->is_tv_show(), 1, "This is a valid TV show");
  is($obj->show_name(), "test", "show name is test");
  is($obj->is_by_date(), 0, "This is not sorted by date");
  is($obj->is_tv_show(), 1, "This is a TV show.");
  can_ok($obj, 'is_multi_episode');
  is($obj->is_multi_episode(),0,"This is not a multi-episode file.");
  can_ok($obj, 'season');
  is($obj->season(),'01', "Season: 01");
  can_ok($obj, 'episode');
  is($obj->episode(), "01", "Episode 01");
  can_ok($obj, 'season_episode');
  is($obj->season_episode(), "S01E01", "season_episode returns SO1EO1");
  can_ok($obj, 'is_by_season');
  is($obj->is_by_season(), 1, "SXXEXX or SXXEXXEXX format");
  is($obj->ext(),"avi", "extension is avi");

};

subtest "test.S01E01E02.avi" => sub {
  my $obj = File::TVShow::Info->new("test.S01E01E02.avi");
  is($obj->is_tv_show(), 1, "This is a valid TV show");
  is($obj->show_name(), "test", "show name is test");
  is($obj->is_by_date(), 0, "This is not sorted by date");
  is($obj->is_tv_show(), 1, "This is a TV show.");
  can_ok($obj, 'season');
  is($obj->season(),'01', "Season: 01");
  can_ok($obj, 'is_multi_episode');
  is($obj->is_multi_episode(), 1, "This is a multi-episode file.");
  can_ok($obj, 'episode');
  is($obj->episode(), "01", "Episode 01");
  can_ok($obj, 'season_episode');
  is($obj->season_episode(), "S01E01E02", "season_episode returns SO1EO1E02");
  is($obj->ext(),"avi", "extension is avi");

};

subtest "test.S01E02.EXTRA_META.avi" => sub {
  my $obj = File::TVShow::Info->new("test.S01E02.extra_meta.avi");
  is($obj->is_tv_show(), 1, "This is a valid TV show");
  is($obj->show_name(), "test", "show name is test");
  is($obj->is_multi_episode(), 0,"This is not a multi-episode file.");
  is($obj->season_episode(), "S01E02", "season_episode returns SO1EO2");
  can_ok($obj, 'episode_name');
  is($obj->episode_name(), "", "Episode Name: ");
};

subtest "test.S01E02E03.EXTRA_META.avi" => sub {
  my $obj = File::TVShow::Info->new("test.S01E02E03.extra_meta.avi");
  is($obj->is_tv_show(), 1, "This is a valid TV show");
  is($obj->show_name(), "test", "show name is test");
  is($obj->is_multi_episode(), 1, "This is a multi-episode file.");
  is($obj->season_episode(), "S01E02E03", "season_episode returns SO1EO2E03");
  can_ok($obj, 'episode_name');
  is($obj->episode_name(), "", "Episode Name: ");
};

subtest "test.S01E02E03.Pilot.720p.avi" => sub {
  my $obj = File::TVShow::Info->new("test.S01E02E03.Pilot.720p.avi");
  is($obj->is_tv_show(), 1, "This is a valid TV show");
  is($obj->show_name(), "test", "show name is test");
  is($obj->is_multi_episode(), 1, "This is a multi-episode file.");
  is($obj->season_episode(), "S01E02E03", "season_episode returns SO1EO2E03");
  can_ok($obj, 'episode_name');
  is($obj->episode_name(), "Pilot", "Episode Name: Pilot");
};

subtest "Luther.S05E03.720p.AMZN.WEB-DL.DDP5.1.H.264-NTb[eztv].mkv" => sub {
  my $obj = File::TVShow::Info->new("Luther.S05E03.720p.AMZN.WEB-DL.DDP5.1.H.264-NTb[eztv].mkv");
  is($obj->episode_name(), "", "Episode Name: ");
  print Data::Dumper::Dumper($obj);
};

done_testing();
