package Digest::ssdeep;

use warnings;
use strict;
use Carp;
use Text::WagnerFischer qw/distance/;
use List::Util qw/max/;

use version; 
our $VERSION = qv('0.9.3');

BEGIN {
    require Exporter;
    use vars qw(@ISA @EXPORT_OK);
    @ISA       = qw(Exporter);
    @EXPORT_OK = qw(
      ssdeep_hash
      ssdeep_hash_file
      ssdeep_compare
      ssdeep_dump_last
    );
}

use constant FNV_PRIME  => 0x01000193;
use constant FNV_INIT   => 0x28021967;
use constant MAX_LENGTH => 64;

# Weights:
#  same                = 0
#  insertion/deletion  = 1
#  mismatch            = 2
#  swap                = N/A (should be 5)
$Text::WagnerFischer::REFC = [ 0, 1, 2 ];

my @b64 = split '',
  "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
my @DEBUG_LAST;

my @last7chars;    # will use character 7 places before
{                  # begin rolling hash internals

    my $roll_h1;    # rolling hash internal
    my $roll_h2;    # rolling hash internal
    my $roll_h3;    # rolling hash internal

    # Resets the roll hash internal status
    sub _reset_rollhash {
        @last7chars =
          ( 0, 0, 0, 0, 0, 0, 0 );    # will use character 7 places before
        $roll_h1 = 0;
        $roll_h2 = 0;
        $roll_h3 = 0;
    }

    # Updates rolling_hash's internal state and return the rolling_hash value.
    # Parameters: the next character.
    # Returns: the actual rolling hash value
    sub _roll_hash {
        my $char    = shift;
        my $char7bf = shift @last7chars;

        push @last7chars, $char;

        $roll_h2 += 7 * $char - $roll_h1;
        $roll_h1 += $char - $char7bf;

        $roll_h3 <<= 5;    # 5*7 = 35 (so it vanish after 7 iterations)
        $roll_h3 &= 0xffffffff;
        $roll_h3 ^= $char;

        #printf("c=%d  cAnt=%d    H1=%u  H2=%u  H3=%u\n",
        #	$char, $char7bf,
        #	$roll_h1, $roll_h2, $roll_h3);

        return $roll_h1 + $roll_h2 + $roll_h3;
    }

}    # end rolling hash internals

# In-place updates the FNV hash using the new character
# _update_fnv($fnvhash, $newchar);
sub _update_fnv {
    use integer;    # we need integer overflow in multiplication
    $_[0] *= FNV_PRIME;
    $_[0] &= 0xffffffff;
    $_[0] ^= $_[1];
    no integer;
}

# Calculates initial blocksize
# Parameter: the length of the whole data
sub _calc_initbs {
    my $length = shift;

    # MAX_LENGTH * bs < length
    # MAX_LENGTH * 3 * 2 * 2 * 2 * ... < length
    #my $n = int(log($length / (MAX_LENGTH * 3)) / log(2));
    #my $bs = 3 * 2**$n;
    my $bs = 3;
    $bs *= 2 while ( $bs * MAX_LENGTH < $length );

    return $bs > 3 ? $bs : 3;
}

