=head1 NAME

Digest::FNV::XS - Fowler/Noll/Vo (FNV) hashes

=head1 SYNOPSIS

 use Digest::FNV::XS; # nothing exported by default

=head1 DESCRIPTION

This module is more or less a faster version of L<Digest::FNV>,
that additionally supports binary data, incremental hashing,
more FNV variants and more. The API isn't compatible (and
neither are the generated hash values. The hash values computed by
this module match the official FNV hash values as documented on
L<http://www.isthe.com/chongo/tech/comp/fnv/>).

=over 4

=cut

package Digest::FNV::XS;

BEGIN {
   $VERSION = 0.02;
   @ISA = qw(Exporter);
   @EXPORT_OK = qw(fnv0_32 fnv0_64 fnv1_32 fnv1a_32 fnv1_64 fnv1a_64 xorfold_32 xorfold_64 reduce_32 reduce_64);

   require Exporter;
   Exporter::export_ok_tags(keys %EXPORT_TAGS);

   require XSLoader;
   XSLoader::load Digest::FNV::XS, $VERSION;
}

=item $hash = Digest::FNV::XS::fnv1a_32 $data[, $init]

=item $hash = Digest::FNV::XS::fnv1a_64 $data[, $init]

Compute the 32 or 64 bit FNV-1a hash of the given string.

C<$init> is the optional initialisation value, allowing incremental
hashing. If missing or C<undef> then the appropriate FNV constant is used.

The 64 bit variant is only available when perl was compiled with 64 bit support.

The FNV-1a algorithm is the preferred variant, as it has slightly higher
quality and speed then FNV-1.

=item $hash = Digest::FNV::XS::fnv1_32 $data[, $init]

=item $hash = Digest::FNV::XS::fnv1_64 $data[, $init]

Compute the 32 or 64 bit FNV-1 hash of the given string.

C<$init> is the optional initialisation value, allowing incremental
hashing. If missing or C<undef> then the appropriate FNV constant is used.

The 64 bit variant is only available when perl was compiled with 64 bit support.

The FNV-1a variant is preferable if you can choose.

=item $hash = Digest::FNV::XS::fnv0_32 $data[, $init]

=item $hash = Digest::FNV::XS::fnv0_64 $data[, $init]

The obsolete FNV-0 algorithm. Same as calling the FNV1 variant with C<$init = 0>.

C<$init> is the optional initialisation value, allowing incremental
hashing. If missing or C<undef> then the appropriate FNV constant is used.

The 64 bit variant is only available when perl was compiled with 64 bit support.

=item $hash = Digest::FNV::XS::xorfold_32 $hash, $bits

=item $hash = Digest::FNV::XS::xorfold_64 $hash, $bits

XOR-folds the 32 (64) bit FNV hash to C<$bits> bits, which can be any
value between 1 and 32 (64) inclusive.

XOR-folding is a good method to reduce the FNV hash to a power of two range.

=item $hash = Digest::FNV::XS::reduce_32 $hash, $range

=item $hash = Digest::FNV::XS::reduce_64 $hash, $range

These two functions can be used to reduce a 32 (64) but FNV hash to
an integer in the range 0 .. C<$range>, using the retry method, which
distributes any bias more evenly.

=back

=head2 INCREMENTAL HASHING

You can hash data incrementally by feeding the previous hahs value as
C<$init> argument for the next call, for example:

   $hash = fnv1a_32 $data1;
   $hash = fnv1a_32 $data2, $hash; # and so on

Or in a loop (relying on the fact that C<$hash> is C<undef> initially):

   my $hash;
   $hash = fnv1a_32 $_, $hash
      for ...;

=head2 REDUCIDNG THE HASH VALUE

A common problem is to reduce the 32 (64) bit FNV hash value to a smaller range,
0 .. C<$range>.

The easiest method to do that, is to mask (For power of two) or modulo
(for other values) the hash value, i.e.:

   $inrage = $hash & ($range - 1) # for $range values that are power of two
   $inrage = $hash % $range       # for any range

This is called the lazy mod mapping method, which creates small biases that rarely
cause any problems in practise.

Nevertheless, you can improve the distribution of the bias by using
I<XOR folding>, for power of two ranges (and 32 bit hashews, there is also
C<forfold_64>)

   $inrage = Digest::FNV::XS::xorfold_32 $hash, $log2_of_range

And, using the retry method, for generic ranges (and 32 bit hashes, there
is also C<reduce_64>):

   $inrange = Digest::FNX::XS::reduce_32 $hash, $range

=head1 AUTHOR

 Marc Lehmann <schmorp@schmorp.de>
 http://software.schmorp.de/pkg/Digest-FNV-XS.html

=cut

1

