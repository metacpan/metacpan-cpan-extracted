#!perl

# Tests for RT #49607

use Test::More tests => 33;
use strict;
no warnings 'utf8';

# build long strings for tests
# has imbedded \n and different kinds of quotes
# parts from which to build long strings
my $part_plain            = "x" x 50;
my $part_quotes           = ("y" x 8 . "\\\"" . "z" x 8 . "\\\'") x 3;
my $part_nl               = "a" x 49 . "\n";
my $part_cont_nl          = "b" x 49 . "\\\n";
my $part_dosnl            = "a" x 49 . "\r\n";
my $part_cont_dosnl       = "b" x 49 . "\\\r\n";
my $part_cr               = "a" x 49 . "\r";
my $part_cont_cr          = "b" x 49 . "\\\r";
my $part_ls               = "a" x 49 . "\x{2028}";
my $part_cont_ls          = "b" x 49 . "\\\x{2028}";
my $part_ps               = "a" x 49 . "\x{2029}";
my $part_cont_ps          = "b" x 49 . "\\\x{2029}";
my $part_quote_nl         = $part_quotes . "\n";
my $part_quote_cont_nl    = $part_quotes . "\\\n";
my $part_quote_dosnl      = $part_quotes . "\r\n";
my $part_quote_cont_dosnl = $part_quotes . "\\\r\n";
my $part_quote_cr         = $part_quotes . "\r";
my $part_quote_cont_cr    = $part_quotes . "\\\r";
my $part_quote_ls         = $part_quotes . "\x{2028}";
my $part_quote_cont_ls    = $part_quotes . "\\\x{2028}";
my $part_quote_ps         = $part_quotes . "\x{2029}";
my $part_quote_cont_ps    = $part_quotes . "\\\x{2029}";

# legal test strings
my $long_legal_nl        = (
 $part_plain . $part_cont_nl . $part_quotes . $part_cont_dosnl .
 $part_cont_ls . $part_cont_ps . $part_cont_cr . $part_plain .
 $part_quote_cont_nl . $part_quote_cont_dosnl . $part_quote_cont_cr .
 $part_quote_cont_ls . $part_quote_cont_ps
) x 100;
my $long_legal_nonl      = ($part_plain . $part_quotes) x 500;
my $long_legal_noqt_nonl = ($part_plain) x 10000;
my $short_legal_cont_nl  = (
 $part_cont_nl . $part_quote_cont_nl . $part_cont_dosnl .
 $part_quote_cont_dosnl . $part_quote_cont_cr . $part_quote_cont_ls .
 $part_quote_cont_ps
) x 3;
my $short_legal_nonl     = ($part_plain   . $part_quotes);

# illegal test strings (line continuations w/o \)
my $short_illegal   = (
 $part_nl . $part_quote_nl . $part_dosnl . $part_quote_dosnl . $part_ls .
 $part_quote_ls . $part_ps . $part_quote_ps . $part_cr . $part_quote_cr
) x 3;
my $long_illegal    = ($part_plain . $part_cont_nl . $part_quotes . $part_nl . $part_plain . $part_quote_nl) x 200;

my $single = "\'";
my $double = "\"";
my %qname = ($single, 'single', $double, 'double');

my $j;

# add arbitrary quotes
sub add_quote {
    my ($qt, $str) = @_;
    return $qt . $str . $qt;
}
# compute expected values
# only works for cases in this test
sub get_exp {
    my ($qt, $in) = @_;
    $in =~ s/\\(?:\r\n?|[\n\x{2029}\x{2028}])//gx; # eliminate legal line
    $in =~ s/\\(.)/$1/gx;                          # continuations
    $in;
}
# test legal string literal
# try both single and double quoted versions
sub test_legal {
    my ($str, $msg) = @_;
    test_legal_1 ($single, $str, $msg);
    test_legal_1 ($double, $str, $msg);
}
sub test_legal_1 {
    my ($qt, $str, $msg) = @_;
    my $code;
    my $got = "";

    my $qmsg = "$qname{$qt}-quoted $msg";

    # test for legal syntax
    ok ($code = $j->parse ("var a = " . add_quote($qt, $str) . ";\n"), "Parse $qmsg");

    # test for correct value
    $code->execute       if $code;
    $got = $j->prop("a") if $code;
    my $exp = get_exp ($qt, $str);
    if (length ($str) < 1000) {
        is ($got ,  $exp, "Value of $qmsg");  # more descriptive error message
    } else {
        ok ($got eq $exp, "Value of $qmsg");  # shorter error message for gigantic strings
    }
}
# test illegal string litteral
sub test_illegal {
    my ($str, $msg) = @_;

    # test for catch of illegal syntax (parse should fail)
    ok (!$j->parse ("var a = " . add_quote($single, $str) . ";\n"), "single-quoted $msg");
    ok (!$j->parse ("var a = " . add_quote($double, $str) . ";\n"), "double-quoted $msg");
}


#--------------------------------------------------------------------#
# Test 1: See if the module loads

BEGIN { use_ok('JE') };
$j = new JE;

#--------------------------------------------------------------------#
# Tests 2-21: Parse legal strings

test_legal ($long_legal_nl       , 'long string with escaped quotes and legal line continuations');
test_legal ($long_legal_nonl     , 'long string with escaped quotes and no line continuations'   );
test_legal ($long_legal_noqt_nonl, 'long string with no escaped quotes or line continuations'    );
test_legal ($short_legal_cont_nl , 'short string with legal line continuations'                  );
test_legal ($short_legal_nonl    , 'short string with escaped quotes and no line continuations'  );

#--------------------------------------------------------------------#
# Tests 22-25: Parse illegal strings (must fail)

# We actually consider support for embedded unescaped line breaks to be
# a feature, but we may re-enable these tests in a future version if they
# conflict with a later edition of ECMAScript.
SKIP:{
 skip "We do not want these to pass.", 4;
 test_illegal (
  $long_illegal      , 'long string with illegal line continuations'
 );
 test_illegal (
  $short_illegal     , 'short string with illegal line continuations'
 );
}

#--------------------------------------------------------------------#
# Tests 26-33: Illegal line feeds can be allowed by setting a parser option

# This variable is not used, at least in the current implementation.
#$JE::Parser::allow_unescaped_lf = 1;

test_legal ($long_illegal      , 'long string with illegal line continuations  (allow unescape line feeds)' );
test_legal ($short_illegal     , 'short string with illegal line continuations (allow unescape line feeds)');
