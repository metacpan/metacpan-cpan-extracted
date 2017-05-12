# Copyright (C) 2013 MURATA Yasuhisa
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

package MIME::EcoEncode::Param;

use 5.008005;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw($VERSION);
our @EXPORT = qw(mime_eco_param mime_deco_param);
our $VERSION = '0.95';

our $HEAD; # head string
our $HTL;  # head + tail length
our $LF;   # line feed
our $BPL;  # bytes per line
our $UTF8;
our $REG_W;

sub mime_eco_param {
    my $str = shift;

    return '' unless defined $str;
    return '' if $str eq '';

    my ($trailing_crlf) = ($str =~ /(\x0d?\x0a|\x0d)$/);
    $str =~ tr/\n\r//d;
    if ($str =~ /^\s*$/) {
       return $trailing_crlf ? $str . $trailing_crlf : $str;
    }

    my $charset = shift || 'UTF-8';

    our $HEAD; # head string

    my $cs;
    my $type; # 0: RFC 2231, 1: "Q", 2: "B"
    if ($charset =~ /^([-0-9A-Za-z_]+)(\'[^\']*\')?$/i) {
	$cs = lc($1);
	$type = 0;
	$HEAD = $2 ? $charset : $charset . "''";
    }
    elsif ($charset =~ /^([-0-9A-Za-z_]+)(\*[^\?]*)?(\?[QB])?$/i) {
	$cs = lc($1);
	if (defined $3) {
	    $type = (lc($3) eq '?q') ? 1 : 2;
	    $HEAD = '=?' . $charset . '?';
	}
	else {
	    $type = 2;
	    $HEAD = '=?' . $charset . '?B?';
	}
    }
    else { # invalid option
	return undef;
    }

    our $HTL;  # head + tail length
    our $LF  = shift || "\n"; # line feed
    our $BPL = shift || 76;   # bytes per line
    our $UTF8 = 1;
    our $REG_W = qr/(.)/;

    my $jp = 0;
    my $np;

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

    $str =~ s/^(\s*)//; # leading whitespace
    my $sps = $1;
    my ($param, $value) = split('=', $str, 2);

    unless (defined $value) {
        return $trailing_crlf ? $str . $trailing_crlf : $str;
    }

    my $quote = 0;

    if ($value =~ s/^\s*"(.*)"$/$1/) {
        $quote = 1;
    }
    if ($value eq '') {
        return $trailing_crlf ? $str . $trailing_crlf : $str;
    }

    my $result = "$sps$param=";
    my $v_len = length($value);
    my $ll_len = length($result);

    if (!$quote && $value !~ /[^\w!#\$&\+-\.\^`\{\|}~]/) { # regular token
        if ($type or $ll_len + $v_len <= $BPL) {
            $result .= $value;
            return $trailing_crlf ? $result . $trailing_crlf : $result;
        }

        my $n = 0;
        my $c;
        my $p_str;

        $result = "$sps$param\*0=";
        $ll_len += 2;
        while ($value =~ /(.)/g) {
            $c = $1;
            if ($ll_len + 1 > $BPL) {
                $n++;
                $p_str = " $param\*$n=";
                $result .= "$LF$p_str$c";
                $ll_len = 1 + length($p_str);
            }
            else {
                $result .= $c;
                $ll_len++;
            }
        }
        return $trailing_crlf ? $result . $trailing_crlf : $result;
    }
    if ($quote && $value !~ /[^\t\x20-\x7e]/) { # regular quoted-string
        if ($type or $ll_len + $v_len + 2 <= $BPL) {
            $result .= "\"$value\"";
            return $trailing_crlf ? $result . $trailing_crlf : $result;
        }

        my $n = 0;
        my $vc;
        my $vc_len;
        my $p_str;

        $result = "$sps$param\*0=\"";
        $ll_len += 3;
        while ($value =~ /(\\.|.)/g) {
            $vc = $1;
            $vc_len = length($vc);
            if ($ll_len + $vc_len + 1 > $BPL) {
                $n++;
                $p_str = " $param\*$n=\"";
                $result .= "\"$LF$p_str$vc";
                $ll_len = $vc_len + length($p_str);
            }
            else {
                $result .= $vc;
                $ll_len += $vc_len;
            }
        }
        $result .= '"';
        return $trailing_crlf ? $result . $trailing_crlf : $result;
    }

    #
    # extended parameter (contain regular parameter)
    #

    if ($jp) {
	if ($type == 0) {
	    return param_enc_jp($param, $value, $sps, $trailing_crlf, $quote);
	}

	if ($type == 1) { # "Q" encoding
	    require MIME::EcoEncode::JP_Q;
	    $MIME::EcoEncode::JP_Q::HEAD  = $HEAD;
	    $MIME::EcoEncode::JP_Q::HTL   = $HTL;
	    $MIME::EcoEncode::JP_Q::LF    = $LF;
	    $MIME::EcoEncode::JP_Q::BPL   = $BPL;
	    $MIME::EcoEncode::JP_Q::MODE  = 0;

	    my $enc =
		MIME::EcoEncode::JP_Q::add_ew_jp_q($value,
						   length($result) + 1,
						   \$np, 1, 1);
	    if ($enc eq ' ') {
		$enc =
		    MIME::EcoEncode::JP_Q::add_ew_jp_q($value, 2, \$np, 1);
		$result .= "$LF \"$enc\"";
	    }
	    else {
		$result .= "\"$enc\"";
	    }
	    return $trailing_crlf ? $result . $trailing_crlf : $result;
	}
	else { # "B" encoding
	    require MIME::EcoEncode::JP_B;
	    $MIME::EcoEncode::JP_B::HEAD  = $HEAD;
	    $MIME::EcoEncode::JP_B::HTL   = $HTL;
	    $MIME::EcoEncode::JP_B::LF    = $LF;
	    $MIME::EcoEncode::JP_B::BPL   = $BPL;

	    my $enc =
		MIME::EcoEncode::JP_B::add_ew_jp_b($value,
						   length($result) + 1,
						   \$np, 1, 1);
	    if ($enc eq ' ') {
		$enc =
		    MIME::EcoEncode::JP_B::add_ew_jp_b($value, 2, \$np, 1);
		$result .= "$LF \"$enc\"";
	    }
	    else {
		$result .= "\"$enc\"";
	    }
	    return $trailing_crlf ? $result . $trailing_crlf : $result;
	}
    }

    if ($type == 0) {
	return param_enc($param, $value, $sps, $trailing_crlf, $quote);
    }
    if ($type == 1) { # "Q" encoding
	require MIME::EcoEncode;
        $MIME::EcoEncode::HEAD  = $HEAD;
        $MIME::EcoEncode::HTL   = $HTL;
        $MIME::EcoEncode::LF    = $LF;
        $MIME::EcoEncode::BPL   = $BPL;
        $MIME::EcoEncode::REG_W = $REG_W;

        my $enc =
	    MIME::EcoEncode::add_ew_q($value, length($result) + 1,
                                         \$np, 1, 1);
        if ($enc eq ' ') {
            $enc =
		MIME::EcoEncode::add_ew_q($value, 2, \$np, 1);
            $result .= "$LF \"$enc\"";
        }
        else {
            $result .= "\"$enc\"";
        }
        return $trailing_crlf ? $result . $trailing_crlf : $result;
    }
    else { # "B" encoding
	require MIME::EcoEncode;
        $MIME::EcoEncode::HEAD  = $HEAD;
        $MIME::EcoEncode::HTL   = $HTL;
        $MIME::EcoEncode::LF    = $LF;
        $MIME::EcoEncode::BPL   = $BPL;
        $MIME::EcoEncode::REG_W = $REG_W;

        my $enc =
	    MIME::EcoEncode::add_ew_b($value, length($result) + 1,
                                         \$np, 1, 1);
        if ($enc eq ' ') {
            $enc =
		MIME::EcoEncode::add_ew_b($value, 2, \$np, 1);
            $result .= "$LF \"$enc\"";
        }
        else {
            $result .= "\"$enc\"";
        }
        return $trailing_crlf ? $result . $trailing_crlf : $result;
    }
}


sub param_enc {
    my $param = shift;
    my $value = shift;
    my $sps = shift;
    my $trailing_crlf = shift;
    my $quote = shift;

    my $result;
    my $ll_len;

    our $UTF8;
    our $REG_W;
    our $HEAD;

    $value = "\"$value\"" if $quote;
    my $vstr = $value;

    $value =~ s/([^\w!#\$&\+-\.\^`\{\|}~])/
        sprintf("%%%X",ord($1))/egox;

    $result = "$sps$param\*=$HEAD";
    if (length($result) + length($value) <= $BPL) {
        $result .= $value;
        return $trailing_crlf ? $result . $trailing_crlf : $result;
    }

    my $n = 0;
    my $nn = 1;
    my $w1;
    my $p_str;
    my $w;
    my $w_len;
    my $chunk = '';
    my $ascii = 1;

    $result = "$sps$param\*0\*=$HEAD";
    $ll_len = length($result);

    utf8::decode($vstr) if $UTF8; # UTF8 flag on

    while ($vstr =~ /$REG_W/g) {
        $w1 = $1;
	utf8::encode($w1) if $UTF8; # UTF8 flag off
        $w_len = length($w1); # size of one character

        $value =~ /((?:%..|.){$w_len})/g;
        $w = $1;
        $w_len = length($w);

        $ascii = 0 if $w_len > 1;

        # 1 is ';'
        if ($ll_len + $w_len + 1 > $BPL) {
            $p_str = " $param\*$nn\*=";
            if ($ascii) {
                if ($n == 0) {
                    $result = "$sps$param\*0=$HEAD$chunk$w;";
                }
                else {
                    $result .= "$LF $param\*$n=$chunk$w;";
                }
                $ll_len = length($p_str);
                $chunk = '';
            }
            else {
                if ($n == 0) {
                    $result = "$result$chunk;";
                }
                else {
                    $result .= "$LF $param\*$n\*=$chunk;";
                }
                $ll_len = length($p_str) + $w_len;
                $chunk = $w;
            }
            $ascii = 1 if $w_len == 1;
            $n = $nn;
            $nn++;
        }
        else {
            $chunk .= $w;
            $ll_len += $w_len;
        }
    }
    if ($ascii) {
        if ($chunk eq '') {
            chop($result);
        }
        else {
            $result .= "$LF $param\*$n=$chunk";
        }
    }
    else {
        $result .= "$LF $param\*$n\*=$chunk";
    }
    return $trailing_crlf ? $result . $trailing_crlf : $result;
}


sub param_enc_jp {
    my $param = shift;
    my $value = shift;
    my $sps = shift;
    my $trailing_crlf = shift;
    my $quote = shift;

    my $result;
    my $ll_len;

    our $HEAD;

    $value = "\"$value\"" if $quote;
    my $vstr = $value;

    $value =~ s/([^\w!#\$&\+-\.\^`\{\|}~])/
        sprintf("%%%X",ord($1))/egox;

    $result = "$sps$param\*=$HEAD";
    if (length($result) + length($value) <= $BPL) {
        $result .= $value;
        return $trailing_crlf ? $result . $trailing_crlf : $result;
    }

    my $n = 0;
    my $nn = 1;
    my $p_str;
    my $ascii = 1;

    my $ee_str = '%1B%28B';
    my $ee_len = 7;

    my $vstr_len = length($vstr);

    my $k_in = 0; # ascii: 0, zen: 1 or 2, han: 9
    my $k_in_bak = 0;
    my $ec;
    my ($w, $w_len) = ('', 0);
    my ($chunk, $chunk_len) = ('', 0);
    my ($w1, $w1_bak);
    my $enc_len;

    $vstr =~ s/\e\(B$//;
    $result = "$sps$param\*0\*=$HEAD";
    $ll_len = length($result);

    while ($vstr =~ /\e(..)|./g) {
        $ec = $1;
        $value =~ /(%1B(?:%..|.)(?:%..|.)|(?:%..|.))/g;
        $w1 = $1;
        $w .= $w1;
        if (defined $ec) {
            $w1_bak = $w1;
            if ($ec eq '(B') {
                $k_in = 0;
            }
            elsif ($ec eq '$B') {
                $k_in = 1;
            }
            else {
                $k_in = 9;
            }
            next;
        }
        else {
            if ($k_in == 1) {
                $k_in = 2;
                next;
            }
            elsif ($k_in == 2) {
                $k_in = 1;
            }
        }
        $w_len = length($w);
        $enc_len = $w_len + ($k_in ? $ee_len : 0);
        $ascii = 0 if $w_len > 1;

        # 1 is ';'
        if ($ll_len + $enc_len + 1 > $BPL) {
            $p_str = " $param\*$nn\*=";
            if ($ascii) {
                if ($n == 0) {
                    $result = "$sps$param\*0=$HEAD$chunk$w;";
                }
                else {
                    $result .= "$LF $param\*$n=$chunk$w;";
                }
                $ll_len = length($p_str);
                $chunk = '';
            }
            else {
                if ($k_in_bak) {
                    $chunk .= $ee_str;
                    if ($k_in) {
                        if ($k_in_bak == $k_in) {
                            $w = $w1_bak . $w;
                            $w_len += length($w1_bak);
                        }
                    }
                    else {
                        $w = $w1;
                        $w_len = length($w1);
                    }
                }
                if ($n == 0) {
                    $result = "$result$chunk;";
                }
                else {
                    $result .= "$LF $param\*$n\*=$chunk;";
                }
                $ll_len = length($p_str) + $w_len;
                $chunk = $w;
            }
            $ascii = 1 if $w_len == 1;
            $n = $nn;
            $nn++;
        }
        else {
            $chunk .= $w;
            $ll_len += $w_len;
        }
        $k_in_bak = $k_in;
        $w = '';
        $w_len = 0;
    }
    if ($ascii) {
        if ($chunk eq '') {
            chop($result);
        }
        else {
            $result .= "$LF $param\*$n=$chunk";
        }
    }
    else {
        $chunk .= $ee_str if $k_in_bak;
        $result .= "$LF $param\*$n\*=$chunk";
    }
    return $trailing_crlf ? $result . $trailing_crlf : $result;
}


sub mime_deco_param {
    my $str = shift;
    if ((!defined $str) || $str eq '') {
        return ('') x 5 if wantarray;
        return '';
    }

    my ($trailing_crlf) = ($str =~ /(\x0d?\x0a|\x0d)$/);
    $str =~ tr/\n\r//d;
    if ($str =~ /^\s*$/) {
        return ($trailing_crlf ? $str . $trailing_crlf : $str,
                ('') x 4) if wantarray;
        return $trailing_crlf ? $str . $trailing_crlf : $str;
    }

    $str =~ s/^(\s*)//; # leading whitespace
    my $sps = $1;

    my $result = '';
    my ($param, $value, $charset, $lang);
    my ($param0, $value0, $charset0, $lang0) = ('') x 4;

    my $bq_on = shift; # "B/Q" decode ON/OFF
    $bq_on = 1 unless defined $bq_on;

    if ($bq_on) {
	$str =~ /([^=]*)=\s*"(.*?[^\\])"\s*/;
	($param, $value) = ($1, $2);

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
	       )}x;

	if ($value and $value =~ qr/$reg_ew(\s|$)/) { # "B" or "Q"
	    ($charset0, $lang0) = ($1, $2);
	    $lang0 = '' unless defined $lang0;
	    $param0 = $param;

	    require MIME::Base64;
	    MIME::Base64->import();

	    require MIME::QuotedPrint;
	    MIME::QuotedPrint->import();

	    my ($b_enc, $q_enc);

	    for my $w (split /\s+/, $value) {
		if ($w =~ qr/$reg_ew$/o) {
		    ($charset, $lang, $b_enc, $q_enc) = ($1, $2, $3, $4);
		    if (defined $q_enc) {
			$q_enc =~ tr/_/ /;
			$value0 .= decode_qp($q_enc);
		    }
		    else {
			$value0 .= decode_base64($b_enc);
		    }
		}
	    }
	    if (lc($charset0) eq
		'iso-2022-jp') { # remove redundant ESC sequences
		$value0 =~ s/(\e..)([^\e]+)\e\(B(?=\1)/$1$2\n/g;
		$value0 =~ s/\n\e..//g;
		$value0 =~ s/\e\(B(\e..)/$1/g;
	    }
	    $result = "$sps$param0=\"$value0\"";
	    if (wantarray) {
		return ($trailing_crlf ? $result . $trailing_crlf : $result,
			$param0, $charset0, $lang0, $value0);
	    }
	    return $trailing_crlf ? $result . $trailing_crlf : $result;
	}
    }

    my ($param0_init, $cs_init, $quote) = (0) x 3;
    my %params;

    while ($str =~ /([^=]*)=(\s*".*?[^\\]";?|\S*)\s*/g) {
        ($param, $value) = ($1, $2);
        $value =~ s/;$//;
        if ($value =~ s/^\s*"(.*)"$/$1/) {
            $quote = 1;
        }
        if ($param =~ s/\*$//) {
            if (!$cs_init) {
                if ($value =~ /^(.*?)'(.*?)'(.*)/) {
                    ($charset0, $lang0, $value) = ($1, $2, $3);
                }
                $cs_init = 1;
            }
            $value =~ s/%([0-9A-Fa-f][0-9A-Fa-f])/pack('H2', $1)/eg;
        }
        if (!$param0_init) {
            $param =~ s/\*0$//;
            $param0 = $param;
            $param0_init = 1;
        }
        $params{$param} = $value;
    }

    my $n = keys %params;

    $result = ($n == 0) ? "$sps$str" : "$sps$param0=";
    $value0 = $params{$param0};
    $value0 = '' unless defined $value0;
    if ($n > 1) {
        for (my $i = 1; $i < $n; $i++) {
            $value = $params{$param0 . "\*$i"};
            $value0 .= $value if defined $value;
        }
    }
    if (lc($charset0) eq 'iso-2022-jp') { # remove redundant ESC sequences
        $value0 =~ s/(\e..)([^\e]+)\e\(B(?=\1)/$1$2\n/g;
        $value0 =~ s/\n\e..//g;
        $value0 =~ s/\e\(B(\e..)/$1/g;
    }
    $result .= ($quote ? "\"$value0\"" : $value0);
    if (wantarray) {
        if (!$cs_init and $quote) {
            $value0 =~ s/\\(.)/$1/g;
        }
        return ($trailing_crlf ? $result . $trailing_crlf : $result,
                $param0, $charset0, $lang0, $value0);
    }
    return $trailing_crlf ? $result . $trailing_crlf : $result;
}

1;