# Calculates the ssdeep fuzzy hash of a string
# Parameters: the string
# Returns: the fuzzy hash in string or array
sub ssdeep_hash {
    my $string = shift;

    return unless defined $string;

    my $bs = _calc_initbs( length $string );
    @DEBUG_LAST = ();

    my $hash1;
    my $hash2;

    while (1) {
        _reset_rollhash();
        my $fnv1 = FNV_INIT;    # traditional hash blocksize
        my $fnv2 = FNV_INIT;    # traditional hash 2*blocksize

        $hash1 = '';
        $hash2 = '';

        for my $i ( 0 .. length($string) - 1 ) {
            my $c = ord( substr( $string, $i, 1 ) );

            #printf("c: %u, H1=%x\tH2=%x\n", $c, $fnv1, $fnv2);

            my $h = _roll_hash($c);
            _update_fnv( $fnv1, $c );    # blocksize FNV hash
            _update_fnv( $fnv2, $c );    # 2* blocksize FNV hash

            if ( $h % $bs == ( $bs - 1 ) and length $hash1 < MAX_LENGTH - 1 ) {

                #printf "Hash $h Trigger 1 at $i\n";
                my $b64char = $b64[ $fnv1 & 63 ];
                $hash1 .= $b64char;

                push @DEBUG_LAST,
                  [ 1, $i + 1, join( '|', @last7chars ), $fnv1, $b64char ];

                $fnv1 = FNV_INIT;

            }

            if ( $h % ( 2 * $bs ) == ( 2 * $bs - 1 )
                and length $hash2 < MAX_LENGTH / 2 - 1 )
            {

                #printf "Hash $h Trigger 2 at $i\n";
                my $b64char = $b64[ $fnv2 & 63 ];
                $hash2 .= $b64char;

                push @DEBUG_LAST,
                  [ 2, $i + 1, join( '|', @last7chars ), $fnv2, $b64char ];

                $fnv2 = FNV_INIT;
            }

        }

        $hash1 .= $b64[ $fnv1 & 63 ];
        $hash2 .= $b64[ $fnv2 & 63 ];

        push @DEBUG_LAST,
          [
            1, length($string),
            join( '|', @last7chars ), $fnv1,
            $b64[ $fnv1 & 63 ]
          ];

        push @DEBUG_LAST,
          [
            2, length($string),
            join( '|', @last7chars ), $fnv2,
            $b64[ $fnv2 & 63 ]
          ];

        last if $bs <= 3 or length $hash1 >= MAX_LENGTH / 2;

        $bs = int( $bs / 2 ); # repeat with half blocksize if no enough triggers
        $bs > 3 or $bs = 3;
    }

    my @outarray = ( $bs, $hash1, $hash2 );
    return wantarray ? @outarray : join ':', @outarray;
}

# Convenient function. Slurps file. You should not use it for long files.
# You should not use pure perl implementation for long files anyway.
# Parameter: filename
# Returns: ssdeep hash in string or array format
sub ssdeep_hash_file {
    my $file = shift;

    # Slurp the file (we can also use File::Slurp
    local ($/);
    open( my $fh, '<', $file ) or return;
    my $string = <$fh>;
    close $fh;

    return ssdeep_hash($string);
}

# Determines the longest common substring
sub _lcss {
    my $strings = join "\0", @_;
    my $lcs = '';

    for my $n ( 1 .. length $strings ) {
        my $re = "(.{$n})" . '.*\0.*\1' x ( @_ - 1 );
        last unless $strings =~ $re;
        $lcs = $1;
    }

    return $lcs;
}

# Calculates how similar two strings are using the Wagner-Fischer package.
# Parameters: min_lcs, string A, string B
# Returns: the likeliness being 0 totally dissimilar and 100 same string
# Returns 0 also if the longest common substring is shorter than min_lcs
sub _likeliness {
    my ( $min_lcs, $a, $b ) = @_;

    return 0 unless length( _lcss( $a, $b ) ) >= $min_lcs;

    my $dist = distance( $a, $b );

    #$DB::single = 2;

    # Must follow ssdeep original's code for compatibility
    #  $dist = 100 * $dist / (length($a) + length($b));
    $dist = int( $dist * MAX_LENGTH / ( length($a) + length($b) ) );
    $dist = int( 100 * $dist / 64 );

    $dist > 100 and $dist = 100;
    return 100 - $dist;
}

