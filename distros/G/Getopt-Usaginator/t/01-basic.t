#!/usr/bin/env perl

use strict;
use warnings;

use Test::Most 'no_plan';
use File::Spec;
use IPC::Open3;
use Symbol qw/ gensym /;

sub run {
    my $file = shift;
    local $/;
    $file = File::Spec->canonpath( $file );
    my $handle = gensym;
    my $pid = open3 undef, undef, $handle, "$^X $file" or die $!;
    my $output = <$handle>;
    waitpid $pid, 0;
    my $status = $? >> 8;
    return ( $status, $output );
}

# The testing is really more complicated than the actual module
# Just test on "nice" platforms, for now
if ( $^O =~ m/^(?:linux|freebsd|openbsd)/i ) {

    my ( $status, $output );

    ( $status, $output ) = run 't/assets/t0';
    is( $status, 255 );
    is( $output, <<_END_ );
Apple

Usage: t0
_END_

    ( $status, $output ) = run 't/assets/t1';
    is( $status, 2 );
    is( $output, <<_END_ );
Banana

Usage: t1
_END_

    ( $status, $output ) = run 't/assets/t2';
    is( $status, 0 );
    is( $output, <<_END_ );
Usage: t2
_END_
}
else {
    ok( 1 );
}

