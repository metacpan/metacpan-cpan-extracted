package Digest::MurmurHash3;
use strict;
use base qw(Exporter);
use Config ();
use constant HAVE_64BITINT => $Config::Config{use64bitint};
use XSLoader;
BEGIN {
    our $VERSION = '0.03';
    XSLoader::load __PACKAGE__, $VERSION;
}

our @EXPORT_OK = qw( murmur32 mumur128 murmur128_x86 murmur128_x64 );
if ( ! HAVE_64BITINT ) {
    *murmur128_x64 = sub {
        Carp::croak( "64bit integers are not supported on your perl" );
    };
    *murmur128 = \&murmur128_x64;
} else {
    *murmur128 = \&murmur128_x86;
}

1;
__END__

=head1 NAME

Digest::MurmurHash3 - MurmurHash3 Implementation For Perl

=head1 SYNOPSIS

    use Digest::MurmurHash3 qw( murmur32 );

    # on 64 bit platforms, defaults to x64. otherwise x86
    # note that the values for each platform *WILL DIFFER*
    use Digest::MurmurHash3 qw( murmur128 );

    # If you want to explicitly require one algorithm, you need
    # to be specific
    use Digest::MurmurHash3 qw( murmur128_x64 );
    use Digest::MurmurHash3 qw( murmur128_x86 );

    my $hash = murmur32( $data_to_hash );

    # Create four 8 bit pieces
    my ($v1, $v2, $v3, $v4) = murmur128_x86( $data_to_hash );

    # Create two 64 bit pieces (your perl must be built to use 64bit ints)
    my ($v1, $v2) = murmur128_x64( $data_to_hash );

=head1 DESCRIPTION

This module provides an interface to MurmurHash3 functions.

=head1 FUNCTIONS

=head2 $h = murmur32( $data [, $seed] )

Calculates a 32 bit hash.

=head2 @varies = murmur128( $data [, $seed ] )

Calculates a 128 bit hash.

Note that the actual implementation of this function will differ depending 
on how your perl was built.

If your perl was built with 64 bit integers, this function is an alias to
mumur128_x64(). Otherwise, it's an alias to mumur128_x68(). While they
employ similar calculations, each use the best approach for your system so
the results are different. The x64 version returns two element list of
64 bit integers. The x86 version returns a four element list of 32 bit
integers.

=head2 ($v1, $v2, $v3, $v4) = mumur128_x86( $data [, $seed ] )

Calculates a 128 bit hash. The result is returned as a four element list of
32 bit integers

=head2 ($v1, $v2) = murmur128_x64( $data [, $seed ] )

Calculates a 128 bit hash. The result is returned as a two element list of
64 bit integers

=head1 AUTHOR

Daisuke Maki C<< <daisuke@endeworks.jp> >>

MurmurHash3 by Austin Appleby.

=cut