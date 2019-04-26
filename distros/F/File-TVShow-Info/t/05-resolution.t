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

subtest "test.(2015).S01E01.1080p.[ettv].avi" => sub {
  my $obj = File::TVShow::Info->new("test.(2015).S01E01.1080p.[ettv].avi");
  can_ok($obj, '_isolate_name_year');
  is($obj->{show_name}, "test", "Show name only contains test");
  can_ok($obj, 'has_year');
  is($obj->has_year(), 1, "has_year is: True");
  is($obj->{year}, "2015", "Year is 2015");
  is($obj->is_tv_show(), 1, "This is a valid TV show");
  can_ok($obj, 'original_show_name');
  is($obj->original_show_name(), "test.(2015)", "Original show name: test.(2015)");
  is($obj->show_name(), "test", "Show name is: test");
  is($obj->is_by_date(), 0, "This is not sorted by date");
  is($obj->is_tv_show(), 1, "This is a TV show.");
  can_ok($obj, 'is_multi_episode');
  is($obj->is_multi_episode(), 0,"This is not a multi-episode file.");
  can_ok($obj, 'season');
  is($obj->season(),'01', "Season: 01");
  can_ok($obj, 'episode');
  is($obj->episode(), "01", "Episode: 01");
  can_ok($obj, 'season_episode');
  is($obj->season_episode(), "S01E01", "season_episode: SO1EO1");
  is($obj->ext(),"avi", "extension is avi");
  can_ok($obj, '_get_release_group');
  can_ok($obj, 'release_group');
  is($obj->release_group(), "ettv", "release_group returned: ettv");
  can_ok($obj, '_get_resolution');
  can_ok($obj, 'resolution');
  is($obj->resolution(), "1080p", "Resolution: 1080p");

};

subtest "Teen.wolf.S01E02.720p.vtv.avi" => sub {

  my $obj = File::TVShow::Info->new("Teen.wolf.S01E02.720p.vtv.avi");
  $obj->_isolate_name_year();
  is($obj->{show_name}, "Teen.wolf", "Show name is Teen.wolf");
  is($obj->has_year(), 0, "has_year is: False");
  is($obj->{year}, undef, "year is not defined");
  is($obj->{original_show_name}, undef, "original_show_name is not defined");
  is($obj->release_group(), "vtv", "release_group returned: vtv");
  is($obj->resolution(), "720p", "Resolution: 720p");
};

subtest "The.4400.S01E02.avi" => sub {

  my $obj = File::TVShow::Info->new("The.4400.S01E02.avi");
  $obj->_isolate_name_year();
  is($obj->{show_name}, "The.4400", "Show name is The.4400");
  is($obj->{year}, undef, "year is not defined");
  is($obj->release_group(), '', "release_group is: ''");
  is($obj->resolution(), '', "resolution is : ''");
};

done_testing();
