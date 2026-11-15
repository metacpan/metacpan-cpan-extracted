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

use File::Basename        qw( dirname );
use File::Spec::Functions qw( catdir catfile );
use File::Temp            qw( tempdir );
use Test::More;

########################################################################
# $assume_dir decides whether the last component of $path is a
# directory:
#
# defined: used as given, the path is not examined.  a true value
# treats $path as a directory; a defined false value ('' or 0)
# treats the last component as a file.
#
# not given or undef: an existing path is checked with -d; a path
# that does not exist croaks.
#
# the first entry of dir_paths is the starting directory: $path when
# it is treated as a directory, its parent when not.
#
# cases share one cache: the '' and 0 rows precede the undef rows so
# that an undef sharing their cache entry fails.

require_ok 'FindBin::Parents'
or BAIL_OUT 'Failed require FindBin::Parents';

FindBin::Parents->import( qw( dir_paths ) );

my $exist_d = tempdir CLEANUP => 1;
my $parent  = dirname $exist_d;
my $missing = catdir $exist_d, 'missing';
my $file    = catfile $exist_d, 'file';

open my $fh, '>', $file
or die "open '$file': $!";

close $fh;

my @casez =
(
    {
        name    => "existing dir, '': dropped"
      , argz    => [ $exist_d, '' ]
      , expect  => $parent
    }
  , {
        name    => 'existing dir, 0: dropped'
      , argz    => [ $exist_d, 0 ]
      , expect  => $parent
    }
  , {
        name    => 'existing dir, 1: kept'
      , argz    => [ $exist_d, 1 ]
      , expect  => $exist_d
    }
  , {
        name    => 'existing dir, not given: kept by -d'
      , argz    => [ $exist_d ]
      , expect  => $exist_d
    }
  , {
        name    => 'existing dir, undef: kept by -d'
      , argz    => [ $exist_d, undef ]
      , expect  => $exist_d
    }
  , {
        name    => 'existing file, not given: dropped by -d'
      , argz    => [ $file ]
      , expect  => $exist_d
    }
  , {
        name    => 'existing file, undef: dropped by -d'
      , argz    => [ $file, undef ]
      , expect  => $exist_d
    }
  , {
        name    => 'existing file, 1: kept'
      , argz    => [ $file, 1 ]
      , expect  => $file
    }
  , {
        name    => 'missing path, 1: kept'
      , argz    => [ $missing, 1 ]
      , expect  => $missing
    }
  , {
        name    => "missing path, '': dropped"
      , argz    => [ $missing, '' ]
      , expect  => $exist_d
    }
);

for my $case ( @casez )
{
    my ( $name, $argz, $expect ) = @{ $case }{ qw( name argz expect ) };

    my ( $found ) = dir_paths( @$argz );

    is $found, $expect, "dir_paths $name";
}

# a missing path without $assume_dir cannot be checked: croak.

my $croak_re
= qr
{
    ^ Bogus [ ] dir_paths: [ ] '\Q$missing\E' [ ] does [ ] not [ ] exist;
}x;

my @croak_casez =
(
    {
        name    => 'missing path, not given'
      , argz    => [ $missing ]
    }
  , {
        name    => 'missing path, undef'
      , argz    => [ $missing, undef ]
    }
);

for my $case ( @croak_casez )
{
    my ( $name, $argz ) = @{ $case }{ qw( name argz ) };

    eval { dir_paths( @$argz ) };

    like $@, $croak_re, "dir_paths $name: croaks naming the path";
}

# -d returns '' for an existing non-directory: no warning from its
# use in the cache key.

my @warn_casez =
(
    {
        name    => 'existing dir'
      , path    => $exist_d
    }
  , {
        name    => 'existing file'
      , path    => $file
    }
);

for my $case ( @warn_casez )
{
    my ( $name, $path ) = @{ $case }{ qw( name path ) };

    my @warnz   = ();

    {
        local $SIG{ __WARN__ } = sub { push @warnz, @_ };

        my @found = dir_paths( $path, undef );
    }

    is scalar @warnz, 0, "dir_paths $name, undef: no warning";
}

done_testing;

__END__

=head1 NAME

03b-Parent-assume-dir.t - dir_paths handling of $assume_dir

=head1 DESCRIPTION

C<$assume_dir> overrides the C<-d> test.  A true value treats the
path as a directory.  A defined false value (C<''> or C<0>) treats
the last component as a file, so it is dropped even when it is an
existing directory.  Not given, or C<undef>, checks an existing path
with C<-d>; a path that does not exist croaks.

=head1 SEE ALSO

L<FindBin::Parents>, F<03-Parent-sanity.t>, F<03c-Parent-path.t>
