#!perl -w

use strict;
no strict "vars";

use Math::MatrixBool;

# ======================================================================
#   $product = $matrix1->Multiplication($matrix2);
#   $kleene = $matrix->Kleene();
#   $transpose->Transpose($matrix);
# ======================================================================

print "1..73\n";

$n = 1;

$a = Math::MatrixBool->new_from_string(<<"MATRIX");
[ 0 1 1 1 ]
[ 1 0 1 1 ]
[ 0 1 0 1 ]
[ 1 0 0 1 ]
MATRIX

if (ref($a) eq 'Math::MatrixBool')
{ print "ok $n\n"; } else { print "not ok $n\n"; }
$n++;

$b = Math::MatrixBool->new_from_string(<<"MATRIX");
[ 0 0 0 1 ]
[ 0 0 1 0 ]
[ 0 1 0 0 ]
[ 1 0 0 0 ]
MATRIX

if (ref($b) eq 'Math::MatrixBool')
{ print "ok $n\n"; } else { print "not ok $n\n"; }
$n++;

$d = Math::MatrixBool->new_from_string(<<"MATRIX");
[ 1 1 1 0 ]
[ 1 1 0 1 ]
[ 1 0 1 0 ]
[ 1 0 0 1 ]
MATRIX

if (ref($d) eq 'Math::MatrixBool')
{ print "ok $n\n"; } else { print "not ok $n\n"; }
$n++;

$e = Math::MatrixBool->new_from_string(<<"MATRIX");
[ 1 0 0 1 ]
[ 0 1 0 1 ]
[ 1 0 1 1 ]
[ 0 1 1 1 ]
MATRIX

if (ref($e) eq 'Math::MatrixBool')
{ print "ok $n\n"; } else { print "not ok $n\n"; }
$n++;

$c = $a->Multiplication($b);

if ($c->equal($d))
{ print "ok $n\n"; } else { print "not ok $n\n"; }
$n++;

$c = $b * $a;

if ($c->equal($e))
{ print "ok $n\n"; } else { print "not ok $n\n"; }
$n++;

$matrix = Math::MatrixBool->new_from_string(<<"MATRIX");
[ 0 1 0 0 0 0 0 0 ]
[ 0 0 1 0 0 0 0 0 ]
[ 0 0 0 0 0 1 0 0 ]
[ 1 0 0 0 0 0 0 0 ]
[ 0 0 0 0 0 0 0 1 ]
[ 0 0 0 1 0 0 0 0 ]
[ 0 0 0 0 0 1 0 0 ]
[ 0 0 0 0 0 0 1 0 ]
MATRIX

if (ref($matrix) eq 'Math::MatrixBool')
{ print "ok $n\n"; } else { print "not ok $n\n"; }
$n++;

$test = Math::MatrixBool->new_from_string(<<"MATRIX");
[ 1 1 1 1 0 1 0 0 ]
[ 1 1 1 1 0 1 0 0 ]
[ 1 1 1 1 0 1 0 0 ]
[ 1 1 1 1 0 1 0 0 ]
[ 1 1 1 1 1 1 1 1 ]
[ 1 1 1 1 0 1 0 0 ]
[ 1 1 1 1 0 1 1 0 ]
[ 1 1 1 1 0 1 1 1 ]
MATRIX

if (ref($test) eq 'Math::MatrixBool')
{ print "ok $n\n"; } else { print "not ok $n\n"; }
$n++;

$kleene = $matrix->Kleene();

if ($kleene->equal($test))
{ print "ok $n\n"; } else { print "not ok $n\n"; }
$n++;

$sample = $kleene->Clone();

if ($kleene->equal($sample))
{ print "ok $n\n"; } else { print "not ok $n\n"; }
$n++;

$prod = $matrix->Shadow();
$sum = $matrix->Shadow();

$prod->One();
$sum->One();

