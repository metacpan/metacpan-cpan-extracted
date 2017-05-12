#
# $Id: EUCJPMS.pm 7 2006-08-25 22:45:46Z naruse $
#
package Encode::EUCJPMS;
use strict;
our $VERSION = "0.07";
 
use Encode qw(:fallbacks);
use XSLoader;
XSLoader::load(__PACKAGE__,$VERSION);

Encode::define_alias(qr/\beuc-?jp-?ms$/i  => '"eucJP-ms"');
Encode::define_alias(qr/\beuc-?jp-?win$/i => '"eucJP-ms"');
Encode::define_alias(qr/\bglibc-EUC_JP_MS-2.3.3$/i => '"eucJP-ms"');

for my $name ('cp50220','cp50221'){ #, 'cp50222'
    my $h2z     = ($name eq 'cp50220')    ? 1 : 0;
    my $jis0212 = 0;

    $Encode::Encoding{$name} =
        bless {
               Name      =>   $name,
               h2z       =>   $h2z,
               jis0212   =>   $jis0212,
              } => __PACKAGE__;
}

use base qw(Encode::Encoding);

# we override this to 1 so PerlIO works
sub needs_lines { 1 }

use Encode::CJKConstants qw(:all);

#
# decode is identical for all 2022 variants
#

sub decode($$;$)
{
    my ($obj, $str, $chk) = @_;
    my $residue = '';
    if ($chk){
	$str =~ s/([^\x00-\x7f].*)$//so and $residue = $1;
    }
    $residue .= jis_euc(\$str);
    $_[1] = $residue if $chk;
    return Encode::decode('cp51932', $str, FB_PERLQQ);
}

#
# encode is different
#

sub encode($$;$)
{
    require Encode::JP::H2Z;
    my ($obj, $utf8, $chk) = @_;
    # empty the input string in the stack so perlio is ok
    $_[1] = '' if $chk;
    my ($h2z, $jis0212) = @$obj{qw(h2z jis0212)};
    my $octet = Encode::encode('cp51932', $utf8, FB_PERLQQ) ;
    $h2z and &Encode::JP::H2Z::h2z(\$octet);
    euc_jis(\$octet, $jis0212);
    return $octet;
}

