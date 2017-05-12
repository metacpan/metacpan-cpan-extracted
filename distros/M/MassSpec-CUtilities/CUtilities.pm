package MassSpec::CUtilities;

use 5.008;
use strict;
use warnings;
use Carp;

require Exporter;
use AutoLoader;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use MassSpec::CUtilities ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.05';

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.

    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "&MassSpec::CUtilities::constant not defined" if $constname eq 'constant';
    my ($error, $val) = constant($constname);
    if ($error) { croak $error; }
    {
	no strict 'refs';
	# Fixed between 5.005_53 and 5.005_61
#XXX	if ($] >= 5.00561) {
#XXX	    *$AUTOLOAD = sub () { $val };
#XXX	}
#XXX	else {
	    *$AUTOLOAD = sub { $val };
#XXX	}
    }
    goto &$AUTOLOAD;
}

require XSLoader;
XSLoader::load('MassSpec::CUtilities', $VERSION);

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

=head1 NAME

MassSpec::CUtilities - Perl extension containing C utilities for use in mass spectrometry

=head1 SYNOPSIS

  # MassSpec::CUtilities is an XS module so there's a chance that you or
  # your target user might not get it to install cleanly on the target system;
  # therefore it's recommended to make its presence optional and to offer
  # slower-performing Perl equivalents where practical.
  # 
  # Also note that this module uses a 19-letter amino alphabet rather than
  # the traditional 20-letter alphabet, since the isobars Leucine(L) and
  # Isoleucine(I) are represented instead by "X."  Furthermore some portions
  # of this module assume that their input peptides are internally in
  # alphabetical order.
  my $haveCUtilities;
  if (eval 'require MassSpec::CUtilities') {
          import MassSpec::CUtilities;
          $haveCUtilities = 1;
  } else {
          $haveCUtilities = 0;
  }
  if ($haveCUtilities) {
          my $candidate = MassSpec::CUtilities::encodeAsBitString("ACCGT");
          my @shortPeptides = ("ACT","CCGM","ACCGTY","CCT");
          my (@list,@answer);
          foreach $_ (@shortPeptides) {
                  push @list, MassSpec::CUtilities::encodeAsBitString($_);
          }
          if (MassSpec::CUtilities::testManyBitStrings($candidate,\@shortPeptides,\@list,\@answer)) {
                  # should print "ACT" and "CCT" only
                  print "Matched: " . join(',',@answer) . "\n";
          }
   }
   # see API documentation for other available subroutines


=head1 ABSTRACT

  An eclectic mix of C utilities originally used in a mass spectrometry
  denovo sequencing project at NIH.  It includes a fast Huffman decoder
  suitable (with minor modifications) for use with the CPAN module
  Algorithm::Huffman, as well as a fast peptide mass calculator and methods for
  encoding peptides as products of prime numbers or as bitmaps.

=head1 DESCRIPTION

An eclectic mix of C utilities originally used in a mass spectrometry
denovo sequencing project at NIH.  It includes a fast Huffman decoder
suitable (with minor modifications) for use with the CPAN module
Algorithm::Huffman, as well as a fast peptide mass calculator and methods for
encoding peptides as products of prime numbers or as bitmaps.

=head2 PROGRAMMER'S INTERFACE (API)

=over 4

=item B<computePeptideMass>(peptide)

Compute the mass of a peptide in daltons.

=item B<initDecoderTree>(Huffman_code,values)

Initialize a Huffman decoder tree given a Huffman code and the delta-values associated with the
corresponding code.  This could be easily generalized for a more common use of Huffman
trees, mapping Huffman codes to the actual decoded values.  However, since AACs are
always guaranteed to be sorted, we're encoding the deltas (differences) between consecutive
characters rather than the character itself.  See the code for more details.

=item B<fast_decode>(encoded,len)

Perform Huffman decoding, assuming that the decoder tree has already been initialized
by a call to C<initDecoderTree>().

=item B<bitsAvailableForPrimeProducts>()

Report the number of bits available for computing prime products based upon the local
hardware architecture and C compiler support.  In general, less than 64 bits isn't very
useful, and anything greater than 64 bits would be fantastic.

=item B<computePrimeProduct>(peptide)

Compute an encoded value for a peptide, using a code which maps each amino acid to one
of the lowest 19 prime numbers and then computes their (multiplicative) product.  Returns
C<undef> if there aren't enough available bits to encode this prime.

I<(N.B.: one might do better using 71 instead of 2 and
thereby be able to perform arithmetic modulo 2**N, where N might typically be 16 or 32)>

=item B<testManyPrimeProducts>(product,peptides,multiples,answer)

Perform bulk testing of a single encoded peptide-product versus a collection of similarly
encoded products, to see which of the set <@multiples> are exact divisors of C<$product>, which
corresponds to a string being an extension of one of the strings in C<@peptides>.  Any successful
hits are logged in the C<@answer>, and the hit count is returned as the subroutine's value.

=item B<computeManyPrimeProducts>(peptides,multiples)

Like C<computePrimeProduct>, but attempts to compute these products for multiple peptides
and terminates with a non-positive value if any of these computations fail due to a lack
of bits in one of the prime products.

=item B<encodeAsBitString>(peptide)

Yet another approach to comparing whether one peptide is an extension of one or more of
a set of other peptides.  Here we determine the maximum number of each amino acid which
can "fit" in a peptide of a given maximum mass (currently hard-coded as 2000 daltons).  Then
we encode one bit for each of the possible occurrences of each amino acid (usually wasting a
lot of bits).

=item B<testManyBitStrings>(encodedCandidate,peptides,bitstrings,answer)

Test the bitstrings encoded in C<encodeAsBitString>() against one another in a manner
analogous to C<testManyPrimeProducts>().

=item B<quickAACLookup>(minmass,maxmass,answer)

For a small in-memory database (AACs up to 4 residues long), find all the AACs associated with a mass range.

=item B<binarySearchSpectrum>(mass,extended_spectrum)

Perform a binary search of C<extended_spectrum>, and return the index of the entry just
greater than C<mass>.

=back

=head1 THANKS TO

=over 4

=item Assaf Rahav (C<rahav_assaf@yahoo.com>)
who suggested the prime product idea

=item Jack Chen (C<xchen@helix.nih.gov>)
who wrote the C code for portions of the Huffman decoder

=back

=head1 SEE ALSO

Spengler, B.
I<De novo sequencing, peptide composition analysis, and composition-based sequencing: a new strategy employing accurate mass determination by fourier transform ion cyclotron resonance mass spectrometry.>
J Am Soc Mass Spectrom. B<2004> May;15(5):B<703-14>.

Any good computer science textbook about data structures

TODO: add journal citation(s) here

=head1 AUTHOR

Jonathan Epstein, E<lt>Jonathan_Epstein@nih.govE<gt>

=head1 COPYRIGHT AND LICENSE

                          PUBLIC DOMAIN NOTICE

        National Institute of Child Health and Human Development

 This software/database is a "United States Government Work" under the
 terms of the United States Copyright Act.  It was written as part of
 the author's official duties as a United States Government employee and
 thus cannot be copyrighted.  This software/database is freely available
 to the public for use. The National Institutes of Health and the U.S.
 Government have not placed any restriction on its use or reproduction.

 Although all reasonable efforts have been taken to ensure the accuracy
 and reliability of the software and data, the NIH and the U.S.
 Government do not and cannot warrant the performance or results that
 may be obtained by using this software or data. The NIH and the U.S.
 Government disclaim all warranties, express or implied, including
 warranties of performance, merchantability or fitness for any particular
 purpose.
 
Please cite the author in any work or product based on this material.
 

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
