use Math::Clipper ':all';
use Test::More tests=>7;

#my $ai = [
#[-900359890780731,536870912000000],
#[0,-1073741824000000],
#[900359890780731,536870912000000]
#];
#my $bi = [
#[-900359890780731,-536870912000000],
#[900359890780731,-536870912000000],
#[0,1073741824000000]
#];

my $ai = [
[-15 ,  20],
[  0 , -40],
[ 15 ,  20]
];
my $bi = [
[-15 , -20],
[ 15 , -20],
[  0 ,  40]
];

my $triarea=100;

my $clipper = Math::Clipper->new;
$clipper->use_full_coordinate_range(1);
$clipper->add_subject_polygon($ai);
$clipper->add_clip_polygon($bi);
my $result = $clipper->execute(CT_DIFFERENCE);
ok(
  scalar(@{$result})==3,
  'DIFFERENCE should give three polygons'
  );
ok(
  3*$triarea == area_sum($result) ,
  'DIFFERENCE areas are reasonable'
  );

$clipper->clear();
$clipper->add_subject_polygon($ai);
$clipper->add_clip_polygon($bi);
$result = $clipper->execute(CT_UNION);
ok(
  scalar(@{$result})==1,
  'UNION should give one polygon'
  );
ok(
  12*$triarea == area_sum($result) ,
  'UNION area is reasonable'
  );

$clipper->clear();
$clipper->add_subject_polygon($ai);
$clipper->add_clip_polygon($bi);
$result = $clipper->execute(CT_XOR);
# xor of test gives two polygons, each with two shared points between triangles, but that might
# not be reliable or desired. It's a Clipper issue though, and might change with new versions
# so don't want to count result polygons for xor
ok(
  6*$triarea == area_sum($result) ,  
  'XOR area is reasonable'
  );

$clipper->clear();
$clipper->add_subject_polygon($ai);
$clipper->add_clip_polygon($bi);
$result = $clipper->execute(CT_INTERSECTION);
ok(
  scalar(@{$result})==1,
  'INTERSECTION should give one polygon'
  );
ok(
  6*$triarea == area_sum($result) ,
  'INTERSECTION area is reasonable'
  );

sub area_sum {
    my $polys=shift;
    my $ret = 0;
    map {$ret+=Math::Clipper::area($_)} @{$polys};
    return $ret;
    }