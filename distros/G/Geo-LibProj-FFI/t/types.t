#!perl
use strict;
use warnings;
use lib 'lib';

use Test::More;
use Test::Exception;
use Test::Warnings;

# Data types (particularly PJ_COORD)
# https://proj.org/development/reference/datatypes.html

plan tests => 13 + 13*2 + 1;

use Geo::LibProj::FFI qw( :all );


my ($a, $b, $c, $d, $v, $union, $struct);


# PJ_COORD: constructors

($a, $b, $c, $d) = (12.5, -34.5, 67.5, -89.5);

subtest 'PJ_LP new' => sub {
	plan tests => 2*3 + 4;
	lives_and { $struct = 0; ok $struct = Geo::LibProj::FFI::PJ_LP->new(); } 'empty';
	lives_and { is $struct->lam(), 0 } 'lam empty';
	lives_and { is $struct->phi(), 0 } 'phi empty';
	my $lp = { lam => $a, phi => $b };
	lives_and { $struct = 0; ok $struct = Geo::LibProj::FFI::PJ_LP->new({ lam => $a, phi => $b }); } 'new';
	lives_and { is $struct->lam(), $a } 'lam';
	lives_and { is $struct->phi(), $b } 'phi';
	lives_ok { $union = 0; $union = Geo::LibProj::FFI::PJ_COORD->new({ lp => $lp }) } 'new union';
	lives_and { is_deeply $union->v(), [$a, $b, 0, 0] } 'union array';
	lives_ok { $union = 0; $union = Geo::LibProj::FFI::PJ_COORD->new({ lp => $struct }) } 'new union struct';
	lives_and { is_deeply $union->v(), [$a, $b, 0, 0] } 'union struct array';
};

subtest 'PJ_XY new' => sub {
	plan tests => 2*3 + 4;
	lives_and { $struct = 0; ok $struct = Geo::LibProj::FFI::PJ_XY->new(); } 'new empty';
	is eval '$struct->x', 0, 'x empty';
	is eval '$struct->y', 0, 'y empty';
	my $xy = { 'x' => $a, 'y' => $b };
	lives_and { $struct = 0; ok $struct = Geo::LibProj::FFI::PJ_XY->new( $xy ); } 'new';
	is eval '$struct->x', $a, 'x';
	is eval '$struct->y', $b, 'y';
	lives_ok { $union = 0; $union = Geo::LibProj::FFI::PJ_COORD->new({ xy => $xy }) } 'new union';
	lives_and { is_deeply $union->v(), [$a, $b, 0, 0] } 'union array';
	lives_ok { $union = 0; $union = Geo::LibProj::FFI::PJ_COORD->new({ xy => $struct }) } 'new union struct';
	lives_and { is_deeply $union->v(), [$a, $b, 0, 0] } 'union struct array';
};

subtest 'PJ_UV new' => sub {
	plan tests => 2*3 + 4;
	lives_and { $struct = 0; ok $struct = Geo::LibProj::FFI::PJ_UV->new(); } 'new empty';
	lives_and { is $struct->u(), 0 } 'u empty';
	lives_and { is $struct->v(), 0 } 'v empty';
	my $uv = { u => $a, v => $b };
	lives_and { $struct = 0; ok $struct = Geo::LibProj::FFI::PJ_UV->new( $uv ); } 'new';
	lives_and { is $struct->u(), $a } 'u';
	lives_and { is $struct->v(), $b } 'v';
	lives_ok { $union = 0; $union = Geo::LibProj::FFI::PJ_COORD->new({ uv => $uv }) } 'new union';
	lives_and { is_deeply $union->v(), [$a, $b, 0, 0] } 'union array';
	lives_ok { $union = 0; $union = Geo::LibProj::FFI::PJ_COORD->new({ uv => $struct }) } 'new union struct';
	lives_and { is_deeply $union->v(), [$a, $b, 0, 0] } 'union struct array';
};

