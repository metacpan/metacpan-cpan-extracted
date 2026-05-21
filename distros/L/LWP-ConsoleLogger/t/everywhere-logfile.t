use strict;
use warnings;

use File::Temp qw( tempfile );
use IPC::Run3  qw( run3 );
use Path::Tiny qw( path );
use Test::More import => [qw( diag done_testing is like ok subtest unlike )];
use Test::Warnings;

subtest 'LWPCL_LOGFILE writes UTF-8 without Wide-character warnings' => sub {
    my ( undef, $logfile ) = tempfile( UNLINK => 1 );

    my @cmd = ( $^X, '-Ilib', 't/everywhere-logfile-child.pl' );
    my ( $stdout, $stderr );
    {
        local $ENV{LWPCL_LOGFILE} = $logfile;
        run3( \@cmd, \undef, \$stdout, \$stderr );
    }
    is( $? >> 8, 0, 'child exited cleanly' )
        or diag "stderr: $stderr";

    unlike(
        $stderr, qr/Wide character in print/,
        'no "Wide character in print" warnings emitted'
    );

    my $bytes = path($logfile)->slurp_raw;
    like( $bytes, qr/\xF0\x9F\x98\x84/, '😄 UTF-8 bytes present in log file' );
};

done_testing;
