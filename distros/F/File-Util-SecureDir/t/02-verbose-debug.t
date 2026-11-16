########################################################################
# housekeeping
########################################################################
use v5.36;

use Test::More;

BEGIN
{
    use File::Basename          qw( dirname );
    use File::Spec::Functions   qw( catdir rel2abs );

    require lib;
    lib->import( rel2abs catdir dirname( $0 ), '..', 'lib' );
}

# verbose and debug can be set and reset by any caller, any number of
# times.  They do not select a filter: this file ends with none set.

use File::Util::SecureDir;

my $pkg     = 'File::Util::SecureDir';
my $reset   = sub { $pkg->verbose( 0 ); $pkg->debug( 0 ) };

########################################################################
# accessor methods
########################################################################

$reset->();

ok ! $pkg->verbose, 'verbose: false after reset';
ok ! $pkg->debug,   'debug: false after reset';

$pkg->verbose( 1 );

ok $pkg->verbose, 'verbose: true after verbose( 1 )';

ok ! $pkg->debug, 'verbose( 1 ) leaves debug alone';

$pkg->verbose( 0 );

ok ! $pkg->verbose, 'verbose: false again after verbose( 0 )';

$pkg->debug( 1 );

ok $pkg->debug, 'debug: true after debug( 1 )';

ok ! $pkg->verbose, 'debug( 1 ) leaves verbose alone';

$pkg->debug( 0 );

ok ! $pkg->debug, 'debug: false again after debug( 0 )';

########################################################################
# import arguments, one flag per test.  Both flags start false.
########################################################################

my @casez
= (
    {
        name    => 'import verbose: verbose on'
      , args    => [ qw( verbose ) ]
      , flag    => 'verbose'
      , expect  => 1
    }
  , {
        name    => 'import verbose: debug stays off'
      , args    => [ qw( verbose ) ]
      , flag    => 'debug'
      , expect  => 0
    }
  , {
        name    => 'import verbose=1: verbose on'
      , args    => [ qw( verbose=1 ) ]
      , flag    => 'verbose'
      , expect  => 1
    }
  , {
        name    => 'import verbose=0: verbose off'
      , args    => [ qw( verbose=0 ) ]
      , flag    => 'verbose'
      , expect  => 0
    }
  , {
        name    => 'import debug: debug on'
      , args    => [ qw( debug ) ]
      , flag    => 'debug'
      , expect  => 1
    }
  , {
        name    => 'import debug: verbose stays off'
      , args    => [ qw( debug ) ]
      , flag    => 'verbose'
      , expect  => 0
    }
  , {
        name    => 'import debug=1: debug on'
      , args    => [ qw( debug=1 ) ]
      , flag    => 'debug'
      , expect  => 1
    }
  , {
        name    => 'import debug=0: debug off'
      , args    => [ qw( debug=0 ) ]
      , flag    => 'debug'
      , expect  => 0
    }
  , {
        name    => 'import verbose debug: verbose on'
      , args    => [ qw( verbose debug ) ]
      , flag    => 'verbose'
      , expect  => 1
    }
  , {
        name    => 'import verbose debug: debug on'
      , args    => [ qw( verbose debug ) ]
      , flag    => 'debug'
      , expect  => 1
    }
  , {
        name    => 'import verbose=1 debug=0: verbose on'
      , args    => [ qw( verbose=1 debug=0 ) ]
      , flag    => 'verbose'
      , expect  => 1
    }
  , {
        name    => 'import verbose=1 debug=0: debug off'
      , args    => [ qw( verbose=1 debug=0 ) ]
      , flag    => 'debug'
      , expect  => 0
    }
);

for my $case ( @casez )
{
    my ( $name, $args, $flag, $expect )
    = @{ $case }{ qw( name args flag expect ) };

    $reset->();

    $pkg->import( $args->@* );

    is( ( $pkg->$flag ? 1 : 0 ), $expect, $name );
}

########################################################################
# a later import resets what an earlier one set
########################################################################

$reset->();

$pkg->import( 'verbose' );
$pkg->import( 'verbose=0' );

ok ! $pkg->verbose, 'import: verbose=0 after verbose turns it off again';

########################################################################
# any file may set them, not only the #! code
########################################################################

$reset->();

my $ok = eval "\n#line 1 \"Other/Module.pm\"\n$pkg->import( 'verbose' ); 1";

ok $ok, 'import verbose from another file: accepted';

ok $pkg->verbose, 'import verbose from another file: verbose on';

$reset->();

is $pkg->filter, '', 'verbose and debug never select a filter';

done_testing;
