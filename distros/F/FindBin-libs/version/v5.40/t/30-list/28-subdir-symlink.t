########################################################################
# housekeeping
########################################################################
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

use File::Basename        qw( basename dirname );
use File::Spec::Functions qw( catdir rel2abs   );
use File::Temp            qw( tempdir          );
use Test::More;

########################################################################
# subdir=bar where bar is a symlink: a link to an existing directory
# passes -d and is found; a dangling link is not.
#
# each case builds BASE/bar in a tempdir with a unique name in the
# test's own directory (searched first from $Bin), so leftovers from
# earlier runs or tests running in parallel cannot collide with it.
# CLEANUP removes it.

require_ok 'FindBin::libs'
or BAIL_OUT 'Failed require FindBin::libs';

my $test_d  = dirname rel2abs $0;

my @casez =
(
    {
        name    => 'symlink to an existing dir: found'
      , target  => '..'
      , expect  => 1
    }
  , {
        name    => 'dangling symlink: skipped'
      , target  => 'missing'
      , expect  => 0
    }
);

for my $case ( @casez )
{
    my ( $name, $target, $expect ) = @{ $case }{ qw( name target expect ) };

    my $base_d  = tempdir 'foo_XXXXXX', DIR => $test_d, CLEANUP => 1;
    my $base    = basename $base_d;
    my $link    = catdir $base_d, 'bar';

    symlink $target, $link
    or die "Bogus fixture: symlink '$link' -> '$target': $!\n";

    FindBin::libs->import
    (
        "base=$base"
      , qw( subdir=bar subonly export=found nofail )
    );

    my @found   = do { no warnings 'once'; @Testophile::found };

    my $count   = grep { $_ eq $link } @found;

    is $count, $expect, "subdir=bar, $name";
}

done_testing;
