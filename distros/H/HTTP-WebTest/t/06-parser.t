#!/usr/bin/perl -w

# $Id: 06-parser.t,v 1.23 2003/04/26 15:12:15 m_ilya Exp $

# This script tests wt scripts parser

use strict;

use HTTP::WebTest::Parser;
use HTTP::WebTest::SelfTest;

use Test::More tests => 70;

# 1-60: check parsed wt script (which contains all variants of
# supported syntax)
{
    {
	package HTTP::WebTest::PlayGround;
	use vars qw($test1);

	$test1 = 'AAA';
    }

    my $filename = shift;

    my $data = read_file('t/simple.wt');
    my ($tests, $opts) = HTTP::WebTest::Parser->parse($data);

    # check $tests
    ok(@$tests == 4);
    ok($tests->[0]{test_name} eq 'Some name here');
    ok($tests->[0]{auth}[0] eq 'name');
    ok($tests->[0]{auth}[1] eq 'value');
    ok(@{$tests->[0]{regex_require}} == 11);
    ok($tests->[0]{regex_require}[0] eq 'Quoted text " test');
    ok($tests->[0]{regex_require}[1] eq 'We can => quote \'');
    ok($tests->[0]{regex_require}[2] eq 'test "');
    ok($tests->[0]{regex_require}[3] eq "test '");
    ok($tests->[0]{regex_require}[4] eq 'test $a');
    ok($tests->[0]{regex_require}[5] eq 'test @a');
    ok($tests->[0]{regex_require}[6]->() eq 'test $a');
    ok($tests->[0]{regex_require}[7]->() eq 'test @a');
    ok($tests->[0]{regex_require}[8]->() eq '$a');
    ok($tests->[0]{regex_require}[9]->() eq '\\$a');
    ok($tests->[0]{regex_require}[10]->() eq 'AAA');
    ok($tests->[0]{url} eq 'www.dot.com');
    ok(@{$tests->[0]{regex_forbid}} == 7);
    ok($tests->[0]{regex_forbid}[0] eq 'More = tests');
    ok($tests->[0]{regex_forbid}[1] eq 'Some @#$%^&* chars');
    ok($tests->[0]{regex_forbid}[2] eq 'more');
    ok($tests->[0]{regex_forbid}[3] eq 'tests and fun');
    ok($tests->[0]{regex_forbid}[4] eq 'abcdef 1234');
    ok($tests->[0]{regex_forbid}[5] eq ' a b c d \' e f ');
    ok($tests->[0]{regex_forbid}[6]->() eq '');
    ok($tests->[0]{ignore_case} eq 'yes');
    ok($tests->[0]{show_cookies} eq 'yes');
    ok($tests->[0]{show_html} eq 'no');
    ok($tests->[1]{test_name} eq 'Another name # this is not a comment');
    ok($tests->[1]{url} eq 'www.tiv.net');
    ok(@{$tests->[1]{cookie}} == 2);
    ok(@{$tests->[1]{cookie}[0]} == 12);
    ok(@{$tests->[1]{cookie}[1]} == 12);
    ok($tests->[1]{cookie}[0][0] eq '0');
    ok($tests->[1]{cookie}[0][1] eq 'webtest');
    ok($tests->[1]{cookie}[0][2] eq 'This is the cookie value');
    ok($tests->[1]{cookie}[1][1] eq 'webtest1');
    ok($tests->[2]{test_name}->() eq 'Some evals are here');
    ok($tests->[2]{file}->() eq '6.ext');
    ok($tests->[2]{params}[0]->() eq 'name');
    ok($tests->[2]{params}[3]->() eq 'bla');
    my $aref = $tests->[2]{auth}->();
    ok(@$aref == 2);
    ok($aref->[0] eq 'http');
    ok($aref->[1] eq 'http://some.proxy.com/');
    $aref = $tests->[3]{params};
    ok(@$aref == 2);
    ok($aref->[0] eq 'upload');
    $aref = $aref->[1];
    ok(@$aref == 6);
    ok($aref->[0] eq 'file');
    ok($aref->[1] eq '/a/myfile');
    ok($aref->[2] eq 'filename');
    ok($aref->[3] eq 'myfile');
    ok($aref->[4] eq 'Content-Type');
    ok($aref->[5] eq 'text/plain');

    # check $opts
    ok($opts->{text_require}[0] eq 'Require some');
    ok($opts->{text_require}[1] eq 'text');
    ok($opts->{text_forbid}[0] eq 'Another');
    ok($opts->{text_forbid}[1] eq 'syntax');
    ok($opts->{text_forbid}[2] eq 'for list');
    ok($opts->{text_forbid}[3] eq 'elements');
    ok($opts->{ignore_case} eq 'no');
}

# 61-68: test error handling for borked wtscript files
parse_error_check(wtscript   => 't/borked1.wt',
		  check_file => 't/test.out/borked1.err');
parse_error_check(wtscript   => 't/borked2.wt',
		  check_file => 't/test.out/borked2.err');
parse_error_check(wtscript   => 't/borked3.wt',
		  check_file => 't/test.out/borked3.err');
parse_error_check(wtscript   => 't/borked4.wt',
		  check_file => 't/test.out/borked4.err');
parse_error_check(wtscript   => 't/borked5.wt',
		  check_file => 't/test.out/borked5.err');
parse_error_check(wtscript   => 't/borked6.wt',
		  check_file => 't/test.out/borked6.err');
SKIP: {
    skip 'test is skipped because it triggers Perl bug', 1
        if $] < 5.006;

    my $out_filter = sub {
	$_[0] =~ s/\(eval \d+\) line \d+/(eval NN) line N/;
    };
    parse_error_check(wtscript   => 't/borked7.wt',
		      check_file => 't/test.out/borked7.err',
		      out_filter => $out_filter);
}
parse_error_check(wtscript   => 't/borked8.wt',
		  check_file => 't/test.out/borked8.err');

# 69-70: test writing wtscript for single test
{
    my @params = ( xxx => 'yyy',
                   zzz => [ 1 => 2 ],
                   abc => [ 1 => [ 2 => 3 ] ],
                   bad => [ qw|( ) ' \' " => { }| ]);
    my $output = HTTP::WebTest::Parser->write_test(\@params);
    compare_output(check_file => 't/test.out/write_params',
                   output_ref => \$output);

    # crash test - parse wtscript, generate, parse wtscript and
    # compare results
    my ($tests1, $opts1) = HTTP::WebTest::Parser->parse($output);
    my $output1 = HTTP::WebTest::Parser->write_test([ %{$tests1->[0]} ]);
    my ($tests2, $opts2) = HTTP::WebTest::Parser->parse($output1);
    is_deeply([$tests1, $opts1],
              [$tests2, $opts2]);
}

sub parse_error_check {
    my %param = @_;
    my $wtscript   = $param{wtscript};
    my $check_file = $param{check_file};
    my $out_filter = $param{out_filter};

    eval {
	my $data = read_file($wtscript);
	my ($tests, $opts) = HTTP::WebTest::Parser->parse($data);
    };
    if($@) {
	my $text = $@;
	my @out_filter = $out_filter ? (out_filter => $out_filter) : ();
	canonical_output(output_ref => \$text,
			 @out_filter);
	compare_output(check_file => $check_file,
		       output_ref => \$text);
    } else {
	fail('Was expecting an exception - did not get any');
    }
}
