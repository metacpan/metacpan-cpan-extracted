package Digest::FNV::PurePerl;

use warnings;
use strict;
use Exporter;

our @ISA = qw(Exporter);
our @EXPORT = qw( fnv fnv32 fnv32a fnv64 fnv64a );

=head1 NAME

Digest::FNV::PurePerl - PurePerl implementation of Digest::FNV hashing algorithm.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.03';


=head1 SYNOPSIS

    use Digest::FNV::PurePerl qw( fnv fnv32 fnv32a fnv64 fnv64a );

    my $fnv32hash = fnv("abc123");
    
    my $fnv32hash = fnv32("abc123"); # This does the same as the previous example
    
    my $hashref = fnv64("abc123");
    $hashref->{bits};     # 32 for 32 bit systems, 64 for 64 bit systems
    $hashref->{upper};    # Upper 32 bits
    $hashref->{lower};    # Lower 32 bits
    $hashref->{bigint}    # use bigint; version of this possibly large number
    $hashref->{longlong}; # 64 bit representation (i.e. (upper << 32) | lower)
                          # This value is useless on 32 bit systems

=head1 DESCRIPTION

FNV is a hashing algorithm for short to medium length strings.  It is best
suited for strings that are typically around 1024 bytes or less (URLs, IP
addresses, hostnames, etc).  This implementation is based on the code provided
by Landon Curt Noll.

There are two slightly different algorithms.  One is called FNV-1, and the other
is FNV-1a.  Both algorithms are provided for each of 32 and 64 bit hash values.

For full information on this algorithm please visit
http://isthe.com/chongo/tech/comp/fnv/

The original Digest::FNV was written by Tan D Nguyen <tnguyen@cpan.org>.  This
version is a drop-in replacement (all existing code should continue to work).
However, it is a complete rewrite.

This new version works on both 32 and 64 bit platforms.

=head1 CAVEATS

Part of the challenge of supporting this module are the differences between
32-bit and 64-bit architectures.

In practice the values returned by these algorithms are often further processed
further algorithms.  It is for that reason that the nature of what the
fnv64/fnv64a functions return is exposed.  When trying to support both 64 and
32 bit architectures it is necessary.

You cannot rely on only $hashref->{bigint} if you plan to perform and further
math on that value on 32 bit systems.  You also cannot rely on
$hashref->{longlong} unless you know the architecture.

This module attempts to provide all of the necessary information to arrive at a
true 64-bit value.  Often times you're passing values to other software (a
database, for example), and that database probably provides 64-bit left shift
operations.

=head1 EXPORT

fnv fnv32 fnv32a fnv64 fnv64a

=head1 FUNCTIONS

=head2 fnv fnv32 fnv32a

    use Digest::FNV::PurePerl;

    my $url = "http://www.google.com/";
    print fnv($url),"\n";
        #-> 1088293357

    print fnv32($url),"\n";
        #-> 1088293357

    print fnv32a($url),"\n";
        #-> 912201313

=cut

sub fnv {
    my ($string) = @_;
    my $fnv_prime = 0x01000193;
    my $hval = 0x811c9dc5;

    if ((1<<32) == 4294967296) {
        foreach my $c (unpack('C*', $string)) {
            $hval += (
                (($hval << 1) ) +
                (($hval << 4) ) +
                (($hval << 7) ) +
                (($hval << 8) ) +
                (($hval << 24) ) );
            $hval = $hval & 0xffffffff;
            $hval ^= $c;
        }
    }
    else {
        use bigint;
        foreach my $c (unpack('C*', $string)) {
            $hval += (
                (($hval << 1) ) +
                (($hval << 4) ) +
                (($hval << 7) ) +
                (($hval << 8) ) +
                (($hval << 24) ) );
            $hval = $hval & 0xffffffff;
            $hval ^= $c;
        }
    }
    return $hval;
}

sub fnv32 {
    my ($string) = @_;
    return fnv($string);
}

