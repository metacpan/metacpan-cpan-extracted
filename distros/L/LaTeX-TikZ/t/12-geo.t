#!perl -T

use strict;
use warnings;

use Test::More tests => (16 + 2 * 5) + 2 * (13 + 2 * 3);

use Math::Complex;

use LaTeX::TikZ;

use lib 't/lib';
use LaTeX::TikZ::TestHelper;

using Tikz->formatter(
 format => '%d',
);

sub failed_valid {
 my ($tc) = @_;
 qr/Validation failed for '\Q$tc\E'/;
}

my $o = Tikz->point(0);
my $z = Tikz->point(1+2*i);

# Line

my $l = eval {
 Tikz->line($o => $z);
};
is $@, '', 'creating a line from two TikZ points doesn\'t croak';

check $l, 'a line from two Tikz points', <<'RES';
\draw (0cm,0cm) -- (1cm,2cm) ;
RES

$l = eval {
 Tikz->line([-1,2] => 3-4*i);
};
is $@, '', 'creating a line from constants doesn\'t croak';

check $l, 'a line from two Tikz points', <<'RES';
\draw (-1cm,2cm) -- (3cm,-4cm) ;
RES

# Arrow

my $ar = eval {
 Tikz->arrow($o, 1);
};
is $@, '', 'creating an arrow from two points doesn\'t croak';

check $ar, 'an arrow from two points', <<'RES';
\draw [->] (0cm,0cm) -- (1cm,0cm) ;
RES

$ar = eval {
 Tikz->arrow(2, dir => -i());
};
is $@, '', 'creating an arrow from a point and a direction doesn\'t croak';

check $ar, 'an arrow from a point and a direction', <<'RES';
\draw [->] (2cm,0cm) -- (2cm,-1cm) ;
RES

# Polyline

my $w = Tikz->point(3, -4);

for my $closed (0, 1) {
 my $polyline = $closed ? 'closed_polyline' : 'polyline';
 my $cycle    = $closed ? '-- cycle '       : '';
 my $desc     = $closed ? 'closed polyline' : 'polyline';

 my $pl = eval {
  Tikz->$polyline($o, $z);
 };
 is $@, '', "creating a $desc from two Tikz points doesn't croak";

 check $pl, "a $desc from two Tikz points", <<"RES";
\\draw (0cm,0cm) -- (1cm,2cm) $cycle;
RES

 $pl = eval {
  Tikz->$polyline($o, $z, $w);
 };
 is $@, '', "creating a $desc from three Tikz points doesn't croak";

 check $pl, "a $desc from three Tikz points", <<"RES";
\\draw (0cm,0cm) -- (1cm,2cm) -- (3cm,-4cm) $cycle;
RES

 $pl = eval {
  Tikz->$polyline(-1, (2-3*i), [-4, 5]);
 };
 is $@, '', "creating a $desc from three Tikz points doesn't croak";

 check $pl, "a $desc from three Tikz points", <<"RES";
\\draw (-1cm,0cm) -- (2cm,-3cm) -- (-4cm,5cm) $cycle;
RES

 $pl = eval {
  Tikz->$polyline($o);
 };
 like $@, qr/at least two LaTeX::TikZ::Set::Point objects are needed in order to build a polyline/, "creating a $desc from only one Tikz point croaks";

 $pl = eval {
  Tikz->$polyline(qw<foo bar>);
 };
 like $@, failed_valid('LaTeX::TikZ::Point::Autocoerce'), "creating a $desc from two string croaks";
}

# Rectangle

my $r = eval {
 Tikz->rectangle($o => $z);
};
is $@, '', 'creating a rectangle from two TikZ points doesn\'t croak';

check $r, 'a rectangle from two Tikz points', <<'RES';
\draw (0cm,0cm) rectangle (1cm,2cm) ;
RES

$r = eval {
 Tikz->rectangle([-1,2] => 3-4*i);
};
is $@, '', 'creating a rectangle from constants doesn\'t croak';

check $r, 'a rectangle from two Tikz points', <<'RES';
\draw (-1cm,2cm) rectangle (3cm,-4cm) ;
RES

$r = eval {
 Tikz->rectangle($z => -3);
};
is $@, '', 'creating a rectangle from a TikZ point and a constant doesn\'t croak';

check $r, 'a rectangle from a TikZ point and a constant', <<'RES';
\draw (1cm,2cm) rectangle (-3cm,0cm) ;
RES

$r = eval {
 Tikz->rectangle($o => { width => 3, height => -4 });
};
is $@, '', 'creating a rectangle from a TikZ point and width/height doesn\'t croak';

check $r, 'a rectangle from a TikZ point and width/height', <<'RES';
\draw (0cm,0cm) rectangle (3cm,-4cm) ;
RES

$r = eval {
 Tikz->rectangle((-1+2*i) => { width => 3, height => -4 });
};
is $@, '', 'creating a rectangle from a constant and width/height doesn\'t croak';

check $r, 'a rectangle from a constant and width/height', <<'RES';
\draw (-1cm,2cm) rectangle (2cm,-2cm) ;
RES

# Circle

my $c = eval {
 Tikz->circle($z => 3);
};
is $@, '', 'creating a circle from a TikZ point and a constant doesn\'t croak';

check $c, 'a circle from a Tikz point and a constant', <<'RES';
\draw (1cm,2cm) circle (3cm) ;
RES

$c = eval {
 Tikz->circle([-1,2] => 3);
};
is $@, '', 'creating a circle from an array ref and a constant doesn\'t croak';

check $c, 'a circle from an array ref and a constant', <<'RES';
\draw (-1cm,2cm) circle (3cm) ;
RES

$c = eval {
 Tikz->circle((4-5*i) => 3);
};
is $@, '', 'creating a circle from a complex and a constant doesn\'t croak';

check $c, 'a circle from a complex and a constant', <<'RES';
\draw (4cm,-5cm) circle (3cm) ;
RES

eval {
 Tikz->circle($o => -1);
};
like $@, failed_valid('__ANON__'),
                              'creating a circle with a negative radius croaks';

# Arc

using Tikz->formatter(
 format => "%.03f"
);

my $arc = eval {
 Tikz->arc(1, i, $o);
};
is $@, '', 'creating a simple arc doesn\'t croak';

check $arc, 'simple arc', <<'RES';
\begin{scope}
\clip (0.969cm,0.000cm) -- (1.085cm,0.000cm) -- (1.032cm,0.335cm) -- (0.878cm,0.638cm) -- (0.638cm,0.878cm) -- (0.335cm,1.032cm) -- (0.000cm,1.085cm) -- (0.000cm,0.969cm) -- cycle ;
\draw (0.000cm,0.000cm) circle (1.000cm) ;
\end{scope}
RES

eval {
 Tikz->arc(0, 1);
};
my $err = quotemeta 'Tikz->arc($first_point, $second_point, $center)';
like $@, qr/^$err/, 'creating an arc from only two points croaks';

eval {
 Tikz->arc(0, 1, i);
};
like $@, qr/The two first points aren't on a circle of center the last/,
         'creating an arc with two points not on a circle of center c croaks';
