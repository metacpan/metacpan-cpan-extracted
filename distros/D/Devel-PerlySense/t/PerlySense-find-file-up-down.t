#!/usr/bin/perl -w
use strict;

use Test::More tests => 8;
use Test::Exception;

use File::Basename;
use File::Spec::Functions;

use lib "../lib";

use_ok("Devel::PerlySense");


BEGIN { -d "t" and chdir("t"); }


ok(my $oPs = Devel::PerlySense->new(), "new ok");



{
    my $dirData = "data/simple-lib";
    my $fileOrigin = "$dirData/lib/Win32/Word/Writer.pm";
    my $dirOrigin = dirname($fileOrigin);
    my $nameModule = "Win32::Word::Writer::Table2";
    my $fileModuleTarget = catfile("Writer", "Table2.pm");


    throws_ok( sub { $oPs->fileFindModule() }, qr/nameModule/, "fileFindModule dies ok with missing param");

    is($oPs->fileFindModule(nameModule => $nameModule, dirOrigin => "fsdlkj/sdfsdjk"), undef, "Didn't find file ok");
    is($oPs->fileFindModule(nameModule => "FLorjsdkdj", dirOrigin => $dirOrigin), undef, "Didn't find file ok");

    like($oPs->fileFindModule(nameModule => $nameModule, dirOrigin => $dirOrigin), qr/ \Q$fileModuleTarget\E $/x, "Found file downwards ok");


    note("Check that the file without the prefix of the main file is found and not shadowed by it");
    my $nameModuleShadowed = "Word::Writer";
    my $fileModuleShadowedTarget = catfile("lib", "Word", "Writer.pm");
    like(
        $oPs->fileFindModule(nameModule => $nameModuleShadowed, dirOrigin => $dirOrigin),
        qr/ \Q$fileModuleShadowedTarget\E $/x,
        "Found file downwards ok even though it might have been shadowed by the longer name",
    );
}


{
    my $dirData = "data/simple-lib";
    my $fileOrigin = "$dirData/lib/Win32/Word/Writer/Table2.pm";
    my $dirOrigin = dirname($fileOrigin);
    my $nameModule = "Win32::Word::Writer";
    my $fileModuleTarget = catfile("..", "Writer.pm");

    like($oPs->fileFindModule(nameModule => $nameModule, dirOrigin => $dirOrigin), qr/ Writer\.pm $/x, "Found file upwards ok");
}






__END__
