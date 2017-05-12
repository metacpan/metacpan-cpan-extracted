# Copyright (C) 2011-2013 MURATA Yasuhisa
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

package MIME::EcoEncode;

use 5.008005;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw($VERSION);
our @EXPORT = qw(mime_eco mime_deco);
our $VERSION = '0.95';

use MIME::Base64;
use MIME::QuotedPrint;

use constant TAIL => '?=';

our $LF;   # line feed
our $BPL;  # bytes per line
our $MODE; # unstructured : 0, structured : 1, auto : 2

our $HEAD; # head string
our $HTL;  # head + tail length
our $UTF8;
our $REG_W;
our $ADD_EW;
our $REG_RP;

sub mime_eco {
    my $str = shift;

    return '' unless defined $str;
    return '' if $str eq '';

    my ($trailing_crlf) = ($str =~ /(\x0d?\x0a|\x0d)$/);
    $str =~ tr/\n\r//d;
    if ($str =~ /^\s*$/) {
       return $trailing_crlf ? $str . $trailing_crlf : $str;
    }

    my $charset = shift || 'UTF-8';

    # invalid option
    return undef
	unless $charset =~ /^([-0-9A-Za-z_]+)(?:\*[^\?]*)?(\?[QB])?$/i;

    my $cs = lc($1);
    $charset .= '?B' unless defined $2;

    our $LF  = shift || "\n"; # line feed
    our $BPL = shift || 76;   # bytes per line
    our $MODE = shift;
    $MODE = 2 unless defined $MODE;

    my $lss = shift;
    $lss = 25 unless defined $lss;

    our $HEAD; # head string
    our $HTL;  # head + tail length
    our $UTF8 = 1;
    our $REG_W = qr/(.)/;
    our $ADD_EW;
    our $REG_RP;

    my $jp = 0;

    my $pos;
    my $np;
    my $refsub;
    my $reg_rp1;

    my ($w1, $w1_len, $w2);
    my ($sps, $sps_len);
    my $sp1 = '';
    my $sp1_bak;
    my $result;
    my $ascii;
    my $tmp;
    my $count = 0;

    my $q_enc = ($charset =~ /Q$/i) ? 1 : 0;
    $HEAD = '=?' . $charset . '?';
    $HTL = length($HEAD) + 2;

    if ($cs ne 'utf-8') {
	$UTF8 = 0;
	if ($cs eq 'iso-2022-jp') {
	    $jp = 1;
	}
	elsif ($cs eq 'shift_jis') {
	    # range of 2nd byte : [\x40-\x7e\x80-\xfc]
	    $REG_W = qr/([\x81-\x9f\xe0-\xfc]?.)/;
	}
	elsif ($cs eq 'gb2312') { # Simplified Chinese
	    # range of 2nd byte : [\xa1-\xfe]
	    $REG_W = qr/([\xa1-\xfe]?.)/;
	}
	elsif ($cs eq 'euc-kr') { # Korean
	    # range of 2nd byte : [\xa1-\xfe]
	    $REG_W = qr/([\xa1-\xfe]?.)/;
	}
	elsif ($cs eq 'big5') { # Traditional Chinese
	    # range of 2nd byte : [\x40-\x7e\xa1-\xfe]
	    $REG_W = qr/([\x81-\xfe]?.)/;
	}
	else { # Single Byte (Latin, Cyrillic, ...)
	    ;
	}
    }

    $str =~ /(\s*)(\S+)/gc;
    ($sps, $w2) = ($1, $2);

    if ($w2 =~ /[^\x21-\x7e]/) {
	$ascii = 0;
	$sps_len = length($sps);
	if ($sps_len > $lss) {
	    $result = substr($sps, 0, $lss);
	    $w1 = substr($sps, $lss) . $w2;
	    $pos = $lss;
	}
	else {
	    $result = $sps;
	    $w1 = $w2;
	    $pos = $sps_len;
	}
    }
    else {
	$ascii = 1;
	$result = '';
	$w1 = "$sps$w2";
	$pos = 0;
    }

    if ($MODE == 2) {
	$MODE = ($w1 =~ /^(?:Subject:|Comments:)$/i) ? 0 : 1;
    }

    if ($jp) {
	if ($q_enc) {
	    require MIME::EcoEncode::JP_Q;
	    $MIME::EcoEncode::JP_Q::HEAD = $HEAD;
	    $MIME::EcoEncode::JP_Q::HTL  = $HTL;
	    $MIME::EcoEncode::JP_Q::LF   = $LF;
	    $MIME::EcoEncode::JP_Q::BPL  = $BPL;
	    $MIME::EcoEncode::JP_Q::MODE = $MODE;
	    if ($MODE == 0) {
		$refsub = \&MIME::EcoEncode::JP_Q::add_ew_jp_q;
	    }
	    else {
		$refsub = \&add_ew_sh;
		$reg_rp1 = qr/\e\(B[\x21-\x7e]*\)\,?$/;
		$REG_RP = qr/\e\(B[\x21-\x7e]*?(\){1,3}\,?)$/;
		$ADD_EW = \&MIME::EcoEncode::JP_Q::add_ew_jp_q;
	    }
	}
	else {
	    require MIME::EcoEncode::JP_B;
	    $MIME::EcoEncode::JP_B::HEAD = $HEAD;
	    $MIME::EcoEncode::JP_B::HTL  = $HTL;
	    $MIME::EcoEncode::JP_B::LF   = $LF;
	    $MIME::EcoEncode::JP_B::BPL  = $BPL;
	    if ($MODE == 0) {
		$refsub = \&MIME::EcoEncode::JP_B::add_ew_jp_b;
	    }
	    else {
		$refsub = \&add_ew_sh;
                $reg_rp1 = qr/\e\(B[\x21-\x7e]*\)\,?$/;
                $REG_RP = qr/\e\(B[\x21-\x7e]*?(\){1,3}\,?)$/;
		$ADD_EW = \&MIME::EcoEncode::JP_B::add_ew_jp_b;
	    }
	}
    }
    else {
	if ($MODE == 0) {
	    $refsub = $q_enc ? \&add_ew_q : \&add_ew_b;
	}
	else {
	    $refsub = \&add_ew_sh;
	    $reg_rp1 = qr/\)\,?$/;
            $REG_RP = qr/(\){1,3}\,?)$/;
            $ADD_EW = $q_enc ? \&add_ew_q : \&add_ew_b;
	}
    }

    while ($str =~ /(\s*)(\S+)/gc) {
	($sps, $w2) = ($1, $2);
	if ($w2 =~ /[^\x21-\x7e]/) {
	    $sps_len = length($sps);
	    if ($ascii) { # "ASCII \s+ non-ASCII"
		$sp1_bak = $sp1;
		$sp1 = chop($sps);
		$w1 .= $sps if $sps_len > $lss;
		$w1_len = length($w1);
		if ($count == 0) {
		    $result = $w1;
		    $pos = $w1_len;
		}
		else {
		    if (($count > 1) and ($pos + $w1_len + 1 > $BPL)) {
                        $result .= "$LF$sp1_bak$w1";
                        $pos = $w1_len + 1;
                    }
                    else {
                        $result .= "$sp1_bak$w1";
                        $pos += $w1_len + 1;
                    }
		}
		if ($sps_len <= $lss) {
		    if ($pos >= $BPL) {
			$result .= $LF . $sps;
			$pos = $sps_len - 1;
		    }
		    elsif ($pos + $sps_len - 1 > $BPL) {
			$result .= substr($sps, 0, $BPL - $pos) . $LF
			    . substr($sps, $BPL - $pos);
			$pos += $sps_len - $BPL - 1;
		    }
		    else {
			$result .= $sps;
			$pos += $sps_len - 1;
		    }
		}
		$w1 = $w2;
	    }
	    else { # "non-ASCII \s+ non-ASCII"
		if (($MODE == 1) and ($sps_len <= $lss)) {
		    if ($w1 =~ /$reg_rp1/ or $w2 =~ /^\(/) {
			if ($count == 0) {
			    $result .= &$refsub($w1, $pos, \$np, 0);
			}
			else {
			    $tmp = &$refsub($w1, 1 + $pos, \$np, 0);
			    $result .= ($tmp =~ s/^ /$sp1/) ?
				"$LF$tmp" : "$sp1$tmp";
			}
			$pos = $np;
			$sp1 = chop($sps);
			if ($pos + $sps_len - 1 > $BPL) {
			    $result .= substr($sps, 0, $BPL - $pos) . $LF
				. substr($sps, $BPL - $pos);
			    $pos += $sps_len - $BPL - 1;
			}
			else {
			    $result .= $sps;
			    $pos += $sps_len - 1;
			}
			$w1 = $w2;
		    }
		    else {
			$w1 .= "$sps$w2";
		    }
		}
		else {
		    $w1 .= "$sps$w2";
		}
	    }
	    $ascii = 0;
	}
	else { # "ASCII \s+ ASCII" or "non-ASCII \s+ ASCII"
	    $w1_len = length($w1);
	    if ($ascii) { # "ASCII \s+ ASCII"
		if ($count == 0) {
                    $result = $w1;
                    $pos = $w1_len;
                }
		else {
		    if (($count > 1) and ($pos + $w1_len + 1 > $BPL)) {
                        $result .= "$LF$sp1$w1";
                        $pos = $w1_len + 1;
                    }
                    else {
                        $result .= "$sp1$w1";
                        $pos += $w1_len + 1;
                    }
		}
	    }
	    else { # "non-ASCII \s+ ASCII"
		if ($count == 0) {
		    $result .= &$refsub($w1, $pos, \$np, 0);
                    $pos = $np;
                }
		else {
		    $tmp = &$refsub($w1, 1 + $pos, \$np, 0);
		    $result .= ($tmp =~ s/^ /$sp1/) ? "$LF$tmp" : "$sp1$tmp";
		    $pos = $np;
		}
	    }
	    $sps_len = length($sps);
	    if ($pos >= $BPL) {
		$sp1 = substr($sps, 0, 1);
		$w2 = substr($sps, 1) . $w2;
	    }
	    elsif ($pos + $sps_len - 1 > $BPL) {
		$result .= substr($sps, 0, $BPL - $pos);
		$sp1 = substr($sps, $BPL - $pos, 1);
		$w2 = substr($sps, $BPL - $pos + 1) . $w2;
		$pos = $BPL;
	    }
	    else {
		$sp1 = chop($sps);
		$result .= $sps;
		$pos += $sps_len - 1;
	    }
	    $w1 = $w2;
	    $ascii = 1;
	}
	$count++ if $count <= 1;
    }
    ($sps) = ($str =~ /(.*)/g); # All space of the remainder

    if ($ascii) {
	$w1 .= $sps;
	if ($count == 0) {
	    $result = $w1;
	}
	else {
	    $w1_len = length($w1);
	    if (($count > 1) and ($pos + $w1_len + 1 > $BPL)) {
		$result .= "$LF$sp1$w1";
	    }
	    else {
		$result .= "$sp1$w1";
	    }
	}
    }
    else {
	$sps_len = length($sps);
	if ($count == 0) {
	    if ($sps_len > $lss) {
		$w1 .= substr($sps, 0, $sps_len - $lss);
		$result .= &$refsub($w1, $pos, \$np, $lss) .
		    substr($sps, $sps_len - $lss);
	    }
	    else {
		$result .= &$refsub($w1, $pos, \$np, $sps_len) . $sps;
	    }
	}
	else {
	    if ($sps_len > $lss) {
		$w1 .= substr($sps, 0, $sps_len - $lss);
		$tmp = &$refsub($w1, 1 + $pos, \$np, $lss) .
		    substr($sps, $sps_len - $lss);
	    }
	    else {
		$tmp = &$refsub($w1, 1 + $pos, \$np, $sps_len) . $sps;
	    }
	    $result .= ($tmp =~ s/^ /$sp1/) ? "$LF$tmp" : "$sp1$tmp";
	}
    }
    return $trailing_crlf ? $result . $trailing_crlf : $result;
}


