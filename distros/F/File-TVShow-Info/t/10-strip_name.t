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

subtest "Life.on.Mars.S05E03.720p.AMZN.WEB-DL.DDP5.1.H.264-NTb[eztv].mkv" => sub {
  my $obj = File::TVShow::Info->new("Life.on.Mars.S05E03.720p.AMZN.WEB-DL.DDP5.1.H.264-NTb[eztv].mkv");
  can_ok($obj, 'strip_show_name');
  is($obj->strip_show_name(), "Life on Mars", "Show Name: Life on Mars");
};

subtest "Life.on-Mars.S00E01.720p.AMZN.WEB-DL.DDP5.1.H.264-NTb[eztv].mkv" => sub {
  my $obj = File::TVShow::Info->new("Life.on-Mars.S00E01.720p.AMZN.WEB-DL.DDP5.1.H.264-NTb[eztv].mkv");
  is($obj->strip_show_name(), "Life on Mars", "Show Name: Life on Mars");
};

subtest "Life-on-Mars.S00E01.720p.AMZN.WEB-DL.DDP5.1.H.264-NTb[eztv].mkv" => sub {
  my $obj = File::TVShow::Info->new("Life-on-Mars.S00E01.720p.AMZN.WEB-DL.DDP5.1.H.264-NTb[eztv].mkv");
  is($obj->strip_show_name(), "Life on Mars", "Show Name: Life on Mars");
};

subtest "Life_on-Mars.S00E01.720p.AMZN.WEB-DL.DDP5.1.H.264-NTb[eztv].mkv" => sub {
  my $obj = File::TVShow::Info->new("Life_on-Mars.S00E01.720p.AMZN.WEB-DL.DDP5.1.H.264-NTb[eztv].mkv");
  is($obj->strip_show_name(), "Life on Mars", "Show Name: Life on Mars");
};

done_testing();
