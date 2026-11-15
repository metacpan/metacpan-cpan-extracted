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

use Symbol      qw( qualify_to_ref );

require_ok qw( File::Spec::Functions );

########################################################################
# sanity check whether Cwd has working subs
########################################################################

sub sanity
{
    my $handler = shift
    or return;

    eval
    {
        $handler->( '//' );
        $handler->( 'cwd' );
        1
    }
}


my $cur = File::Spec::Functions->can( 'curdir'  )
or BAIL_OUT q{F::S::F  lacks 'curdir'};

my $rel = File::Spec::Functions->can( 'rel2abs' )
or BAIL_OUT q{F::S::F  lacks 'rel2abs'};

my $cwd = $cur->()
or BAIL_OUT q{F::S::F::curdir returns empty.};

note "Working dir:  '$cwd'";

my $abs = $rel->( $cwd )
or BAIL_OUT q{F::S::F::rel2abs returns empty for '$cwd'.};

note "Abs path:     '$abs'";

-e $abs
or BAIL_OUT q{F::S::F::rel2abs returns non-existant '$cwd'.};

pass 'Usable current directory handler.';

done_testing

__END__

BEGIN
{
    # however... there have been complaints of 
    # places where abs_path does not work. 
    #
    # if abs_path fails on the working directory
    # then replace it with rel2abs and live with 
    # possibly slower, redundant directories.
    #
    # the abs_path '//' hack allows for testing 
    # broken abs_path on primitive systems that
    # cannot handle the rooted system being linked
    # back to itself.

    use Cwd qw( &cwd );

    my $abs = Cwd->can( 'abs_path'  )
    or die "Odd: Cwd cannot 'abs_path'\n";

    if
    (
        eval { $abs->( '//' );  $abs->( cwd ); 1 }
    )
    {
        # nothing more to do: abs_path works.
    }
    elsif
    (
        $abs = Cwd->can( 'rel2abs'  )
    )
    {
        # ok, we have a substitute
    }
    else
    {
        die "Cwd fails abs_path test && lacks 'rel2abs'\n";
    }

    my $ref = *{ qualify_to_ref 'abs_path', __PACKAGE__ };

    undef &{ *$ref };

    *{ $ref } = $abs;

}
