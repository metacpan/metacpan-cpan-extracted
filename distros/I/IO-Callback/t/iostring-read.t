# IO::Callback 1.08 t/iostring-read.t
# This is t/read.t from IO::String 1.08, adapted to IO::Callback.

use strict;
use warnings;

use Test::More tests => 23;
use Test::NoWarnings;

use IO::Callback;

my $str = <<EOT;
This is an example
of a paragraph

and a single line.

EOT

my $callback_pos;
my $io;

sub reset_test {
    my $pos = shift || 0;

    $callback_pos = $pos;
    $io = IO::Callback->new('<', \&callback);
}

sub callback {
    defined $callback_pos or die "callback called again after returning eof";
    if ($callback_pos < length $str) {
        my $oldpos = $callback_pos;
        $callback_pos = length $str;
        return substr $str, $oldpos;
    } else {
        undef $callback_pos;
        return;
    }
}

reset_test();
my @lines = <$io>;
is_deeply( [@lines], ["This is an example\n","of a paragraph\n","\n","and a single line.\n","\n"], "read all lines" );

use vars qw(@tmp $buf);

ok( ! defined ($io->getline), "$io->getline false after eof" );
ok( ! (@tmp = $io->getlines), "$io->getlines false after eof" );
ok( ! defined (<$io>),        "<$io> false after eof" );
ok( ! defined ($io->getc),    "$io->getc false after eof" );
ok( ! read($io, $buf, 100),   "read $io false after eof" );

{
    local $/;  # slurp mode
    reset_test();
    @lines = $io->getlines;
    is_deeply( \@lines, [$str], "slurp got whole string" );

    reset_test(index($str, "and"));
    my $line = <$io>;
    is( $line, "and a single line.\n\n", "slurp 2nd part of string" );
}

{
    local $/ = "";  # paragraph mode
    reset_test();
    @lines = <$io>;
    is_deeply( \@lines, ["This is an example\nof a paragraph\n\n", "and a single line.\n\n"], "para mode" );
}

{
    local $/ = "is";
    reset_test();
    @lines = ();
    while (<$io>) {
        push(@lines, $_);
    }

    is_deeply( \@lines, ["This", " is", " an example\n" .
                                        "of a paragraph\n\n" .
                                        "and a single line.\n\n"], "getlines with \$/ = is"
    );
}


# Test read

reset_test();

is( read($io, $buf, 3), 3, "read returned 3" );
is( $buf, "Thi", "read got correct data" );

is( sysread($io, $buf, 3, 2), 3, "sysread returned 3" );
is( $buf, "Ths i", "sysread got correct data" );

reset_test(length($str) - 4);

ok( ! $io->eof, "no eof with 4 bytes to go" );

is( read($io, $buf, 20), 4, "read got 4 bytes" );
is( $buf, "e.\n\n", "read got the final 4 bytes of the string" );

is( read($io, $buf, 20), 0, "read at eof returned 0" );
ok( $io->eof, "eof indicator set" );

reset_test();

is( read($io, $buf, 0), 0, "0 len read returned 0" );

is( read($io, $buf, 4), 4, "got 4 bytes after 0len read" );
is( $buf, "This", "got correct 4 bytes after 0len read" );

