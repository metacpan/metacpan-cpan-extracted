#!perl -T

use Test::More qw/no_plan/;
use Test::Deep;

use Hash::Slice qw/slice/;

my (%hash, $slice);

%hash = (a => 1, b => 2, c => { d => 3, e => 4, f => { g => 5, h => 6, k => [ 0 .. 4 ] } }, z => 7 );
$slice = slice \%hash, qw/a z/, [ c => qw/e/, [ f => qw/g k/ ] ];
cmp_deeply($slice =>{ a => 1, z => 7, c => { e => 4, f => { g => 5, k => [ 0, 1, 2, 3, 4 ] } } });

%hash = (qw/a 1 b 2 c 3 d 4/);
$slice = Hash::Slice::slice \%hash, qw/a c/;
cmp_deeply($slice => { a => 1, c => 3 });

%hash = (qw/a 1 b 2 c 3 d 4/, e => { qw/f 5 g 6 h 7/, i => { qw/j 8 k 9 l 10/ } });
$slice = slice \%hash, qw/a c/, [ e => qw/g h/, [ i => qw/l/ ] ];
cmp_deeply($slice => { a => 1, c => 3, e => { g => 6, h => 7, i => { l => 10 } } });

%hash = (qw/a 1 b 2 c 3 d 4/, e => { f => 3, g => 5 });
$slice = Hash::Slice::slice \%hash, qw/a c/, [ e => qw/f g/];
cmp_deeply($slice => { a => 1, c => 3, e => { f => 3, g => 5 } });

if (eval { require Clone }) {
    %hash = (qw/a 1 b 2 c 3 d 4/, e => { f => 5, g => 6 });
    $slice = Hash::Slice::clone_slice \%hash, qw/a c e/;
    $slice->{e}->{g} = 7;
    cmp_deeply($slice => { a => 1, c => 3, e => { f => 5, g => 7 } });
    is($hash{e}->{f}, 5);
    is($hash{e}->{g}, 6);
    is($slice->{e}->{f}, 5);
    is($slice->{e}->{g}, 7);
}

if (eval { require Storable }) {
    %hash = (qw/a 1 b 2 c 3 d 4/, e => { f => 5, g => 6 });
    $slice = Hash::Slice::dclone_slice \%hash, qw/a c e/;
    $slice->{e}->{g} = 7;
    cmp_deeply($slice => { a => 1, c => 3, e => { f => 5, g => 7 } });
    is($hash{e}->{f}, 5);
    is($hash{e}->{g}, 6);
    is($slice->{e}->{f}, 5);
    is($slice->{e}->{g}, 7);
}
