#!/usr/bin/perl -w
use strict;

use Test::More tests => 14;
use Test::Exception;

use Cwd;
use Data::Dumper;
use Path::Class;

use lib ("lib", "../lib");

use Devel::PerlySense::Util::Log;

use_ok("Devel::PerlySense::Project");
use_ok("Devel::PerlySense");


BEGIN { -d "t" and chdir("t"); }



ok(
    my $oPerlySense = Devel::PerlySense->new(),
    "New PerlySense object ok",
);



my $dirBase = "data/project/with-perlysenseproject";
my $dirProject = "$dirBase/source";

my $dirTest = "$dirProject/bogus/lib/Game";
my $fileTest = "$dirTest/Lawn.pm";

my @aDirTest = (
    "glib/perl5lib",
    "deps/perl5lib",
    "../../with-dir/source/lib",
);


ok($oPerlySense->setFindProject(file => $fileTest), "Found Project");
my $oProject = $oPerlySense->oProject;
like($oProject->dirProject, qr/with-perlysenseproject.source$/, "Got good project root dir");
is_deeply(
    $oPerlySense->rhConfig->{project}->{inc_dir},
    [ @aDirTest ],
);


my $file;

$file = $fileTest;
ok(!$oProject->isFileInProject(file => "dsfjdslk"), "Completely missing file is not in project");

ok( $oProject->isFileInProject(file => $fileTest), "Same file is in project");
ok( $oProject->isFileInProject(file => "$fileTest.missing"), "Missing file that could be in project is. It does not have to exist");

ok(!$oProject->isFileInProject(file => "data/inc-lib/Game/Object/Worm.pm"), "Existing file outside of project isn't in project");


note("Test inc_dir");
#This dir is in the inc_dir according to the loaded yaml config
ok(
    $oProject->isFileInProject(file => "data/project/with-dir/source/lib/Game/Lawn.pm"),
    "Missing file that could be in project is. It does not have to exist",
) or warn( Devel::PerlySense::Util::Log->_textTailDebug() . "\n\nTEST FAILED, THIS ABOVE TEXT IS THE RECENT DEBUG LOG FOR DIAGNOSTICS PURPOSES.\nSORRY ABOUT SPAMMING LIKE THIS, BUT I NEED THE OUTPUT TO FIGURE OUT WHAT'S WRONG\n" );




note("inc_dir");
my $dirBaseAbs = dir(cwd(), $dirProject);
my %hIncDirAbsolute = map { $_ => 1 } $oProject->aDirIncAbsolute;

for my $dir (@aDirTest) {
    my $dirAbs = dir($dirBaseAbs, $dir );
    ok( $hIncDirAbsolute{$dirAbs}, "Found absolute dir for ($dir) ($dirAbs)");
}



__END__
