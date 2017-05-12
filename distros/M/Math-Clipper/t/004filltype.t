use Math::Clipper ':all';
use Test::More tests=>4;

my $ai = [ #area = 16
[0,0],
[4,0],
[4,4],
[0,4]
];
my $bi = [#area = 4, is inside $ai
[1,1],
[3,1],
[3,3],
[1,3]
];
my $bir = [#area = 4 (negative if PFT_NONZERO), is inside $ai
[1,3],
[3,3],
[3,1],
[1,1]
];


my $clipper = Math::Clipper->new;
$clipper->use_full_coordinate_range(1);
$clipper->add_subject_polygon($ai);
$clipper->add_subject_polygon($bi);
my $result = $clipper->execute(CT_DIFFERENCE,PFT_EVENODD,PFT_EVENODD); # PFT_EVENODD is default, just being explicit here
ok(scalar(@{$result}) == 2,'EVENODD begets hole');
$clipper->clear();

$clipper->add_subject_polygon($ai);
$clipper->add_subject_polygon($bir);
$result = $clipper->execute(CT_DIFFERENCE,PFT_EVENODD,PFT_EVENODD); # PFT_EVENODD is default, just being explicit here
ok(scalar(@{$result}) == 2,'EVENODD still begets hole despite reversed inner polygon winding');
$clipper->clear();

$clipper->add_subject_polygon($ai);
$clipper->add_subject_polygon($bir);
$result = $clipper->execute(CT_DIFFERENCE,PFT_NONZERO,PFT_NONZERO);
ok(scalar(@{$result}) == 2,'NONZERO begets hole with inner polygon wound opposite to outer');
$clipper->clear();

$clipper->add_subject_polygon($ai);
$clipper->add_subject_polygon($bi);
$result = $clipper->execute(CT_DIFFERENCE,PFT_NONZERO,PFT_NONZERO);
ok(scalar(@{$result}) == 1,'NONZERO begets one polygon, when inner poly wound same as outside');
$clipper->clear();

