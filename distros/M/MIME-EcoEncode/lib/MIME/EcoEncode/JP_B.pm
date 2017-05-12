# Copyright (C) 2011-2013 MURATA Yasuhisa
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

package MIME::EcoEncode::JP_B;

use strict;
use warnings;

our $VERSION = '0.95';

use MIME::Base64;

use constant TAIL => '?=';

our $HEAD; # head string
our $HTL;  # head + tail length
our $LF;   # line feed
our $BPL;  # bytes per line

# add encoded-word for "B" encoding and 7bit-jis string
#   parameters:
#     sp  : start position (indentation of the first line)
#     ep  : end position of last line (call by reference)
#     rll : room of last line (default: 0)
#     fof : flag to check size-over at the first time
sub add_ew_jp_b {
    my ($str, $sp, $ep, $rll, $fof) = @_;

    return '' if $str eq '';

    # encoded size + sp
    my $ep_v = int((length($str) + 2) / 3) * 4 + $HTL + $sp;

    if ($ep_v + $rll <= $BPL) {
        $$ep = $ep_v;
        return $HEAD . encode_base64($str, '') . TAIL;
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
    my $max_len  = int(($BPL - $HTL - $sp) / 4) * 3;
    my $max_len2 = int(($BPL - $HTL - 1) / 4) * 3;
    my $max_len3 = int(($BPL - $HTL - 1 - $rll) / 4) * 3;

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
            if ($k_in_bak < 0) { # size over at the first time
                $result = ' ';
                return $result if $fof;
            }
            else {
                if ($k_in_bak) {
                    $chunk = $w_bak .
                        substr($str, 0, pos($str) - $w_len, "") . "\e\(B";
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
                    $chunk = $w_bak . substr($str, 0, pos($str) - $w_len, "");
                }
                $result .= $HEAD . encode_base64($chunk, '') . TAIL . "$LF ";
            }
            substr($str, 0, $w_len, "");
            $chunk_len = length($str) + length($w);
            if ($chunk_len <= $max_len3) {
                $chunk = $w . $str;
                last;
            }
            $ll_flag = 1 if $chunk_len <= $max_len2;
            $w_bak = $w;
            $max_len = $max_len2 - length($w_bak);
        }
        else {
            if ($ll_flag and pos($str) + $k_out == length($str)) { # last char
                if ($k_in_bak < 0) { # size over at the first time
                    $result = ' ';
                    return $result if $fof;
                }
                else {
                    if ($k_in_bak) {
                        $chunk = $w_bak .
                            substr($str, 0, pos($str) - length($w), "") .
                                "\e\(B";
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
                            substr($str, 0, pos($str) - length($w), "");
                    }
                    $result .= $HEAD
                        . encode_base64($chunk, '') . TAIL . "$LF ";
                }
                $chunk = $k_out ? $w . "\e\(B" : $w;
                last;
            }
        }
        $k_in_bak = $k_in;
        $w = '';
    }
    $ep_str = $HEAD . encode_base64($chunk, '') . TAIL;
    $$ep = length($ep_str) + 1;
    return $result . $ep_str;
}

1;
