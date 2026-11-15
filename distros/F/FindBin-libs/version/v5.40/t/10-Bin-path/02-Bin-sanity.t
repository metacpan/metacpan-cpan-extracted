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

my $madness = 'FindBin::Bin';
my @importz = qw( $Bin &Bin $Bin_l &Bin_l );

note "INC is:\n" => explain \@INC;

require_ok $madness;

eval { $madness->import( @importz ) };
$@ and fail "Import fails: $@";

for my $name ( qw( Bin Bin_l ) )
{
    my $ref     = qualify_to_ref $name;

    my $expect  = eval{ ${ *$ref }  };
    my $found   = eval{ &{ *$ref }  };

    if( $found && $expect )
    {
        is $found, $expect, "\$$name matches ${name}() ('$expect')";
    }
    elsif( $expect )
    {
        fail "\$$name not exported";
    }
    elsif( $found )
    {
        fail "${name}() returns undef";
    }
    else
    {
        fail "${name}() and \$$name not exported";
    }
}

done_testing;

__END__
