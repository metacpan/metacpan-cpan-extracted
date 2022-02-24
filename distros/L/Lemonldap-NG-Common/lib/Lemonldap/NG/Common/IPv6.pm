package Lemonldap::NG::Common::IPv6;

use strict;
use base 'Exporter';

our $VERSION = '2.0.10';
our @EXPORT  = qw(&isIPv6 &net6 &expand6);

sub isIPv6 {
    my ($ip) = @_;
    return $ip =~ /^[a-z0-9:]+$/i;
}

sub net6 {
    my ( $ip, $bits ) = @_;

    # Convert to binary
    my $b = join '',
      map { unpack( 'B*', pack( 'H*', $_ ) ) } split( ':', expand6($ip) );
    my $net = substr $b, 0, $bits;
    $net .= '0' x ( 128 - length($net) );
    $net = unpack( 'H*', pack( 'B*', $net ) );
    $net = join( ':', ( unpack "a4" x 8, $net ) );
    $net = compact6($net);
    return $net;
}

sub expand6 {
    my @arr;
    my @_parts = ( $_[0] =~ /([0-9A-Fa-f]+)/g );
    my $nparts = scalar @_parts;
    if ( $nparts != 8 ) {
        for ( my $i = 1 ; $i <= ( 8 - $nparts ) ; $i++ ) {
            push @arr, hex "0000";
        }
    }

    my @parts = map { ( $_ eq '::' ) ? @arr : hex $_ }
      ( $_[0] =~ /((?:[0-9A-Fa-f]+)|(?:::))/g );

    return join( ":", map { sprintf "%04x", $_ } @parts );

}

sub compact6 {
    $_[0] =~ s/(^|:)0+([\w])/$1$2/g;
    if ( $_[0] =~ ':0:' ) {
        my @t   = ( $_[0] =~ /\:(?:0\:)+/g );
        my $ind = -1;
        my $len = 0;
        for ( my $i = 0 ; $i < @t ; $i++ ) {
            $ind = $i if ( length( $t[$i] ) > $len );
        }
        $_[0] =~ s/$t[$ind]/::/;
        $_[0] =~ s/^0//;
    }
    return $_[0];
}

1;