for ( $i = 0; $i < 7; $i++ )
{
    if (! $sum->equal($test))
    { print "ok $n\n"; } else { print "not ok $n\n"; }
    $n++;

    $prod = $prod->Multiplication($matrix);
    $sum->Union($sum,$prod);
}

if ($sum->equal($test))
{ print "ok $n\n"; } else { print "not ok $n\n"; }
$n++;

&check_product();

$matrix->Bit_On(3,5);

$test = $matrix->Shadow();
$test->Fill();

$kleene = $matrix->Kleene();

if ($kleene->equal($test))
{ print "ok $n\n"; } else { print "not ok $n\n"; }
$n++;

$prod = $matrix->Shadow();
$sum = $matrix->Shadow();

$prod->One();
$sum->One();

for ( $i = 0; $i < 7; $i++ )
{
    if (! $sum->equal($test))
    { print "ok $n\n"; } else { print "not ok $n\n"; }
    $n++;

    $prod *= $matrix;
    $sum |= $prod;
}

if ($sum->equal($test))
{ print "ok $n\n"; } else { print "not ok $n\n"; }
$n++;

&check_product();

$x1 = Math::MatrixBool->new_from_string(<<"MATRIX");
[ 1 1 0 ]
[ 1 1 1 ]
[ 1 0 1 ]
MATRIX

if (ref($x1) eq 'Math::MatrixBool')
{ print "ok $n\n"; } else { print "not ok $n\n"; }
$n++;

$x2 = Math::MatrixBool->new_from_string(<<"MATRIX");
[ 1 1 0 1 ]
[ 0 1 1 1 ]
[ 0 1 1 0 ]
[ 1 1 0 0 ]
MATRIX

if (ref($x2) eq 'Math::MatrixBool')
{ print "ok $n\n"; } else { print "not ok $n\n"; }
$n++;

$y = Math::MatrixBool->new_from_string(<<"MATRIX");
[ 1 1 0 0 ]
[ 0 1 1 0 ]
[ 1 0 1 1 ]
MATRIX

if (ref($y) eq 'Math::MatrixBool')
{ print "ok $n\n"; } else { print "not ok $n\n"; }
$n++;

$z = Math::MatrixBool->new_from_string(<<"MATRIX");
[ 0 1 1 ]
[ 1 0 1 ]
[ 0 1 0 ]
[ 1 0 0 ]
MATRIX

if (ref($z) eq 'Math::MatrixBool')
{ print "ok $n\n"; } else { print "not ok $n\n"; }
$n++;

$r = $y * $z;

if ($r->equal($x1))
{ print "ok $n\n"; } else { print "not ok $n\n"; }
$n++;

$r = $z * $y;

if ($r->equal($x2))
{ print "ok $n\n"; } else { print "not ok $n\n"; }
$n++;

$r = $a->Shadow();
$temp = ~$a;
$r->Transpose($temp);

if (! $temp->equal($a))
{ print "ok $n\n"; } else { print "not ok $n\n"; }
$n++;
if ($r->equal($a))
{ print "ok $n\n"; } else { print "not ok $n\n"; }
$n++;

$r = $b->Shadow();
$temp = ~$b;
$r->Transpose($temp);

if ($temp->equal($b)) # symmetric!
{ print "ok $n\n"; } else { print "not ok $n\n"; }
$n++;
if ($r->equal($b))
{ print "ok $n\n"; } else { print "not ok $n\n"; }
$n++;

$r = $c->Shadow();
$temp = ~$c;
$r->Transpose($temp);

if (! $temp->equal($c))
{ print "ok $n\n"; } else { print "not ok $n\n"; }
$n++;
if ($r->equal($c))
{ print "ok $n\n"; } else { print "not ok $n\n"; }
$n++;

$r = $d->Shadow();
$temp = ~$d;
$r->Transpose($temp);

if (! $temp->equal($d))
{ print "ok $n\n"; } else { print "not ok $n\n"; }
$n++;
if ($r->equal($d))
{ print "ok $n\n"; } else { print "not ok $n\n"; }
$n++;

