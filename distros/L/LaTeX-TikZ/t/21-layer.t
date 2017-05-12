#!perl -T

use strict;
use warnings;

use Test::More tests => 9 + 3 * 10;

use LaTeX::TikZ;

use lib 't/lib';
use LaTeX::TikZ::TestHelper;

using Tikz->formatter(
 format => '%d',
);

sub check_layers {
 my ($set, $desc, $exp, $layers) = @_;

 local $Test::Builder::Level = $Test::Builder::Level + 1;

 my ($head, $decl, $body) = check($set, $desc, $exp);

 my $exp_decl = [
  map("\\pgfdeclarelayer{$_}", @$layers),
  "\\pgfsetlayers{main,@{[join ',', @$layers]}}",
 ];

 is_deeply $decl, $exp_decl, "$desc: declarations";
}

my $middle = eval {
 Tikz->layer('middle');
};
is $@, '', 'creating a layer doesn\'t croak';

my $top = eval {
 Tikz->layer(
  'top',
  above => [ 'middle' ],
 );
};
is $@, '', 'creating a layer above another doesn\'t croak';

my $bottom = eval {
 Tikz->layer(
  'bottom',
  above => [ 'main' ],
  below => [ 'middle' ],
 );
};
is $@, '', 'creating a layer above and below anothers doesn\'t croak';

my $foo = eval {
 Tikz->raw('foo')
     ->mod($middle)
};
is $@, '', 'creating a layered raw set doesn\'t croak';

check_layers $foo, 'one layered raw set', <<'RES', [ 'middle' ];
\begin{pgfonlayer}{middle}
\draw foo ;
\end{pgfonlayer}
RES

my $bar = eval {
 Tikz->raw('bar')
     ->mod($top)
};
is $@, '', 'creating another layered raw set doesn\'t croak';

my $seq = Tikz->seq($foo, $bar);

check_layers $seq, 'a sequence of two layered raw sets',
             <<'RES', [ qw<middle top> ];
\begin{pgfonlayer}{middle}
\draw foo ;
\end{pgfonlayer}
\begin{pgfonlayer}{top}
\draw bar ;
\end{pgfonlayer}
RES

sub failed_valid {
 my ($tc) = @_;
 qr/Validation failed for '\Q$tc\E'/;
}

eval {
 $seq->layer(sub { });
};
like $@, failed_valid('Str'), 'directly adding a wrong layer croaks';

eval {
 $seq->layer($bottom);
};
is $@, '', 'directly adding a layer to a sequence doesn\'t croak';

my $res = eval {
 $seq->layer;
};
is $@,     '',     'calling an empty ->layer onto a sequence doesn\'t croak';
is "$res", "$seq", 'empty ->layer returns the object itself';

check_layers $seq, 'a layered sequence', <<'RES', [ qw<bottom middle top> ];
\begin{pgfonlayer}{bottom}
\begin{pgfonlayer}{middle}
\draw foo ;
\end{pgfonlayer}
\begin{pgfonlayer}{top}
\draw bar ;
\end{pgfonlayer}
\end{pgfonlayer}
RES

my $baz = Tikz->raw('baz');
$seq->add($baz);

my $red = Tikz->color('red');
$seq->mod($red);

check_layers $seq, 'mods folding with layers 1',
             <<'RES', [ qw<bottom middle top> ];
\begin{pgfonlayer}{bottom}
\begin{scope} [color=red]
\begin{pgfonlayer}{middle}
\draw [color=red] foo ;
\end{pgfonlayer}
\begin{pgfonlayer}{top}
\draw [color=red] bar ;
\end{pgfonlayer}
\draw baz ;
\end{scope}
\end{pgfonlayer}
RES

$baz->mod($top);

check_layers $seq, 'mods folding with layers 2',
             <<'RES', [ qw<bottom middle top> ];
\begin{pgfonlayer}{bottom}
\begin{scope} [color=red]
\begin{pgfonlayer}{middle}
\draw [color=red] foo ;
\end{pgfonlayer}
\begin{pgfonlayer}{top}
\draw [color=red] bar ;
\end{pgfonlayer}
\begin{pgfonlayer}{top}
\draw [color=red] baz ;
\end{pgfonlayer}
\end{scope}
\end{pgfonlayer}
RES

my $seq2 = Tikz->seq($bar, $baz, $foo)
               ->mod($red);

check_layers $seq2, 'mods folding with layers 3', <<'RES', [ qw<middle top> ];
\begin{scope} [color=red]
\begin{pgfonlayer}{top}
\begin{scope} [color=red]
\draw bar ;
\draw baz ;
\end{scope}
\end{pgfonlayer}
\begin{pgfonlayer}{middle}
\draw [color=red] foo ;
\end{pgfonlayer}
\end{scope}
RES

my $qux = Tikz->raw('qux');
$seq2 = Tikz->seq($qux, $foo)
            ->mod($red);

check_layers $seq2, 'mods folding with layers 4', <<'RES', [ 'middle' ];
\begin{scope} [color=red]
\draw qux ;
\begin{pgfonlayer}{middle}
\draw [color=red] foo ;
\end{pgfonlayer}
\end{scope}
RES

my $seq3 = Tikz->seq($seq2, $bar)
               ->mod($red);

check_layers $seq3, 'mods folding with layers 5', <<'RES', [ qw<middle top> ];
\begin{scope} [color=red]
\draw qux ;
\begin{pgfonlayer}{middle}
\draw [color=red] foo ;
\end{pgfonlayer}
\begin{pgfonlayer}{top}
\draw [color=red] bar ;
\end{pgfonlayer}
\end{scope}
RES

$seq3 = Tikz->seq($bar, $seq2)
            ->mod($red);

check_layers $seq3, 'mods folding with layers 6', <<'RES', [ qw<middle top> ];
\begin{scope} [color=red]
\begin{pgfonlayer}{top}
\draw [color=red] bar ;
\end{pgfonlayer}
\draw qux ;
\begin{pgfonlayer}{middle}
\draw [color=red] foo ;
\end{pgfonlayer}
\end{scope}
RES

my $blue = Tikz->color('blue');
$qux->mod($blue);

check_layers $seq2, 'mods folding with layers 7', <<'RES', [ 'middle' ];
\begin{scope} [color=red]
\draw [color=blue] qux ;
\begin{pgfonlayer}{middle}
\draw [color=red] foo ;
\end{pgfonlayer}
\end{scope}
RES
