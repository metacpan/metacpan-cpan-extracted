package Testophile;

use v5.40;

########################################################################
# test the current module: $0 is */t/X/foo.t, the module is in */lib.
#
# lib must exist; if it is a symlink it must resolve to the lib next
# to the physical t directory, code outside the checkout is not
# loaded.  add it to @INC unless it is already there, or a blib is
# ("make test", "prove -b").

my $lib_d;

BEGIN
{
    use Cwd                   qw( abs_path );
    use File::Spec::Functions qw( catdir catpath rel2abs splitdir splitpath );
    use List::Util            qw( first );

    my ( $vol, $dir )   = splitpath rel2abs $0;
    my @dirz            = splitdir $dir;

    pop @dirz
    while @dirz && $dirz[-1] ne 't';

    @dirz
    or die "Bogus test path: no 't' directory in '$0'.\n";

    my $t_d     = catpath $vol, ( catdir @dirz ), '';

    $dirz[-1]   = 'lib';
    $lib_d      = catpath $vol, ( catdir @dirz ), '';

    -d $lib_d
    or die "Bogus test path: '$lib_d' from '$0' is not a directory.\n";

    if( -l $lib_d )
    {
        my ( $t_vol, $t_phys )  = splitpath abs_path( $t_d ), 1;
        my @t_dirz              = splitdir $t_phys;

        $t_dirz[-1] = 'lib';

        my $expect  = catpath $t_vol, ( catdir @t_dirz ), '';
        my $found   = abs_path $lib_d;

        $found eq $expect
        or die "Bogus lib: symlink '$lib_d' resolves to '$found', "
        . "expected '$expect' next to the test directory.\n";
    }

    first
    {
        ! ref $_
        and
        (
            m{ (?: ^ | / ) blib / }x
            or rel2abs( $_ ) eq $lib_d
        )
    }
    @INC
    or unshift @INC, $lib_d;
}

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
