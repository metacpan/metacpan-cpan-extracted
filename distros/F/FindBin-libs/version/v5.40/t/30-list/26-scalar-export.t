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

use File::Basename        qw( basename );
use Test::More;

########################################################################
# scalar is used with export: it installs the single nearest
# directory, and with subdir implies subonly to get that value.
# without export it croaks.  noscalar is the default, not a request
# for subonly.
#
# fixture: walking up from t/30-list finds t/lib and lib, each with a
# FindBin subdir, so subdir=FindBin finds two FindBin dirs and their
# parents.

require_ok 'FindBin::libs'
or BAIL_OUT 'Failed require FindBin::libs';

eval { FindBin::libs->import( qw( scalar ) ) };

like $@, qr{ ^ Bogus [ ] 'scalar' [ ] argument [ ] without [ ] 'export' }x,
'scalar without export: croaks';

no warnings 'once';

FindBin::libs->import( qw( subdir=FindBin export=pairs ) );

my @pairz   = @Testophile::pairs;

ok scalar( grep { basename( $_ ) ne 'FindBin' } @pairz ),
'fixture: subdir=FindBin finds parent dirs';

FindBin::libs->import( qw( subdir=FindBin noscalar export=noscalar ) );

is_deeply \@Testophile::noscalar, \@pairz,
'noscalar: same as no scalar, parents kept';

FindBin::libs->import( qw( subdir=FindBin scalar export=single ) );

is $Testophile::single, $pairz[0],
'scalar with subdir: the nearest subdir';

done_testing;

__END__

=head1 NAME

26-scalar-export.t - scalar requires export; noscalar is ignored

=head1 DESCRIPTION

C<scalar> without C<export> croaks.  C<noscalar> does not imply
C<subonly>: the parent directories are kept.  C<scalar> with
C<subdir> exports the nearest subdirectory.

=head1 SEE ALSO

L<FindBin::libs>
