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

subtest "Not a valid TV Show file." => sub {
  my $obj = File::TVShow::Info->new("test.avi");
  can_ok($obj, 'is_tv_show');
  is($obj->is_tv_show(),0, "This is not a TV Show file.");
};

subtest "Series Name.2018.01.03.Episode_name.avi" => sub {
  my $obj = File::TVShow::Info->new("Series Name.2018.01.03.Episode_name.avi");
  is($obj->is_tv_show(),1, "This is a TV Show.");
  can_ok($obj, "show_name");
  is($obj->show_name(), "Series Name", "Show name is Series Name");
  can_ok($obj, 'is_by_date');
  is($obj->is_by_date(),1, "This is sorted by date.");
  can_ok($obj, 'ext');
  is($obj->ext(),"avi", "extension is avi");
  can_ok($obj, 'year');
  is($obj->year(), "2018", "year is 2018");
  can_ok($obj, 'month');
  is($obj->month(), "01", "month is 01");
  can_ok($obj, "date");
  is($obj->date(), "03", "date is 03");
  can_ok($obj, "ymd");
  is($obj->ymd(), "2018.01.03", "ymd is 2018.01.03");
  can_ok($obj, 'is_by_season');
  is($obj->is_by_season(), 0, "This is not be season");
};

subtest "Series Name.2018.01.03.Episode_name.720p.avi" => sub {
  my $obj = File::TVShow::Info->new("Series Name.2018.01.03.Episode_name.720p.avi");
  is($obj->episode_name(), "Episode_name", "episode_name is: Episode_name");
};

done_testing();
