#!perl -T

use strict;
use warnings;

use Test::More tests => 8 + 2 * 16;

use LaTeX::TikZ;

use lib 't/lib';
use LaTeX::TikZ::TestHelper;

using Tikz->formatter(
 format => '%d',
);

my $clip1 = Tikz->raw('clip1');
my $clip2 = Tikz->raw('clip2');

my $foo = eval {
 Tikz->raw('foo')
     ->clip($clip1);
};
is $@, '', 'creating a clipping a raw path with ->clip doesn\'t croak';

check $foo, 'one clipped raw set', <<'RES';
\begin{scope}
\clip clip1 ;
\draw foo ;
\end{scope}
RES

my $bar = eval {
 Tikz->raw('bar')
     ->mod(Tikz->clip(Tikz->raw('clip1')));
};
is $@, '', 'creating a clipping a raw path with ->mod doesn\'t croak';

check $bar, 'another clipped raw set', <<'RES';
\begin{scope}
\clip clip1 ;
\draw bar ;
\end{scope}
RES

my $seq = Tikz->seq($foo, $bar);

check $seq, 'mods folding with clips 1', <<'RES';
\begin{scope}
\clip clip1 ;
\draw foo ;
\draw bar ;
\end{scope}
RES

my $baz = Tikz->raw('baz')
              ->clip($clip2);

check Tikz->seq($seq, $baz), 'mods folding with clips 2', <<'RES';
\begin{scope}
\clip clip1 ;
\draw foo ;
\draw bar ;
\end{scope}
\begin{scope}
\clip clip2 ;
\draw baz ;
\end{scope}
RES

check Tikz->seq($baz, $seq), 'mods folding with clips 3', <<'RES';
\begin{scope}
\clip clip2 ;
\draw baz ;
\end{scope}
\begin{scope}
\clip clip1 ;
\draw foo ;
\draw bar ;
\end{scope}
RES

my $seq2 = Tikz->seq($seq, $baz)
               ->clip($clip1);

check $seq2, 'mods folding with clips 4', <<'RES';
\begin{scope}
\clip clip1 ;
\draw foo ;
\draw bar ;
\begin{scope}
\clip clip2 ;
\draw baz ;
\end{scope}
\end{scope}
RES

$seq2 = Tikz->seq($seq, $baz)
            ->clip($clip2);

check $seq2, 'mods folding with clips 5', <<'RES';
\begin{scope}
\clip clip2 ;
\begin{scope}
\clip clip1 ;
\draw foo ;
\draw bar ;
\end{scope}
\draw baz ;
\end{scope}
RES

$seq2->clip($clip1);

check $seq2, 'mods folding with clips 6', <<'RES';
\begin{scope}
\clip clip2 ;
\begin{scope}
\clip clip1 ;
\draw foo ;
\draw bar ;
\draw baz ;
\end{scope}
\end{scope}
RES

$seq2->mod(Tikz->color('red'));

check $seq2, 'mods folding with clips 7', <<'RES';
\begin{scope} [color=red]
\clip clip2 ;
\begin{scope}
\clip clip1 ;
\draw foo ;
\draw bar ;
\draw baz ;
\end{scope}
\end{scope}
RES

$seq2->layer('top');
$seq->layer('bottom');

check $seq2, 'mods folding with clips and layers', <<'RES';
\begin{pgfonlayer}{top}
\begin{scope} [color=red]
\clip clip2 ;
\begin{scope}
\clip clip1 ;
\begin{pgfonlayer}{bottom}
\begin{scope} [color=red]
\clip clip2 ;
\begin{scope}
\clip clip1 ;
\draw foo ;
\draw bar ;
\end{scope}
\end{scope}
\end{pgfonlayer}
\draw baz ;
\end{scope}
\end{scope}
\end{pgfonlayer}
RES

my $a = Tikz->point;
my $b = Tikz->point(4, 2);
my $c = Tikz->point(1, 3);
my $d = Tikz->point(2, 1);

my $r1 = Tikz->rectangle($a, $b);
my $r2 = Tikz->rectangle($c, $d);

$seq = eval {
 Tikz->seq(
  Tikz->raw("foo")
       ->clip($r1)
 )->clip($r2);
};
is $@, '', 'two intersecting rectangle clips doesn\'t croak';

check $seq, 'two intersecting rectangle clips', <<'RES';
\begin{scope}
\clip (1cm,3cm) rectangle (2cm,1cm) ;
\begin{scope}
\clip (0cm,0cm) rectangle (4cm,2cm) ;
\draw foo ;
\end{scope}
\end{scope}
RES

$r2 = Tikz->rectangle($a, $d); # $r2 is a subset of $r1

$seq = eval {
 Tikz->seq(
  Tikz->raw("foo")
       ->clip($r1)
 )->clip($r2);
};
is $@, '', 'two overlapping rectangle clips 1 doesn\'t croak';

check $seq, 'two overlapping rectangle clips 1', <<'RES';
\begin{scope}
\clip (0cm,0cm) rectangle (2cm,1cm) ;
\draw foo ;
\end{scope}
RES

$seq = eval {
 Tikz->seq(
  Tikz->raw("foo")
       ->clip($r2)
 )->clip($r1);
};
is $@, '', 'two overlapping rectangle clips 2 doesn\'t croak';

check $seq, 'two overlapping rectangle clips 2', <<'RES';
\begin{scope}
\clip (0cm,0cm) rectangle (4cm,2cm) ;
\begin{scope}
\clip (0cm,0cm) rectangle (2cm,1cm) ;
\draw foo ;
\end{scope}
\end{scope}
RES

my $c1 = Tikz->circle($a, 2);
my $c2 = Tikz->circle($d, 3);

$seq = eval {
 Tikz->seq(
  Tikz->raw("foo")
       ->clip($c1)
 )->clip($c2);
};
is $@, '', 'two intersecting circle clips doesn\'t croak';

check $seq, 'two intersecting circle clips', <<'RES';
\begin{scope}
\clip (2cm,1cm) circle (3cm) ;
\begin{scope}
\clip (0cm,0cm) circle (2cm) ;
\draw foo ;
\end{scope}
\end{scope}
RES

$c2 = Tikz->circle($a, 1); # $c2 is a subset of $c1

$seq = eval {
 Tikz->seq(
  Tikz->raw("foo")
       ->clip($c1)
 )->clip($c2);
};
is $@, '', 'two overlapping circle clips 1 doesn\'t croak';

check $seq, 'two overlapping circle clips 1', <<'RES';
\begin{scope}
\clip (0cm,0cm) circle (1cm) ;
\draw foo ;
\end{scope}
RES

$seq = eval {
 Tikz->seq(
  Tikz->raw("foo")
       ->clip($c2)
 )->clip($c1);
};
is $@, '', 'two overlapping circle clips 2 doesn\'t croak';

check $seq, 'two overlapping circle clips 2', <<'RES';
\begin{scope}
\clip (0cm,0cm) circle (2cm) ;
\begin{scope}
\clip (0cm,0cm) circle (1cm) ;
\draw foo ;
\end{scope}
\end{scope}
RES