sub fnv32a {
    my ($string) = @_;
    my $fnv_prime = 0x01000193;
    my $hval = 0x811c9dc5;

    if ((1<<32) == 4294967296) {
        foreach my $c (unpack('C*', $string)) {
            $hval ^= $c;
            $hval += (
                (($hval << 1) ) +
                (($hval << 4) ) +
                (($hval << 7) ) +
                (($hval << 8) ) +
                (($hval << 24) ) );
            $hval = $hval & 0xffffffff;
        }
    }
    else {
        use bigint;
        foreach my $c (unpack('C*', $string)) {
            $hval ^= $c;
            $hval += (
                (($hval << 1) ) +
                (($hval << 4) ) +
                (($hval << 7) ) +
                (($hval << 8) ) +
                (($hval << 24) ) );
            $hval = $hval & 0xffffffff;
        }
    }
    return $hval;
}

=head2 fnv64 fnv64a

    use Digest::FNV::PurePerl;
    use Data::Dumper;

    my $url = "http://www.google.com/";
    my $fnv64hash = fnv64($url);
    print Dumper($fnv64hash);
        #-> $VAR1 = {
        #->          'bigint' => bless( {
        #->                               'value' => [
        #->                                            290527405,
        #->                                            988083964,
        #->                                            9
        #->                                          ],
        #->                               'sign' => '+'
        #->                             }, 'Math::BigInt' ),
        #->          'upper' => 2325532018,
        #->          'lower' => 1179644077,
        #->          'longlong' => '9988083964290527405',
        #->          'bits' => 64
        #->        };

    fnv65a($url);

=cut

sub fnv64 {
    my ($string) = @_;
    my $fnv_prime = 0;
    my %hval = (
        'bits'  => 0,
        'upper' => 0,
        'lower' => 0,
        'longlong' => 0,
        'bigint' => 0
    );

    if ((1<<32) == 4294967296) {
        $hval{'bits'} = 64;
    }
    elsif ((1<<32) == 0) {
        $hval{'bits'} = 32;
    }
    else {
        $hval{'bits'} = undef;
    }

    my $FNV_64_PRIME_LOW = 0x1b3;	# lower bits of FNV prime
    my $FNV_64_PRIME_SHIFT = 8;     # top FNV prime shift above 2^32
    my @val = (0, 0, 0, 0);
    my @tmp = (0, 0, 0, 0);
    my $FNV1_64_LOWER = 0x84222325;
    my $FNV1_64_UPPER = 0xcbf29ce4;
    my $upper;
    my $lower;

    $val[0] = $FNV1_64_LOWER;
    $val[1] = ($val[0] >> 16);
    $val[0] &= 0xffff;
    $val[2] = $FNV1_64_UPPER;
    $val[3] = ($val[2] >> 16);
    $val[2] &= 0xffff;

    foreach my $c (unpack('C*', $string)) {
        $tmp[0] = $val[0] * $FNV_64_PRIME_LOW;
        $tmp[1] = $val[1] * $FNV_64_PRIME_LOW;
        $tmp[2] = $val[2] * $FNV_64_PRIME_LOW;
        $tmp[3] = $val[3] * $FNV_64_PRIME_LOW;
        # multiply by the other non-zero digit
        $tmp[2] += $val[0] << $FNV_64_PRIME_SHIFT;	# tmp[2] += val[0] * 0x100
        $tmp[3] += $val[1] << $FNV_64_PRIME_SHIFT;	# tmp[3] += val[1] * 0x100
        # propagate carries
        $tmp[1] += ($tmp[0] >> 16);
        $val[0] = $tmp[0] & 0xffff;
        $tmp[2] += ($tmp[1] >> 16);
        $val[1] = $tmp[1] & 0xffff;
        $val[3] = $tmp[3] + ($tmp[2] >> 16);
        $val[2] = $tmp[2] & 0xffff;

        # Doing a val[3] &= 0xffff; is not really needed since it simply
        # removes multiples of 2^64.  We can discard these excess bits
        # outside of the loop when we convert to Fnv64_t.
    
        $val[0] &= 0xffff;
        $val[1] &= 0xffff;
        $val[2] &= 0xffff;
        $val[3] &= 0xffff;

        $tmp[0] &= 0xffff;
        $tmp[1] &= 0xffff;
        $tmp[2] &= 0xffff;
        $tmp[3] &= 0xffff;

        # xor the bottom with the current octet
        $val[0] ^= $c;
    }
    $upper = $hval{'upper'} = (($val[3]<<16) | $val[2]) & 0xffffffff;
    $lower = $hval{'lower'} = (($val[1]<<16) | $val[0]) & 0xffffffff;
    $hval{'longlong'} = ($upper << 32) | $lower;
    use bigint;
    $hval{'bigint'} = (($upper << 32) | $lower);
    return \%hval;
}

