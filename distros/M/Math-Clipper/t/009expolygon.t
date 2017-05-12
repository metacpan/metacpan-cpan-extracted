use Math::Clipper ':all';
use Test::More tests=>6;
use Test::Deep;

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
$clipper->add_subject_polygon($ai);
$clipper->add_subject_polygon($bi);
my $result = $clipper->ex_execute(CT_DIFFERENCE,PFT_EVENODD,PFT_EVENODD); # PFT_EVENODD is default, just being explicit here
is(scalar(@{$result}),1,'one expolygon with outer and holes');
cmp_bag($result->[0]->{outer},$ai,'outer same as original outer');
#diag("\nmany?:".scalar(@{$result->[0]->{holes}})."\n");
cmp_bag($result->[0]->{holes}->[0],$bi,'holes[0] same as original hole');
$clipper->clear();

#same, but with PFT_NONZERO fill strategy
$clipper->add_subject_polygon($ai);
$clipper->add_subject_polygon($bir);
$result = $clipper->ex_execute(CT_DIFFERENCE,PFT_NONZERO,PFT_NONZERO);
is(scalar(@{$result}),1,'one expolygon with outer and holes');
cmp_bag($result->[0]->{outer},$ai,'outer same as original outer');
#diag("\nmany?:".scalar(@{$result->[0]->{holes}})."\n");
cmp_bag($result->[0]->{holes}->[0],$bi,'holes[0] same as original hole');
$clipper->clear();