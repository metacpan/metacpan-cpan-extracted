#!/usr/bin/perl -w
use strict;

use Test::More tests => 8;
use Test::Exception;

use Data::Dumper;
use File::Path;

use lib "../lib", "lib";

use_ok("Devel::PerlySense::Home");





ok(
    my $oHome = Devel::PerlySense::Home->new(),
    "New PerlySense object ok",
);



my $dirTemp = "./test_home_temp";
rmtree($dirTemp);
END { rmtree($dirTemp) }

my $dirTempHome = "$dirTemp/.PerlySense";


{
    note("Identify candidates");
    
    local %ENV = ();
    is_deeply(
        [ $oHome->aDirHomeCandidate ],
        [ "/" ],
        "Candidate list empty ok",
    );

    local $ENV{HOME} = $dirTemp;
    is_deeply(
        [ $oHome->aDirHomeCandidate ],
        [ $dirTemp, "/" ],
        "Candidate list with HOME ok",
    );


    

    note("Create dir");
    ok( ! -d $dirTemp, "No directory currently");

    like($oHome->dirHome, qr/test_home_temp..PerlySense/, "Got correct home dir");
    like(
        $oHome->dirHomeCache,
        qr/test_home_temp..PerlySense.cache/,
        "Got correct home cache dir",
    );
    like(
        $oHome->dirHomeLog,
        qr/test_home_temp..PerlySense.log/,
        "Got correct home log dir",
    );
    
}




__END__
