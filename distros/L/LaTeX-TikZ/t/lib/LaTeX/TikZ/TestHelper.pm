package LaTeX::TikZ::TestHelper;

use strict;
use warnings;

use Test::More ();

use Mouse::Exporter;

Mouse::Exporter->setup_import_methods(
 as_is => [ qw<using check is_point_ok> ],
);

my $tikz;

sub using {
 $tikz = $_[0] if defined $_[0];

 return $tikz;
}

sub check {
 my ($set, $desc, $exp) = @_;

 local $Test::Builder::Level = $Test::Builder::Level + 1;

 my ($head, $decl, $body) = eval {
  $tikz->render(ref $set eq 'ARRAY' ? @$set : $set);
 };
 Test::More::is($@, '', "$desc: no error");

 unless (ref $exp eq 'ARRAY') {
  $exp = [ split /\n/, $exp ];
 }
 unshift @$exp, '\begin{tikzpicture}';
 push    @$exp, '\end{tikzpicture}';

 Test::More::is_deeply($body, $exp, "$desc: body");

 return $head, $decl, $body;
}

sub is_point_ok {
 my ($p, $x, $y, $desc) = @_;

 my $ok = Test::More::isa_ok($p, 'LaTeX::TikZ::Point', "$desc isa point");
 if ($ok) {
  Test::More::cmp_ok($p->x, '==', $x, "$desc x coordinate is right");
  Test::More::cmp_ok($p->y, '==', $y, "$desc y coordinate is right");
 } else {
  Test::More::fail("$desc placeholder $_") for 1, 2;
 }
}

1;