subtest 'PJ_LPZ new' => sub {
	plan tests => 2*4 + 4;
	lives_and { $struct = 0; ok $struct = Geo::LibProj::FFI::PJ_LPZ->new(); } 'new empty';
	lives_and { is $struct->lam(), 0 } 'lam empty';
	lives_and { is $struct->phi(), 0 } 'phi empty';
	lives_and { is $struct->z(), 0 } 'z empty';
	my $lpz = { lam => $a, phi => $b, z => $c };
	lives_and { $struct = 0; ok $struct = Geo::LibProj::FFI::PJ_LPZ->new( $lpz ); } 'new';
	lives_and { is $struct->lam(), $a } 'lam';
	lives_and { is $struct->phi(), $b } 'phi';
	lives_and { is $struct->z(), $c } 'z';
	lives_ok { $union = 0; $union = Geo::LibProj::FFI::PJ_COORD->new({ lpz => $lpz }) } 'new union';
	lives_and { is_deeply $union->v(), [$a, $b, $c, 0] } 'union array';
	lives_ok { $union = 0; $union = Geo::LibProj::FFI::PJ_COORD->new({ lpz => $struct }) } 'new union struct';
	lives_and { is_deeply $union->v(), [$a, $b, $c, 0] } 'union struct array';
};

subtest 'PJ_XYZ new' => sub {
	plan tests => 2*4 + 4;
	lives_and { $struct = 0; ok $struct = Geo::LibProj::FFI::PJ_XYZ->new(); } 'new empty';
	is eval '$struct->x', 0, 'x empty';
	is eval '$struct->y', 0, 'y empty';
	is eval '$struct->z', 0, 'z empty';
	my $xyz = { 'x' => $a, 'y' => $b, 'z' => $c };
	lives_and { $struct = 0; ok $struct = Geo::LibProj::FFI::PJ_XYZ->new( $xyz ); } 'new';
	is eval '$struct->x', $a, 'x';
	is eval '$struct->y', $b, 'y';
	is eval '$struct->z', $c, 'z';
	lives_ok { $union = 0; $union = Geo::LibProj::FFI::PJ_COORD->new({ xyz => $xyz }) } 'new union';
	lives_and { is_deeply $union->v(), [$a, $b, $c, 0] } 'union array';
	lives_ok { $union = 0; $union = Geo::LibProj::FFI::PJ_COORD->new({ xyz => $struct }) } 'new union struct';
	lives_and { is_deeply $union->v(), [$a, $b, $c, 0] } 'union struct array';
};

subtest 'PJ_UVW new' => sub {
	plan tests => 2*4 + 4;
	lives_and { $struct = 0; ok $struct = Geo::LibProj::FFI::PJ_UVW->new(); } 'new empty';
	lives_and { is $struct->u(), 0 } 'u empty';
	lives_and { is $struct->v(), 0 } 'v empty';
	lives_and { is $struct->w(), 0 } 'w empty';
	my $uvw = { u => $a, v => $b, w => $c };
	lives_and { $struct = 0; ok $struct = Geo::LibProj::FFI::PJ_UVW->new( $uvw ); } 'new';
	lives_and { is $struct->u(), $a } 'u';
	lives_and { is $struct->v(), $b } 'v';
	lives_and { is $struct->w(), $c } 'w';
	lives_ok { $union = 0; $union = Geo::LibProj::FFI::PJ_COORD->new({ uvw => $uvw }) } 'new union';
	lives_and { is_deeply $union->v(), [$a, $b, $c, 0] } 'union array';
	lives_ok { $union = 0; $union = Geo::LibProj::FFI::PJ_COORD->new({ uvw => $struct }) } 'new union struct';
	lives_and { is_deeply $union->v(), [$a, $b, $c, 0] } 'union struct array';
};

