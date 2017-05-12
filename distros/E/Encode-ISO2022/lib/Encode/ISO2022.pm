#-*- perl -*-
#-*- coding: us-ascii -*-

package Encode::ISO2022;

use 5.007003;
use strict;
use warnings;
use base qw(Encode::Encoding);
our $VERSION = '0.04';

use Carp qw(carp croak);
use XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);

my $err_encode_nomap = '"\x{%*v04X}" does not map to %s';
my $err_decode_nomap = '%s "\x%*v02X" does not map to Unicode';

my $DIE_ON_ERR = Encode::DIE_ON_ERR();
my $FB_QUIET = Encode::FB_QUIET();
my $HTMLCREF = Encode::HTMLCREF();
my $LEAVE_SRC = Encode::LEAVE_SRC();
my $PERLQQ = Encode::PERLQQ();
my $RETURN_ON_ERR = Encode::RETURN_ON_ERR();
my $WARN_ON_ERR = Encode::WARN_ON_ERR();
my $XMLCREF = Encode::XMLCREF();

# Constructor

sub Define {
    my $pkg = shift;
    my %opts = @_;

    my $Name = $opts{Name};
    croak 'No name defined' unless $Name;

    my @CCS = @{$opts{CCS} || []};
    croak 'No CCS defined' unless @CCS;
    my @ccs;
    foreach my $ccs (@CCS) {
	my $encoding;
	if (ref $ccs->{encoding}) {
	    $encoding = $ccs->{encoding};
	} elsif ($ccs->{encoding}) {
	    $encoding = Encode::find_encoding($ccs->{encoding});
	}
	croak sprintf 'Unknown encoding "%s"', ($ccs->{encoding} || '')
	    unless $encoding;
	push @ccs, { %$ccs, encoding => $encoding };
    }

    my $self = bless {
	CCS      => [@ccs],
	LineInit => $opts{LineInit},
	Name     => $Name,
	SubChar  => ($opts{SubChar} || '?')
    } => $pkg;

    Encode::define_alias($opts{Alias} => "\"$Name\"") if $opts{Alias};
    $Encode::Encoding{$Name} = $self;
}

# decode method

