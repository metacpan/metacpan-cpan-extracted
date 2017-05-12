=head1 NAME

Encode::RAD50 - Convert to and from the Rad50 character set.

=head1 SYNOPSIS

 use Encode;
 use Encode::RAD50; # Sorry about this.
 $rad50 = encode ('RAD50', 'FOO');
 $ascii = decode ('rad50', pack 'n', 10215);
 binmode STDOUT, ':encoding(rad50)'; # Perverse, but it works.
 print 'A#C'; # Gives a warning, since '#' isn't valid.

Because this is not a standard encoding, you will need to explicitly

 use Encode::RAD50;

Though of course the name of the module is case-sensitive, the name
of the encoding (passed to encode (), decode (), or ":encodingZ<>()")
is not case-sensitive.

=head1 DESCRIPTION

This package is designed to convert to and from the Rad50 character set.
It's really a piece of retrocomputing, since this character set was, to
the best of my knowledge, only used for the Digital (R.I.P.) PDP-11
computer, under (at least) the RSX-11 (including IAS and P/OS), RT-11,
RSTS (-11 and /E)  operating systems.

Rad50 is a way to squeeze three characters into two bytes, by
restricting the character set to upper-case 7-bit ASCII letters, digits,
space, "." and "$". There is also an encoding for what was called "the
illegal character." In the language of the Encode modules this is the
substitution character, and its ASCII representation is "?".

When more than three characters are encoded, the first three go in the
first two bytes, the second three in the second two, and so on.

If you try to encode some number of characters other than a multiple of
three, implicit spaces will be added to the right-hand end of the string.
These will become explicit when you decode.

The astute observer will note that the character set does not have 50
characters. To which I reply that it does, if you count the invalid
character and if your "50" is octal.

The test suite was verified using the RSX-11M+ "CVT" command. But the
CVT command interprets "A" as though it were "E<nbsp>E<nbsp>A" (i.e.
leading spaces), whereas this module interprets it as "AE<nbsp>E<nbsp>"
(i.e. trailing spaces).

Nothing is actually exported by this package. The "encode" and "decode"
in the synopsis come from the L<Encode> package.

It is not clear to me that the PerlIO support is completely correct.
But the test suite passes under cygwin, darwin, MSWin32, and VMS (to
identify them by the contents of $^O).

=head2 Methods

The following methods should be considered public:

=over 4

=cut

package Encode::RAD50;

use strict;
use warnings;

use base qw{Encode::Encoding};

our $VERSION = '0.012';

use Carp;
use Encode qw{:fallback_all};

use constant SUBSTITUTE => '?';
use constant RADIX => 40;
use constant MAX_WORD => RADIX * RADIX * RADIX;
# use constant CARP_MASK => WARN_ON_ERR | DIE_ON_ERR;

__PACKAGE__->Define( 'RAD50' );

my @r52asc = split '', ' ABCDEFGHIJKLMNOPQRSTUVWXYZ$.?0123456789';
my %irad50;
for (my $inx = 0; $inx < @r52asc; $inx++) {
    $irad50{$r52asc[$inx]} = $inx;
}

my $subs_value = $irad50{SUBSTITUTE ()};
delete $irad50{SUBSTITUTE ()};

my $chk_mod = ~0;	# Bits to mask in the check argument.

#	_carp ($check, ...)
#	is a utility subroutine which croaks if the DIE_ON_ERR bit
#	of $check is set, carps if WARN_ON_ERR is set (and it hasn't
#	already croaked!), and returns true if RETURN_ON_ERR is set.
#	It is not part of the public interface to this module, and the
#	author reserves the right to do anything at all to it without
#	telling anyone.

sub _carp {
    my ($check, @args) = @_;
    $check & DIE_ON_ERR and croak @args;
    $check & WARN_ON_ERR and carp @args;
    return $check & RETURN_ON_ERR;
}

=item $string = $object->decode ($octets, $check)

This is the decode method documented in L<Encode::Encoding>. Though you
B<can> call it directly, the anticipated mechanism is via the decode
subroutine exported by Encode.

=cut

# The Encode::Encoding documentation says that decode() SHOULD modify
# its $octets argument (the one after $self) if the $check argument is
# true. If perlio_ok() is true, SHOULD becomes MUST. Perl::Critic does
# not want us to do this, so we need to silence it.

