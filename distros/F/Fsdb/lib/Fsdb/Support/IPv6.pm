#!/usr/bin/perl -w

#
# Fsdb::Support::IPv6.pm
# Copyright (C) 2021 by John Heidemann <johnh@ficus.cs.ucla.edu>
#
# This program is distributed under terms of the GNU general
# public license, version 2.  See the file COPYING
# in $dblib for details.
#

package Fsdb::Support::IPv6;

=head1 NAME

Fsdb::Support::IPv6 - ipv6-parsing helpers

=head1 SYNOPSIS

    use Fsdb::Support::IPv6;

=cut
#'


=head2 ipv6_zeroize

    $ipv6_zeroized = Fsdb::Support::IPv6::ipv6_zeroize('1:0002:3:4::');
    # result is 1:2:3:4:0:0:0:0

Normalize an IPv6 address so it has all hextets present,
with no leading zeros.

Also treats strings of hex digits without colons as IPv6 prefixes.

=cut
sub ipv6_zeroize {
    my ($s) = @_;
    if ($s !~ /:/) {
        # no :, so it must be a hex string
        # first, make it 32 bytes
        if (length($s) < 32) {
            $s = $s . "0" x (32 - length($s));
        };
        return undef if (length($s) > 32);
        # insert colons (that we will then take out below :-( )
        $s =~ s/(....)/$1:/g;
        $s =~ s/:$//;
    }
#    if ($s !~ /::/) {
#        return $s;
#    };
    my(@double_colon_parts) = split(/::/, $s);
    return undef if ($#double_colon_parts > 1);  # multiple :: !
    my(@hextets) = split(/:/, $s);
    if ($#hextets < 7) {
        my(@full) = ();
        my($found) = undef;
        foreach (@hextets) {
            if ($_ eq '') {
                if ($found) {
                    # ::1 will return the list('', '', '1')
                    push(@full, '0');
                } else {
                    push(@full, ('0') x (8 - $#hextets));
                    $found = 1;
                };
            } elsif ($_ ne '') {
                s/^0+//g;
                $_ = '0' if ($_ eq '');   # put back singleton zero
                push (@full, $_);
            };
        };
        # 1:: returns the list ('1')
        push (@full, ('0') x (7 - $#hextets)) if (!$found);
        return join(':', @full);
    } elsif ($#hextets == 7) {
        my(@full) = ();
        foreach (@hextets) {
            s/^0+//g;
            $_ = '0' if ($_ eq '');   # put back singleton zero
            push (@full, $_);
        };
        return join(':', @full);
    } else {
        return undef;
    };                 
};

=head2 ipv6_fullhex

    $ipv6_fullhex = Fsdb::Support::IPv6::ipv6_full('1:0002:3:4::');
    # result is 0001000200030004000000000000000

Rewrite an IPv6 address as a full, 128-bit, base-16 number.

=cut
sub ipv6_fullhex {
    my ($s) = ipv6_zeroize($_[0]);
    my($r) = '';
    my(@parts) = split(/:/, $s);
    return join('', map { length($_) >= 4 ? $_ : ('0' x (4 - length($_)) . $_) } @parts);
};


=head2 ipv6_normalize

    $ipv6_normal = Fsdb::Support::IPv6::ipv6_normalize('1:0002::7:0:00:8');
    # result is 1:2::7:0:0:8

Convert an IPv6 address to IETF normal form.
The input maybe has some fields 0 or leading zero,
or :: in a non-standard place.
Normalize it to remove leading zeros and replace the leftmost,
longest run of zeros with ::.

Also treats strings of hex digits without colons as IPv6 prefixes.

=cut
sub ipv6_normalize {
    my ($s) = @_;
    $s = ipv6_zeroize($s) if ($s =~ /::/ || $s !~ /:/);   # expand :: or hex-only
    # we must have all fields, but maybe have leading zeros and runs of zeros
    my(@hextets) = split(/:/, $s);
    return undef if ($#hextets != 7);
    my(@trimmed_hextets) = ();
    my(@zero_run);
    my($max_zero_run) = 0;
    foreach (@hextets) {
        s/^0//g;
        $_ = '0' if ($_ eq '');   # put back singleton zero
        push(@trimmed_hextets, $_);
        my($cur_zero_run) = ($_ ne '0' ? 0 : ($#zero_run == -1 ? 1 : $zero_run[$#zero_run] + 1));
        push(@zero_run, $cur_zero_run);
        $max_zero_run = $cur_zero_run if ($cur_zero_run > $max_zero_run);
    };
    # kill leftmost zero run, if any
    return join(':', @trimmed_hextets) if ($max_zero_run == 0);
    my (@zero_runned_hextets) = ();
    my $cur_zero_run = undef;
    my $found_zero_run = undef;
    foreach (0..$#trimmed_hextets) {
        if ($zero_run[$_]) {
            $cur_zero_run = $zero_run[$_];
        } else {
            if (defined($cur_zero_run)) {
                # end of a zero run
                if ($cur_zero_run == $max_zero_run && !$found_zero_run) {
                    # found the :: place!
                    $found_zero_run = 1;
                    push(@zero_runned_hextets, ($#zero_runned_hextets == -1 ? ':' : ''));
                } else {
                    push(@zero_runned_hextets, ('0') x $cur_zero_run);
                };
            };
            push(@zero_runned_hextets, $trimmed_hextets[$_]);
            $cur_zero_run = undef;
        };
    };
    # trailing zeros
    if (defined($cur_zero_run)) {
        if ($cur_zero_run == $max_zero_run && !$found_zero_run) {
            # found the :: place!
            $found_zero_run = 1;
            push(@zero_runned_hextets, ($#zero_runned_hextets == -1 ? '::' : ':'));  # trailing :
        } else {
            push(@zero_runned_hextets, ('0') x $cur_zero_run);
        };
    };
    return join (':', @zero_runned_hextets);
};

=head2 ip_fullhex_to_normal

    $ip_normal = Fsdb::Support::IPv6::ip_fullhex_to_normal('20010db8000300040005000600070008');
    # result is 2001:db8:3:4:5:6:7:8

    $ip_normal = Fsdb::Support::IPv6::ip_fullhex_to_normal('c0000201');
    # result is 192.0.2.1

Convert an IPv6 address to IETF normal form.
The input maybe has some fields 0 or leading zero,
or :: in a non-standard place.
Normalize it to remove leading zeros and replace the leftmost,
longest run of zeros with ::.

Also treats strings of hex digits without colons as IPv6 prefixes.

=cut
sub ip_fullhex_to_normal {
    my($s) = @_;
    if (length($s) <= 8) {
        my(@octets) = map { sprintf("%d", hex($_)) } unpack('(A2)*', $s);
        while ($#octets < 3) {
            push(@octets, '0');
        };
        return join('.', @octets);
    } else {
        return ipv6_normalize($s);
    };
}


=head2 _test_zero_fill

Internal testing.

=cut
sub _test_zero_fill {
    my($in, $out) = @_;
    my($trial) = ipv6_zeroize($in);
    $out //= "undef";
    $trial //= "undef";
    if ($trial eq $out) {
        print "zzf ok: $in -> $out\n";
    } else {
        print "zzf NO: $in -> $out but got $trial\n";
    };
}

=head2 _test_zero_remove

Internal testing.

=cut
sub _test_zero_remove {
    my($in, $out) = @_;
    return if (!defined($out));
    my($trial) = ipv6_normalize($in);
    $out //= "undef";
    $trial //= "undef";
    if ($trial eq $out) {
        print "zrr ok: $in -> $out\n";
    } else {
        print "zrr NO: $in -> $out but got $trial\n";
    };
}

=head2 _test_fullhex

Internal testing.

=cut
sub _test_fullhex {
    my($in, $out) = @_;
    my($trial) = ipv6_fullhex($in);
    $trial //= "undef";
    if ($trial eq $out) {
        print "fh ok: $in -> $out\n";
    } else {
        print "fh NO: $in -> $out but got $trial\n";
    };
}

=head2 _test_fullhex_to_normal

Internal testing.

=cut
sub _test_fullhex_to_normal {
    my($in, $out) = @_;
    my($trial) = ip_fullhex_to_normal($in);
    $trial //= "undef";
    if ($trial eq $out) {
        print "fhn ok: $in -> $out\n";
    } else {
        print "fhn NO: $in -> $out but got $trial\n";
    };
}

=head2 _test_both

Internal testing.

=cut
sub _test_both {
    my($in, $out) = @_;
    _test_zero_fill($in, $out);
    _test_zero_remove($out, $in);
};

=head2 _test_ipv6

Internal testing.

=cut
sub _test_ipv6 {
    _test_both("1:2:3:4:5:6:7:8", "1:2:3:4:5:6:7:8");
    _test_zero_fill("1:2:3:4:5:6:7:0", "1:2:3:4:5:6:7:0");
    _test_both("1:2:3:4:5:6:7::", "1:2:3:4:5:6:7:0");
    _test_both("1:2:3:4:5:6::",   "1:2:3:4:5:6:0:0");
    _test_zero_fill("1:002:3:4:5:6::",   "1:2:3:4:5:6:0:0");
    _test_zero_fill("1:0000:3:4:5:6::",   "1:0:3:4:5:6:0:0");
    _test_both("1:2:3:4:5::8",    "1:2:3:4:5:0:0:8");
    _test_both("1:2:3:4::8",      "1:2:3:4:0:0:0:8");
    _test_both("1:2:3:4::7:8",    "1:2:3:4:0:0:7:8");
    _test_both("1::8",            "1:0:0:0:0:0:0:8");
    _test_both("::1",             "0:0:0:0:0:0:0:1");
    _test_both("1::",             "1:0:0:0:0:0:0:0");
    _test_both("::",              "0:0:0:0:0:0:0:0");
    _test_both("1:2::6:0:0:8",    "1:2:0:0:6:0:0:8");
    # _test_zero_remove("1:2::6:0:0:8",    "1:2:0:0:6:0:0:8");
    _test_zero_fill("1:002::6:0:0:8",    "1:2:0:0:6:0:0:8");
    _test_zero_fill("1:2:0:0:6::8",    "1:2:0:0:6:0:0:8");  # technically non-compliant
    _test_zero_fill("1:2::6::8",       undef);              # ambiguous, coudl be 1:2:0:0:6:0:0:8, or 1:2:0:0:0:6:0:8, or other configs
    _test_fullhex("1:2:3:4:5:6:7:8", "00010002000300040005000600070008");
    _test_fullhex("1:002::6:0:0:8",  "00010002000000000006000000000008");
    _test_fullhex("1:abcd::6:0:0:8", "0001abcd000000000006000000000008");
    # missing case 2021-12-10
    _test_zero_fill("1:02:003:0004:5:6:7:8", "1:2:3:4:5:6:7:8");
    _test_zero_fill("00010002000300040005000600070008", "1:2:3:4:5:6:7:8");
    _test_zero_fill("00010002000300040000000000070008", "1:2:3:4:0:0:7:8");
    _test_zero_fill("000100020003", "1:2:3:0:0:0:0:0");
    _test_fullhex_to_normal('20010db8000300040005000600070008', '2001:db8:3:4:5:6:7:8');
    _test_fullhex_to_normal('c0000201', '192.0.2.1');
};

# _test_ipv6;

1;