# We accept hash in both array and scalar format
# Parameters: $hashA, $hashB, [$min_lcs]
# Parameters: \@hashA, \@hashB, [$min_lcs]
# Returns: file matching in %
sub ssdeep_compare {
    my @hashA;    # hash = bs:hash1:hash2
    my @hashB;    # hash = bs:hash1:hash2
    @hashA = ref( $_[0] ) eq 'ARRAY' ? @{ $_[0] } : split ':', $_[0];
    @hashB = ref( $_[1] ) eq 'ARRAY' ? @{ $_[1] } : split ':', $_[1];
    my $min_lcs = $_[2] || 7;

    if ( @hashA != 3 or $hashA[0] !~ /\d+/ ) {
        carp "Argument 1 is not a ssdeep hash.";
        return;
    }

    if ( @hashB != 3 or $hashB[0] !~ /\d+/ ) {
        carp "Argument 2 is not a ssdeep hash.";
        return;
    }

    # Remove sequences of more than three repeated character
    s/(.)\1{3,}/$1/gi for @hashA;
    s/(.)\1{3,}/$1/gi for @hashB;

    # Remove trailing newlines
    s/\s+$//gi for @hashA;
    s/\s+$//gi for @hashB;

    #$DB::single = 2;

    my $like;

    # Blocksize comparison
    # bsA:hash_bsA:hash_2*bsA
    # bsB:hash_bsB:hash_2*bsB
    if ( $hashA[0] == $hashB[0] ) {

        # Compare both hashes
        my $like1 = _likeliness( $min_lcs, $hashA[1], $hashB[1] );
        my $like2 = _likeliness( $min_lcs, $hashA[2], $hashB[2] );
        $like = max( $like1, $like2 );
    }
    elsif ( $hashA[0] == 2 * $hashB[0] ) {

        # Compare hash_bsA with hash_2*bsB
        $like = _likeliness( $min_lcs, $hashA[1], $hashB[2] );
    }
    elsif ( 2 * $hashA[0] == $hashB[0] ) {

        # Compare hash_2*bsA with hash_bsB
        $like = _likeliness( $min_lcs, $hashA[2], $hashB[1] );
    }
    else {

        # Nothing suitable to compare, sorry
        return 0;
    }

    return $like;
}

# Dump internals information. See help.
sub ssdeep_dump_last {
    my @result;
    for (@DEBUG_LAST) {
        push @result, join ",", @{$_};
    }
    return @result;
}

1;    # Magic true value required at end of module
__END__

=head1 NAME

Digest::ssdeep - Pure Perl ssdeep (CTPH) fuzzy hashing

=head1 VERSION

This document describes Digest::ssdeep version 0.9.0


=head1 SYNOPSIS

    use Digest::ssdeep qw/ssdeep_hash ssdeep_hash_file/;

    $hash = ssdeep_hash( $string );
    # or in array context:
    @hash = ssdeep_hash( $string );

    $hash = ssdeep_hash_file( "data.txt" );

    @details = ssdeep_dump_last();
    
    
    use Digest::ssdeep qw/ssdeep_compare/;

    $match = ssdeep_compare( $hashA, $hashB );
    $match = ssdeep_compare( \@hashA, \@hashB );
	


=head1 DESCRIPTION

This module provides simple implementation of ssdeep fuzzy hashing also known as Context Triggered Piecewise
Hashing (CTPH).

=head2 Fuzzy hashing algorithm

Please, refer to Jesse Kornblum's paper for a detailed discussion (L<SEE ALSO>).

To calculate the CTPH we should choose a maximum signature length. Then divide
the file in as many chunks as this length. Calculate a hash or checksum for
each chunk and map it to a character. The fuzzy hashing is the concatenation of
all the characters.

We cannot use fixed length blocks to separate the file. Because if we add or
remove a character all of the following blocks are also changed. So we must
divide the file using the "context" i.e. a block starts and ends in one of the
predefined sequence of characters. So the problem is 'Which contexts
-sequences- we define to separate the file in N parts?.'

This is the 'roll' of the I<rolling hash>. It is a function of the N last
inputs, in this case the 7 last characters. The result of the rolling hash
function is uniformly spread between all valid output values.  This makes the
rolling hash some kind of I<pseudo-random> function whose output depends only
on the last N characters. Since the output is supposed to be uniform, we can
modulus BS and the expected values are 0 to BS-1 with the same probability.

