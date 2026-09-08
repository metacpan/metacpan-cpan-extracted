#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use File::Raw::XML;

# Depth at its boundaries, and shapes that are wide rather than deep.
# Nothing here asserts on time.

sub refused { my $ok = eval { File::Raw::XML::_dump(@_); 1 }; $ok ? '' : $@ }
sub nested  { my $n = shift; ('<a>' x $n) . ('</a>' x $n) }

ok(!refused(nested(256)),        'depth 256 is accepted under the default');
like(refused(nested(257)),       qr/nesting deeper than max_depth at byte offset 768/, 'depth 257 is refused, at the opening tag that went over');
ok(!refused(nested(3), 3),       'max_depth 3 accepts depth 3');
like(refused(nested(4), 3),      qr/nesting deeper than max_depth at byte offset 9/, 'and refuses depth 4');
ok(!refused('<a/>', 1),          'max_depth 1 accepts a root');
like(refused('<a><b/></a>', 1),  qr/nesting deeper/, 'and refuses a child');
ok(!refused(nested(300), 300),   'a cap above the default is honoured');
ok(!refused(nested(257), -1),    'a negative max_depth means the default' ) if 0;

# wide
{
    my $siblings = '<r>' . ('<a/>' x 100_000) . '</r>';
    my $t = eval { File::Raw::XML::_dump($siblings) };
    ok($t, 'one hundred thousand siblings parse') or diag $@;
    is(scalar @{ $t->[1][0][6] }, 100_000, 'and all of them are there');

    my $attrs = '<r ' . join(' ', map { "a$_=\"$_\"" } 1 .. 10_000) . '/>';
    $t = eval { File::Raw::XML::_dump($attrs) };
    ok($t, 'ten thousand attributes parse') or diag $@;
    is(scalar @{ $t->[1][0][4] }, 10_000, 'and all of them are there, in order');
    is($t->[1][0][4][9999][2], 'a10000', 'the last one is the last one');

    my $text = '<r>' . ('x' x 1_000_000) . '</r>';
    $t = eval { File::Raw::XML::_dump($text) };
    ok($t, 'a megabyte of text parses') or diag $@;
    is(length $t->[1][0][6][0][1], 1_000_000, 'and comes back whole');

    my $cdata = '<r>' . ('<![CDATA[y]]>' x 50_000) . '</r>';
    $t = eval { File::Raw::XML::_dump($cdata) };
    ok($t, 'fifty thousand adjacent CDATA sections parse') or diag $@;
    is(scalar @{ $t->[1][0][6] }, 1, 'and merge into one text node');
    is(length $t->[1][0][6][0][1], 50_000, 'of the right length');
}

# the walkers on a deep document do not recurse: depth 256 through descendants and text
{
    my $deep = ('<a>' x 256) . 'leaf' . ('</a>' x 256);
    my $w = File::Raw::XML::_walk($deep, undef, 'a');
    is(scalar @{ $w->{descendants} }, 255, 'descendants of the root: every nested a');
    is($w->{text}, 'leaf', 'text through the whole depth');
    is_deeply($w->{find}, ['a'], 'find sees only the direct child');
}

done_testing;
