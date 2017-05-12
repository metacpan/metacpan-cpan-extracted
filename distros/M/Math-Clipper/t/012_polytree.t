use Math::Clipper ':all';
use Test::More tests => 9;

{
    my $square1 = [
        [0,0],
        [10,0],
        [10,10],
        [0,10],
    ];
    my $hole1 = [
        [2,2],
        [2,8],
        [8,8],
        [8,2],
    ];
    my $square2 = [
        [4,4],
        [6,4],
        [6,6],
        [4,6],
    ];
    
    my $clipper = Math::Clipper->new;
    $clipper->add_subject_polygons([ $square1, $hole1, $square2 ]);
    my $polytree = $clipper->pt_execute(CT_UNION);
    is scalar(@$polytree), 1, 'only one top-level polygon';
    ok exists $polytree->[0]{outer}, 'top-level polygon has outer type';
    is area($polytree->[0]{outer}), area($square1), 'top-level polygon has expected area';
    is scalar(@{ $polytree->[0]{children} }), 1, 'top-level polygon has one child';
    ok exists $polytree->[0]{children}[0]{hole}, 'top-level polygon child is hole';
    is scalar(@{ $polytree->[0]{children}[0]{children} }), 1, 'hole has one child';
    ok exists $polytree->[0]{children}[0]{children}[0]{outer}, 'hole child has outer type';
    is area($polytree->[0]{children}[0]{children}[0]{outer}), area($square2), 'hole child has expected area';
}

{
    my $square1 = [
        [0,0],
        [10,0],
        [10,10],
        [0,10],
    ];
    my $square2 = [
        [20,20],
        [30,20],
        [30,30],
        [20,30],
    ];
    my $clipper = Math::Clipper->new;
    $clipper->add_subject_polygons([ $square1, $square2 ]);
    my $polytree = $clipper->pt_execute(CT_INTERSECTION);
    is scalar(@$polytree), 0, 'null intersection returned empty arrayref';
}

__END__
