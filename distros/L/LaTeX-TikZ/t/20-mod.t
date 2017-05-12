#!perl -T

use strict;
use warnings;

use Test::More tests => 23 + 2 * 24;

use LaTeX::TikZ;

use lib 't/lib';
use LaTeX::TikZ::TestHelper;

using Tikz->formatter(
 format => '%d',
);

my $red = eval {
 Tikz->color('red');
};
is $@, '', 'creating a color mod doesn\'t croak';

my $foo = eval {
 Tikz->raw('foo')
     ->mod($red)
};
is $@, '', 'creating a modded raw set doesn\'t croak';

check $foo, 'one modded raw set', <<'RES';
\draw [color=red] foo ;
RES

my $foo2 = eval {
 Tikz->raw('foo')
     ->mod('->')
};
is $@, '', 'creating a modded raw set from a string doesn\'t croak';

check $foo2, 'one modded raw set from a string', <<'RES';
\draw [->] foo ;
RES

sub failed_valid {
 my ($tc) = @_;
 qr/Validation failed for '\Q$tc\E'/;
}

eval {
 Tikz->raw([ 'fail' ])
     ->mod(Tikz->raw('epic'));
};
like $@, failed_valid('LaTeX::TikZ::Mod'), 'trying to use a non LTM mod croaks';

my $scale = eval {
 Tikz->scale(2);
};
is $@, '', 'creating a scale mod doesn\'t croak';

$foo2 = eval {
 Tikz->raw('foo')
     ->mod($scale);
};
is $@, '', 'applying a scale mod doesn\'t croak';

check $foo2, 'a raw set with a scale mod', <<'RES';
\draw [scale=2.000] foo ;
RES

$foo2 = eval {
 Tikz->union(
  Tikz->raw('foo')
      ->mod($scale),
 )->mod(Tikz->scale(4));
};
is $@, '', 'applying two scale mods doesn\'t croak';

check $foo2, 'a union of a raw set with two scale mods', <<'RES';
\draw [scale=4.000] foo ;
RES

my $width = eval {
 Tikz->width(25);
};
is $@, '', 'creating a width mod doesn\'t croak';

eval {
 $foo->mod($width);
};
is $@, '', 'adding another mod doesn\'t croak';

check $foo, 'one double modded raw set', <<'RES';
\draw [color=red,line width=4.0pt] foo ;
RES

eval {
 $foo->mod($red);
};
is $@, '', 're-adding an previously set mod doesn\'t croak';

check $foo, 'one triple modded raw set (with duplicates)', <<'RES';
\draw [color=red,line width=4.0pt] foo ;
RES

my $bar = Tikz->raw('bar');
$foo = eval {
 Tikz->seq(
  Tikz->raw('foo'),
  $bar
 )->mod($red, $width);
};
is $@, '', 'setting two mods in a row doesn\'t croak';

check $foo, 'one triple modded sequence of raw sets', <<'RES';
\begin{scope} [color=red,line width=4.0pt]
\draw foo ;
\draw bar ;
\end{scope}
RES

my $nested = eval {
 Tikz->seq(
  Tikz->seq(Tikz->raw("foo"))
      ->mod($red)
 )->mod($width)
};
is $@, '', 'creating nested modded sequences doesn\'t croak';

check $nested, 'nested modded sequences', <<'RES';
\draw [line width=4.0pt,color=red] foo ;
RES

my $baz = eval {
 Tikz->raw('baz')
     ->mod($red);
};
is $@, '', 'creating another colored raw set doesn\'t croak';

check Tikz->seq($foo, $baz), 'mods folding 1', <<'RES';
\begin{scope} [color=red]
\begin{scope} [line width=4.0pt]
\draw foo ;
\draw bar ;
\end{scope}
\draw baz ;
\end{scope}
RES

check Tikz->seq($baz, $foo), 'mods folding 2', <<'RES';
\begin{scope} [color=red]
\draw baz ;
\begin{scope} [line width=4.0pt]
\draw foo ;
\draw bar ;
\end{scope}
\end{scope}
RES

my $qux = eval {
 Tikz->raw('qux')
     ->mod($width);
};
is $@, '', 'creating another raw set with modded width doesn\'t croak';

check Tikz->seq($foo, $baz, $qux), 'mods folding 3', <<'RES';
\begin{scope} [color=red]
\begin{scope} [line width=4.0pt]
\draw foo ;
\draw bar ;
\end{scope}
\draw baz ;
\end{scope}
\draw [line width=4.0pt] qux ;
RES

check Tikz->seq($foo, $qux, $baz), 'mods folding 4', <<'RES';
\begin{scope} [line width=4.0pt]
\begin{scope} [color=red]
\draw foo ;
\draw bar ;
\end{scope}
\draw qux ;
\end{scope}
\draw [color=red] baz ;
RES

