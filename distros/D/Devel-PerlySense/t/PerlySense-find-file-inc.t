#!/usr/bin/perl -w
use strict;

use Test::More tests => 5;
use Test::Exception;

use File::Basename;
use File::Spec::Functions;
use Path::Class;

use lib "../lib";

use_ok("Devel::PerlySense");

BEGIN { -d "t" and chdir("t"); }




{
    local @INC = (@INC, "data/inc-lib");

    {
        ok(my $oPs = Devel::PerlySense->new(), "new ok");
        my $dirData = "data/simple-lib/lib";
        my $dirOrigin = $dirData;
        my $nameModule = "Game::Event::Timed";
        my $fileModuleTarget = catfile("Game", "Event", "Timed.pm");

        like(
            $oPs->fileFindModule(nameModule => $nameModule, dirOrigin => $dirOrigin),
            qr/ \Q$fileModuleTarget\E $/x,
            "Found file downwards before \@INC ok",
        );
    }


    {
        ok(my $oPs = Devel::PerlySense->new(), "new ok");
        my $dirData = file("data/inc-lib")->absolute . "";
        my $dirOrigin = "/";
        my $nameModule = "Game::Event::Timed";
        my $fileModuleTarget = catfile($dirData, "Game", "Event", "Timed.pm");

        like(
            $oPs->fileFindModule(nameModule => $nameModule, dirOrigin => $dirOrigin),
            qr/ \Q$fileModuleTarget\E $/x,
            "Found file in inc ok",
        );
    }
}







__END__