Let the blocksize (BS) be the length of file divided by the maximum signature
length (i.e. 64). If we split the file each time the rolling hash mod BS gives
BS-1 we get 64 blocks.  This is not a good approach because if the length
changes, blocksize changes also. So we cannot compare files with dissimilar
sizes. One good approach is to take some 'predefined' blocksizes and choose the
one that fits based on the file size. The blocksizes in ssdeep are C<3, 6, 12,
..., 3 * 2^i>.

So this is the algorithm:

=over

=item *

Given the file size we calculate an initial blocksize (BS).

=item *

For each character we calculate the rolling hash R. Its output value depends
only on the 7 last characters sequence.

=item *

Each time C<R mod BS = BS-1> (we meet one of the trigger 7 characters
sequences) we write down the I<traditional hash> of the current block and start
another block.

=back

The pitfall is Rolling Hash is statistically uniform, but it does not mean it
will give us exactly 64 blocks.

=over

=item *

Sometimes it will gives us more than 64 blocks. In that case we will
concatenate the trailing blocks.

=item *

Sometimes it will gives us less than 64 blocks. No problem, 64 is the maximum
length, it can be less.

=item *

Sometimes it will gives us less than 32 blocks. In that case, we should try a
half-size blocksize to get more blocks.

=back

The I<traditional hash> is an usual hash or checksum function. We use 32 bit
FNV-1a hash (L<SEE ALSO>). But its output is 32 bits, so we need to map it to a
base-64 character alphabet. That is, we only use the 6 least significant bits
of FNV-1a hash.


=head2 Output

The ssdeep hash has this shape: C<BS:hash1:hash2>

=over

=item B<BS>

It is the blocksize. We can only compare hashes from the same blocksize.

=item B<hash1>

This is the concatenation of FNV-1a results (mapped to 64 characters) for each block in the file.

=item B<hash2>

This is the same that hash1 but using double the blocksize. We write this result
because a small change can halve or double the blocksize. If this happens,
we can compare at least one part of the two signatures.

=back

=head2 Comparison

There are several algorithms to compare two strings. I have used the same that
ssdeep uses for compatibility reasons. Only in certain cases, the result from
this module is not the same as ssdeep compiled version.  Please see
L<DIFFERENCES> below for details.

These are the steps for matching calculation:

=over

=item *

The first step is to compare the block sizes. We only can compare hashes calculated
for the same block size. In one ssdeep string we have both blocksize and double
blocksize hashes. So we try to match at least of the hashes. If they have no
common block sizes, the comparison returns 0.

=item *

Remove sequences of more than three equal characters. These same character
sequences have little information about the file and bias the matching score.

=item *

Test for a coincidence of, at least 7 characters. This is the default, but this
value can be changed. If the longest common substring is not a least this
length, the function returns 0. We expect a lot of collisions since we are
mapping 32 bit FNV values into 64 character output. This is a way to remove
false positives.

=item *

We use the Wagner-Fischer algorithm to compute the Levenshtein distance using
these weights:

=over

=item *

Same character: 0

=item *

Adition or deletion: 1

=item *

Sustitution: 2

=back

=item *

Following the original ssdeep algorithm we scale the value so the output be between 0
and 100.

=back




=head1 INTERFACE 

This section describes the recommended interface for generating and comparing
ssdeep fuzzy hashes.

=over

=item B<ssdeep_hash>

Calculates the ssdeep hash of the input string. 

Usage:

    $hash = ssdeep_hash( $string );

or in array context

    @hash = ssdeep_hash( $string );

In scalar context it returns a
hash with the format C<bs:hash1:hash2>. Being C<bs> the blocksize, C<hash1>
the fuzzy hash for this blocksize and C<hash2> the hash for double blocksize.
The maximum length of each hash is 64 characters.

In array context it returns the same components above but in a 3 elements array.

=item B<ssdeep_hash_file>

Calculates the hash of a file.

