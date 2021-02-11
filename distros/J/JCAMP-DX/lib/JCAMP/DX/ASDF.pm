#------------------------------------------------------------------------------
#$Author: andrius $
#$Date: 2021-02-10 13:44:25 +0200 (Tr, 10 vas. 2021) $
#$Revision: 94 $
#$URL: svn+ssh://www.crystallography.net/home/coder/svn-repositories/JCAMP-DX/tags/v0.03/lib/JCAMP/DX/ASDF.pm $
#------------------------------------------------------------------------------
#*
#  Encoder/decoder for ASDF formats.
#**

package JCAMP::DX::ASDF;

use strict;
use warnings;

# ABSTRACT: encoder/decoder for ASDF formats
our $VERSION = '0.03'; # VERSION

require Exporter;
our @ISA = qw( Exporter );
our @EXPORT_OK = qw(
    decode
);

our $debug = 0;

sub decode_FIX
{
    my( $line ) = @_;
    $line =~ s/^\s+//;
    $line =~ s/\s+$//;

    return split /\s+/, $line;
}

sub decode_PAC
{
    my( $line ) = @_;
    $line =~ s/^\s+//;
    $line =~ s/\s+$//;

    my @elements = $line =~ /([ +-]?\d+)/g;
    return map { s/^[ +]//; $_ } @elements;
}

sub decode_SQZ
{
    my( $line ) = @_;
    $line =~ s/\s+(\d)/+$1/g;
    $line =~ s/\s+-/-/g;

    $line =~ s/\@/+0/g;
    $line =~ s/([A-I])/'+' . (ord( $1 ) - ord( 'A' ) + 1)/ge;
    $line =~ s/([a-i])/-ord( $1 ) + ord( 'a' ) - 1/ge;
    return decode_DIF( $line );
}

sub decode_DIF
{
    my( $line ) = @_;
    my @elements;
    while( $line ) {
        if( $line =~ s/^\+// ) {
            next;
        } elsif( $line =~ s/^(-?\d+)// ) {
            push @elements, int( $1 );
            print STDERR "got $& -> $elements[-1]\n" if $debug;
        } elsif( $line =~ s/^%(\d*)// ) {
            push @elements, $elements[-1] + ($1 ne '' ? $1 : 0);
            print STDERR "got $& -> $elements[-1]\n" if $debug;
        } elsif( $line =~ s/^([J-R])(\d*)// ) {
            push @elements, $elements[-1] +
                            ((ord( $1 ) - ord( 'J' ) + 1) . ($2 // ''));
            print STDERR "got $& -> $elements[-1]\n" if $debug;
        } elsif( $line =~ s/^([j-r])(\d*)// ) {
            push @elements, $elements[-1] -
                            ((ord( $1 ) - ord( 'j' ) + 1) . ($2 // ''));
            print STDERR "got $& -> $elements[-1]\n" if $debug;
        } elsif( $line =~ s/^(.)// ) {
            warn "unrecognised symbol: $1";
        }
    }
    return @elements;
}

sub decode_DIFDUP
{
    my( $line ) = @_;
    $line =~ s/(.)([S-Z])/$1 x ( ord( $2 ) - ord( 'S' ) + 1 )/ge;
    $line =~ s/(.)s/$1 x 9/g;
    return decode_SQZ( $line );
}

sub decode
{
    &decode_DIFDUP;
}

1;
