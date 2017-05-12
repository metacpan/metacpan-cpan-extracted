# Copyright (C) 2011-2013 MURATA Yasuhisa
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

package MIME::EcoEncode::JP_Q;

use strict;
use warnings;

our $VERSION = '0.95';

use MIME::QuotedPrint;

use constant TAIL => '?=';

our $HEAD; # head string
our $HTL;  # head + tail length
our $LF;   # line feed
our $BPL;  # bytes per line
our $MODE; # unstructured : 0, structured : 1

# add encoded-word for "Q" encoding and 7bit-jis string
#   parameters:
#     sp  : start position (indentation of the first line)
#     ep  : end position of last line (call by reference)
#     rll : room of last line (default: 0)
#     fof : flag to check size-over at the first time
sub add_ew_jp_q {
    my ($str, $sp, $ep, $rll, $fof) = @_;

    return '' if $str eq '';

    # '.' is added to invalidate RFC 2045 6.7.(3)
    my $qstr = encode_qp($str . '.', '');
    my $ee_len; # structured: 7, unstructured: 5
    my $ee_str;

    chop($qstr); # cut '.'
    $qstr =~ s/_/=5F/g;
    $qstr =~ tr/ /_/;
    $qstr =~ s/\t/=09/g;
    if ($MODE) { # structured
	$ee_len = 7; # '=1B=28B'
	$ee_str = '=1B=28B';
        $qstr =~ s/([^\w\!\*\+\-\/\=])/sprintf("=%X",ord($1))/ego;
    }
    else { # unstructured
	$ee_len = 5; # '=1B(B'
	$ee_str = '=1B(B';
        $qstr =~ s/\?/=3F/g;
    }
    my $qstr_len = length($qstr);
    my $ep_v = $qstr_len + $HTL + $sp;

    if ($ep_v + $rll <= $BPL) {
	$$ep = $ep_v;
	return $HEAD . $qstr . TAIL;
    }

    my $ll_flag = ($ep_v <= $BPL) ? 1 : 0;
    my $k_in = 0; # ascii: 0, zen: 1 or 2, han: 9
    my $k_in_bak = -1;
    my $k_out;
    my $ec;
    my $w1;
    my $w1_bak = '';
    my $w = '';
    my $w_len;
    my $w_bak = '';
    my $chunk;
    my $chunk_len;
    my $result = '';
    my $ep_str;
    my $max_len  = $BPL - $HTL - $sp;
    my $max_len2 = $BPL - $HTL - 1;
    my $max_len3 = $BPL - $HTL - 1 - $rll;

    while ($str =~ /\e(..)|./g) {
	$ec = $1;
	$qstr =~ /(\=1B(?:\=..|.)(?:\=..|.)|(?:\=..|.))/g;
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
        $k_out = $k_in ? $ee_len : 0;
        if (pos($qstr) + $k_out > $max_len) {
            $w_len = length($w);
            if ($k_in_bak < 0) { # size over at the first time
                $result = ' ';
                return $result if $fof;
            }
            else {
                if ($k_in_bak) {
                    $chunk = $w_bak .
                        substr($qstr, 0, pos($qstr) - $w_len, "") . $ee_str;
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
                    $chunk = $w_bak .
			substr($qstr, 0, pos($qstr) - $w_len, "");
                }
                $result .= $HEAD . $chunk . TAIL . "$LF ";
            }
            substr($qstr, 0, $w_len, "");
            $chunk_len = length($qstr) + length($w);
            if ($chunk_len <= $max_len3) {
                $chunk = $w . $qstr;
                last;
            }
            $ll_flag = 1 if $chunk_len <= $max_len2;
            $w_bak = $w;
            $max_len = $max_len2 - length($w_bak);
        }
        else {
            if ($ll_flag
		and pos($qstr) + $k_out == length($qstr)) { # last char
                if ($k_in_bak < 0) { # size over at the first time
                    $result = ' ';
                    return $result if $fof;
                }
                else {
                    if ($k_in_bak) {
                        $chunk = $w_bak .
                            substr($qstr, 0, pos($qstr) - length($w), "") .
                                $ee_str;
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
			$chunk = $w_bak .
			    substr($qstr, 0, pos($qstr) - length($w), "");
		    }
		    $result .= $HEAD . $chunk . TAIL . "$LF ";
		}
		$chunk = $k_out ? $w . $ee_str : $w;
		last;
	    }
	}
	$k_in_bak = $k_in;
	$w = '';
    }
    $ep_str = $HEAD . $chunk . TAIL;
    $$ep = length($ep_str) + 1;
    return $result . $ep_str;
}

1;
