use strict;
use warnings;
use Test::More tests => 11;

use HTML::Template::Parser::ExprParser;

test_error_message('=', qr/\A=\Z/);
test_error_message('==', qr/\A==\Z/);
test_error_message('foo ==', qr/\A ==\Z/);
test_error_message('foo(', qr/\A\(\Z/);
test_error_message('foo(', qr/\A\(\Z/);
test_error_message(q{foo('bar)}, qr/\A\('bar\)\Z/);
test_error_message(q{foo("bar)}, qr/\A\("bar\)\Z/);
test_error_message(q{foo(bar')}, qr/\A\(bar'\)\Z/);
test_error_message(q{foo(bar")}, qr/\A\(bar"\)\Z/);
test_error_message(q{foo("bar')}, qr/\A\("bar'\)\Z/);
test_error_message(q{foo('bar")}, qr/\A\('bar"\)\Z/);

sub test_error_message {
    my($expr, $remain_re) = @_;

    my $parser = HTML::Template::Parser::ExprParser->new;
    my $expr_temp = $expr;
    my $list = $parser->parse(\$expr_temp);

    like($expr_temp, $remain_re, "expr is [$expr]");
}
