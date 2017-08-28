package MYDan::Collector::Util;
use strict;
use warnings;

use Carp;
use POSIX ":sys_wait_h";

sub system
{
    my ( $todo, $exit, $cpid ) = shift;

    return ( -65, "exec error:$!" ) unless $cpid = open my $out, "-|", $todo;

    while( my $t = <$out>) { print $t; }

    waitpid $cpid, WNOHANG;
    if    ( $? == -1 ) { $exit = -66; }
    elsif ( $? & 127 ) { $exit = $? & 127; }
    else  { $exit = $? >> 8; }
    close $out;
    return $exit;
}

sub qx
{
    my ( $todo, @output, $cpid ) = shift;

    return () unless $cpid = open my $x, "-|", $todo;

    while( my $t = <$x> ) { push @output, $t; }

    waitpid $cpid, 0;
    my @r = ( $? == -1 || $? & 127 ) ? () : @output;
    close $x;
    wantarray ? @r : join '', @r;
}

sub system_qx
{
    my ( $todo, $output, $exit, $cpid ) = ( shift, '' );

    return ( -65, "exec error:$!" ) unless $cpid = open my $out, "-|", $todo;

    while( my $t = <$out>) { $output .= $t; }

    waitpid $cpid, WNOHANG;
    if    ( $? == -1 ) { $exit = -66; }
    elsif ( $? & 127 ) { $exit = $? & 127; }
    else  { $exit = $? >> 8; }
    close $out;
    return ( $exit, $output );
}

1;
