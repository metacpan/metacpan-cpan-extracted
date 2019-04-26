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

subtest "Life.on.Mars.US.S01E01.HDTV.XViD-DOT.avi" => sub {
  my $obj = File::TVShow::Info->new("Life.on.Mars.US.S01E01.HDTV.XViD-DOT.avi");
  can_ok($obj, '_get_country');
  is($obj->{country}, 'US', "{country} is: US");
  can_ok($obj, 'country');
  can_ok($obj, 'has_country');
  is($obj->has_country(), '1', "show_name has country");
  is($obj->country(), 'US', 'country: US');

};

subtest "Life.on.Mars.(US).S01E01.HDTV.XViD-DOT.avi" => sub {
  my $obj = File::TVShow::Info->new("Life.on.Mars.(US).S01E01.HDTV.XViD-DOT.avi");
  is($obj->country(), 'US', 'country: US');

};

subtest "Life.on.Mars.UK.S01E01.HDTV.XViD-DOT.avi" => sub {
  my $obj = File::TVShow::Info->new("Life.on.Mars.UK.S01E01.HDTV.XViD-DOT.avi");
  is($obj->country(), 'UK', 'country: UK');

};

subtest "Life.on.Mars.AR.S01E01.HDTV.XViD-DOT.avi" => sub {
  my $obj = File::TVShow::Info->new("Life.on.Mars.AR.S01E01.HDTV.XViD-DOT.avi");
  is($obj->has_country(), 0);
};

subtest "The.best.of.Us.S01E01.HDTV.XViD-DOT.avi" => sub {
  my $obj = File::TVShow::Info->new("The.best.of.Us.S01E01.HDTV.XViD-DOT.avi");
  is($obj->has_country(), 0);
};

done_testing();
