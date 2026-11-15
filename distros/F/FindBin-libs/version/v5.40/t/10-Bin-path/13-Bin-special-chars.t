package Testophile;
use v5.40;

# Test that canon_dir correctly handles paths containing characters
# that are special in regexes or shell: brackets, parens, plus, spaces.
# These must pass through as literal path components, not be treated as
# patterns or shell metacharacters.

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

use File::Spec::Functions qw( catdir );
use Test::More;

use FindBin::Bin qw( $Bin $Bin_l );

my $cwd = FindBin::Bin::pwd();

my @cases
= (
    [ 'bracket pair',  "foo[1]"         ]
  , [ 'parens',        "foo(bar)"       ]
  , [ 'plus sign',     "foo+bar"        ]
  , [ 'space in name', "foo bar"        ]
  , [ 'dollar sign',   'foo$bar'        ]
  , [ 'hash',          'foo#bar'        ]
);

for my $case ( @cases )
{
    my ( $label, $component ) = @$case;

    my $input = catdir $cwd, $component;
    my $got   = FindBin::Bin::canon_dir( $input );

    is $got, $input, "canon_dir preserves special chars: $label";
}

{
    my $input = catdir $cwd, 'a[1]', '..', 'b(2)';
    my $exp   = catdir $cwd, 'b(2)';
    is FindBin::Bin::canon_dir( $input ), $exp,
        "canon_dir resolves .. with special-char components";
}

done_testing;
__END__
