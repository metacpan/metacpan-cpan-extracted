#!perl

use strict;
use warnings;

use File::ReplaceBytes;
use Test::Most;    # plan is down at bottom

my $deeply = \&eq_or_diff;

########################################################################
#
# Fundamentals

can_ok( 'File::ReplaceBytes', qw/pread pwrite replacebytes/ );

########################################################################
#
# pread

open my $fh, '<', 't/testdata' or die "could not read t/testdata: $!\n";

my $buf = '';
my $st = File::ReplaceBytes::pread( $fh, $buf, 8, 8 );
$deeply->( [ $buf, $st ], [ 'bbbbbbbb', 8 ], 'read bx8' );

my $at = sysseek( $fh, 0, 1 );
ok( $at == 0, 'no position change after read' );

# and where pread from should not be influenced by position...
sysseek( $fh, 4, 0 );
$buf = '';
$st = File::ReplaceBytes::pread( $fh, $buf, 8, 7 );
$deeply->( [ $buf, $st ], [ 'abbbbbbb', 8 ], 'read after seek()' );

$buf = undef;
$st = File::ReplaceBytes::pread( $fh, $buf, 7, 6 );
$deeply->( [ $buf, $st ], [ 'aabbbbb', 7 ], 'read into undef scalar' );

$st = File::ReplaceBytes::pread( $fh, $buf, -1, 0 );
is( $st, -1, 'pread negative len' );

$st = File::ReplaceBytes::pread( $fh, $buf, 8, -1 );
is( $st, -1, 'pread negative offset' );

$buf = undef;
$st = File::ReplaceBytes::pread( $fh, $buf, 0, 0 );
ok( $st == 0 && !defined $buf, 'pread zero read' );

undef $fh;
$buf = '';
throws_ok(
    sub { File::ReplaceBytes::pread( $fh, $buf, 7, 6 ) },
    qr/undefined value as filehandle reference/,
    'bad filehandle'
);

# TODO way to detect in-memory fh vs. those that point to files? so can
# skip or issue error? Because pread on such... well, yeah. no.
# Devel::Peek shows no obvious differences between this and a file
# filehandle. (but could also be a socket, or who knows, probably just
# best to warn in the docs "must be file filehandle, here's your loaded
# shotgun, good luck!")
#my $data = 'aaaaaaaabbbbbbbbcccccccc';
#open my $imfh, '<', \$data;

my $to_write = "a" x 16;
my $readout;
my $write_offset = 8;
my $written;

########################################################################
#
# replacebytes (and also to create the 'out' file used by other tests)

$to_write     = "b" x 15;
$write_offset = 4;
$st = File::ReplaceBytes::replacebytes( 'out', $to_write, $write_offset );
is( $st, length $to_write, 'replacebytes some bytes' );

# so very naughty! prevent
is( File::ReplaceBytes::replacebytes( "out\0bla", "lalalalala" ),
    -1, 'embedded NUL in filename is not allowed' );

open $readout, '<', 'out' or die "could not read 'out': $!\n";
seek( $readout, $write_offset, 0 );
$written = do { local $/ = undef; readline $readout };
is( $to_write, $written, 'read what expected to write' );

open $fh, '>', 'out' or die "could not truncate 'out': $!\n";

########################################################################
#
# pwrite

open $fh, '+<', 'out' or die "could not write 'out': $!\n";

$st = File::ReplaceBytes::pwrite( $fh, $to_write, 0, $write_offset );
is( $st, length $to_write, 'pwrite some bytes' );
$at = sysseek( $fh, 0, 1 );
ok( $at == 0, 'should be no filehandle position change' );

# TODO might be fs sync problems if pwrite data tardy getting to disk?

open $readout, '<', 'out' or die "could not read 'out': $!\n";
seek( $readout, $write_offset, 0 );
$written = do { local $/ = undef; readline $readout };
is( $to_write, $written, 'read what expected to write' );

# should be no-ops as nothing to do
is( File::ReplaceBytes::pwrite( $fh, undef ), 0, 'nothing to do 1' );
is( File::ReplaceBytes::pwrite( $fh, '' ),    0, 'nothing to do 2' );

$st = File::ReplaceBytes::pwrite( $fh, "cat", -1 );
is( $st, -1, 'pwrite negative len' );

$st = File::ReplaceBytes::pwrite( $fh, "cat", 0, -1 );
is( $st, -1, 'pwrite negative offset' );

plan tests => 19;
