use strict;
use warnings;
use utf8;
use Lingua::JA::NormalizeText qw/unify_long_spaces/;
use Test::More;

binmode Test::More->builder->$_ => ':utf8'
    for qw/output failure_output todo_output/;


my $normalizer = Lingua::JA::NormalizeText->new(qw/unify_long_spaces/);
is(unify_long_spaces("\x{0020}\x{0020}(´・ω・｀)\x{0020}\x{0020}"), "\x{0020}(´・ω・｀)\x{0020}");
is(unify_long_spaces("<\x{0020}\x{3000}\x{0020}\x{3000}>" x 2), '< >< >');
is(unify_long_spaces("<\x{3000}\x{0020}\x{3000}\x{0020}>" x 2), '< >< >');
is(unify_long_spaces("<\x{0020}\x{3000}\x{3000}\x{0020}>" x 2), '< >< >');
is(unify_long_spaces("<\x{0020}\x{3000}>" x 2), '< >< >');
is($normalizer->normalize("\x{3000}\x{3000}(  ･`ω･´)\x{3000}\x{3000}"), "\x{3000}( ･`ω･´)\x{3000}");

done_testing;
