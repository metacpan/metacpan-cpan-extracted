package Testophile;

use v5.8;

use File::Spec::Functions   qw( catpath         );
use Symbol                  qw( qualify_to_ref  );

use Test::More tests => 3;

BEGIN
{
    mkdir './foo';
    mkdir './foo/etc';
    mkdir './bar';
    mkdir './bar/etc';
}

END
{
    rmdir './foo/etc';
    rmdir './foo';
    rmdir './bar/etc';
    rmdir './bar';
}

SKIP:
{
    2.0 < FindBin::libs->VERSION
    or skip "Test for new version", 3;

    require_ok FindBin::libs;

    FindBin::libs->import
    (
        qw
        (
            base=foo
            subdir=etc
            subonly
            export=etc
            append
        )
    );


    note 'First pass looks for foo/etc:', explain \@etc;

    ok 1 == @etc,   'Found one item in @etc';


    FindBin::libs->import
    (
        qw
        (
            base=bar
            subdir=etc
            subonly
            export=etc
            append
        )
    );

    note 'Second pass looks for bar/etc:', explain \@etc;

    ok 2 == @etc, 'Found two items in @etc';
}

__END__