Usage:

    $hash = ssdeep_hash_file( "/tmp/malware1.exe" );

This is a convenient function. Returns the same of ssdeep_file in scalar or
array context.

Since this function slurps the whole file into memory, you should not use it in
big files. You should not use this module for big files, use libfuzzy wrapper
instead (L<BUGS AND LIMITATIONS>).

Returns B<undef> on errors.

=item B<ssdeep_compare>

Calculates the matching between two hashes.

Usage. To compare two scalar hashes:

    $match = ssdeep_compare( $hashA, $hashB );

To compare two hashes in array format:

    $match = ssdeep_compare( \@hashA, \@hashB );

The default is to discard hashes with less than 7 characters common substring.
To override this default and set this limit to any number you can use:

    $match = ssdeep_compare( $hashA, $hashB, 4 );

The result is a matching score between 0 and 100. See L<Comparison> for
algorithm details.


=item B<ssdeep_dump_last>

Returns an array with information of the last hash calculation. Useful for
debugging or extended details.

Usage after a calculation:

    $hash    = ssdeep_hash_file( "/tmp/malware1.exe" );
    @details = ssdeep_dump_last();

The output is an array of CSV values.

    ...
    2,125870,187|245|110|27|190|66|97,1393131242,q
    1,210575,13|216|13|115|29|52|208,4009217630,e
    2,210575,13|216|13|115|29|52|208,4009217630,e
    1,210730,61|231|220|179|40|89|210,1069791891,T
    1,237707,45|66|251|98|56|138|91,4014305026,C
    ....

Meaning of the output array:

=over

=item B<Field 1>

Part of the hash which is affected. 1 for the fist part, 2 for the second part.

=item B<Field 2>

Offset of the file where the chunk ends. 

=item B<Field 3>

Sequence of 7 characters that triggered the rolling hash.

=item B<Field 4>

Value of the rolling hash at this moment.

=item B<Field 5>

Character output to the fuzzy hash due to this rolling hash trigger.

=back

So we can read it this way:

At byte 125870 of the input file, there is a sequence of these 7 characters:
C<187 245 110 27 190 66 97>. That sequence triggered the second part of the
hash. The FNV hash value of the current chunk is 1393131242 that maps to
character C<q>.

Or this way:

From the 4th row I know the letter C<T> in the first hash comes from the
chunk that started at 210575+1 (the one-starting row before) and ends at
210730. The whole FNV hash of this block was 1069791891.

=back


=head1 BUGS AND LIMITATIONS

=over

=item B<Small blocksize comparison>

Original ssdeep limit the matching of small blocksize hashes. So when comparing
them the matching is limited by its size and is never 100%. This algorithm do
not behaviours that way. Small block sizes hashes are compared as big block
sizes ones.

=item B<Performance>

This is a Pure Perl implementation. The performance is far from optimal. To
calculate hashes more efficiently, please use compiled software like libfuzzy
bindings (L<SEE ALSO>).

=item B<Test 64 bits systems>

This module has not been tested in 64 bit systems yet.

=back


Please report any bugs or feature requests to
C<bug-digest-ssdeep@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 SEE ALSO

=over

=item Ssdeep's home page

L<http://ssdeep.sourceforge.net/>

=item Jesse Kornblum's original paper I<Identifying almost identical files using context triggered piecewise hashing>

L<http://dfrws.org/2006/proceedings/12-Kornblum.pdf>

=item I<Data::FuzzyHash> Perl binding of binary libfuzzy libraries

L<https://github.com/hideo55/Data-FuzzyHash>

=item Text::WagnerFischer - An implementation of the Wagner-Fischer edit distance.

L<http://search.cpan.org/perldoc?Text%3A%3AWagnerFischer>

=item FNV hash's description

L<http://www.isthe.com/chongo/tech/comp/fnv/>

=back

=head1 AUTHOR

Reinoso Guzman  C<< <reinoso.guzman@gmail.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2013, Reinoso Guzman C<< <reinoso.guzman@gmail.com> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
