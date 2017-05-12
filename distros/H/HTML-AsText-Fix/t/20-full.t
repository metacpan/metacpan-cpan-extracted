#!perl
use strict;
use utf8;
use warnings;

use Test::More tests => 7;

use_ok('HTML::Tree');
use_ok('HTML::AsText::Fix');

isa_ok(
    my $tree =
        HTML::Tree->
            new_from_file(
                't/test.html'
            ),
    'HTML::TreeBuilder'
);

ok(
    my $guard =
        HTML::AsText::Fix::object(
            $tree,
            lf_char     => "\x{0a}",
            zwsp_char   => "\x{0a}",
        ),
    'object guard'
);

ok(
    open(my $fh, '<:encoding(UTF-8)', 't/test.txt'),
    'load plaintext'
);

my $text;
{
    local $/ = undef;
    $text = <$fh>;
};

ok(
    $text ne '',
    'text non-empty'
);

close $fh;

ok(
    $tree->as_text eq $text,
    'match'
);
