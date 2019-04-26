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

subtest "test.(2015).S01E01.avi" => sub {
  my $obj = File::TVShow::Info->new("test.(2015).S01E01.avi");
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

};

subtest "Teen.wolf.S01E02.avi" => sub {

  my $obj = File::TVShow::Info->new("Teen.wolf.S01E02.avi");
  $obj->_isolate_name_year();
  is($obj->{show_name}, "Teen.wolf", "Show name is Teen.wolf");
  is($obj->has_year(), 0, "has_year is: False");
  is($obj->{year}, undef, "year is not defined");
  is($obj->{original_show_name}, undef, "original_show_name is not defined");
};

subtest "The.4400.S01E02.avi" => sub {

  my $obj = File::TVShow::Info->new("The.4400.S01E02.avi");
  $obj->_isolate_name_year();
  is($obj->{show_name}, "The.4400", "Show name is The.4400");
  is($obj->{year}, undef, "year is not defined");
};

subtest "S.W.A.T.2017.S01E15.Crews.720p.AMZN.WEBRip.DDP5.1.x264-NTb[eztv].mkv" => sub {
  my $obj = File::TVShow::Info->new("S.W.A.T.2017.S01E15.Crews.720p.AMZN.WEBRip.DDP5.1.x264-NTb[eztv].mkv");
  is($obj->{show_name}, "S.W.A.T");
  is($obj->{year}, "2017");
  is($obj->{episode_name}, "Crews");
  print Data::Dumper::Dumper($obj);
};

subtest "S.W.A.T.2017.S01E15.Crews.AMZN.WEBRip.DDP5.1.x264-NTb[eztv].mkv" => sub {
  my $obj = File::TVShow::Info->new("S.W.A.T.2017.S01E15.Crews.AMZN.WEBRip.DDP5.1.x264-NTb[eztv].mkv");
  is($obj->{show_name}, "S.W.A.T");
  is($obj->{year}, "2017");
  is($obj->{episode_name}, "Crews");
  print Data::Dumper::Dumper($obj);
};

subtest "S.W.A.T.2017.S01E15.Crews.WEBRip.DDP5.1.x264-NTb[eztv].mkv" => sub {
  my $obj = File::TVShow::Info->new("S.W.A.T.2017.S01E15.Crews.WEBRip.DDP5.1.x264-NTb[eztv].mkv");
  is($obj->{show_name}, "S.W.A.T");
  is($obj->{year}, "2017");
  is($obj->{episode_name}, "Crews");
  print Data::Dumper::Dumper($obj);
};
done_testing();