#
# cat_decode
#
my $re_scan_jis_g = qr{
   \G ( ($RE{JIS_0212}) |  $RE{JIS_0208}  |
        ($RE{ISO_ASC})  | ($RE{JIS_KANA}) | )
      ([^\e]*)
}x;
sub cat_decode { # ($obj, $dst, $src, $pos, $trm, $chk)
    my ($obj, undef, undef, $pos, $trm) = @_; # currently ignores $chk
    my ($rdst, $rsrc, $rpos) = \@_[1,2,3];
    local ${^ENCODING};
    use bytes;
    my $opos = pos($$rsrc);
    pos($$rsrc) = $pos;
    while ($$rsrc =~ /$re_scan_jis_g/gc) {
	my ($esc, $esc_0212, $esc_asc, $esc_kana, $chunk) =
	  ($1, $2, $3, $4, $5);

	unless ($chunk) { $esc or last;  next; }

	if ($esc && !$esc_asc) {
	    $chunk =~ tr/\x21-\x7e/\xa1-\xfe/;
	    if ($esc_kana) {
		$chunk =~ s/([\xa1-\xdf])/\x8e$1/og;
	    } elsif ($esc_0212) {
		$chunk =~ s/([\xa1-\xfe][\xa1-\xfe])/\x8f$1/og;
	    }
	    $chunk = Encode::decode('cp51932', $chunk, 0);
	}
	elsif ((my $npos = index($chunk, $trm)) >= 0) {
	    $$rdst .= substr($chunk, 0, $npos + length($trm));
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

# JIS<->EUC
my $re_scan_jis = qr{
   (?:($RE{JIS_0212})|$RE{JIS_0208}|($RE{ISO_ASC})|($RE{JIS_KANA}))([^\e]*)
}x;

sub jis_euc {
    local ${^ENCODING};
    my $r_str = shift;
    $$r_str =~ s($re_scan_jis)
    {
	my ($esc_0212, $esc_asc, $esc_kana, $chunk) =
	   ($1, $2, $3, $4);
	if (!$esc_asc) {
	    $chunk =~ tr/\x21-\x7e/\xa1-\xfe/;
	    if ($esc_kana) {
		$chunk =~ s/([\xa1-\xdf])/\x8e$1/og;
	    }
	    elsif ($esc_0212) {
		$chunk =~ s/([\xa1-\xfe][\xa1-\xfe])/\x8f$1/og;
	    }
	}
	$chunk;
    }geox;
    my ($residue) = ($$r_str =~ s/(\e.*)$//so);
    return $residue;
}

sub euc_jis{
    no warnings qw(uninitialized);
    my $r_str = shift;
    my $jis0212 = shift;
    $$r_str =~ s{
	((?:$RE{EUC_C})+|(?:$RE{EUC_KANA})+|(?:$RE{EUC_0212})+)
	}{
	    my $chunk = $1;
	    my $esc =
		( $chunk =~ tr/\x8E//d ) ? $ESC{KANA} :
		    ( $chunk =~ tr/\x8F//d ) ? $ESC{JIS_0212} :
			$ESC{JIS_0208};
	    if ($esc eq $ESC{JIS_0212} && !$jis0212){
		# fallback to '?'
		$chunk =~ tr/\xA1-\xFE/\x3F/;
	    }else{
		$chunk =~ tr/\xA1-\xFE/\x21-\x7E/;
	    }
	    $esc . $chunk . $ESC{ASC};
	}geox;
    $$r_str =~
	s/\Q$ESC{ASC}\E
	    (\Q$ESC{KANA}\E|\Q$ESC{JIS_0212}\E|\Q$ESC{JIS_0208}\E)/$1/gox;
    $$r_str;
}

1;
__END__

=head1 NAME

Encode::EUCJPMS - Microsoft Compatible Encodings for Japanese

=head1 SYNOPSIS

  use Encode::EUCJPMS;
  use Encode qw/encode decode/;
  $eucJP_ms = encode("eucJP-ms", $utf8);
  $utf8   = decode("eucJP-ms", $euc_jp);

=head1 ABSTRACT

This module implements Microsoft compatible encodings for Japanese.
Encodings supported are as follows.

  Canonical     Alias                                      Description
  --------------------------------------------------------------------
  eucJP-ms      qr/\beuc-?jp-?ms$/i                           eucJP-ms
                qr/\beuc-?jp-?win$/i
  cp51932                                       Windows Codepage 51932
  cp50220                                       Windows Codepage 50220
  cp50221                                       Windows Codepage 50221
  --------------------------------------------------------------------

=head1 DESCRIPTION

To find out how to use this module in detail, see L<Encode>.

=head1 INSTALLATION

To install this module type the following:

   perl Makefile.PL
   make
   make test
   make install

If you want to add eucJP-ms to Encode's demand-loading list
(so you don't have to "use Encode::EUCJPMS"), run

  enc2xs -C

to update Encode::ConfigLocal, a module that controls local settings.
After that, "use Encode;" is enough to load eucJP-ms on demand.

=head1 DEPENDENCIES

This module requires perl version 5.7.3 or later.

=head1 AUTHOR

NARUSE, Yui E<lt>naruse@airemix.comE<gt>

=head1 COPYRIGHT

Copyright (C) 2005-2006 NARUSE, Yui E<lt>naruse@airemix.comE<gt>

This program is free software; you can redistribute it and/or 
modify it under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=head1 SEE ALSO

L<Encode>, L<Encode::JP>

Problems and Solutions for Unicode and User/Vendor Defined Characters
L<http://www.opengroup.or.jp/jvc/cde/ucs-conv-e.html>

Windows Codepage 932
L<http://www.microsoft.com/globaldev/reference/dbcs/932.mspx>

=cut
