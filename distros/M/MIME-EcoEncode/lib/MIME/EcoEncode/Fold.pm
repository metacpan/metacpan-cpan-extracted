# Copyright (C) 2013 MURATA Yasuhisa
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

package MIME::EcoEncode::Fold;

use 5.008005;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw($VERSION);
our @EXPORT = qw(mime_eco_fold);
our $VERSION = '0.95';

our $LF;   # line feed
our $BPL;  # bytes per line
our $UTF8;
our $REG_W;

our $SPL;

sub mime_eco_fold {
    my $str = shift;

    return '' unless defined $str;
    return '' if $str eq '';

    my $charset = shift || 'UTF-8';
    my $cs;

    if ($charset =~ /^([-0-9A-Za-z_]+)$/i) {
	$cs = lc($1);
    }
    else { # invalid option
	return undef;
    }

    our $LF  = shift || "\n "; # line feed
    our $BPL = shift || 990;   # bytes per line
    our $UTF8 = 1;
    our $REG_W = qr/(.)/;

    $LF =~ /([^\x0d\x0a]*)$/;
    our $SPL = length($1);

    my $jp = 0;

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

    my $result = '';
    my $refsub = $jp ? \&line_fold_jp : \&line_fold;
    my $odd = 0;

    for my $line (split /(\x0d?\x0a|\x0d)/, $str) {
        if ($odd) {
            $result .= $line;
            $odd = 0;
        }
        else {
            $result .= &$refsub($line);
            $odd = 1;
        }
    }
    return $result;
}


sub line_fold {
    my $str = shift;

    return '' if $str eq '';

    my $str_len = length($str);

    our $BPL;

    return $str if $str_len <= $BPL;

    our $LF;
    our $UTF8;
    our $REG_W;
    our $SPL;

    my $w = '';
    my $w_len;
    my $w_bak = '';
    my $result = '';
    my $max_len = $BPL;

    my ($chunk, $chunk_len) = ('', 0);
    my $str_pos = 0;

    utf8::decode($str) if $UTF8; # UTF8 flag on

    while ($str =~ /$REG_W/g) {
        $w = $1;
	utf8::encode($w) if $UTF8; # UTF8 flag off
        $w_len = length($w); # size of one character
        if ($chunk_len + $w_len > $max_len) {
            $result .= $chunk . "$LF";
            $str_pos += $chunk_len;
            $max_len = $BPL - $w_len - $SPL;
            if ($str_len - $str_pos <= $max_len) {
		utf8::encode($str) if $UTF8; # UTF8 flag off
                $chunk = substr($str, $str_pos);
                last;
            }
            $chunk = $w;
            $chunk_len = $w_len;
        }
        else {
            $chunk .= $w;
            $chunk_len += $w_len;
        }
    }
    return $result . $chunk;
}


sub line_fold_jp {
    my $str = shift;

    return '' if $str eq '';

    our $BPL;

    return $str if length($str) <= $BPL;

    our $LF;
    our $SPL;

    my $k_in = 0; # ascii: 0, zen: 1 or 2, han: 9
    my $k_in_bak = -1;
    my $k_out;
    my $ec;
    my $w1;
    my $w1_bak = '';
    my $w = '';
    my $w_len;
    my $w_bak = '';
    my $result = '';
    my $max_len = $BPL;

    while ($str =~ /(\e(..)|.)/g) {
        ($w1, $ec) = ($1, $2);
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
        $k_out = $k_in ? 3 : 0; # 3 is "\e\(B"
        if (pos($str) + $k_out > $max_len) {
            $w_len = length($w);
            if ($k_in_bak) {
                $result .= $w_bak .
                    substr($str, 0, pos($str) - $w_len, "") . "\e\(B$LF";
                if ($k_in) {
                    if ($k_in_bak == $k_in) {
                        $w = $w1_bak . $w;
                    }
                }
                else {
                    $w = $w1;
                }
            }
            else {
                $result .= $w_bak .
                    substr($str, 0, pos($str) - $w_len, "") . "$LF";
            }
            substr($str, 0, $w_len, "");
            $max_len = $BPL - length($w) - $SPL;
            if (length($str) <= $max_len) {
                return $result . $w . $str;
            }
            $w_bak = $w;
        }
        $k_in_bak = $k_in;
        $w = '';
    }
    return $result . $w_bak . $str; # impossible
}

1;