sub decode {		## no critic (RequireArgUnpacking)
    my ($self, undef, $check) = @_;
    $check ||= 0;
    $check &= $chk_mod;
    my $out = '';
    while (length ($_[1])) {
	my ($bits) = unpack length $_[1] > 1 ? 'n1' : 'C1', $_[1];
	if ($bits < MAX_WORD) {
	    my $treble = '';
	    for (my $inx = 0; $inx < 3; $inx++) {
		my $char = $bits % RADIX;
		$bits = ($bits - $char) / RADIX;
		$char = $r52asc[$char];
		$char eq SUBSTITUTE and
		    _carp ($check, "'$char' is an invalid character.") and
		    return $out;
		$treble = $char . $treble;
	    }
	    $out .= $treble;
	} else {
	    _carp ($check, sprintf ("0x%04x is an invalid value", $bits))
		    and return $out;
	    $out .= SUBSTITUTE x 3;
	}
    } continue {
	substr ($_[1], 0, 2, '');
    }
    return $out;
}


=item $octets = $object->encode ($string, $check)

This is the encode method documented in L<Encode::Encoding>. Though you
B<can> call it directly, the anticipated mechanism is via the encode
subroutine exported by Encode.

=cut

# The Encode::Encoding documentation says that encode() SHOULD modify
# its $string argument (the one after $self) if the $check argument is
# true. If perlio_ok() is true, SHOULD becomes MUST. Perl::Critic does
# not want us to do this, so we need to silence it.

# Note that we copy $_[1] into $string and pad it to a multiple of 3
# and work from that, because otherwise we get odd behavior on input
# that is not a multiple of 3. But we strip characters from the original
# argument as well.

sub encode {		## no critic (RequireArgUnpacking)
    my ($self, $string, $check) = @_;
    $check ||= 0;
    $check &= $chk_mod;
    length ($string) % 3 and
	$string .= ' ' x (3 - length ($string) % 3);
    my @out;
    while (length ($_[1])) {
	my $bits = 0;
	foreach my $char (split '', substr ($string, 0, 3, '')) {
	    if (exists $irad50{$char}) {
		$bits = $bits * RADIX + $irad50{$char};
	    } else {
		_carp ($check, "'$char' is an invalid character") and
		    return pack 'n*', @out;
		$bits = $bits * RADIX + $subs_value;
	    }
	}
	push @out, $bits;
    } continue {
	substr ($_[1], 0, 3, '');
    }
    return pack 'n*', @out;
}

=item $old_val = Encode::RAD50->silence_warnings ($new_val)

This class method causes Encode::RAD50 to ignore the WARN_ON_ERR
flag. This is primarily for testing purposes, meaning that I couldn't
figure out any other way to suppress the warnings when testing the
handling of invalid characters in PerlIO.

If the argument is true, warnings are not generated even if the caller
specifies the WARN_ON_ERROR flag. If the argument is false, warnings
are generated if the caller specifies WARN_ON_ERROR. Either way, the
previous value is returned.

If no argument is passed, you get the current setting. The initial
setting is false.

=cut

sub silence_warnings {
    my $old = !($chk_mod & WARN_ON_ERR);
    @_ and $chk_mod = $_[0] ?
	$chk_mod & ~WARN_ON_ERR :
	$chk_mod | WARN_ON_ERR;
    return $old;
}

1;

__END__

=back

=head1 BUGS

Perlqq, HTML charref, and XML charref fallback modes are not supported,
because the RAD50 character set does not have the necessary characters.
In plainer language, you can't stick a backslash in the output stream
if the backslash is an invalid character. Requests for these fallback
modes will be ignored, and the replacement character inserted.

=head1 SEE ALSO

L<Encode>, L<Encode::Encoding>, and L<Encode::PerlIO>.

=head1 ACKNOWLEDGMENTS

Steve Lionel's posting of the VAX Fortran IRAD50 to comp.os.vms provided
the model for what encode should do if the length of the input string was
not a multiple of three.

Brian, for flushing out more operating systems that used RAD50.

Nora Narum, for helping with RSX CVT syntax.

=head1 AUTHOR

Thomas R. Wyant, III (F<wyant at cpan dot org>)

=head1 COPYRIGHT AND LICENSE

Copyright 2005-2007, 2011-2016 by Thomas R. Wyant, III
(F<wyant at cpan dot org>). All rights reserved.

PDP-11, RSTS-11, RSTS/E,  RSX-11, RSX-11M+, P/OS and RT-11 are
trademarks of Hewlett-Packard Development Company, L.P.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut
