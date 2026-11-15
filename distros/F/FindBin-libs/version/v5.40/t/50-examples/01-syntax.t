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
use File::Spec::Functions qw( catfile rel2abs  );
use Test::More;

########################################################################
# locate project root -- same two-dirname walk as 02-perl_t
########################################################################

my $dir0    = rel2abs dirname $0;
my $test_d  = dirname $dir0;
my $work_d  = dirname $test_d;

chdir $work_d
or BAIL_OUT "chdir '$work_d': $!";

-d 'example'
or BAIL_OUT "Missing example/ directory under $work_d";

########################################################################
# perl -wc each example script
########################################################################

local $ENV{ PERL5LIB } = './lib';

for my $name
(
    qw
    (
        dual_etc_paths
        dual_lib_paths
        find_ld_dirs
        find_myconfig
        layered_etc
        list_etc_dirs
        multi_config_dir
        p5run
        single_config_dir
    )
)
{
    my $script = catfile 'example', $name;

    unless( -e $script )
    {
        fail "Missing example: $name";
        next
    }

    chomp( my @out = qx{ perl -wc "$script" 2>&1 } );

    if( @out && $out[-1] =~ m{ syntax \s OK $}x )
    {
        pass "Syntax OK: $name";

        1 < @out
        and diag join "\n\t", "\nWarnings:", @out;
    }
    else
    {
        fail "Fails compilation: $name";
        diag join "\n\t", "\nOutput:", @out;
    }
}

done_testing;
__END__
