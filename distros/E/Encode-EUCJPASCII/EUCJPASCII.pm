package Encode::EUCJPASCII;
use strict;
use warnings;
our $VERSION = "0.03";
 
use Encode qw(:fallbacks);
use XSLoader;
XSLoader::load(__PACKAGE__,$VERSION);

Encode::define_alias(qr/\beuc-?jp(-?open)?(-?19970715)?-?ascii$/i
		     => '"eucJP-ascii"');
Encode::define_alias(qr/\b(x-)?iso-?2022-?jp-?ascii$/i
		     => '"x-iso2022jp-ascii"');

my $name = 'x-iso2022jp-ascii';
$Encode::Encoding{$name} = bless { Name => $name } => __PACKAGE__;

use base qw(Encode::Encoding);

# we override this to 1 so PerlIO works
sub needs_lines { 1 }

use Encode::CJKConstants qw(:all);
use Encode::JP::JIS7;

# 26 row-cell pairs swapped between JIS C 6226-1978 and JIS X 0208-1983.
# cf. JIS X 0208:1997 Annex 2 Table 1.
my @swap1978 = ("\x30\x33" => "\x72\x4D", "\x32\x29" => "\x72\x74",
		"\x33\x42" => "\x69\x5a", "\x33\x49" => "\x59\x78",
		"\x33\x76" => "\x63\x5e", "\x34\x43" => "\x5e\x75",
		"\x34\x52" => "\x6b\x5d", "\x37\x5b" => "\x70\x74",
		"\x39\x5c" => "\x62\x68", "\x3c\x49" => "\x69\x22",
		"\x3F\x59" => "\x70\x57", "\x41\x28" => "\x6c\x4d",
		"\x44\x5B" => "\x54\x64", "\x45\x57" => "\x62\x6a",
		"\x45\x6e" => "\x5b\x6d", "\x45\x73" => "\x5e\x39",
		"\x46\x76" => "\x6d\x6e", "\x47\x68" => "\x6a\x24",
		"\x49\x30" => "\x5B\x58", "\x4b\x79" => "\x50\x56",
		"\x4c\x79" => "\x69\x2e", "\x4F\x36" => "\x64\x46",
		"\x36\x46" => "\x74\x21", "\x4B\x6A" => "\x74\x22",
		"\x4D\x5A" => "\x74\x23", "\x60\x76" => "\x74\x24",
		);
my %swap1978 = (@swap1978, reverse @swap1978);

