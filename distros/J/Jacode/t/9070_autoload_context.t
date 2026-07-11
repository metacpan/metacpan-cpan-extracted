######################################################################
#
# t/9070_autoload_context.t - AUTOLOAD wrapper preserves caller context
#
# Jacode.pm dispatches every Jacode::foo() call to jacode::foo() in
# jacode.pl through an AUTOLOAD-installed wrapper.  The wrapper must
# preserve the caller's list/scalar context, because functions such as
# getcode() and convert() return different values in list and scalar
# context:
#
#     ($matched_length, $encoding) = Jacode::getcode(\$line);   # list
#                        $encoding  = Jacode::getcode(\$line);   # scalar
#
# A wrapper that evaluates the callee in scalar context only (for
# example "my $return = eval { &$callee }") silently breaks the list
# form: $matched_length receives the encoding name and $encoding
# becomes undef.  This test guards against that regression.
#
# Copyright (c) 2026 INABA Hitoshi <ina.cpan@gmail.com> in a CPAN
######################################################################

# This file is encoded in UTF-8.
die "This file is not encoded in UTF-8.\n" if 'あ' ne "\xe3\x81\x82";
die "This script is for perl only. You are using $^X.\n" if $^X =~ /jperl/i;

use strict;
BEGIN { $INC{'warnings.pm'} = '' if $] < 5.006 }; use warnings; local $^W=1;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Jacode;

my $testno = 1;
sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" }

my @tests = (

    # getcode in list context returns (matched_length, encoding)
    sub {
        my $line = "\xE3\x81\x82";   # HIRAGANA LETTER A in utf8
        my($matched_length, $encoding) = Jacode::getcode(\$line);
        ok((defined($matched_length) and ($matched_length == 3) and defined($encoding) and ($encoding eq 'utf8')),
           qq{getcode list context => matched_length=@{[defined $matched_length ? $matched_length : 'undef']}, encoding=@{[defined $encoding ? $encoding : 'undef']} (expect 3, utf8)});
    },

    # getcode in scalar context returns the encoding name
    sub {
        my $line = "\xE3\x81\x82";
        my $encoding = Jacode::getcode(\$line);
        ok((defined($encoding) and ($encoding eq 'utf8')),
           qq{getcode scalar context => encoding=@{[defined $encoding ? $encoding : 'undef']} (expect utf8)});
    },

    # getcode list context for euc input
    sub {
        my $line = "\xA4\xA2";   # HIRAGANA LETTER A in euc
        my($matched_length, $encoding) = Jacode::getcode(\$line);
        ok((defined($matched_length) and ($matched_length == 2) and defined($encoding) and ($encoding eq 'euc')),
           qq{getcode list context euc => matched_length=@{[defined $matched_length ? $matched_length : 'undef']}, encoding=@{[defined $encoding ? $encoding : 'undef']} (expect 2, euc)});
    },

    # getcode list context for sjis input
    sub {
        my $line = "\x82\xA0";   # HIRAGANA LETTER A in sjis
        my($matched_length, $encoding) = Jacode::getcode(\$line);
        ok((defined($matched_length) and ($matched_length == 2) and defined($encoding) and ($encoding eq 'sjis')),
           qq{getcode list context sjis => matched_length=@{[defined $matched_length ? $matched_length : 'undef']}, encoding=@{[defined $encoding ? $encoding : 'undef']} (expect 2, sjis)});
    },

    # the list form must NOT collapse the encoding into the first element
    sub {
        my $line = "\xE3\x81\x82";
        my($first, $second) = Jacode::getcode(\$line);
        ok((defined($first) and ($first ne 'utf8')),
           qq{getcode list context first element is length, not encoding => first=@{[defined $first ? $first : 'undef']} (must not be 'utf8')});
    },

    # convert in list context returns (converted_ref_glob, input_encoding)
    # in scalar context returns the input encoding name
    sub {
        my $line = "\xE3\x81\x82";
        my $input_encoding = Jacode::convert(\$line, 'sjis', 'utf8');
        ok((defined($input_encoding) and ($input_encoding eq 'utf8') and ($line eq "\x82\xA0")),
           qq{convert scalar context => input_encoding=@{[defined $input_encoding ? $input_encoding : 'undef']}, result=@{[uc unpack('H*',$line)]} (expect utf8, 82A0)});
    },

    # convert with explicit input encoding, list context returns 2 elements
    sub {
        my $line = "\x82\xA0";
        my @return = Jacode::convert(\$line, 'euc', 'sjis');
        ok((scalar(@return) == 2) and defined($return[1]) and ($return[1] eq 'sjis') and ($line eq "\xA4\xA2"),
           qq{convert list context => elements=@{[scalar @return]}, input_encoding=@{[defined $return[1] ? $return[1] : 'undef']}, result=@{[uc unpack('H*',$line)]} (expect 2, sjis, A4A2)});
    },
);

$| = 1;
print "1..", scalar(@tests), "\n";
for my $test (@tests) {
    $test->();
}

__END__
