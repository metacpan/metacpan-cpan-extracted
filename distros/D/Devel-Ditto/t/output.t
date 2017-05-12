#!perl

use strict;
use warnings;

use File::Spec;
use Test::More tests => 2;
use IPC::Run qw( run );

run [ $^X, '-MDevel::Ditto', File::Spec->catfile( 't', 'myprog.pl' ) ],
 \my $in, \my $out, \my $err
 or die "Failed: $?";

is $out, "[main, " . File::Spec->canonpath("t/myprog.pl") . ", 9] This is regular text\n"
 . "[MyPrinter, " . File::Spec->canonpath("t/lib/MyPrinter.pm") . ", 7] Hello, World\n", 'STDOUT';
is $err, "[main, " . File::Spec->canonpath("t/myprog.pl") . ", 10] This is a warning\n"
 . "[MyPrinter, " . File::Spec->canonpath("t/lib/MyPrinter.pm") . ", 8] Whappen?\n", 'STDERR';

# vim:ts=2:sw=2:et:ft=perl