sub decode($$;$) {
    my ( $obj, $str, $chk ) = @_;
    my $residue = '';
    if ($chk) {
        $str =~ s/([^\x00-\x7f].*)$//so and $residue = $1;
    }
    # Handle JIS X 0201 sequences.
    $str =~ s{\e\(J ([^\e]*) (?:\e\(B)?}{
	my $s = $1;
	$s =~ s{([\x5C\x7E]+)}{
	    my $c = $1;
	    $c =~ s/\x5C/\x21\x6F/g;
	    $c =~ s/\x7E/\x21\x31/g;
	    "\e\$B".$c."\e(B";
	}eg;
	($s =~ /^\e/? "\e(B": '').$s;
    }egsx;
    # Handle JIS C 6226-1978 sequences.
    $str =~ s{\e\$\@ ([^\e]*) (?:\e\$B)?}{
	my $s = $1;
	$s =~ s{([\x21-\x7E]{2})}{$swap1978{$1} || $1}eg;
	"\e\$B".$s;
    }egsx;
    $residue .= Encode::JP::JIS7::jis_euc( \$str );
    $_[1] = $residue if $chk;
    return Encode::decode( 'eucJP-ascii', $str, $chk );
}

sub encode($$;$) {
    my ( $obj, $utf8, $chk ) = @_;

    # empty the input string in the stack so perlio is ok
    $_[1] = '' if $chk;
    my $octet = Encode::encode( 'eucJP-ascii', $utf8, $chk );
    Encode::JP::JIS7::euc_jis( \$octet, 1 );
    return $octet;
}

#
# cat_decode
#
my $re_scan_jis_g = qr{
    \G ( ($RE{JIS_0212}) | (\e\$\@) |  $RE{JIS_0208}  |
	 (\e\(J) | ($RE{ISO_ASC})  | ($RE{JIS_KANA}) | )
      ([^\e]*)
  }x;

sub cat_decode {    # ($obj, $dst, $src, $pos, $trm, $chk)
    my ( $obj, undef, undef, $pos, $trm ) = @_;    # currently ignores $chk
    my ( $rdst, $rsrc, $rpos ) = \@_[ 1, 2, 3 ];
    local ${^ENCODING};
    use bytes;
    my $opos = pos($$rsrc);
    pos($$rsrc) = $pos;
    while ( $$rsrc =~ /$re_scan_jis_g/gc ) {
        my ( $esc, $esc_0212, $esc_0208_1978, $esc_0201, $esc_asc, $esc_kana, $chunk ) =
	    ( $1, $2, $3, $4, $5, $6, $7 );

        unless ($chunk) { $esc or last; next; }
	
        if ( $esc && !$esc_asc && !$esc_0208_1978 && !$esc_0201 ) {
            $chunk =~ tr/\x21-\x7e/\xa1-\xfe/;
            if ($esc_kana) {
                $chunk =~ s/([\xa1-\xdf])/\x8e$1/og;
            }
            elsif ($esc_0212) {
                $chunk =~ s/([\xa1-\xfe][\xa1-\xfe])/\x8f$1/og;
            }
            $chunk = Encode::decode( 'eucJP-ascii', $chunk, 0 );
        }
	elsif ( $esc_0208_1978 ) {
	    $chunk =~ s{([\x21-\x7E]{2})}{$swap1978{$1} || $1}eg;
            $chunk =~ tr/\x21-\x7e/\xa1-\xfe/;
            $chunk = Encode::decode( 'eucJP-ascii', $chunk, 0 );
	}
	elsif ( $esc_0201 ) {
	    $chunk =~ s/\x5C/\xA1\xEF/og;
	    $chunk =~ s/\x7E/\xA1\xB1/og;
            $chunk = Encode::decode( 'eucJP-ascii', $chunk, 0 );
	}
        elsif ( ( my $npos = index( $chunk, $trm ) ) >= 0 ) {
            $$rdst .= substr( $chunk, 0, $npos + length($trm) );
            $$rpos += length($esc) + $npos + length($trm);
            pos($$rsrc) = $opos;
            return 1;
        }
        $$rdst .= $chunk;
        $$rpos = pos($$rsrc);
    }
    $$rpos = pos($$rsrc);
    pos($$rsrc) = $opos;
    return '';
}

1;
__END__

=head1 NAME
 
Encode::EUCJPASCII - eucJP-ascii - An eucJP-open mapping
 
=head1 SYNOPSIS

    use Encode::EUCJPASCII;
    use Encode qw/encode decode/;
    $eucjp = encode("eucJP-ascii", $utf8);
    $utf8 = decode("eucJP-ascii", $eucjp);

=head1 DESCRIPTION

This module provides eucJP-ascii, one of eucJP-open mappings,
and its derivative.
Following encodings are supported.

  Canonical    Alias                           Description
  --------------------------------------------------------------
  eucJP-ascii                                  eucJP-ascii
               qr/\beuc-?jp(-?open)?(-?19970715)?-?ascii$/i
  x-iso2022jp-ascii                            7-bit counterpart
               qr/\b(x-)?iso-?2022-?jp-?ascii$/i
  --------------------------------------------------------------

B<Note>: C<x-iso2022jp-ascii> is unofficial encoding name:
It had never been registered by any standards bodies.

=head1 SEE ALSO

L<Encode>, L<Encode::JP>, L<Encode::EUCJPMS>

TOG/JVC CDE/Motif Technical WG (Oct. 1996).
I<Problems and Solutions for Unicode and User/Vendor Defined Characters>.
Revision at Jul. 15 1997.

=head1 AUTHOR

Hatuka*nezumi - IKEDA Soji <hatuka(at)nezumi.nu>

=head1 COPYRIGHT

Copyright (C) 2009 Hatuka*nezumi - IKEDA Soji.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
