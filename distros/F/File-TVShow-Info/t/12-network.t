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
  can_ok($obj, '_get_network');
  is($obj->{network}, "AMZN", "network: AMZN");
  can_ok($obj, '_network');
  is($obj->_network(), 'AMZN', "Network: AMZN");
};

subtest "Life.on-Mars.S00E01.So.Far.720p.ABC.WEB-DL.DDP5.1.H.264-NTb[eztv].mkv" => sub {
  my $obj = File::TVShow::Info->new("Life.on-Mars.S00E01.So.Far.720p.ABC.WEB-DL.DDP5.1.H.264-NTb[eztv].mkv");
  is($obj->_network(), 'ABC', "Network: ABC");
};

subtest "Life.on-Mars.S00E01.So-Far.720p.HULU.WEB-DL.DDP5.1.H.264-NTb[eztv].mkv" => sub {
  my $obj = File::TVShow::Info->new("Life.on-Mars.S00E01.So-Far.720p.HULU.WEB-DL.DDP5.1.H.264-NTb[eztv].mkv");
  is($obj->_network(), 'HULU', "Network: HULU");
};

subtest "Life.on-Mars.S00E01.So-Far.720p.HUlu.WEB-DL.DDP5.1.H.264-NTb[eztv].mkv" => sub {
  my $obj = File::TVShow::Info->new("Life.on-Mars.S00E01.So-Far.720p.HUlu.WEB-DL.DDP5.1.H.264-NTb[eztv].mkv");
  is($obj->_network(), 'HUlu', "Network: HUlu");
};

done_testing();
