#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);
use Symbol qw(gensym);

use lib 'lib';
use Developer::Dashboard::GoRoutine;

{
    package Local::GoRoutine::FalsePrintHandle;

    # TIEHANDLE creates a harmless tied handle for failure testing.
    # Input: class name; output: a tied-handle object.
    sub TIEHANDLE {
        my ($class) = @_;
        return bless {}, $class;
    }

    # PRINT deliberately reports a failed write without emitting a warning.
    # Input: tied-handle object and print arguments; output: false status.
    sub PRINT {
        return 0;
    }
}

package main;

# Under the event-loop engine there is one interpreter, so a shared
# filehandle is the plain Perl filehandle itself: no remote dispatcher, no
# marshalling. A routine that prints to the shared handle writes to the
# same underlying open-file description, and every ordinary filehandle
# operation works from inside a routine exactly as it does on the main
# thread. Each phase below runs its operations inside a routine and the
# results are checked after wait_all.

my ( undef, $path ) = tempfile( UNLINK => 1 );
open share my $handle, '+>', $path
    or die "Could not open '$path': $!";
binmode $handle or die "Could not set the temporary handle to raw mode: $!";

ok !defined tied( *$handle ),
    'a shared filehandle is an ordinary untied Perl filehandle';

# A fresh routine reports pending until the engine dispatches it.
my $writer = go sub {
    print $handle "first\n" or die "print failed: $!";
    printf $handle "%s:%d\n", 'second', 2 or die "printf failed: $!";
};
is $writer->status, 'pending', 'a fresh routine reports pending';
wait_all();
is $writer->status, 'done', 'the writer routine finishes';
ok $writer->is_running == 0, 'a finished routine is not running';

share my $line;
go sub {
    seek $handle, 0, 0 or die "seek failed: $!";
    $line = readline $handle;
};
wait_all();
is $line, "first\n", 'READLINE from a routine returns one line';

share my @rest;
go sub {
    @rest = readline $handle;
};
wait_all();
is_deeply \@rest, ["second:2\n"],
    'READLINE in list context returns the remaining lines';

share my $char;
go sub {
    seek $handle, 0, 0 or die "seek failed: $!";
    $char = getc $handle;
};
wait_all();
is $char, 'f', 'GETC from a routine returns one character';

share my $read_count;
share my $read_buffer = '';
go sub {
    seek $handle, 0, 0 or die "seek failed: $!";
    $read_count = read $handle, $read_buffer, 3;
};
wait_all();
is $read_count, 3, 'READ from a routine reports the byte count';
is $read_buffer, 'fir', 'READ from a routine returns the populated buffer';

share my $scalar_read;
share my $scalar_buffer = '';
go sub {
    seek $handle, 0, 0 or die "seek failed: $!";
    $scalar_read = read $handle, $scalar_buffer, 2;
};
wait_all();
is $scalar_read, 2, 'scalar-context READ reports only the byte count';

share my $binmode_layered;
share my $binmode_plain;
go sub {
    $binmode_layered = binmode $handle, ':raw';
    $binmode_plain   = binmode $handle;
};
wait_all();
ok $binmode_layered, 'BINMODE accepts an explicit layer';
ok $binmode_plain,   'BINMODE without a layer preserves Perl defaults';

share my $position;
go sub {
    seek $handle, 2, 0 or die "seek failed: $!";
    $position = tell $handle;
};
wait_all();
is $position, 2, 'TELL returns the current file position';

share my $descriptor;
go sub {
    $descriptor = fileno $handle;
};
wait_all();
ok defined $descriptor, 'FILENO exposes the underlying descriptor';

share my $at_eof = 0;
go sub {
    seek $handle, 15, 0 or die "seek failed: $!";
    $at_eof = eof $handle ? 1 : 0;
};
wait_all();
ok $at_eof, 'EOF reports the consumed file end';

share my $write_offset;
share my $write_default;
share my $closed;
go sub {
    seek $handle, 2, 0 or die "seek failed: $!";
    $write_offset  = syswrite $handle, '--tag', 3, 2;
    $write_default = syswrite $handle, 'X', 1;
    $closed        = close $handle;
};
wait_all();
is $write_offset,  3, 'WRITE applies the requested length and offset';
is $write_default, 1, 'WRITE defaults an omitted offset to zero';
ok $closed, 'CLOSE returns the underlying close result';

open my $verify, '<:raw', $path or die "Could not reopen '$path': $!";
my $contents = do { local $/; <$verify> };
close $verify or die "Could not close '$path': $!";
is $contents, "fitagXsecond:2\n",
    'routine writes land in the file at the intended byte range';

# A handle that declines the print reports failure to the routine, just as
# it does on the main thread: print returns false and no warning is raised.
my $failed_handle = gensym();
tie *{$failed_handle}, 'Local::GoRoutine::FalsePrintHandle'
    or die 'Could not create the tied test handle';
share my $declined_print;
go sub {
    $declined_print = print {$failed_handle} 'x';
};
wait_all();
ok !$declined_print,
    'print returns false when the handle declines the write';
untie *{$failed_handle};

done_testing;

__END__

=head1 NAME

t/253-goroutine-handle-dispatch-coverage.t - test shared handle use from routines

=head1 PURPOSE

Tests that a filehandle shared with C<share> can be used from inside a
C<go> routine under the single-threaded event-loop engine: printing to it
from a routine lands in the file, and the ordinary filehandle operations
(seek, readline, getc, read, binmode, tell, fileno, eof, syswrite, close)
behave exactly as they do on the main thread.

=head1 WHY IT EXISTS

Shared filehandle behavior used to cross a worker-interpreter boundary
through a remote dispatcher. Under the new engine there is one interpreter,
so the shared handle IS the plain Perl filehandle, and the dispatcher is
gone. This test pins the observable that mattered all along -- a routine
writing to a shared handle reaches the file -- using native handles, and
keeps deterministic coverage for each operation's return value and
position handling without any dispatcher.

=head1 WHEN TO USE

Run this test when changing shared handle operations, byte-count behavior,
or position handling:

    d2 docker compose exec dev prove -lv t/253-goroutine-handle-dispatch-coverage.t

=head1 HOW TO USE

The test opens a temporary raw file as a shared handle, runs each
filehandle operation inside a C<go> routine, waits with C<wait_all>, and
checks return values and final file contents. It tests both scalar and list
context for C<read>, and both forms of C<binmode>.

=head1 WHAT USES IT

The repository test suite and four-metric coverage gate use this test to
verify shared-handle behavior in Developer::Dashboard::GoRoutine.

=head1 EXAMPLES

The test exercises C<print>, C<printf>, line reads, C<getc>, C<read>,
C<syswrite>, C<seek>, C<tell>, C<eof>, C<fileno>, C<binmode>, and C<close>
from inside routines. C<syswrite> is tested with both an explicit offset
and its default offset, plus a tied handle that declines the print so the
routine sees a false return without a warning.

=cut