subtest 'PJ_LPZT new' => sub {
	plan tests => 2*5 + 4;
	lives_and { $struct = 0; ok $struct = Geo::LibProj::FFI::PJ_LPZT->new(); } 'new empty';
	lives_and { is $struct->lam(), 0 } 'lam empty';
	lives_and { is $struct->phi(), 0 } 'phi empty';
	lives_and { is $struct->z(), 0 } 'z empty';
	lives_and { is $struct->t(), 0 } 't empty';
	my $lpzt = { lam => $a, phi => $b, z => $c, t => $d };
	lives_and { $struct = 0; ok $struct = Geo::LibProj::FFI::PJ_LPZT->new( $lpzt ); } 'new';
	lives_and { is $struct->lam(), $a } 'lam';
	lives_and { is $struct->phi(), $b } 'phi';
	lives_and { is $struct->z(), $c } 'z';
	lives_and { is $struct->t(), $d } 't';
	lives_ok { $union = 0; $union = Geo::LibProj::FFI::PJ_COORD->new({ lpzt => $lpzt }) } 'new union';
	lives_and { is_deeply $union->v(), [$a, $b, $c, $d] } 'union array';
	lives_ok { $union = 0; $union = Geo::LibProj::FFI::PJ_COORD->new({ lpzt => $struct }) } 'new union struct';
	lives_and { is_deeply $union->v(), [$a, $b, $c, $d] } 'union struct array';
};

subtest 'PJ_XYZT new' => sub {
	plan tests => 2*5 + 4;
	lives_and { $struct = 0; ok $struct = Geo::LibProj::FFI::PJ_XYZT->new(); } 'new empty';
	is eval '$struct->x', 0, 'x empty';
	is eval '$struct->y', 0, 'y empty';
	is eval '$struct->z', 0, 'z empty';
	is eval '$struct->t', 0, 't empty';
	my $xyzt = { 'x' => $a, 'y' => $b, 'z' => $c, 't' => $d };
	lives_and { $struct = 0; ok $struct = Geo::LibProj::FFI::PJ_XYZT->new( $xyzt ); } 'new';
	is eval '$struct->x', $a, 'x';
	is eval '$struct->y', $b, 'y';
	is eval '$struct->z', $c, 'z';
	is eval '$struct->t', $d, 't';
	lives_ok { $union = 0; $union = Geo::LibProj::FFI::PJ_COORD->new({ xyzt => $xyzt }) } 'new union';
	lives_and { is_deeply $union->v(), [$a, $b, $c, $d] } 'union array';
	lives_ok { $union = 0; $union = Geo::LibProj::FFI::PJ_COORD->new({ xyzt => $struct }) } 'new union struct';
	lives_and { is_deeply $union->v(), [$a, $b, $c, $d] } 'union struct array';
};

subtest 'PJ_UVWT new' => sub {
	plan tests => 2*5 + 4;
	lives_and { $struct = 0; ok $struct = Geo::LibProj::FFI::PJ_UVWT->new(); } 'new empty';
	lives_and { is $struct->u(), 0 } 'u empty';
	lives_and { is $struct->v(), 0 } 'v empty';
	lives_and { is $struct->w(), 0 } 'w empty';
	lives_and { is $struct->t(), 0 } 't empty';
	my $uvwt = { u => $a, v => $b, w => $c, t => $d };
	lives_and { $struct = 0; ok $struct = Geo::LibProj::FFI::PJ_UVWT->new( $uvwt ); } 'new';
	lives_and { is $struct->u(), $a } 'u';
	lives_and { is $struct->v(), $b } 'v';
	lives_and { is $struct->w(), $c } 'w';
	lives_and { is $struct->t(), $d } 't';
	lives_ok { $union = 0; $union = Geo::LibProj::FFI::PJ_COORD->new({ uvwt => $uvwt }) } 'new union';
	lives_and { is_deeply $union->v(), [$a, $b, $c, $d] } 'union array';
	lives_ok { $union = 0; $union = Geo::LibProj::FFI::PJ_COORD->new({ uvwt => $struct }) } 'new union struct';
	lives_and { is_deeply $union->v(), [$a, $b, $c, $d] } 'union struct array';
};

