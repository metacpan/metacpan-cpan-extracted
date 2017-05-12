use strict;
use Test;
use HTML::LoL;

my @tests = (['<b>foo</b>', [b => 'foo']],
             ['&nbsp;', &hl_noquote('&nbsp;')],
             ['&nbsp;', &hl_entity('nbsp')],
             [qr[<a (href="x" target="y"|target="y" href="x")>bar</a>],
              [a => {href => 'x', target => 'y'}, 'bar']],
             ['<a href="&amp;">x</a>', [a => {href => '&'}, 'x']],
             ['<a href="&">x</a>', [a => {href => ['"&"']}, 'x']],
             ['<a>x</a>', [a => {attr => hl_bool(0)}, 'x']],
             ['<a attr>x</a>', [a => {attr => hl_bool(1)}, 'x']],
             ['<b>  foo  </b>', &hl_preserve([b => '  foo  '])]);

my $num = @tests;

&plan(tests => $num);

my $fail = 0;
foreach my $test (@tests) {
  my @test = @$test;
  my $expected = shift @test;
  my $result;
  ++$fail unless &ok(&hl(sub { $result .= shift }, @test), $expected);
}

die "$fail of $num tests failed\n" if $fail;
