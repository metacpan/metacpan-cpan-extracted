#!perl -T

use strict;
use warnings;

use Test::More tests => 11 + 2 * 8;

use LaTeX::TikZ;

use lib 't/lib';
use LaTeX::TikZ::TestHelper;

using Tikz->formatter(
 format => '%d',
);

my $translate = eval {
 Tikz->functor(
  'LaTeX::TikZ::Set::Point' => sub {
   my ($functor, $set, $v) = @_;

   $set->new(
    point => [
     $set->x + $v->x,
     $set->y + $v->y,
    ],
    label => $set->label,
    pos   => $set->pos,
   );
  },
 );
};
is $@, '', 'creating a translator doesn\'t croak';

my $seq = Tikz->seq(
                 Tikz->point,
                 Tikz->raw('foo'),
                 Tikz->point(2),
                 Tikz->line(-1 => 3)
                     ->clip(Tikz->circle(1, 1)),
                 Tikz->union(
                  Tikz->chain(4 => '--' => [ -3, 2 ]),
                  Tikz->join('-|' => [ -1, 0 ], [ 0, 1 ]),
                 ),
                )
              ->clip(Tikz->rectangle([0, -1] => [2, 3]));

my $seq2 = eval {
 $seq->$translate(Tikz->point(-1, 1));
};
is $@, '', 'translating a sequence doesn\'t croak';

check $seq, 'the original sequence', <<'RES';
\begin{scope}
\clip (0cm,-1cm) rectangle (2cm,3cm) ;
\draw (0cm,0cm) ;
\draw foo ;
\draw (2cm,0cm) ;
\begin{scope}
\clip (1cm,0cm) circle (1cm) ;
\draw (-1cm,0cm) -- (3cm,0cm) ;
\end{scope}
\draw (4cm,0cm) -- (-3cm,2cm) (-1cm,0cm) -| (0cm,1cm) ;
\end{scope}
RES

check $seq2, 'the translated sequence', <<'RES';
\begin{scope}
\clip (-1cm,0cm) rectangle (1cm,4cm) ;
\draw (-1cm,1cm) ;
\draw foo ;
\draw (1cm,1cm) ;
\begin{scope}
\clip (0cm,1cm) circle (1cm) ;
\draw (-2cm,1cm) -- (2cm,1cm) ;
\end{scope}
\draw (3cm,1cm) -- (-4cm,3cm) (-2cm,1cm) -| (-1cm,2cm) ;
\end{scope}
RES

my $poly = Tikz->closed_polyline(
 [ 0, 0 ], [ 1, 0 ], [ 1, 1 ], [ 0, 1 ]
);

my $poly2 = eval {
 $poly->$translate(Tikz->point(-1, 1));
};
is $@, '', 'translating a polyline doesn\'t croak';

check $poly2, 'the translated polyline', <<'RES';
\draw (-1cm,1cm) -- (0cm,1cm) -- (0cm,2cm) -- (-1cm,2cm) -- cycle ;
RES

my $strip = eval {
 Tikz->functor(
  '+LaTeX::TikZ::Mod' => sub { return },
 );
};
is $@, '', 'creating a stripper doesn\'t croak';

$_->mod(Tikz->color('red')) for $seq2->kids;

my $seq3 = eval {
 $seq2->$strip;
};
is $@, '', 'stripping a sequence doesn\'t croak';

check $seq2, 'the original sequence', <<'RES';
\begin{scope} [color=red]
\clip (-1cm,0cm) rectangle (1cm,4cm) ;
\draw (-1cm,1cm) ;
\draw foo ;
\draw (1cm,1cm) ;
\begin{scope}
\clip (0cm,1cm) circle (1cm) ;
\draw (-2cm,1cm) -- (2cm,1cm) ;
\end{scope}
\draw (3cm,1cm) -- (-4cm,3cm) (-2cm,1cm) -| (-1cm,2cm) ;
\end{scope}
RES

check $seq3, 'the stripped sequence', <<'RES';
\draw (-1cm,1cm) ;
\draw foo ;
\draw (1cm,1cm) ;
\draw (-2cm,1cm) -- (2cm,1cm) ;
\draw (3cm,1cm) -- (-4cm,3cm) (-2cm,1cm) -| (-1cm,2cm) ;
RES

my $special = eval {
 Tikz->functor(
  '+LaTeX::TikZ::Mod' => sub { die "mod\n" },
  '+LaTeX::TikZ::Set' => sub { die "set\n" },
 );
};
is $@, '', 'creating a special functor with + rules doesn\'t croak';

eval { $seq->$special };
is $@, "set\n", 'special functor with + rules eats everything properly';

$special = eval {
 Tikz->functor(
  '+LaTeX::TikZ::Mod'       => sub { die "mod\n" },
  '+LaTeX::TikZ::Set'       => sub { die "set\n" },
  'LaTeX::TikZ::Set::Point' => sub { Tikz->point(7) },
  'LaTeX::TikZ::Set::Path'  => sub { Tikz->raw('moo') },
 );
};
is $@, '', 'creating a special functor with + and normal rules doesn\'t croak';

my $res = eval { Tikz->point(3, 4)->$special };
is $@, '', 'special functor with + and normal rules orders its rules properly';

check $res, 'the result of the special functor', <<'RES';
\draw (7cm,0cm) ;
RES

$res = eval { Tikz->raw('hlagh')->$special };
is $@, '',
      'special functor with + and normal rules orders its rules properly again';

check $res, 'the result of the special functor', <<'RES';
\draw moo ;
RES

using eval {
 Tikz->formatter(
  origin => [ -1, 1 ],
 );
};
is $@, '', 'creating a formatter object with an origin doesn\'t croak';

check $seq, 'a sequence translated by an origin', <<'RES';
\begin{scope}
\clip (-1cm,0cm) rectangle (1cm,4cm) ;
\draw (-1cm,1cm) ;
\draw foo ;
\draw (1cm,1cm) ;
\begin{scope}
\clip (0cm,1cm) circle (1cm) ;
\draw (-2cm,1cm) -- (2cm,1cm) ;
\end{scope}
\draw (3cm,1cm) -- (-4cm,3cm) (-2cm,1cm) -| (-1cm,2cm) ;
\end{scope}
RES
