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
# dir_paths validates $path before the walk: a false path croaks, a
# relative path croaks, the literal 'pwd' is replaced by pwd().
#
# the walk lists the root once: splitdir returns ( '', '' ) for the
# root, the second must not add the root again.

require_ok 'FindBin::Parents'
or BAIL_OUT 'Failed require FindBin::Parents';

FindBin::Parents->import( qw( dir_paths ) );

my @croak_casez =
(
    {
        name    => "false path ''"
      , argz    => [ '', 1 ]
      , expect  => qr{ ^ Bogus [ ] dir_paths: [ ] false [ ] path [ ] argument\. }x
    }
  , {
        name    => "false path '0'"
      , argz    => [ '0', 1 ]
      , expect  => qr{ ^ Bogus [ ] dir_paths: [ ] false [ ] path [ ] argument\. }x
    }
  , {
        name    => "relative path 'foo/bar'"
      , argz    => [ 'foo/bar', 1 ]
      , expect  => qr{ ^ Bogus [ ] dir_paths: [ ] 'foo/bar' [ ] is [ ] not [ ] an [ ] absolute [ ] path\. }x
    }
  , {
        name    => "relative path '.'"
      , argz    => [ '.', 1 ]
      , expect  => qr{ ^ Bogus [ ] dir_paths: [ ] '\.' [ ] is [ ] not [ ] an [ ] absolute [ ] path\. }x
    }
);

for my $case ( @croak_casez )
{
    my ( $name, $argz, $expect ) = @{ $case }{ qw( name argz expect ) };

    eval { dir_paths( @$argz ) };

    like $@, $expect, "dir_paths $name: croaks";
}

my ( $pwd_first ) = eval { dir_paths( 'pwd' ) };

is $pwd_first, FindBin::Bin::pwd(), "dir_paths 'pwd': starts at pwd()";

SKIP:
{
    my @root_casez =
    (
        {
            name    => "'/', not given"
          , argz    => [ '/' ]
        }
      , {
            name    => "'/', 1"
          , argz    => [ '/', 1 ]
        }
      , {
            name    => "'/', ''"
          , argz    => [ '/', '' ]
        }
      , {
            name    => "top-level path, ''"
          , argz    => [ "/dir_paths-missing-$$", '' ]
        }
      , {
            name    => "'/x/..', 1"
          , argz    => [ '/x/..', 1 ]
        }
    );

    skip "Root walk uses *NIX paths, not $^O", scalar @root_casez
    if $^O =~ m{ ^ (?: MSWin32 | VMS ) $ }x;

    for my $case ( @root_casez )
    {
        my ( $name, $argz ) = @{ $case }{ qw( name argz ) };

        my @found   = dir_paths( @$argz );

        is_deeply \@found, [ '/' ], "dir_paths $name: root listed once";
    }
}

done_testing;

__END__

=head1 NAME

03c-Parent-path.t - dir_paths path validation and the root walk

=head1 DESCRIPTION

A false path and a relative path croak; the literal C<'pwd'> is
replaced by C<FindBin::Bin::pwd()>.  A walk that starts at the root
lists it once.

The root cases are skipped on MSWin32 and VMS, which have other
root forms.

=head1 SEE ALSO

L<FindBin::Parents>, F<03b-Parent-assume-dir.t>
