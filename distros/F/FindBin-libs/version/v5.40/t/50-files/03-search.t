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

use File::Path            qw( make_path );
use File::Spec::Functions qw( catdir catfile );
use File::Temp            qw( tempdir );
use Test::More;

########################################################################
# searches run in a child perl: $Bin is fixed by $0, so each case
# runs a script under a fixture tree:
#
#   $root/a/etc/app.conf
#   $root/a/b/etc/app.conf
#   $root/a/b/etc/dead.conf     -> missing (dangling symlink)
#   $root/a/b/top.rc
#   $root/a/b/.myconfig.yaml
#   $root/a/b/t/run.pl          the script
#
# run.pl imports with its arguments and prints the variable named
# by $ENV{ FBF_VAR }, one path per line, or "<$value>" for a
# scalar.  ignore= keeps a
# system /etc/app.conf out of the results.

my $root    = tempdir CLEANUP => 1;
my $a_d     = catdir $root, 'a';
my $b_d     = catdir $a_d, 'b';

make_path map { catdir $_, 'etc' } $a_d, $b_d;
make_path catdir $b_d, 't';

for my $path
(
    catfile( $a_d, qw( etc app.conf ) )
  , catfile( $b_d, qw( etc app.conf ) )
  , catfile( $b_d, 'top.rc' )
  , catfile( $b_d, '.myconfig.yaml' )
)
{
    open my $fh, '>', $path
    or die "Bogus fixture: open '$path': $!\n";
}

symlink catfile( $b_d, 'missing' ), catfile( $b_d, qw( etc dead.conf ) )
or die "Bogus fixture: symlink dead.conf: $!\n";

my $script  = catfile $b_d, qw( t run.pl );

open my $fh, '>', $script
or die "Bogus fixture: open '$script': $!\n";

print $fh <<'END';
use v5.40;
require FindBin::Files;
FindBin::Files->import( @ARGV );
my $name = $ENV{ FBF_VAR };
no strict 'refs';
if( grep { $_ eq 'scalar' } @ARGV )
{
    say '<', ${ "main::$name" }, '>';
}
else
{
    say for @{ "main::$name" };
}
END

close $fh;

my $a_conf  = catfile $a_d, qw( etc app.conf  );
my $b_conf  = catfile $b_d, qw( etc app.conf  );
my $dead    = catfile $b_d, qw( etc dead.conf );
my $top     = catfile $b_d, 'top.rc';
my $dot_cfg = catfile $b_d, '.myconfig.yaml';

my @casez =
(
    {
        name    => 'list: all matches, nearest first'
      , argz    => [ qw( file=etc/app.conf export=found ignore= ) ]
      , expect  => [ $b_conf, $a_conf ]
    }
  , {
        name    => 'scalar: nearest match'
      , argz    => [ qw( file=etc/app.conf export=found scalar ignore= ) ]
      , expect  => [ "<$b_conf>" ]
    }
  , {
        name    => 'dir: prefixed to file'
      , argz    => [ qw( dir=etc file=app.conf export=found ignore= ) ]
      , expect  => [ $b_conf, $a_conf ]
    }
  , {
        name    => 'basename: found in the parent itself'
      , argz    => [ qw( file=top.rc export=found ignore= ) ]
      , expect  => [ $top ]
    }
  , {
        name    => "scalar, no match: ''"
      , argz    => [ qw( file=etc/none export=found scalar nofail ignore= ) ]
      , expect  => [ '<>' ]
    }
  , {
        name    => 'list, no match: empty'
      , argz    => [ qw( file=etc/none export=found nofail ignore= ) ]
      , expect  => []
    }
  , {
        name    => 'strict: dangling symlink skipped'
      , argz    => [ qw( file=etc/dead.conf export=found nofail ignore= ) ]
      , expect  => []
    }
  , {
        name    => 'nostrict: dangling symlink returned'
      , argz    => [ qw( file=etc/dead.conf export=found nostrict ignore= ) ]
      , expect  => [ $dead ]
    }
  , {
        name    => 'ignore: parent skipped'
      , argz    => [ "ignore=$b_d", qw( file=etc/app.conf export=found ) ]
      , expect  => [ $a_conf ]
    }
  , {
        name    => 'export: default name from basename, directory ignored'
      , argz    => [ qw( file=etc/app.conf ignore= ) ]
      , expect  => [ $b_conf, $a_conf ]
      , varname => 'app_conf'
    }
  , {
        name    => 'export: default name strips leading dot'
      , argz    => [ qw( file=.myconfig.yaml ignore= ) ]
      , expect  => [ $dot_cfg ]
      , varname => 'myconfig_yaml'
    }
);

# the child finds the modules via the same lib as this test.

local $ENV{ PERL5LIB } = join ':' => grep { ! ref } @INC;

for my $case ( @casez )
{
    my ( $name, $argz, $expect, $var )
    = @{ $case }{ qw( name argz expect varname ) };

    local $ENV{ FBF_VAR } = $var // 'found';

    my @found   = qx{ $^X $script $argz->@* 2>/dev/null };

    chomp @found;

    is_deeply \@found, $expect, $name;
}

# the fail carp is its own test.

local $ENV{ FBF_VAR } = 'found';

my $err = qx{ $^X $script file=etc/none export=found ignore= 2>&1 };

like $err, qr{ No [ ] 'etc/none' [ ] found }x, 'fail: carps when nothing is found';

done_testing;
