use strict;
use warnings;
use Test::More tests => 4;

use HTML::Template::Parser;

test_error_message(q{<TMPL_VAR EXPR="foo">}, qr{^$});
test_error_message(q{<TMPL_VAR NAME="foo">}, qr{^$});
test_error_message(q{<TMPL_VAR EXPR="${foo}">}, qr{^$});
test_error_message(q{<TMPL_VAR NAME="${foo}">}, qr!line 1. column 1. something wrong. Can't use \${name} at NAME. \[\${foo}\]!);

sub test_error_message {
    my($template_string, $error_message_re) = @_;

    my $parser = HTML::Template::Parser->new;
    eval {
        my $tree = $parser->parse($template_string);
    };
    like($@, $error_message_re, "template_string is [$template_string]");
}

