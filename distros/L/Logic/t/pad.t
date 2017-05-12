use Test::More tests => 23;

BEGIN { use_ok('Logic::Variable'); }

sub setup_pad {
    my $pad = Logic::Variable::Pad->new;

    $pad->{x} = 1;
    $pad->{y} = 2;
    $pad->{z} = 3;

    $pad->save;      # r1

    $pad->{a} = 4;
    $pad->{x} = 5;

    $pad->save;      # r2

    $pad->{y} = 6;

    $pad->save;      # r3

    $pad->{z} = 7;
    $pad->{a} = 8;
    $pad;
}

{
    my $pad = setup_pad();

    my @expected = ( 
        { x => 5, y => 6, z => 7, a => 8 },       # pad 3
        { x => 5, y => 6, z => 3, a => 4 },       # pad 2
        { x => 5, y => 2, z => 3, a => 4 },       # pad 1
        { x => 1, y => 2, z => 3, a => undef },   # pad 0
    );

    for my $exp (@expected) {
        for (sort keys %$exp) {
            is($pad->{$_}, $exp->{$_}, "test $_");
        }
        $pad->restore;
    }
}

{
    my $pad = setup_pad();
    
    is($pad->revision, 3, "revision 3");
    $pad->commit(1);
    is($pad->revision, 3, "still revision 3");
    is($pad->{z}, 7, "revision 3 stuff still here");
    $pad->restore;
    is($pad->revision, 1, "skipped revision 2");
    is($pad->{z}, 3, "revision 1 stuff here now");
    is($pad->{x}, 1, "revision 2's diffs are gone");
}
    
# vim: ft=perl :
