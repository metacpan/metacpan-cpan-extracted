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

subtest "Prey.S05E03.Pilot.720p.AMZN.WEB-DL.DDP5.1.H.264-NTb[eztv].mkv" => sub {
  my $obj = File::TVShow::Info->new("Prey.S05E03.Pilot.720p.AMZN.WEB-DL.DDP5.1.H.264-NTb[eztv].mkv");
  is($obj->clean_show_name(), "Prey", "Show Name: Prey");
};

subtest "Prey US.S05E03.Pilot.720p.AMZN.WEB-DL.DDP5.1.H.264-NTb[eztv].mkv" => sub {
  my $obj = File::TVShow::Info->new("Prey US.S05E03.Pilot.720p.AMZN.WEB-DL.DDP5.1.H.264-NTb[eztv].mkv");
  is($obj->clean_show_name(), "Prey (US)", "Show Name: Prey (US)");
};

subtest "Prey.US.S05E03.Pilot.720p.AMZN.WEB-DL.DDP5.1.H.264-NTb[eztv].mkv" => sub {
  my $obj = File::TVShow::Info->new("Prey.US.S05E03.Pilot.720p.AMZN.WEB-DL.DDP5.1.H.264-NTb[eztv].mkv");
  is($obj->clean_show_name(), "Prey (US)", "Show Name: Prey (US)");
};

subtest "Prey (US).S05E03.Pilot.720p.AMZN.WEB-DL.DDP5.1.H.264-NTb[eztv].mkv" => sub {
  my $obj = File::TVShow::Info->new("Prey (US).S05E03.Pilot.720p.AMZN.WEB-DL.DDP5.1.H.264-NTb[eztv].mkv");
  is($obj->clean_show_name(), "Prey (US)", "Show Name: Prey (US)");
};

subtest "Prey.(US).S05E03.Pilot.720p.AMZN.WEB-DL.DDP5.1.H.264-NTb[eztv].mkv" => sub {
  my $obj = File::TVShow::Info->new("Prey.(US).S05E03.Pilot.720p.AMZN.WEB-DL.DDP5.1.H.264-NTb[eztv].mkv");
  is($obj->clean_show_name(), "Prey (US)", "Show Name: Prey (US)");
};

subtest "Castle.S05E03.Pilot.720p.AMZN.WEB-DL.DDP5.1.H.264-NTb[eztv].mkv" => sub {
  my $obj = File::TVShow::Info->new("Castle.S05E03.Pilot.720p.AMZN.WEB-DL.DDP5.1.H.264-NTb[eztv].mkv");
  is($obj->clean_show_name(), "Castle", "Show Name: Castle");
};

subtest "Castle.2009.S05E03.Pilot.720p.AMZN.WEB-DL.DDP5.1.H.264-NTb[eztv].mkv" => sub {
  my $obj = File::TVShow::Info->new("Castle.2009.S05E03.Pilot.720p.AMZN.WEB-DL.DDP5.1.H.264-NTb[eztv].mkv");
  is($obj->clean_show_name(), "Castle (2009)", "Show Name: Castle (2009)");
};

subtest "Castle.(2009).S05E03.Pilot.720p.AMZN.WEB-DL.DDP5.1.H.264-NTb[eztv].mkv" => sub {
  my $obj = File::TVShow::Info->new("Castle.(2009).S05E03.Pilot.720p.AMZN.WEB-DL.DDP5.1.H.264-NTb[eztv].mkv");
  is($obj->clean_show_name(), "Castle (2009)", "Show Name: Castle (2009)");
};

subtest "Doctor.Who.(2005).S05E03.Pilot.720p.AMZN.WEB-DL.DDP5.1.H.264-NTb[eztv].mkv" => sub {
  my $obj = File::TVShow::Info->new("Doctor.Who.(2005).S05E03.Pilot.720p.AMZN.WEB-DL.DDP5.1.H.264-NTb[eztv].mkv");
  is($obj->clean_show_name(), "Doctor Who (2005)", "Show Name: Doctor Who (2009)");
};

done_testing();