subtest 'PJ_OPK new' => sub {
	plan tests => 2*4 + 4;
	lives_and { $struct = 0; ok $struct = Geo::LibProj::FFI::PJ_OPK->new(); } 'new empty';
	lives_and { is $struct->o(), 0 } 'o empty';
	lives_and { is $struct->p(), 0 } 'p empty';
	lives_and { is $struct->k(), 0 } 'k empty';
	my $opk = { o => $a, p => $b, k => $c };
	lives_and { $struct = 0; ok $struct = Geo::LibProj::FFI::PJ_OPK->new( $opk ); } 'new';
	lives_and { is $struct->o(), $a } 'o';
	lives_and { is $struct->p(), $b } 'p';
	lives_and { is $struct->k(), $c } 'k';
	lives_ok { $union = 0; $union = Geo::LibProj::FFI::PJ_COORD->new({ opk => $opk }) } 'new union';
	lives_and { is_deeply $union->v(), [$a, $b, $c, 0] } 'union array';
	lives_ok { $union = 0; $union = Geo::LibProj::FFI::PJ_COORD->new({ opk => $struct }) } 'new union struct';
	lives_and { is_deeply $union->v(), [$a, $b, $c, 0] } 'union struct array';
};

subtest 'PJ_ENU new' => sub {
	plan tests => 2*4 + 4;
	lives_and { $struct = 0; ok $struct = Geo::LibProj::FFI::PJ_ENU->new(); } 'new empty';
	lives_and { is $struct->e(), 0 } 'e empty';
	lives_and { is $struct->n(), 0 } 'n empty';
	lives_and { is $struct->u(), 0 } 'u empty';
	my $enu = { e => $a, n => $b, u => $c };
	lives_and { $struct = 0; ok $struct = Geo::LibProj::FFI::PJ_ENU->new( $enu ); } 'new';
	lives_and { is $struct->e(), $a } 'e';
	lives_and { is $struct->n(), $b } 'n';
	lives_and { is $struct->u(), $c } 'u';
	lives_ok { $union = 0; $union = Geo::LibProj::FFI::PJ_COORD->new({ enu => $enu }) } 'new union';
	lives_and { is_deeply $union->v(), [$a, $b, $c, 0] } 'union array';
	lives_ok { $union = 0; $union = Geo::LibProj::FFI::PJ_COORD->new({ enu => $struct }) } 'new union struct';
	lives_and { is_deeply $union->v(), [$a, $b, $c, 0] } 'union struct array';
};

subtest 'PJ_GEOD new' => sub {
	plan tests => 2*4 + 4;
	lives_and { $struct = 0; ok $struct = Geo::LibProj::FFI::PJ_GEOD->new(); } 'new empty';
	is eval '$struct->s', 0, 's empty';
	is eval '$struct->a1', 0, 'a1 empty';
	is eval '$struct->a2', 0, 'a2 empty';
	my $geod = { 's' => $a, 'a1' => $b, 'a2' => $c };
	lives_and { $struct = 0; ok $struct = Geo::LibProj::FFI::PJ_GEOD->new( $geod ); } 'new';
	is eval '$struct->s', $a, 's';
	is eval '$struct->a1', $b, 'a1';
	is eval '$struct->a2', $c, 'a2';
	lives_ok { $union = 0; $union = Geo::LibProj::FFI::PJ_COORD->new({ geod => $geod }) } 'new union';
	lives_and { is_deeply $union->v(), [$a, $b, $c, 0] } 'union array';
	lives_ok { $union = 0; $union = Geo::LibProj::FFI::PJ_COORD->new({ geod => $struct }) } 'new union struct';
	lives_and { is_deeply $union->v(), [$a, $b, $c, 0] } 'union struct array';
};

