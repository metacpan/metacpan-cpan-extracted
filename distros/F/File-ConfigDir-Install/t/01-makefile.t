#!/usr/bin/perl

use strict;
use warnings;

use Config;

use File::Path qw/ rmtree /;
use File::Temp qw/ tempdir /;
use Test::More;

use ExtUtils::MakeMaker;

my $FILE = "test-$$-Makefile";
rmtree( [ "tlib-$$", "troot-$$" ], 0, 0 );
END { 
    $FILE and -f $FILE and unlink $FILE;
    rmtree( [ "tlib-$$", "troot-$$" ], 0, 0 );
}

use File::ConfigDir::Install;

install_config 't/etc';

{ package # hide
  MY;

  use File::ConfigDir::Install qw(:MY);
}


delete $ENV{PERL_MM_OPT};   # local::lib + PREFIX below will FAIL
# XXX maybe we should just remove INSTALL_BASE=[^ ]+ from PERL_MM_OPT?

WriteMakefile(
    NAME              => 'File::ConfigDir::Install',
    VERSION_FROM      => 'lib/File/ConfigDir/Install.pm',
    INST_ETC          => "tlib-$$/etc",
    INST_LIB          => "tlib-$$/lib",
    MAKEFILE          => $FILE,
    PREREQ_PM         => {},
    ($] >= 5.005 ?     
      (ABSTRACT_FROM  => 'lib/File/ConfigDir/Install.pm', 
       AUTHOR         => 'Jens Rehsack <sno@>') : ()),
);

sub slurp
{
    local @ARGV = @_;
    local $/;
    local $.;
    <>;
};


#####
ok( -f $FILE, "Created $FILE" );
my $content = slurp $FILE;
ok( $content =~ m(t.etc.fsd-install.json), "Recognized: t/etc/fsd-install.json" );

my $tmpdir = tempdir( CLEANUP => 1 );

#####
mysystem( $Config{make}, '-f', $FILE );
my $TOP = "tlib-$$/etc";
ok( -f "$TOP/fsd-install.json", "Copied to blib for dist: t/etc/fsd-install.json" );

my $c = slurp "$TOP/fsd-install.json";
is( $c, "{ \"goal\": \"installed\" }\n", "Same content: t/etc/fsd-install.json" );

#####
mysystem( $Config{make}, '-f', $FILE, "DESTDIR=$tmpdir", 'install' );

$TOP = File::Spec->catdir($tmpdir, $Config{siteprefix});
note "Checking for " . File::Spec->catfile($TOP, "etc/fsd-install.json");
ok( -f File::Spec->catfile($TOP, "etc/fsd-install.json"), "Installed: t/etc/fsd-install.json");

#####################################
sub mysystem
{
    my $cmd = join ' ', @_;
    note $cmd;
    my $ret = qx($cmd 2>&1);
    note $ret;
    return unless $?;
    die "Error running $cmd: ?=$? ret=$ret";
}

done_testing();
