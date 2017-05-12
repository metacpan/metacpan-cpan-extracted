package Digest::FP56x1xor;

use 5.008008;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Digest::FP56x1xor ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
gen cat gen_l cat_l x2l l2x	
cooked
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.15';	# keep in sync with ../../Digest-FP56x1xor.xs

require XSLoader;
XSLoader::load('Digest::FP56x1xor', $VERSION);

# Preloaded methods go here.

1;
__END__

=head1 NAME

Digest::FP56x1xor - A 64bit fingerprint algorithm that features arithmetics.

=head1 SYNOPSIS

  use Digest::FP56x1xor qw(gen cat);	# ... x2l l2x gen_x cat_x

  my $hash1 = gen_l($text1);    	
  my $hash  = cat_l($hash1, $hash2); 

  my $hash1_x = gen($text1);    	
  my $hash_x  = cat($hash1_x, l2x($hash));
  my $hash    = x2l($hash_x));

  cooked($buffer, $offset, $length);
  my $cooked = cooked("\f\n \t Hello  World.\n\n\n+ Bye ( 3+ 4) = FOO ...   \n");
  # $cooked = "Hello World. Bye(3+4)=FOO..."

=head1 DESCRIPTION

Digest::FP56x1xor contains two basic methods, gen and cat.
gen generates a hash value from the given string $text.
cat computes the hash value that corresponds to the 
concatenation of the texts from which its two arguments were generated.

A hash is returned by gen as a 64bit integer; 
The highest 8 bits store 'length($text) mod 56' -- which is used in cat;
The lower 56 bits contain the hash value itself.
The highest 2 bits always remain 0.

The following equation is always true:

cat(gen($text1),gen($text2)) 
                eq
    gen($text1.$text2)

The hash of a text $text = $text1.$text2 can be calculated from two substrings 
$text1 and $text2, if these substrings cover the entire text 
without overlap.

The algorithm employs a static set of random numbers
taken from atmospheric noise.
All 56 bits are populated after reading 1 byte.

The following 3 expressions are equivalent:
gen($text); 
l2x(gen($text)); 
sprintf("0x016x", gen_l($text));

And the following 2 expressions are equivalent:
gen_l($text); 
x2l(gen($text)); 

cooked() is a helper function that clears a text from most whitespace and
nonprintables.  All ascii-codes above 128 are considered nonprintables, they
are replaced with one '~' character.
Leading '+', '-', '<', '>' characters at the beginning of a line are removed.
This is useful when comparing the output of diff (unified or normal) with the original text.
cooked() treats '\r', '\n', '\v' and '\f' as whitespace. Leading and trailing whitespace is removed, internal whitespace is reduced to one space ' ' character if delimited by word characters on either side and removed otherwise.
Offset and length parameters are optional. Offset defaults to 0, length defaults
to the entire (remaining) string.

All methods are implemented efficiently in C.

A reverse operation $h = sub(gen($text1.$text2), gen($text2));
with $h == gen($text1) may be possible.

=head1 BUGS

It may not qualify as a 'good' or 'strong' hash algorithm, although
the employed random number set makes it stronger than e.g. FP5x12ds.

Gen_l and cat_l are not available if perl has no 64bit long integers.
(use gen and cat then.)

The algorithm should have a proper name. 

Statistics for hash collision are unknown.


=head2 EXPORT

None by default.

=head1 AUTHOR

Juergen Weigert, E<lt>jw@suse.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007-2008 by Juergen Weigert

This library is free software; you can redistribute it and/or modify
it under the same terms as perl itself.

=cut
