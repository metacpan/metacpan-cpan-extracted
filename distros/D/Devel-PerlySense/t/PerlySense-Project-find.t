#!/usr/bin/perl -w
use strict;

use Test::More tests => 21;
use Test::Exception;

use Data::Dumper;

use lib "../lib";

use_ok("Devel::PerlySense::Project");
use_ok("Devel::PerlySense::Project::Unknown");
use_ok("Devel::PerlySense");


BEGIN { -d "t" and chdir("t"); }



ok(
    my $oProjectUnknown = Devel::PerlySense::Project::Unknown->new(),
    "Created Unknown project ok",
);
isa_ok($oProjectUnknown, "Devel::PerlySense::Project");
isa_ok($oProjectUnknown, "Devel::PerlySense::Project::Unknown");


ok(
    my $oPerlySense = Devel::PerlySense->new(),
    "New PerlySense object ok",
);



is(
    Devel::PerlySense::Project->newFromLocation(
        oPerlySense => $oPerlySense,
        dir => "/",
    ),
    undef,
    "Found nothing, looking at the / dir",
);




note("Look for dirs that indicate a project");
{

    #This is to avoid identifying the .PerlySenseProject directory
    #_of_the_development_project_ to interfere with the test which
    #expects a free way all the way up to the root without any
    #projects.
    no warnings;
    local *Devel::PerlySense::Project::newFindExplicit = sub {
        undef;
    };

    my $dirBase = "data/project/with-dir";
    my $dirProject = "$dirBase/source";

    my $rexDirProject = $dirProject;
    $rexDirProject =~ s|\W|.|g;


    my $dirTest = "$dirProject/lib/Game";
    my $fileTest = "$dirTest/Lawn.pm";

    ok(
        my $oProjectDir = Devel::PerlySense::Project->newFromLocation(
            dir => $dirTest,
            oPerlySense => $oPerlySense,
        ),
        "Found Project using dir",
    );
    like($oProjectDir->dirProject, qr/$rexDirProject$/, "  Correct Project dir");
    like(
        $oProjectDir->dirProjectImplicitDir,
        qr/$rexDirProject$/,
        "  Correct Project dir property",
    );

    ok(
        my $oProjectFile = Devel::PerlySense::Project->newFromLocation(
            file => $fileTest,
            oPerlySense => $oPerlySense,
        ),
        "Found Project using file",
    );
    like($oProjectFile->dirProject, qr/$rexDirProject$/, "  Correct Project dir");
    is(
        $oProjectFile->dirProjectImplicitDir,
        "",
        "  Correct Project dir property",
    );
    like(
        $oProjectFile->dirProjectImplicitUse,
        qr/$rexDirProject$/,
        "  Correct Project dir property",
    );

}




note("Look for the modules itself that indicate a project");
{
    #See above.
    no warnings;
    local *Devel::PerlySense::Project::newFindExplicit = sub {
        undef;
    };

    my $dirBase = "data/project/with-use";
    my $dirProject = "$dirBase/source/lib";

    my $rexDirProject = $dirProject;
    $rexDirProject =~ s|\W|.|g;

    my $dirTest = "$dirProject/modules/Game";
    my $fileTest = "$dirTest/Lawn.pm";

    ok(
        my $oProjectFile = Devel::PerlySense::Project->newFromLocation(
            file => $fileTest,
            oPerlySense => $oPerlySense,
        ),
        "Found Project using file",
    );
    like($oProjectFile->dirProject, qr/$rexDirProject$/, "  Correct Project dir");
    like(
        $oProjectFile->dirProjectImplicitUse,
        qr/$rexDirProject$/,
        "  Correct Project dir property",
    );

}





note("Look for a .PerlySenseProject indicate a project");
{

    my $dirBase = "data/project/with-perlysenseproject";
    my $dirProject = "$dirBase/source";

    my $rexDirProject = $dirProject;
    $rexDirProject =~ s|\W|.|g;

    my $dirTest = "$dirProject/bogus/lib/Game";
    my $fileTest = "$dirTest/Lawn.pm";

    ok(
        my $oProjectFile = Devel::PerlySense::Project->newFromLocation(
            file => $fileTest,
            oPerlySense => $oPerlySense,
        ),
        "Found Project using .PerlySenseProject",
    );
    like($oProjectFile->dirProject, qr/$rexDirProject$/, "  Correct Project dir");
    like(
        $oProjectFile->dirProjectExplicitDir,
        qr/$rexDirProject$/,
        "  Correct Project dir property",
    );

}





__END__
