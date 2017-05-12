#!/usr/bin/perl -w
use strict;

use Test::More tests => 21;
use Test::Exception;

use Data::Dumper;

use lib "../lib";

use_ok("Devel::PerlySense");


BEGIN { -d "t" and chdir("t"); }




my $dot = "[.]";
my $up = "${dot}${dot}";



note("Identify which file type to debug");
{
    my $dirBase = "data/project/with-perlysenseproject";
    my $dirProject = "$dirBase/source";
    my $dirTest = "$dirProject/bogus/t";
    my $fileTest = "$dirTest/Game-Lawn.t";


    ok(
        my $oPerlySense = Devel::PerlySense->new(),
        "New PerlySense object ok",
    );
    ok($oPerlySense->setFindProject(file => $fileTest), "Found Project");
    ok(my $oProject = $oPerlySense->oProject, "  got project property");


    note("  Bad config formats");
    {
        local $oProject->rhConfig->{debug_file}->[0]->{rex} = undef;

        throws_ok(
            sub { $oProject->rhConfigTypeForFile(
                file      => $fileTest,
                keyConfig => "debug_file",
            ) },
            qr/Missing rex key/,
            "Missing regex found ok",
        );
    }

    {
        local $oProject->rhConfig->{debug_file}->[0]->{rex} = 'abc(';

        throws_ok(
            sub { $oProject->rhConfigTypeForFile(file => $fileTest, keyConfig => "debug_file") },
            qr/Invalid rex value in config/,
            "Invalid regex found ok",
        );
    }



    {
        local $oProject->rhConfig->{debug_file} = [];

        throws_ok(
            sub { $oProject->rhConfigTypeForFile(file => $fileTest, keyConfig => "debug_file") },
            qr/No run_perl rex matched the/,
            "No matching type found ok",
        );
    }


    my $rhConfigType;

    ok($rhConfigType = $oProject->rhConfigTypeForFile(file => "abc.t", keyConfig => "debug_file"), "Identify a .t file");
    is($rhConfigType->{moniker}, "Test", "  correct moniker");

    ok($rhConfigType = $oProject->rhConfigTypeForFile(file => "abc.pm", keyConfig => "debug_file"), "Identify a .pm file");
    is($rhConfigType->{moniker}, "Module", "  correct moniker");

    ok($rhConfigType = $oProject->rhConfigTypeForFile(file => "abc.pl", keyConfig => "debug_file"), "Identify a .pl file");
    is($rhConfigType->{moniker}, "Script", "  correct moniker");

    ok($rhConfigType = $oProject->rhConfigTypeForFile(file => "abc", keyConfig => "debug_file"), "Identify everything else");
    is($rhConfigType->{moniker}, "Script (no .pl)", "  correct moniker");

}






note("Debug test file inside dir");
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
    my $dirTest = "$dirProject/t";
    my $fileTest = "$dirTest/Game-Lawn.t";


    ok(
        my $oPerlySense = Devel::PerlySense->new(),
        "New PerlySense object ok",
    );
    ok(
        my $rhDebug = $oPerlySense->rhDebugFile(file => $fileTest),
        "rhDebugFile returned a data structure",
    );
    is(scalar keys %$rhDebug, 3, "  correct item count");
    is($rhDebug->{type_source_file}, "Test", "    type_source_file");
    like(
        $rhDebug->{command_debug},
        qr|perl -d "-I." "-Ilib" "t.Game-Lawn.t"|,
        "    command_debug",
    );
    like($rhDebug->{dir_debug_from}, qr|t.data.project.with-dir.source|, "    dir_debug_from");

}





__END__
