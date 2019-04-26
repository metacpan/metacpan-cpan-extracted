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

subtest "test.(2015).S01E01.1080p.[ettv].eng.srt" => sub {
  my $obj = File::TVShow::Info->new("test.(2015).S01E01.1080p.[ettv].eng.srt");
  can_ok($obj, '__get_obj_attr');
  is($obj->__get_obj_attr('season'), "01", "Season: 01");
  is($obj->season(), "01", "Season: 01");
};

done_testing();
