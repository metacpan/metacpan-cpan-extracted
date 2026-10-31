package Testophile;

use v5.40;

use Test::More;

use File::Path  qw( make_path remove_tree   );
use Symbol      qw( qualify_to_ref          );

my @dirz
= qw
(
    ./foo
    ./foo/etc
    ./bar
    ./bar/etc
);
my $madness = 'FindBin::libs';
my @pass1
= qw
(
    base=foo
    subdir=etc
    subonly
    export=etc
    append
);
my @pass2
= qw
(
    base=bar
    subdir=etc
    subonly
    export=etc
    append
);

END
{
    remove_tree $_ or diag "failed remove_tree: $_"
    for qw( ./foo ./bar );
}

SKIP:
{
    require_ok $madness 
    or skip "Failed require: $madness";

    make_path $_ or skip "failed make_path: $_", 1
    for @dirz;

    eval { $madness->import( @pass1 ); 1 }
    or do
    {
        fail "$madness->import( @pass1 ) fails with $@";
        skip 'Failed import pass1', 1;
    };

    my $etc = *{ qualify_to_ref 'etc' }{ ARRAY };

    note 'First pass looks for foo/etc:', explain $etc;
    ok 1 == $etc->@*,   'Found one item in @etc';

    eval { $madness->import( @pass2 ); 1 }
    or do
    {
        fail "$madness->import( @pass2 ) fails with $@";
        skip 'Failed import pass2', 1;
    };

    note 'Second pass looks for bar/etc:', explain $etc;

    ok 2 == $etc->@*, 'Found two items in @etc';
}

done_testing;

__END__