subtest 'PJ_COORD new v' => sub {
	plan tests => 6;
	lives_ok { $union = 0; $union = Geo::LibProj::FFI::PJ_COORD->new() } 'new empty';
	is_deeply $union->v(), [0, 0, 0, 0], 'v empty';
	lives_ok { $union = 0; $union = Geo::LibProj::FFI::PJ_COORD->new({ v => [] }) } 'new empty array';
	is_deeply $union->v(), [0, 0, 0, 0], 'v empty array';
	lives_ok { $union = 0; $union = Geo::LibProj::FFI::PJ_COORD->new({ v => [$a, $b, $c, $d] }) } 'new';
	lives_and { is_deeply $union->v(), [$a, $b, $c, $d] } 'v array';
	$union = proj_coord($a, $b, $c, $d) if ! $union;
};


# PJ_COORD: read and write values

lives_and { $struct = 0; ok $struct = $union->xyzt } 'xyzt';
subtest 'PJ_XYZT' => sub {
	plan skip_all => "(xyzt failed)" unless $struct;
	plan tests => 8;
	is eval '$struct->x', $a, 'x';
	is eval '$struct->y', $b, 'y';
	is eval '$struct->z', $c, 'z';
	is eval '$struct->t', $d, 't';
	lives_ok { eval '$struct->x('.++$a.')' } 'inc x';
	lives_ok { eval '$struct->y('.++$b.')' } 'inc y';
	lives_ok { eval '$struct->z('.++$c.')' } 'inc z';
	lives_ok { eval '$struct->t('.++$d.')' } 'inc t';
};

lives_and { $struct = 0; ok $struct = $union->uvwt } 'uvwt';
subtest 'PJ_UVWT' => sub {
	plan skip_all => "(uvwt failed)" unless $struct;
	plan tests => 8;
	lives_and { is $struct->u(), $a } 'u';
	lives_and { is $struct->v(), $b } 'v';
	lives_and { is $struct->w(), $c } 'w';
	lives_and { is $struct->t(), $d } 't';
	lives_ok { $struct->u(++$a) } 'inc u';
	lives_ok { $struct->v(++$b) } 'inc v';
	lives_ok { $struct->w(++$c) } 'inc w';
	lives_ok { $struct->t(++$d) } 'inc t';
};

lives_and { $struct = 0; ok $struct = $union->lpzt } 'lpzt';
subtest 'PJ_LPZT' => sub {
	plan skip_all => "(lpzt failed)" unless $struct;
	plan tests => 8;
	lives_and { is $struct->lam(), $a } 'lam';
	lives_and { is $struct->phi(), $b } 'phi';
	lives_and { is $struct->z(), $c } 'z';
	lives_and { is $struct->t(), $d } 't';
	lives_ok { $struct->lam(++$a) } 'inc lam';
	lives_ok { $struct->phi(++$b) } 'inc phi';
	lives_ok { $struct->z(++$c) } 'inc z';
	lives_ok { $struct->t(++$d) } 'inc t';
};

lives_and { $struct = 0; ok $struct = $union->geod } 'geod';
subtest 'PJ_GEOD' => sub {
	plan skip_all => "(geod failed)" unless $struct;
	plan tests => 6;
	is eval '$struct->s', $a, 's';
	is eval '$struct->a1', $b, 'a1';
	is eval '$struct->a2', $c, 'a2';
	lives_ok { eval '$struct->s('.++$a.')' } 'inc s';
	lives_ok { eval '$struct->a1('.++$b.')' } 'inc a1';
	lives_ok { eval '$struct->a2('.++$c.')' } 'inc a2';
};

lives_and { $struct = 0; ok $struct = $union->opk } 'opk';
subtest 'PJ_OPK' => sub {
	plan skip_all => "(opk failed)" unless $struct;
	plan tests => 6;
	lives_and { is $struct->o(), $a } 'o';
	lives_and { is $struct->p(), $b } 'p';
	lives_and { is $struct->k(), $c } 'k';
	lives_ok { $struct->o(++$a) } 'inc o';
	lives_ok { $struct->p(++$b) } 'inc p';
	lives_ok { $struct->k(++$c) } 'inc k';
};