# add encoded-word (for structured header)
#   parameters:
#     sp  : start position (indentation of the first line)
#     ep  : end position of last line (call by reference)
#     rll : room of last line (default: 0)
sub add_ew_sh {
    my ($str, $sp, $ep, $rll) = @_;

    our $ADD_EW;
    our $REG_RP;

    my ($lp, $rp); # '(' & ')' : left/right parenthesis
    my ($lp_len, $rp_len) = (0, 0);
    my $tmp;

    if ($str =~ s/^(\({1,3})//) {
	$lp = $1;
	$lp_len = length($lp);
	$sp += $lp_len;
    }
    if ($str =~ /$REG_RP/) {
	$rp = $1;
	$rp_len = length($rp);
	$rll = $rp_len;
	substr($str, -$rp_len) = '';
    }
    $tmp = &$ADD_EW($str, $sp, $ep, $rll);
    if ($lp_len > 0) {
	if ($tmp !~ s/^ / $lp/) {
	    $tmp = $lp . $tmp;
	}
    }
    if ($rp_len > 0) {
	$tmp .= $rp;
	$$ep += $rp_len;
    }
    return $tmp;
}


# add encoded-word for "B" encoding
sub add_ew_b {
    my ($str, $sp, $ep, $rll, $fof) = @_;

    return '' if $str eq '';

    our $LF;   # line feed
    our $BPL;  # bytes per line
    our $HEAD; # head string
    our $HTL;  # head + tail length
    our $UTF8;
    our $REG_W;

    my $str_len = length($str);

    # encoded size + sp
    my $ep_v = int(($str_len + 2) / 3) * 4 + $HTL + $sp;

    if ($ep_v + $rll <= $BPL) {
	$$ep = $ep_v;
	return $HEAD . encode_base64($str, '') . TAIL;
    }

    my $result = '';
    my $w;

    utf8::decode($str) if $UTF8; # UTF8 flag on

    if ($ep_v <= $BPL) {
	$str =~ s/$REG_W$//;
	$w = $1;
	utf8::encode($w) if $UTF8; # UTF8 flag off
	$$ep = int((length($w) + 2) / 3) * 4 + $HTL + 1; # 1 is space
	utf8::encode($str) if $UTF8; # UTF8 flag off
	$result = ($str eq '') ? ' ' :
	    $HEAD . encode_base64($str, '') . TAIL . "$LF ";
	return $result . $HEAD . encode_base64($w, '') . TAIL;
    }

    my ($chunk, $chunk_len) = ('', 0);
    my $w_len;
    my $str_pos = 0;
    my $max_len  = int(($BPL - $HTL - $sp) / 4) * 3;
    my $max_len2 = int(($BPL - $HTL - 1) / 4) * 3;

    while ($str =~ /$REG_W/g) {
	$w = $1;
	utf8::encode($w) if $UTF8; # UTF8 flag off
	$w_len = length($w); # size of one character

	if ($chunk_len + $w_len > $max_len) {
	    if ($chunk_len == 0) { # size over at the first time
		$result = ' ';
		return $result if $fof;
	    }
	    else {
		$result .= $HEAD . encode_base64($chunk, '') . TAIL . "$LF ";
	    }
	    $str_pos += $chunk_len;

	    # encoded size (1 is space)
            $ep_v = int(($str_len - $str_pos + 2) / 3) * 4 + $HTL + 1;
            if ($ep_v + $rll <= $BPL) {
		utf8::encode($str) if $UTF8; # UTF8 flag off
                $chunk = substr($str, $str_pos);
                last;
            }
	    if ($ep_v <= $BPL) {
		$str =~ s/$REG_W$//;
		$w = $1;
		utf8::encode($w) if $UTF8; # UTF8 flag off
		$w_len = length($w);
		utf8::encode($str) if $UTF8; # UTF8 flag off
		$chunk = substr($str, $str_pos);
		$result .= $HEAD . encode_base64($chunk, '') . TAIL . "$LF ";
		$ep_v = int(($w_len + 2) / 3) * 4 + $HTL + 1; # 1 is space
		$chunk = $w;
		last;
	    }
	    $chunk = $w;
	    $chunk_len = $w_len;
	    $max_len = $max_len2;
	}
	else {
	    $chunk .= $w;
	    $chunk_len += $w_len;
	}
    }
    $$ep = $ep_v;
    return $result . $HEAD . encode_base64($chunk, '') . TAIL;
}


# add encoded-word for "Q" encoding
sub add_ew_q {
    my ($str, $sp, $ep, $rll, $fof) = @_;

    return '' if $str eq '';

    our $LF;   # line feed
    our $BPL;  # bytes per line
    our $MODE; # unstructured : 0, structured : 1
    our $HEAD; # head string
    our $HTL;  # head + tail length
    our $UTF8;
    our $REG_W;

    # '.' is added to invalidate RFC 2045 6.7.(3)
    my $qstr = encode_qp($str . '.', '');

    local *qlen;

    chop($qstr); # cut '.'
    $qstr =~ s/_/=5F/g;
    $qstr =~ tr/ /_/;
    $qstr =~ s/\t/=09/g;
    if ($MODE) { # structured
	$qstr =~ s/([^\w\!\*\+\-\/\=])/sprintf("=%X",ord($1))/ego;
	*qlen = sub {
	    my $str = shift;
	    return length($str) * 3 - ($str =~ tr/ A-Za-z0-9\!\*\+\-\///) * 2;
	};
    }
    else { # unstructured
	$qstr =~ s/\?/=3F/g;
	*qlen = sub {
	    my $str = shift;
	    return length($str) * 3 - ($str =~ tr/ -\<\>\@-\^\`-\~//) * 2;
	};
    }

    my $ep_v = length($qstr) + $HTL + $sp;
    if ($ep_v + $rll <= $BPL) {
	$$ep = $ep_v;
	return $HEAD . $qstr . TAIL;
    }

    utf8::decode($str) if $UTF8; # UTF8 flag on

    my $result = '';
    my $chunk_qlen = 0;
    my $w_qlen;
    my $enc_len;
    my $w;

    if ($ep_v <= $BPL) {
	$str =~ s/$REG_W$//;
	$w = $1;
	utf8::encode($w) if $UTF8; # UTF8 flag off
	$w_qlen = qlen($w);
	$$ep = $w_qlen + $HTL + 1; # 1 is space
	$result = ($str eq '') ? ' ' :
	    $HEAD . substr($qstr, 0, -$w_qlen, '') . TAIL . "$LF ";
	return $result . $HEAD . $qstr . TAIL;
    }

    my $max_len = $BPL - $HTL - $sp;
    my $max_len2 = $BPL - $HTL - 1;

    while ($str =~ /$REG_W/g) {
	$w = $1;
	utf8::encode($w) if $UTF8; # UTF8 flag off
	$w_qlen = qlen($w);
	if ($chunk_qlen + $w_qlen > $max_len) {
	    if ($chunk_qlen == 0) { # size over at the first time
		$result = ' ';
		return $result if $fof;
	    }
	    else {
		$result .= $HEAD . substr($qstr, 0, $chunk_qlen, '')
		    . TAIL . "$LF ";
	    }
	    $ep_v = length($qstr) + $HTL + 1; # 1 is space
            if ($ep_v + $rll <= $BPL) {
                last;
            }
	    if ($ep_v <= $BPL) {
		$str =~ s/$REG_W$//;
		$w = $1;
		utf8::encode($w) if $UTF8; # UTF8 flag off
		$w_qlen = qlen($w);
		$result .= $HEAD . substr($qstr, 0, -$w_qlen, '')
		    . TAIL . "$LF ";
		$ep_v = $w_qlen + $HTL + 1; # 1 is space
		last;
	    }
	    $chunk_qlen = $w_qlen;
	    $max_len = $max_len2;
	}
	else {
	    $chunk_qlen += $w_qlen;
	}
    }
    $$ep = $ep_v;
    return $result . $HEAD . $qstr . TAIL;
}


sub mime_deco {
    my $str = shift;
    my $cb = shift;

    my ($charset, $lang, $b_enc, $q_enc);
    my $result = '';
    my $enc = 0;
    my $w_bak = '';
    my $sp_len = 0;
    my ($lp, $rp); # '(' & ')' : left/right parenthesis

    my $reg_ew =
        qr{^
           =\?
           ([-0-9A-Za-z_]+)                         # charset
           (?:\*([A-Za-z]{1,8}                      # language
		   (?:-[A-Za-z]{1,8})*))?           # (RFC 2231 section 5)
           \?
           (?:
               [Bb]\?([0-9A-Za-z\+\/]+={0,2})\?=    # "B" encoding
           |
               [Qq]\?([\x21-\x3e\x40-\x7e]+)\?=     # "Q" encoding
           )
           $}x;

    my ($trailing_crlf) = ($str =~ /(\x0d?\x0a|\x0d)$/);
    $str =~ tr/\n\r//d;

    if ($cb) {
	for my $w (split /([\s]+)/, $str) {
	    $w =~ s/^(\(*)//;
	    $lp = $1;
	    $w =~ s/(\)*)$//;
	    $rp = $1;
            if ($w =~ qr/$reg_ew/o) {
                ($charset, $lang, $b_enc, $q_enc) = ($1, $2, $3, $4);
                $lang = '' unless defined $lang;
		substr($result, -$sp_len) = "" if ($enc and !$lp);
                if (defined $q_enc) {
                    $q_enc =~ tr/_/ /;
                    $result .= $lp . &$cb($w, $charset, $lang,
					  decode_qp($q_enc)) . $rp;
                }
                else {
                    $result .= $lp . &$cb($w, $charset, $lang,
					  decode_base64($b_enc)) . $rp;
                }
                $enc = 1;
            }
            else {
		if ($enc) {
		    if ($w =~ /^\s+$/) {
			$sp_len = length($w);
		    }
		    else {
			$enc = 0;
		    }
		}
                $result .= $lp . $w . $rp;
            }
        }
    }
    else {
        my $cs1 = '';
	my $res_cs1 = '';
	my $res_lang1 = '';
	for my $w (split /([\s]+)/, $str) {
            $w =~ s/^(\(*)//;
            $lp = $1;
            $w =~ s/(\)*)$//;
            $rp = $1;
            if ($w =~ qr/$reg_ew/o) {
                ($charset, $lang, $b_enc, $q_enc) = ($1, $2, $3, $4);
                if ($charset !~ /^US-ASCII$/i) {
                    if ($cs1) {
                        if ($cs1 ne lc($charset)) {
                            $result .= $w;
                            $enc = 0;
                            next;
                        }
                    }
                    else {
                        $cs1 = lc($charset);
			$res_cs1   = $charset || '';
			$res_lang1 = $lang    || '';
                    }
                }
		substr($result, -$sp_len) = "" if ($enc and !$lp);
                if (defined $q_enc) {
                    $q_enc =~ tr/_/ /;
                    $result .= $lp . decode_qp($q_enc) . $rp;
                }
                else {
                    $result .= $lp . decode_base64($b_enc) . $rp;
                }
		$enc = $rp ? 0 : 1;
            }
            else {
		if ($enc) {
		    if ($w =~ /^\s+$/) {
			$sp_len = length($w);
		    }
		    else {
			$enc = 0;
		    }
		}
                $result .= $lp . $w . $rp;
            }
        }
	if ($cs1 eq 'iso-2022-jp') { # remove redundant ESC sequences
	    $result =~ s/(\e..)([^\e]+)\e\(B(?=\1)/$1$2\n/g;
	    $result =~ s/\n\e..//g;
	    $result =~ s/\e\(B(\e..)/$1/g;
	}
	if (wantarray) {
	    return ($trailing_crlf ? $result . $trailing_crlf : $result,
		    $res_cs1, $res_lang1);
	}
    }
    return $trailing_crlf ? $result . $trailing_crlf : $result;
}

1;
