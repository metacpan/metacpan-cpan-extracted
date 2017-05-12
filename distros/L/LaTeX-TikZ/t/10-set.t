#!perl -T

use strict;
use warnings;

use Test::More tests => 29 + 2 * 21;

use LaTeX::TikZ;

use lib 't/lib';
use LaTeX::TikZ::TestHelper;

using Tikz->formatter(
 format => '%d',
);

my $foo = eval {
 Tikz->raw('foo');
};
is $@, '', 'creating a raw set doesn\'t croak';

check $foo, 'one raw set', <<'RES';
\draw foo ;
RES

my $seq2 = eval {
 Tikz->seq($foo, $foo);
};
is $@, '', 'creating a 2-sequence doesn\'t croak';

check $seq2, 'two identical raw sets', <<'RES';
\draw foo ;
\draw foo ;
RES

my $bar = eval {
 Tikz->raw('bar');
};
is $@, '', 'creating another raw set doesn\'t croak';

$seq2 = eval {
 Tikz->seq($foo, $bar);
};
is $@, '', 'creating another 2-sequence doesn\'t croak';

check $seq2, 'two different raw sets', <<'RES';
\draw foo ;
\draw bar ;
RES

my $seq3 = eval {
 Tikz->seq($bar, $seq2, $foo);
};
is $@, '', 'creating a complex sequence doesn\'t croak';

check $seq3, 'two different raw sets and a sequence', <<'RES';
\draw bar ;
\draw foo ;
\draw bar ;
\draw foo ;
RES

my $baz = eval {
 Tikz->raw('baz');
};
is $@, '', 'creating yet another raw set doesn\'t croak';

eval {
 $foo->add($baz);
};
like $@, qr/Can't locate object method "add"/,
                                         'adding something to a raw set croaks';

eval {
 $seq2->add($baz, $baz);
};
is $@, '', 'adding something to a sequence set doesn\'t croak';

check $seq3, 'two different raw sets and an extended sequence', <<'RES';
\draw bar ;
\draw foo ;
\draw bar ;
\draw baz ;
\draw baz ;
\draw foo ;
RES

my $seq4 = eval {
 Tikz->seq;
};
is $@, '', 'creating an empty sequence doesn\'t croak';

check $seq4, 'an empty sequence', '';

$seq4 = eval {
 Tikz->seq(Tikz->seq);
};
is $@, '', 'creating a sequence that contains an empty sequence doesn\'t croak';

check $seq4, 'a sequence that contains an empty sequence', '';

$seq4 = eval {
 Tikz->seq($foo, Tikz->seq);
};
is $@, '',
 'creating a sequence that contains a set and an empty sequence doesn\'t croak';

check $seq4, 'a sequence that contains a set and an empty sequence', <<'RES';
\draw foo ;
RES

$seq4 = eval {
 Tikz->seq(Tikz->seq, $foo);
};
is $@, '',
 'creating a sequence that contains an empty sequence and a set doesn\'t croak';

check $seq4, 'a sequence that contains an empty sequence and a set', <<'RES';
\draw foo ;
RES

$seq4 = eval {
 Tikz->seq($foo, $bar, Tikz->seq);
};
is $@, '',
'creating a sequence that contains 2 sets and an empty sequence doesn\'t croak';

check $seq4, 'a sequence that contains 2 sets and an empty sequence', <<'RES';
\draw foo ;
\draw bar ;
RES

$seq4 = eval {
 Tikz->seq($foo, Tikz->seq, $bar);
};
is $@, '', 'creating a sequence that contains a set, an empty sequence, a set doesn\'t croak';

check $seq4, 'a sequence that contains a set, an empty sequence, a set',<<'RES';
\draw foo ;
\draw bar ;
RES

$seq4 = eval {
 Tikz->seq(Tikz->seq, $foo, $bar);
};
is $@, '',
'creating a sequence that contains an empty sequence and 2 sets';

check $seq4, 'a sequence that contains an empty sequence and 2 sets', <<'RES';
\draw foo ;
\draw bar ;
RES

sub failed_valid {
 my ($tc) = @_;
 qr/Validation failed for '\Q$tc\E'/;
}

eval {
 Tikz->union($foo, $seq2);
};
like $@, failed_valid('Maybe[ArrayRef[LaTeX::TikZ::Set::Path]]'),
         'creating an union that contains a sequence croaks';

my $union = eval {
 Tikz->union($foo, $bar, $baz);
};
is $@, '', 'creating an union set doesn\'t croak';

check $union, 'one union set', <<'RES';
\draw foo bar baz ;
RES

eval {
 $union->add($foo);
};
is $@, '', 'adding something to a union set doesn\'t croak';

check Tikz->seq($union, $union), 'two identical union sets', <<'RES';
\draw foo bar baz foo ;
\draw foo bar baz foo ;
RES

eval {
 $union->add($seq2);
};
like $@, failed_valid('LaTeX::TikZ::Set::Path'),
         'adding a sequence to a union croaks';

my $join = eval {
 Tikz->join('--' => $foo, $bar, $baz);
};
is $@, '', 'creating an chain set joined with a string doesn\'t croak';

check $join, 'one chain set joined with a string', <<'RES';
\draw foo -- bar -- baz ;
RES

eval {
 $join->add($foo);
};
is $@, '', 'adding a set to a chain set joined with a string doesn\'t croak';

check $join, 'one appended chain set joined with a string', <<'RES';
\draw foo -- bar -- baz -- foo ;
RES

$join = eval {
 Tikz->join(sub { ' ' } => $foo, $bar, $baz);
};
is $@, '', 'creating an chain set joined with a coderef doesn\'t croak';

check $join, 'one chain set joined with a string', <<'RES';
\draw foo bar baz ;
RES

eval {
 $join->add($foo);
};
is $@, '', 'adding a set to a chain set joined with a coderef doesn\'t croak';

check $join, 'one appended chain set joined with a coderef', <<'RES';
\draw foo bar baz foo ;
RES

$join = eval {
 Tikz->join([ '', '..', '--' ] => $foo, $bar, $baz);
};
is $@, '', 'creating an chain set joined with an arrayref doesn\'t croak';

check $join, 'one chain set joined with a string', <<'RES';
\draw foo bar .. baz ;
RES

eval {
 $join->add($foo);
};
is $@, '', 'adding a set to a chain set joined with an arrayref doesn\'t croak';

check $join, 'one appended chain set joined with an arrayref', <<'RES';
\draw foo bar .. baz -- foo ;
RES

eval {
 $join->add($bar);
};
is $@, '',
   'adding too many sets to a chain set joined with an arrayref doesn\'t croak';

eval {
 using()->render($join);
};
like $@, qr/^Invalid connector/,
         'adding too many sets to a chain set joined with an arrayref croaks';

my $chain = eval {
 Tikz->chain($foo => '--' => $bar => '->' => $baz);
};
is $@, '', 'creating an chain set with chain doesn\'t croak';

check $chain, 'one chain set from chain', <<'RES';
\draw foo -- bar -> baz ;
RES

eval {
 Tikz->chain($foo, '--', $bar, '--');
};
like $@, qr/^The 'chain' command expects an odd number of arguments/,
         'creating an union that contains a sequence croaks';