lives_and { $struct = 0; ok $struct = $union->enu } 'enu';
subtest 'PJ_ENU' => sub {
	plan skip_all => "(enu failed)" unless $struct;
	plan tests => 6;
	lives_and { is $struct->e(), $a } 'e';
	lives_and { is $struct->n(), $b } 'n';
	lives_and { is $struct->u(), $c } 'u';
	lives_ok { $struct->e(++$a) } 'inc e';
	lives_ok { $struct->n(++$b) } 'inc n';
	lives_ok { $struct->u(++$c) } 'inc u';
};

lives_and { $struct = 0; ok $struct = $union->xyz } 'xyz';
subtest 'PJ_XYZ' => sub {
	plan skip_all => "(xyz failed)" unless $struct;
	plan tests => 6;
	is eval '$struct->x', $a, 'x';
	is eval '$struct->y', $b, 'y';
	is eval '$struct->z', $c, 'z';
	lives_ok { eval '$struct->x('.++$a.')' } 'inc x';
	lives_ok { eval '$struct->y('.++$b.')' } 'inc y';
	lives_ok { eval '$struct->z('.++$c.')' } 'inc z';
};

lives_and { $struct = 0; ok $struct = $union->uvw } 'uvw';
subtest 'PJ_UVW' => sub {
	plan skip_all => "(uvw failed)" unless $struct;
	plan tests => 6;
	lives_and { is $struct->u(), $a } 'u';
	lives_and { is $struct->v(), $b } 'v';
	lives_and { is $struct->w(), $c } 'w';
	lives_ok { $struct->u(++$a) } 'inc u';
	lives_ok { $struct->v(++$b) } 'inc v';
	lives_ok { $struct->w(++$c) } 'inc w';
};

lives_and { $struct = 0; ok $struct = $union->lpz } 'lpz';
subtest 'PJ_LPZ' => sub {
	plan skip_all => "(lpz failed)" unless $struct;
	plan tests => 6;
	lives_and { is $struct->lam(), $a } 'lam';
	lives_and { is $struct->phi(), $b } 'phi';
	lives_and { is $struct->z(), $c } 'z';
	lives_ok { $struct->lam(++$a) } 'inc lam';
	lives_ok { $struct->phi(++$b) } 'inc phi';
	lives_ok { $struct->z(++$c) } 'inc z';
};

lives_and { $struct = 0; ok $struct = $union->xy } 'xy';
subtest 'PJ_XY' => sub {
	plan skip_all => "(xy failed)" unless $struct;
	plan tests => 4;
	is eval '$struct->x', $a, 'x';
	is eval '$struct->y', $b, 'y';
	lives_ok { eval '$struct->x('.++$a.')' } 'inc x';
	lives_ok { eval '$struct->y('.++$b.')' } 'inc y';
};

lives_and { $struct = 0; ok $struct = $union->uv } 'uv';
subtest 'PJ_UV' => sub {
	plan skip_all => "(uv failed)" unless $struct;
	plan tests => 4;
	lives_and { is $struct->u(), $a } 'u';
	lives_and { is $struct->v(), $b } 'v';
	lives_ok { $struct->u(++$a) } 'inc u';
	lives_ok { $struct->v(++$b) } 'inc v';
};

lives_and { $struct = 0; ok $struct = $union->lp } 'lp';
subtest 'PJ_LP' => sub {
	plan skip_all => "(lp failed)" unless $struct;
	plan tests => 4;
	lives_and { is $struct->lam(), $a } 'lam';
	lives_and { is $struct->phi(), $b } 'phi';
	lives_ok { $struct->lam(++$a) } 'inc lam';
	lives_ok { $struct->phi(++$b) } 'inc phi';
};

lives_and { $v = 0; ok $v = $union->v } 'v';
subtest 'vector' => sub {
	plan skip_all => "(v failed)" unless $v;
	plan tests => 3;
	is_deeply $v, [$a, $b, $c, $d], 'v array';
	lives_ok { $union->v([ ++$a, ++$b, ++$c, ++$d ]) } 'inc v';
	is_deeply $union->v(), [25.5, -21.5, 77.5, -85.5], 'v array';
};


done_testing;
