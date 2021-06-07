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

    $ipv6_zeroied = Fsdb::Support::IPv6::ipv6_zeroize('1:0002:3:4::');
    # result is 1:2:3:4:0:0:0:0

Normalize an IPv6 address so it has all hextets present,
with no leading zeros.

=cut
sub ipv6_zeroize {
    my ($s) = @_;
    if ($s !~ /::/) {
        return $s;
    };
    my(@double_colon_parts) = split(/::/, $s);
    return undef if ($#double_colon_parts > 1);
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
    } else {
        return undef;
    };
};

=head2 ipv6_normalize

    $ipv6_normal = Fsdb::Support::IPv6::ipv6_normalize('1:0002::7:0:00:8');
    # result is 1:2:0:0:7:0:0:8

Given an IPv6 address, maybe with some fields 0 or leading zero,
normalize it to remove leading zeros and with the leftmost,
longest run of zeros replaced with ::.

=cut
sub ipv6_normalize {
    my ($s) = @_;
    $s = ipv6_zeroize($s) if ($s =~ /::/);   # expand ::
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

=head2 _test_zero_fill

Internal testing.

=cut
sub _test_zero_fill {
    my($in, $out) = @_;
    my($trial) = ipv6_zeroize($in);
    $out //= "undef";
    $trial //= "undef";
    if ($trial eq $out) {
        print "zf ok: $in -> $out\n";
    } else {
        print "zf NO: $in -> $out but got $trial\n";
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
        print "zr ok: $in -> $out\n";
    } else {
        print "zr NO: $in -> $out but got $trial\n";
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
    _test_zero_remove("1:002::6:0:0:8",    "1:2:0:0:6:0:0:8");
    _test_zero_fill("1:2:0:0:6::8",    "1:2:0:0:6:0:0:8");  # technically non-compliant
    _test_zero_fill("1:2::6::8",       undef);              # ambiguous, coudl be 1:2:0:0:6:0:0:8, or 1:2:0:0:0:6:0:8, or other configs
};

1;

