#!/usr/bin/perl -w
use strict;

use Test::More tests => 7;
use Test::Exception;

use Data::Dumper;

use lib "../lib";

use_ok("Devel::PerlySense::Project");
use_ok("Devel::PerlySense::Project::Unknown");
use_ok("Devel::PerlySense");





ok(
    my $oPerlySense = Devel::PerlySense->new(),
    "New PerlySense object ok",
);


note("No project -- default config");
# Don't look at the entire config, it's bound to change rapidly.
is_deeply(
    $oPerlySense->rhConfig->{project},
    {
        moniker => "The Project Without a Name",
        inc_dir => [ ],
    },
    "The default config looks right",
);





note("Look for a .PerlySenseProject indicate a project");
{

    my $dirBase = "t/data/project/with-perlysenseproject";
    my $dirProject = "$dirBase/source";

    my $rexDirProject = $dirProject;
    $rexDirProject =~ s|\W|.|g;

    my $dirTest = "$dirProject/bogus/lib/Game";
    my $fileTest = "$dirTest/Lawn.pm";

    ok($oPerlySense->setFindProject(file => $fileTest), "Set project ok");

    is_deeply(
        $oPerlySense->rhConfig->{project},
        {
            moniker => "Worm Game",
            inc_dir => [
                "glib/perl5lib",
                "deps/perl5lib",
                "../../with-dir/source/lib",
            ],
        },
        "The project config looks right",
    );

}





__END__