sub fnv64a {
    my ($string) = @_;
    my $fnv_prime = 0;
    my %hval = (
        'bits'  => 0,
        'upper' => 0,
        'lower' => 0,
        'longlong' => 0,
        'bigint' => 0
    );

    if ((1<<32) == 4294967296) {
        $hval{'bits'} = 64;
    }
    elsif ((1<<32) == 0) {
        $hval{'bits'} = 32;
    }
    else {
        $hval{'bits'} = undef;
    }

    my $FNV_64_PRIME_LOW = 0x1b3;	# lower bits of FNV prime
    my $FNV_64_PRIME_SHIFT = 8;     # top FNV prime shift above 2^32
    my @val = (0, 0, 0, 0);
    my @tmp = (0, 0, 0, 0);
    my $FNV1_64_LOWER = 0x84222325;
    my $FNV1_64_UPPER = 0xcbf29ce4;
    my $upper;
    my $lower;

    $val[0] = $FNV1_64_LOWER;
    $val[1] = ($val[0] >> 16);
    $val[0] &= 0xffff;
    $val[2] = $FNV1_64_UPPER;
    $val[3] = ($val[2] >> 16);
    $val[2] &= 0xffff;

    foreach my $c (unpack('C*', $string)) {
        # xor the bottom with the current octet
        $val[0] ^= $c;

        $tmp[0] = $val[0] * $FNV_64_PRIME_LOW;
        $tmp[1] = $val[1] * $FNV_64_PRIME_LOW;
        $tmp[2] = $val[2] * $FNV_64_PRIME_LOW;
        $tmp[3] = $val[3] * $FNV_64_PRIME_LOW;
        # multiply by the other non-zero digit
        $tmp[2] += $val[0] << $FNV_64_PRIME_SHIFT;	# tmp[2] += val[0] * 0x100
        $tmp[3] += $val[1] << $FNV_64_PRIME_SHIFT;	# tmp[3] += val[1] * 0x100
        # propagate carries
        $tmp[1] += ($tmp[0] >> 16);
        $val[0] = $tmp[0] & 0xffff;
        $tmp[2] += ($tmp[1] >> 16);
        $val[1] = $tmp[1] & 0xffff;
        $val[3] = $tmp[3] + ($tmp[2] >> 16);
        $val[2] = $tmp[2] & 0xffff;

        # Doing a val[3] &= 0xffff; is not really needed since it simply
        # removes multiples of 2^64.  We can discard these excess bits
        # outside of the loop when we convert to Fnv64_t.

        $val[0] &= 0xffff;
        $val[1] &= 0xffff;
        $val[2] &= 0xffff;
        $val[3] &= 0xffff;

        $tmp[0] &= 0xffff;
        $tmp[1] &= 0xffff;
        $tmp[2] &= 0xffff;
        $tmp[3] &= 0xffff;
    }
    $upper = $hval{'upper'} = (($val[3]<<16) | $val[2]) & 0xffffffff;
    $lower = $hval{'lower'} = (($val[1]<<16) | $val[0]) & 0xffffffff;
    $hval{'longlong'} = ($upper << 32) | $lower;
    use bigint;
    $hval{'bigint'} = (($upper << 32) | $lower);
    #print "Bigint: ".$hval{'bigint'}."\n";
    #print "Longlong: ".$hval{'longlong'}."\n";
    #print "Upper: ".$upper."\n";
    #print "Lower: ".$lower."\n";
    return \%hval;
}

=head1 AUTHOR

Jeffrey Webster, C<< <jeff.webster at zogmedia.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-digest-fnv-pureperl at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Digest-FNV-PurePerl>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Digest::FNV::PurePerl


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Digest-FNV-PurePerl>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Digest-FNV-PurePerl>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Digest-FNV-PurePerl>

=item * Search CPAN

L<http://search.cpan.org/dist/Digest-FNV-PurePerl/>

=back


=head1 ACKNOWLEDGEMENTS

Inspired by Fowler, Noll, and Vo for their nifty little hashing algorithm.

Thanks to Tan Nguyen for handing over control of Digest::FNV

=head1 COPYRIGHT & LICENSE

Copyright 2010 Jeffrey Webster.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Digest::FNV::PurePerl