sub decode {
    my ($self, $str, $chk) = @_;

    my $chk_sub;
    my $utf8 = '';
    my $errChar;

    if (ref $chk eq 'CODE') {
	$chk_sub = $chk;
	$chk = $PERLQQ | $LEAVE_SRC;
    }

    $self->init_state(1);

    pos($str) = 0;
    my $chunk = '';
  CHUNKS:
    while (
	$str =~ m{
	    \G
	    (
		( # designation (FIXME)
		    \e\x24?[\x28-\x2B\x2D-\x2F][\x20-\x2F]*[\x40-\x7E] |
		    \e\x24[\x40-\x42] |
		) |
		( # locking shift
		    \x0E|\x0F|\e[\x6E\x6F\x7C\x7D\x7E]
		) |
	    )
	    (
		( # single shift 2
		    \x8E|\e\x4E
		) |
		( # single shift 3
		    \x8F|\e\x4F
		) |
	    )
	    (
		[^\x0E\x0F\e\x8E\x8F]*
	    )
	}gcx
    ) {
	my ($func, $g_seq, $ls, $ss, $ss2, $ss3, $chunk) =
	    ($1, $2, $3, $4, $5, $6, $7);

	# process designation and invokation.
	my $errSeq;
	if ($g_seq) {
	    unless (defined $self->designate_dec($g_seq)) {
		$errSeq = $g_seq;
	    }
	} elsif ($ls) {
	    unless (defined $self->invoke_dec($ls)) {
		$errSeq = $ls;
	    }
	}
	if ($errSeq) {
	    if ($chk & $DIE_ON_ERR) {
		croak sprintf $err_decode_nomap, $self->name, '\x', $errSeq;
	    }
	    if ($chk & $WARN_ON_ERR) {
		carp sprintf $err_decode_nomap, $self->name, '\x', $errSeq;
	    }
	    if ($chk & $RETURN_ON_ERR) {
		pos($str) -= length($errSeq) + length($chunk);
		last; # CHUNKS
	    }

	    if ($chk_sub) {
		$utf8 .= join '', map {
		    $chk_sub->(ord $_)
		} split(//, $errSeq . $chunk);
	    } elsif ($chk & $PERLQQ) {
		$utf8 .= sprintf '\x%*v02X', '\x', $errSeq . $chunk;
	    } else {
		$utf8 .= "\x{FFFD}" x length($chunk);
	    }

	    next; # CHUNKS
	}

	# process encoded elements
	while (length $chunk) {
	    my ($conv, $bytes);

	    ($conv, $bytes) = $self->_decode($chunk, $ss);
	    if (defined $conv) {
		$utf8 .= $conv;

		if ($conv =~ /[\r\n]/ and $self->{LineInit}) {
		    $self->init_state(1);
		}
		next;
	    }

	    $errChar = substr($chunk, 0, $bytes || 1);

	    if ($chk & $DIE_ON_ERR) {
		croak sprintf $err_decode_nomap, $self->name, '\x', $errChar;
	    }
	    if ($chk & $WARN_ON_ERR) {
		carp sprintf $err_decode_nomap, $self->name, '\x', $errChar;
	    }
	    if ($chk & $RETURN_ON_ERR) {
		last CHUNKS;
	    }

	    # Maybe erroneous designation: Force invoking CL and retry.
	    if ($errChar =~ /^[\x00-\x1F]/) {
		my @ccs = grep { $_->{cl} } @{$self->{CCS}};
		if (@ccs) {
		    $self->designate($ccs[0]);
		    next;
		}
	    }

	    substr($chunk, 0, length $errChar) = '';

	    if ($chk_sub) {
		$utf8 .= join '', map {
		    $chk_sub->(ord $_)
		} split(//, $errChar);
	    } elsif ($chk & $PERLQQ) {
		$utf8 .= sprintf '\x%*v02X', '\x', $errChar;
	    } else {
		$utf8 .= "\x{FFFD}";
	    }
	}
    } # CHUNKS
    pos($str) -= length($chunk);
    $_[1] = substr($str, pos $str) unless $chk & $LEAVE_SRC;

    return $utf8;
}

sub _decode {
    my ($self, $chunk, $ss) = @_;

    my @ccs;
    my $conv;
    my $errLen;

    if ($ss) {
	@ccs = grep {
	    $_->{_designated_to} and
	    $_->{ss} and $_->{ss} eq $ss
	} @{$self->{CCS}};
    } else {
	@ccs = grep {
	    $_->{_invoked_to} or
	    not ($_->{g} or $_->{g_init} or $_->{ls} or $_->{ss})
	} @{$self->{CCS}};
    }

    foreach my $ccs (@ccs) {
	my $bytes = $ccs->{bytes} || 1;
	my $range =
	    $ccs->{range} ? $ccs->{range} : $ccs->{gr} ? '\xA0-\xFF' : undef;
	my $residue = '';

	if ($range) {
	    if ($chunk =~ /^[^$range]/) {
		next;
	    } elsif ($chunk =~ s/([^$range].*)$//s) {
		$residue = $1;
	    }
	}

	if ($ss) {
	    if ($bytes <= length $chunk) {
		$residue = substr($chunk, $bytes) . $residue;
		$chunk = substr($chunk, 0, $bytes);
	    }
	}

	if ($ccs->{gr}) {
	    $chunk =~ tr/\x20-\x7F\xA0-\xFF/\xA0-\xFF\x20-\x7F/;
	    $conv = $ccs->{encoding}->decode($chunk, $FB_QUIET);
	    $chunk =~ tr/\x20-\x7F\xA0-\xFF/\xA0-\xFF\x20-\x7F/;
	} else {
	    $conv = $ccs->{encoding}->decode($chunk, $FB_QUIET);
	}

	if ($range and $chunk =~ /^([$range]{1,$bytes})/) {
	    my $len = length $1;
	    if (not defined $errLen or $len < $errLen) {
		$errLen = $len;
	    }
	}

	$chunk .= $residue;

	if ($conv =~ /./os) { # length() on utf8 string is slow
	    $_[1] = $chunk;
	    $_[2] = undef;
	    return $conv;
        }
    }
    $_[2] = undef;
    return (undef, $errLen);
}

sub designate_dec {
    my ($self, $g_seq) = @_;

    my $ccs = (grep {
	$_->{g_seq} and $_->{g_seq} eq $g_seq
    } @{$self->{CCS}})[0];
    return undef unless $ccs;

    return $self->designate($ccs);
}

sub invoke_dec {
    my ($self, $ls) = @_;

    my $ccs = (grep {
	$_->{_designated_to} and
	$_->{ls} and $_->{ls} eq $ls
    } @{$self->{CCS}})[0];
    return undef unless $ccs;

    return $self->invoke($ccs);
}

# encode method

sub encode {
    my ($self, $utf8, $chk) = @_;

    my $chk_sub;
    my $str = '';
    my $errChar;
    my $subChar;

    if (ref $chk eq 'CODE') {
	$chk_sub = $chk;
	$chk = $PERLQQ | $LEAVE_SRC;
    }

    $self->init_state(1);

    while ($utf8 =~ /./os) { # length() on utf8 string is slow.
	my $conv;

	$conv = $self->_encode($utf8);
	if (defined $conv) {
	    $str .= $conv;

	    if ($conv =~ /[\r\n]/ and $self->{LineInit}) {
		$self->init_state(1);
	    }
	    next;
	}

	$errChar = substr($utf8, 0, 1);
	if ($chk & $DIE_ON_ERR) {
	    croak sprintf $err_encode_nomap, '}\x{', $errChar, $self->name;
	}
	if ($chk & $WARN_ON_ERR) {
	    carp sprintf $err_encode_nomap, '}\x{', $errChar, $self->name;
	}
	if ($chk & $RETURN_ON_ERR) {
	    last;
	}

	substr($utf8, 0, 1) = '';

	if ($chk_sub) {
	    $subChar = $chk_sub->(ord $errChar);
	    $subChar = Encode::decode_utf8($subChar)
		unless Encode::is_utf8($subChar);
	} elsif ($chk & $PERLQQ) {
	    $subChar = sprintf '\x{%04X}', ord $errChar;
	} elsif ($chk & $XMLCREF) {
	    $subChar = sprintf '&#x%X;', ord $errChar;
	} elsif ($chk & $HTMLCREF) {
	    $subChar = sprintf '&#%d;', ord $errChar;
	} else {
	    $subChar = $self->{SubChar} || '?';
	}
	$conv = $self->_encode($subChar);
	if (defined $conv) {
	    $str .= $conv;
	}
    }
    $_[1] = $utf8 unless $chk & $LEAVE_SRC;

    if (length $str) {
	$str .= $self->init_state();
    }
    return $str;
}

sub _encode {
    my ($self, $utf8) = @_;

    foreach my $ccs (@{$self->{CCS}}) {
	next if $ccs->{dec_only};

	my $conv;

	# CCS with single-shift should encode runs as short as possible.
	# By now we support mapping from Unicode sequence up to 2 characters.
	if (defined $ccs->{ss}) { # empty value is allowed
	    my $bytes = $ccs->{bytes} || 1;
	    my $mc = substr($utf8, 0, 2);
	    $conv = $ccs->{encoding}->encode($mc, $FB_QUIET);
	    if ($bytes < length $conv) {
		$mc = substr($utf8, 0, 1);
		$conv = $ccs->{encoding}->encode($mc, $FB_QUIET);
		if (length $conv) {
		    substr($utf8, 0, 1) = '';
		}
	    } elsif (length $conv == $bytes) {
		substr($utf8, 0, 2) = '';
		$utf8 = $mc . $utf8;
	    } else {
		undef $conv;
	    }
	} else {
	    $conv = $ccs->{encoding}->encode($utf8, $FB_QUIET);
	}
	if (defined $conv and length $conv) {
	    $_[1] = $utf8;
	    return $self->designate($ccs) . $self->invoke($ccs, $conv);
	}
    }
    return undef;
}

sub init_state {
    my ($self, $reset) = @_;

    if ($reset) {
	foreach my $ccs (@{$self->{CCS}}) {
	    delete $ccs->{_designated_to};
	    delete $ccs->{_invoked_to};
	}
	delete $self->{_state};
    }

    my $ret = '';
    foreach my $ccs (grep { $_->{g_init} } @{$self->{CCS}}) {
	$ret .= $self->designate($ccs);
    }
    return $ret;
}

sub designate {
    my ($self, $ccs) = @_;

    my $g = $ccs->{g} || $ccs->{g_init};
    croak sprintf 'Cannot designate %s', $ccs->{encoding}->name
	unless $g;
    my $g_seq = $ccs->{g_seq};

    my @ccs;
    if ($g_seq) { # explicit designation
	@ccs = grep {
	    $_->{g_seq} and $_->{g_seq} eq $g_seq
	} @{$self->{CCS}};
    } else { # static designation
	@ccs = grep {
	    not $_->{g_seq} and
	    ($_->{g} and $_->{g} eq $g or $_->{g_init} and $_->{g_init} eq $g)
	} @{$self->{CCS}};
    }
    # Already designated: do nothing
    return ''
	unless grep {
	    not ($_->{_designated_to} and $_->{_designated_to} eq $g)
	} @ccs;

    # modify designation
    foreach my $ccs (@{$self->{_state}->{$g} || []}) {
	delete $ccs->{_designated_to};
	delete $ccs->{_invoked_to};
    }
    my %invoked = (gr => [], gl => []);
    foreach my $ccs (@ccs) {
	$ccs->{_designated_to} = $g;
	unless ($ccs->{ls} or $ccs->{ss}) {
	    my $i = $ccs->{gr} ? 'gr' : 'gl';

	    $ccs->{_invoked_to} = $i;
	    push @{$invoked{$i}}, $ccs;
	}
    }

    # modify invokation
    foreach my $i (qw/gr gl/) {
	next unless @{$invoked{$i} || []};

	foreach my $ccs (@{$self->{_state}->{$i} || []}) {
	    delete $ccs->{_invoked_to};
	}
	$self->{_state}->{$i} = $invoked{$i};
    }

    $self->{_state}->{$g} = [@ccs];
    return $g_seq || '';
}

sub invoke {
    my ($self, $ccs, $str) = @_;
    $str = '' unless defined $str;

    my $i = $ccs->{gr} ? 'gr' : 'gl';

    if ($i eq 'gr') {
	$str =~ tr/\x20-\x7F/\xA0-\xFF/;
    }

    if ($ccs->{ss}) {
	my $out = '';
	while (length $str) {
	    $out .= $ccs->{ss} . substr($str, 0, ($ccs->{bytes} || 1), '');
	}
	return $out;	
    } elsif ($ccs->{ls}) {
	my $ls = $ccs->{ls};
	my $g_seq = $ccs->{g_seq};
	my $g = $ccs->{g} || $ccs->{g_init};

	my @ccs;
	if ($g_seq) {
	    @ccs = grep {
		$_->{g_seq} and $_->{g_seq} eq $g_seq and
		$_->{ls} and $_->{ls} eq $ls and
		($_->{gr} ? 'gr' : 'gl') eq $i
	    } @{$self->{CCS}};
	} else {
	    @ccs = grep {
		not $_->{g_seq} and ($_->{g} || $_->{g_init}) eq $g and
		$_->{ls} and $_->{ls} eq $ls and
		($_->{gr} ? 'gr' : 'gl') eq $i
	    } @{$self->{CCS}};
	}
	# Already invoked: add nothing
	return $str
	    unless grep {
		not ($_->{_invoked_to} and $_->{_invoked_to} eq $i)
	    } @ccs;

	foreach my $ccs (@{$self->{_state}->{$i} || []}) {
	    delete $ccs->{_invoked_to};
	}
	foreach my $ccs (@ccs) {
	    $ccs->{_invoked_to} = $i;
	}

	$self->{_state}->{$i} = [@ccs];
	return $ccs->{ls} . $str;
    } else {
	return $str;
    }
}

# renew method

sub renew {
    my $self = shift;

    my $clone = bless { map { _renew($_) } %$self } => ref($self);
    $clone->{renewed}++;
    return $clone;
}

sub _renew {
    my $item = shift;

    if (ref $item eq 'HASH') {
	return { map { _renew($_) } %$item };
    } elsif (ref $item eq 'ARRAY') {
	return [ map { _renew($_) } @$item ];
    } elsif (ref $item and $item->can("renew")) {
	return $item->renew;
    } else {
	return $item;
    }
}

# Miscelaneous

sub mime_name {
    my $self = shift;
    return undef if $self->{Name} =~ /^x/i;
    return uc($self->{Name});
}

1;
__END__

=head1 NAME

Encode::ISO2022 - ISO/IEC 2022 character encoding scheme

=head1 SYNOPSIS

  package FooEncoding;
  use base qw(Encode::ISO2022);
  
  __PACKAGE__->Define(
    Name => 'foo-encoding',
    CCS => [ {...CCS one...}, {...CCS two...}, ....]
  );

=head1 DESCRIPTION

This module provides a character encoding scheme (CES) switching a set of
multiple coded character sets (CCS).

A class method Define() may take following arguments.

=over 4

=item Alias => REGEX

The regular expression representing alias of this encoding, if any.

=item Name => STRING

The name of this encoding as L<Encode::Encoding> object.
Mandatory.

=item CCS => [ FEATURE, FEATURE, ...]

List of features defining CCSs used by this encoding.
Mandatory.
Each item is a hash reference containing following items.

=over 4

=item bytes => NUMBER

Number of bytes to represent each character.
Default is 1.

=item cl => BOOLEAN

If true value is set, this CCS includes map to/from code points between
0/0 and 1/15.
There should be one CCS with this flag to reset broken designation.

=item dec_only => BOOLEAN

If true value is set, this CCS will be used only for decoding.

=item encoding => STRING | ENCODING

L<Encode::Encoding> object used as CCS, or its name.
Mandatory.

Encodings used for CCS must provide "raw" conversion.
Namely, they must be stateless and fixed-length conversion over 94^n or 96^n
code tables.
L<Encode::ISO2022::CCS> lists available CCSs.

=item g => STRING

=item g_init => STRING

Working set this CCS may be designated to:
C<'g0'>, C<'g1'>, C<'g2'> or C<'g3'>.

If C<g_init> is set, this CCS will be designated at beginning of coversion
implicitly, and at end of conversion explicitly.

If C<g> or C<g_init> is set and neither of C<ls> nor C<ss> is set,
this CCS will be invoked when it is designated.

If neither of C<g>, C<g_init>, C<ls> nor C<ss> is set,
this CCS is invoked always.

=item g_seq => STRING

Escape sequence to designate this CCS, if it can be designated explicitly.

=item gr => BOOLEAN

If true value is set, this CCS will be invoked to GR using 7-bit conversion
table.

=item ls => STRING

=item ss => STRING

Escape sequence or control character to invoke this CCS,
if it should be invoked explicitly.

If C<ls> is set, this CCS will be invoked by locking-shift.
If C<ss> is set, this CCS will be invoked by single-shift.

=item range => STRING

Possible range of encoded bytes.  General value is
C<'\x21-\x7E'>, C<'\x20-\x7F'>, C<'\xA1-\xFE'> or C<'\xA0-\xFF'>.
This is required for multibyte CCSs to detect broken multibyte sequences.

=back

=item LineInit => BOOLEAN

If it is true, designation and invokation states will be initialized at
beginning of lines.

=item SubChar => STRING

Unicode string to be used for substitution character.

=back

To know more about use of this module,
the source of L<Encode::ISO2022JP2> may be an example.

=head1 CAVEATS

This module implements small subset of the features defined by
ISO/IEC 2022.
Each encoding recognizes only several predefined designation and invokation
functions.
It can handle limited number of coded character sets.
Variable length multibyte coded character sets aren't supported.
And so on.

=head1 SEE ALSO

ISO/IEC 2022
I<Information technology - Character code structure and extension techniques>.

L<Encode>, L<Encode::ISO2022::CCS>.

=head1 AUTHOR

Hatuka*nezumi - IKEDA Soji, E<lt>nezumi@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Hatuka*nezumi - IKEDA Soji

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
