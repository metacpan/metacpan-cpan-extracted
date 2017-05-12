#!/usr/bin/perl -w
use strict;

use Test::More tests => 12;
use Test::Exception;

use Data::Dumper;

use lib "../lib";

use_ok("Devel::PerlySense::Document::Location");
use_ok("Devel::PerlySense::Document");
use_ok("Devel::PerlySense");


BEGIN { -d "t" and chdir("t"); }


ok(my $oLocation = Devel::PerlySense::Document::Location->new(file => "thefile.pm", row => 33, col => 3), "new ok");
$oLocation->rhProperty->{pod} = "=head1 Yup!";


ok(my $oLocationClone = $oLocation->clone, "Clone ok");

is($oLocationClone->file, $oLocation->file, " file ok");
is($oLocationClone->row, $oLocation->row, " row ok");
is($oLocationClone->col, $oLocation->col, " col ok");
is_deeply($oLocationClone->rhProperty, $oLocation->rhProperty, " rhProperty ok");





note("As Info");

ok(
    $oLocation = Devel::PerlySense::Document::Location->new(
        file => "thefile.pm",
        row => 33,
        col => 3,
    ),
    "new ok",
);
is_deeply(
    $oLocation->rhInfo,
    { file => "thefile.pm", row => 33, col => 3 },
    "Got the correct rhInfo",
);


$oLocation->rhProperty->{class_name} = "Game::Object";

is_deeply(
    $oLocation->rhInfo,
    {
        file => "thefile.pm",
        row => 33,
        col => 3,
        class_name => "Game::Object",
    },
    "Got the correct rhInfo with rhProperty set",
);




__END__
