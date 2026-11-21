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
# argument validation: each bad argument croaks naming the problem.
# import is called at runtime; it croaks before searching.

require_ok 'FindBin::Files'
or BAIL_OUT 'Failed require FindBin::Files';

my @casez =
(
    {
        name    => 'missing file'
      , argz    => [ qw( scalar ) ]
      , expect  => qr{ missing/false [ ] file [ ] argument }x
    }
  , {
        name    => 'false file'
      , argz    => [ qw( file=0 ) ]
      , expect  => qr{ missing/false [ ] file [ ] argument }x
    }
  , {
        name    => 'absolute file'
      , argz    => [ qw( file=/etc/app.conf ) ]
      , expect  => qr{ 'file=/etc/app.conf' [ ] is [ ] absolute }x
    }
  , {
        name    => 'file with ..'
      , argz    => [ qw( file=../etc/app.conf ) ]
      , expect  => qr{ 'file=\.\./etc/app.conf' [ ] contains [ ] '\.\.' }x
    }
  , {
        name    => 'basename ..'
      , argz    => [ qw( file=etc/.. export=x ) ]
      , expect  => qr{ 'file=etc/\.\.' [ ] has [ ] basename [ ] '\.\.' }x
    }
  , {
        name    => 'basename .'
      , argz    => [ qw( file=etc/. export=x ) ]
      , expect  => qr{ 'file=etc/\.' [ ] has [ ] basename [ ] '\.' }x
    }
  , {
        name    => 'missing basename'
      , argz    => [ qw( file=etc/ export=x ) ]
      , expect  => qr{ 'file=etc/' [ ] has [ ] no [ ] basename }x
    }
  , {
        name    => 'compound dir'
      , argz    => [ qw( dir=t/50-foobar file=bletch.t ) ]
      , expect  => qr{ 'dir=t/50-foobar' [ ] is [ ] a [ ] compound [ ] path }x
    }
  , {
        name    => 'absolute dir'
      , argz    => [ qw( dir=/t file=bletch.t ) ]
      , expect  => qr{ 'dir=/t' [ ] is [ ] a [ ] compound [ ] path }x
    }
  , {
        name    => 'dir ..'
      , argz    => [ qw( dir=.. file=bletch.t ) ]
      , expect  => qr{ 'dir=\.\.' [ ] is [ ] not [ ] a [ ] directory [ ] name }x
    }
  , {
        name    => 'dir .'
      , argz    => [ qw( dir=. file=bletch.t ) ]
      , expect  => qr{ 'dir=\.' [ ] is [ ] not [ ] a [ ] directory [ ] name }x
    }
  , {
        name    => 'export not an identifier'
      , argz    => [ qw( file=app.conf export=1conf ) ]
      , expect  => qr{ export [ ] name [ ] '1conf' [ ] from [ ] 'file=app.conf' [ ] is [ ] not }x
    }
  , {
        name    => 'default export: basename without word characters'
      , argz    => [ qw( file=- ) ]
      , expect  => qr{ export [ ] name [ ] '' [ ] from [ ] 'file=-' [ ] is [ ] not [ ] an [ ] identifier }x
    }
  , {
        name    => 'default export not an identifier'
      , argz    => [ qw( file=1app.conf ) ]
      , expect  => qr{ export [ ] name [ ] '1app_conf' [ ] from [ ] 'file=1app.conf' [ ] is [ ] not }x
    }
);

for my $case ( @casez )
{
    my ( $name, $argz, $expect ) = @{ $case }{ qw( name argz expect ) };

    eval { FindBin::Files->import( $argz->@* ) };

    like $@, $expect, "croak: $name";
}

########################################################################
# debug warns about a basename without word characters: the
# switch and $ENV{ FBF_DEBUG } each enable it.  file=- croaks for
# lack of an export name after the warning.

my @warn_casez =
(
    {
        name    => 'debug switch: warns'
      , argz    => [ qw( file=- debug ) ]
      , env     => ''
      , expect  => 1
    }
  , {
        name    => 'FBF_DEBUG: warns'
      , argz    => [ qw( file=- ) ]
      , env     => 1
      , expect  => 1
    }
  , {
        name    => 'no debug: silent'
      , argz    => [ qw( file=- ) ]
      , env     => ''
      , expect  => 0
    }
);

for my $case ( @warn_casez )
{
    my ( $name, $argz, $env, $expect )
    = @{ $case }{ qw( name argz env expect ) };

    # $ENV{ FBF_DEBUG } is read once per process: run in a child.

    local $ENV{ FBF_DEBUG } = $env;
    local $ENV{ PERL5LIB }  = join ':' => grep { ! ref } @INC;

    my $err   = qx{ $^X -e 'require FindBin::Files; eval { FindBin::Files->import( qw( $argz->@* ) ) }' 2>&1 };

    my $found = () = $err =~ m{ ^ Basename [ ] '-' [ ] lacks [ ] any [ ] word [ ] chars $ }xmg;

    is $found, $expect, "warning: $name";
}

done_testing;
