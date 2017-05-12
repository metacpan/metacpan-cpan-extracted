package Encode::Base32::Crockford;
{
  $Encode::Base32::Crockford::VERSION = '2.112991';
}

use warnings;
use strict;

use base qw(Exporter);
our @EXPORT_OK = qw(
	base32_encode base32_encode_with_checksum
	base32_decode base32_decode_with_checksum
	normalize
);
our %EXPORT_TAGS = ( 'all' => \@EXPORT_OK );

use Carp qw(croak);
use Scalar::Util qw(looks_like_number);

my %SYMBOLS;

# Note: regular digits do not include I, L, O or U. See spec in documentation.
@SYMBOLS{0..9,'A'..'H','J','K','M','N','P'..'T','V'..'Z'} = 0..31;

# checksum symbols only from here
@SYMBOLS{'*','~','$','=','U'} = 32..36;

my %SYMBOLS_INVERSE = reverse %SYMBOLS;

sub base32_encode {
        my $number = shift;

        die qq("$number" isn't a number) unless looks_like_number($number);

        return '0' unless $number;

        my @digits;

        # Cut a long story short: keep dividing by 32. Use the remainders to make the
        # digits of the converted number, right to left; the quotient goes to the next
        # iteration to be divided again. When the quotient hits zero, i.e. there's not
        # enough for 32 to be a divisor, the value being divided is the final digit.
        while ($number) {
                my $remainder = $number % 32;
                $number = int($number / 32);
                push @digits, $SYMBOLS_INVERSE{$remainder};
        }

        return join('', reverse @digits) || '0';
}

sub base32_encode_with_checksum {
	my $number = shift;

	my $modulo = $number % 37;
	
	return base32_encode($number) . $SYMBOLS_INVERSE{$modulo};
}

sub normalize {
	my ($string, $options) = @_;

	my $orig_string = $string;

	$string = uc($string);
	_normalize_actions($orig_string, $string, $options->{"mode"}) if $string ne $orig_string;

	# fix possible transcription errors and remove chunking symbols
	_normalize_actions($orig_string, $string, $options->{"mode"}) if $string =~ tr/IiLlOo-/111100/d;

	$string;
}

# Actions to carry out if normalize() is operating in a particular mode.
sub _normalize_actions {
	my ($old_string, $new_string, $mode) = @_;

	$mode ||= '';

	warn qq(String "$old_string" corrected to "$new_string") if $mode eq "warn";
	die  qq(String "$old_string" requires normalization) if $mode eq "strict";
}

sub base32_decode {
	my ($string, $options) = @_;

	croak "string is undefined" if not defined $string;
	croak "string is empty" if $string eq '';

	$string = normalize($string, $options);

	my $valid;

	if ($options->{"is_checksum"}) {
		die qq(Checksum "$string" is too long; should be one character)
			if length($string) > 1;

		$valid = qr/^[A-Z0-9\*\~\$=U]$/;

	} else {
		# 'U' is only valid as a checksum symbol.
		$valid = qr/^[A-TV-Z0-9]+$/;
	}

	croak qq(String "$string" contains invalid characters) if $string !~ /$valid/;
	
	
	my $total = 0;

	# For each base32 digit B of position P counted (using zero-based counting)
	# from right in a number, its decimal value D is calculated with the
	# following expression:
	# 	D = B * 32^P.
	# As any number raised to the power of 0 is 1, we can define an "offset" value
	# of 1 for the first digit calculated and simply multiply the offset by 32
	# after deriving the value for each digit.

	foreach my $symbol (split(//, $string)) {
		$total = $total * 32 + $SYMBOLS{$symbol};
	}
	
	$total;
}

sub base32_decode_with_checksum {
	my ($string, $options) = @_;
	my $check_string = $string;

	my $checksum = substr($check_string, (length($check_string) - 1), 1, "");

	my $value = base32_decode($check_string, $options);
	my $checksum_value = base32_decode($checksum, { "is_checksum" => 1 });
	my $modulo = $value % 37;

	croak qq(Checksum symbol "$checksum" is not correct for value "$check_string".)
		if $checksum_value != $modulo;
	
	$value;
}

1;

__END__

=head1 NAME

Encode::Base32::Crockford - encode/decode numbers using Douglas Crockford's Base32 Encoding

=head1 VERSION

version 2.112991

=head1 DESCRIPTION

Douglas Crockford describes a I<Base32 Encoding> at 
L<http://www.crockford.com/wrmg/base32.html>. He says: "[Base32 Encoding is] a
32-symbol notation for expressing numbers in a form that can be conveniently and 
accurately transmitted between humans and computer systems."

This module provides methods to convert numbers to and from that notation.

=head1 SYNOPSIS

    use Encode::Base32::Crockford qw(:all); # import all methods

or

    use Encode::Base32::Crockford qw(base32_decode); # your choice of methods
    
    my $decoded = base32_decode_with_checksum("16JD");
    my $encoded = base32_encode_with_checksum(1234);

=head1 METHODS

=head2 base32_encode

    print base32_encode(1234); # prints "16J"

Encode a base 10 number. Will die on inappropriate input.

=head2 base32_encode_with_checksum

    print base32_encode_with_checksum(1234); # prints "16JD"

Encode a base 10 number with a checksum symbol appended. See the spec for a
description of the checksum mechanism. Wraps the previous method so will also
die on bad input.

=head2 base32_decode

    print base32_decode("16J"); # prints "1234"

    print base32_decode("IO", { mode => "warn"   }); # print "32" but warn
    print base32_decode("IO", { mode => "strict" }); # dies

Decode an encoded number into base 10. Will die on inappropriate input. The
function is case-insensitive, and will strip any hyphens in the input (see
C<normalize()>). A hashref of options may be passed, with the only valid option
being C<mode>. If set to "warn", normalization will produce a warning; if set
to "strict", requiring normalization will cause a fatal error.

=head2 base32_decode_with_checksum

    print base32_decode_with_checksum("16JD"); # prints "1234"

Decode an encoded number with a checksum into base 10. Will die if the checksum
isn't correct, and die on inappropriate input. Takes the same C<mode> option as
C<base32_decode>.

=head2 normalize

    my $string = "ix-Lb-Ko";
    my $clean = normalize($string);

    # $string is now '1X1BK0'.

The spec allows for certain symbols in encoded strings to be read as others, to
avoid problems with misread strings. This function will perform the following
conversions in the input string:

=over 4

=item * "i" or "I" to 1

=item * "l" or "L" to 1

=item * "o" or "O" to 0

=back

It will also remove any instances of "-" in the input, which are permitted by the
spec as chunking symbols to aid human reading of an encoded string, and uppercase
the output.

=head1 AUTHOR

Graham Barr <gbarr@cpan.org>

=head1 CREDITS

The original module was written by Earle Martin <hex@cpan.org>

=head1 COPYRIGHT

This code is free software; you can redistribute it and/or modify it under 
the same terms as Perl itself.

=head1 REPOSITORY

The git repository for this distribution is available at
L<https://github.com/gbarr/Encode-Base32-Crockford>

=cut
