#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 1;
use File::Spec::Functions qw(:ALL);
use Findbin;
use Test::File::ShareDir (
    -root => catdir($FindBin::Bin, updir),
    -share => { -dist => { "Mac-Choose" => "share" } },
);

use Mac::Choose qw(choose);

open my $fh, '|-','osascript','-e','delay 1','-e','tell applications "System Events" to keystroke return';

my $answer = choose "please wait","do not press anything","this dialog should close","within two seconds";
is $answer, "please wait";

close $fh;
