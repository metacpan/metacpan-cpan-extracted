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

use Test::More;

########################################################################
# verify nofail suppresses the "Empty lib directory list" carp, and
# that the default (fail => 1) does carp when no dirs are found.
#
# "findbin_nofail_test_nonexistent" is a base name that will not exist
# anywhere in the ancestor tree, so both imports reliably find nothing.

SKIP:
{
    require_ok 'FindBin::libs'
    or skip 'Failed require FindBin::libs', 4;

    my @warned;

    {
        local $SIG{ __WARN__ } = sub { push @warned, @_ };

        FindBin::libs->import
        (
            qw( base=findbin_nofail_test_nonexistent )
        );
    }

    ok   @warned,                              'default: carp fires when no dirs found';
    like $warned[0], qr/Empty lib directory list/, 'carp message matches expected text';

    my @warned2;

    {
        local $SIG{ __WARN__ } = sub { push @warned2, @_ };

        FindBin::libs->import
        (
            qw( base=findbin_nofail_test_nonexistent nofail )
        );
    }

    ok ! @warned2, 'nofail: no carp when no dirs found';
}

done_testing;

__END__

=head1 NAME

23-nofail.t - verify FindBin::libs nofail import option

=head1 DESCRIPTION

Tests the C<nofail> import option added in FindBin::libs v5.0.8.

Without C<nofail>, FindBin::libs carps "Empty lib directory list from
'$0'" when the import completes with no usable directories found.  With
C<nofail>, the carp is suppressed.

The base name C<findbin_nofail_test_nonexistent> is chosen to be absent
from every ancestor of the test file, ensuring the carp branch is
reached reliably.

=head1 SEE ALSO

L<FindBin::libs>

=cut