check Tikz->seq($baz, $foo, $qux), 'mods folding 5', <<'RES';
\begin{scope} [color=red]
\draw baz ;
\begin{scope} [line width=4.0pt]
\draw foo ;
\draw bar ;
\end{scope}
\end{scope}
\draw [line width=4.0pt] qux ;
RES

check Tikz->seq($baz, $qux, $foo), 'mods folding 6', <<'RES';
\draw [color=red] baz ;
\draw [line width=4.0pt] qux ;
\begin{scope} [color=red,line width=4.0pt]
\draw foo ;
\draw bar ;
\end{scope}
RES

check Tikz->seq($qux, $foo, $baz), 'mods folding 7', <<'RES';
\begin{scope} [line width=4.0pt]
\draw qux ;
\begin{scope} [color=red]
\draw foo ;
\draw bar ;
\end{scope}
\end{scope}
\draw [color=red] baz ;
RES

check Tikz->seq($qux, $baz, $foo), 'mods folding 8', <<'RES';
\draw [line width=4.0pt] qux ;
\draw [color=red] baz ;
\begin{scope} [color=red,line width=4.0pt]
\draw foo ;
\draw bar ;
\end{scope}
RES

my $seq = eval {
 Tikz->seq($foo, $qux, $baz)
     ->mod($red);
};
is $@, '', 'creating a modded sequence set doesn\'t croak';

check $seq, 'mod covering 1', <<'RES';
\begin{scope} [color=red]
\begin{scope} [line width=4.0pt]
\draw foo ;
\draw bar ;
\draw qux ;
\end{scope}
\draw baz ;
\end{scope}
RES

my $seq2 = eval {
 Tikz->seq($seq, $qux)
     ->mod(Tikz->color('blue'));
};
is $@, '', 'creating another modded sequence set doesn\'t croak';

check $seq2, 'mod covering 2', <<'RES';
\begin{scope} [color=blue]
\begin{scope} [color=red]
\begin{scope} [line width=4.0pt]
\draw foo ;
\draw bar ;
\draw qux ;
\end{scope}
\draw baz ;
\end{scope}
\draw [line width=4.0pt] qux ;
\end{scope}
RES

eval {
 $foo->mod(Tikz->raw_mod('raw1'));
 $seq->mod(Tikz->raw_mod('raw2'));
};
is $@, '', 'creating and adding raw mods doesn\'t croak';

check $seq, 'mod covering 3', <<'RES';
\begin{scope} [color=red,raw2]
\begin{scope} [line width=4.0pt]
\begin{scope} [raw1]
\draw foo ;
\draw bar ;
\end{scope}
\draw qux ;
\end{scope}
\draw baz ;
\end{scope}
RES

eval {
 $baz->mod(Tikz->raw_mod($_)) for qw<raw2 raw3>;
};
is $@, '', 'creating and adding another raw mod doesn\'t croak';

check $seq, 'mod covering 4', <<'RES';
\begin{scope} [color=red,raw2]
\begin{scope} [line width=4.0pt]
\begin{scope} [raw1]
\draw foo ;
\draw bar ;
\end{scope}
\draw qux ;
\end{scope}
\draw [raw2,raw3] baz ;
\end{scope}
RES

eval {
 $bar->mod(Tikz->width(50));
};
is $@, '', 'creating and adding another width mod doesn\'t croak';

check $seq, 'mod covering 5', <<'RES';
\begin{scope} [color=red,raw2]
\begin{scope} [line width=4.0pt]
\begin{scope} [raw1]
\draw foo ;
\draw [line width=8.0pt] bar ;
\end{scope}
\draw qux ;
\end{scope}
\draw [raw2,raw3] baz ;
\end{scope}
RES

my ($fred, $fblue) = eval {
 map Tikz->fill($_), qw<red blue>;
};
is $@, '', 'creating two fill mods doesn\'t croak';

$seq = eval {
 Tikz->seq(
  Tikz->raw("foo")
      ->mod($fred)
 )->mod($fred);
};
is $@, '', 'creating a structure with two identical fill mods doesn\'t croak';

check $seq, 'mod covering 6', <<'RES';
\draw [fill=red] foo ;
RES

$seq = eval {
 Tikz->seq(
  Tikz->raw("foo")
      ->mod($fblue)
 )->mod($fred);
};
is $@, '', 'creating a structure with two different fill mods doesn\'t croak';

check $seq, 'mod covering 7', <<'RES';
\draw [fill=red,fill=blue] foo ;
RES

$seq = eval {
 Tikz->seq(
  Tikz->raw("foo")
      ->mod($red)
 )->mod($fred);
};
is $@, '', 'creating a structure with color and fill mods doesn\'t croak';

check $seq, 'mod covering 8', <<'RES';
\draw [fill=red,color=red] foo ;
RES