$r = $e->Shadow();
$temp = ~$e;
$r->Transpose($temp);

if (! $temp->equal($e))
{ print "ok $n\n"; } else { print "not ok $n\n"; }
$n++;
if ($r->equal($e))
{ print "ok $n\n"; } else { print "not ok $n\n"; }
$n++;

$r = $x1->Shadow();
$temp = ~$x1;
$r->Transpose($temp);

if (! $temp->equal($x1))
{ print "ok $n\n"; } else { print "not ok $n\n"; }
$n++;
if ($r->equal($x1))
{ print "ok $n\n"; } else { print "not ok $n\n"; }
$n++;

$r = $x2->Shadow();
$temp = ~$x2;
$r->Transpose($temp);

if (! $temp->equal($x2))
{ print "ok $n\n"; } else { print "not ok $n\n"; }
$n++;
if ($r->equal($x2))
{ print "ok $n\n"; } else { print "not ok $n\n"; }
$n++;

$r = $y->Shadow();
$temp = ~$y;
$r->Transpose($temp);

if ($r->equal($y))
{ print "ok $n\n"; } else { print "not ok $n\n"; }
$n++;

$r = $z->Shadow();
$temp = ~$z;
$r->Transpose($temp);

if ($r->equal($z))
{ print "ok $n\n"; } else { print "not ok $n\n"; }
$n++;

$r = $matrix->Shadow();
$temp = ~$matrix;
$r->Transpose($temp);

if (! $temp->equal($matrix))
{ print "ok $n\n"; } else { print "not ok $n\n"; }
$n++;
if ($r->equal($matrix))
{ print "ok $n\n"; } else { print "not ok $n\n"; }
$n++;

$r = $kleene->Shadow();
$temp = ~$kleene;
$r->Transpose($temp);

if ($temp->equal($kleene)) # symmetric!
{ print "ok $n\n"; } else { print "not ok $n\n"; }
$n++;
if ($r->equal($kleene))
{ print "ok $n\n"; } else { print "not ok $n\n"; }
$n++;

$test = $sample->Clone();

if ($sample->equal($test))
{ print "ok $n\n"; } else { print "not ok $n\n"; }
$n++;

$sample->Transpose($sample);

if (! $sample->equal($test))
{ print "ok $n\n"; } else { print "not ok $n\n"; }
$n++;

$sample->Transpose($sample);

if ($sample->equal($test))
{ print "ok $n\n"; } else { print "not ok $n\n"; }
$n++;

eval { $y->Transpose($y); };

if ($@ =~ /Math::MatrixBool::Transpose\(\): matrix size mismatch/)
{ print "ok $n\n"; } else { print "not ok $n\n"; }
$n++;

eval { $y->[0]->Transpose($y->[1],$y->[2],$y->[0],$y->[1],$y->[2]); };

if ($@ =~ /Bit::Vector::Transpose\(\): matrix size mismatch/)
{ print "ok $n\n"; } else { print "not ok $n\n"; }
$n++;

eval { $y->[0]->Transpose($y->[2],$y->[1],$y->[0],$y->[1],$y->[2]); };

if ($@ =~ /Bit::Vector::Transpose\(\): not a square matrix/)
{ print "ok $n\n"; } else { print "not ok $n\n"; }
$n++;

exit;

sub check_product
{
    my($prod,$base,$i);

    $prod = $matrix->Clone();
    $base = $matrix->Shadow();
    $base->One();
    $prod->Union($prod,$base);
    $base->Copy($prod);

    for ( $i = 0; $i < 6; $i++ )
    {
        if (! $prod->equal($test))
        { print "ok $n\n"; } else { print "not ok $n\n"; }
        $n++;

        $prod = $prod->Product($base);
    }

    if ($prod->equal($test))
    { print "ok $n\n"; } else { print "not ok $n\n"; }
    $n++;
}

__END__

