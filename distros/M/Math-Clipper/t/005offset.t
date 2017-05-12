use Math::Clipper ':all';
use Test::More tests => 19;

my $ccw = [
[0,0],
[4,0],
[4,4],
[0,4]
];
my $cw = [
[0,0],
[0,4],
[4,4],
[4,0]
];


my $offpolys1 = Math::Clipper::offset([$ccw], 1.0, 1);
#diag("\ncnt:\n",scalar(@{$offpolys1}),"\n\n");
ok(scalar(@{$offpolys1})==1,'positive offset, on ccw');
is(Math::Clipper::area($offpolys1->[0]),(16 + 20),'area check for positive ccw off');
#diag("\ngoing in wind1:".Math::Clipper::is_counter_clockwise($ccw) . " vs " .Math::Clipper::is_counter_clockwise($offpolys1->[0]));
my $offpolys2 = Math::Clipper::offset([$offpolys1->[0] , $cw], 1.0, 1); # $cw works as a hole inside $offpolys1->[0]
ok(scalar(@{$offpolys2})==2,'positive offset, on cw');
my $asum=0;
map {
	#diag("\n".Math::Clipper::area($_));
	$asum+=Math::Clipper::area($_)
	} @{$offpolys2};
is($asum,((16 + 20) + (28) - (16 - 12)),'area check for positive cw off');

my $offpolys3 = Math::Clipper::offset([$ccw], -1.0, 1);
#diag("\ngoing in wind2:".Math::Clipper::is_counter_clockwise($ccw) . " vs " .Math::Clipper::is_counter_clockwise($offpolys3->[0]));
ok(scalar(@{$offpolys3})==1,'negative offset, on ccw');
is(Math::Clipper::area($offpolys3->[0]),(16 - 12),'area check for negative ccw off');

my $offpolys4 = Math::Clipper::offset([$offpolys2->[0],$offpolys2->[1]], -1.0, 1);
ok(scalar(@{$offpolys4})==2,'negative offset, on cw');
$asum=0;
map {
	#diag("\n".Math::Clipper::area($_));
	$asum+=Math::Clipper::area($_)
	} @{$offpolys4};
is($asum,((16 + 20) - 16),'area check for negative cw off');

{
    my $res = Math::Clipper::int_offset([$ccw], 1.0, 1, JT_MITER, 2);
    ok @$res == 1, 'positive int_offset, on ccw';
    is Math::Clipper::area($res->[0]), (16 + 20), 'area check for positive ccw int_offset';
}

{
    my $res = Math::Clipper::int_offset([$ccw], -1.0, 1, JT_MITER, 2);
    ok @$res == 1, 'negative int_offset, on ccw';
    is Math::Clipper::area($res->[0]), 2*2, 'area check for negative ccw int_offset';
}

{
    my $res = Math::Clipper::int_offset2([$ccw], 1.0, -1.0, 1, JT_MITER, 2);
    ok @$res == 1, 'int_offset2 returned one item';
    is Math::Clipper::area($ccw), Math::Clipper::area($res->[0]), 'int_offset2 performed double offset';
}

{
    my $res = Math::Clipper::ex_int_offset([$ccw, $cw], 1.0, 1, JT_MITER, 2);
    ok @$res == 1, 'ex_int_offset returned one item';
    isa_ok $res->[0], 'HASH', 'ex_int_offset returned one ExPolygon';
}

{
    my $res = Math::Clipper::ex_int_offset2([$ccw], 1.0, -1.0, 1, JT_MITER, 2);
    ok @$res == 1, 'ex_int_offset2 returned one item';
    isa_ok $res->[0], 'HASH', 'ex_int_offset2 returned one ExPolygon';
    is Math::Clipper::area($ccw), Math::Clipper::area($res->[0]{outer}), 'ex_int_offset2 performed double offset';
}

__END__
