########################################################################
# housekeeping
########################################################################
use v5.36;

use File::Temp  qw( tempdir );
use Test::More;

BEGIN
{
    use File::Basename          qw( dirname );
    use File::Spec::Functions   qw( catdir rel2abs );

    require lib;
    lib->import( rel2abs catdir dirname( $0 ), '..', 'lib' );
}

# filter=all accepts everything and never reads the directory.  It is
# for testing only.  This file ends in all.

use File::Util::SecureDir qw( filter=all );

my $secure  = File::Util::SecureDir->new;
my $root    = tempdir( CLEANUP => 1 );

########################################################################
# selection
########################################################################

is $secure->filter, 'all', 'all: selected by the #! code';

########################################################################
# modes, one mode per test
########################################################################

my @casez
= (
    {
        name    => 'all: mode 0700 accepted'
      , mode    => 0700
    }
  , {
        name    => 'all: mode 0755 accepted'
      , mode    => 0755
    }
  , {
        name    => 'all: mode 0775 accepted'
      , mode    => 0775
    }
  , {
        name    => 'all: mode 0777 accepted'
      , mode    => 0777
    }
);

for my $case ( @casez )
{
    my ( $name, $mode ) = @{ $case }{ qw( name mode ) };

    my $dir = catdir $root, sprintf 'm%04o', $mode;

    mkdir $dir or BAIL_OUT "Failed mkdir '$dir': $!";
    chmod $mode, $dir;

    is scalar( () = $secure->filter_dirs( $dir ) ), 1, $name;
}

########################################################################
# nothing is read, so nothing is warned about
########################################################################

my $missing = catdir $root, 'no-such-dir';
my @warnz   = ();
my @kept    = ();

{
    local $SIG{ __WARN__ } = sub { push @warnz, @_ };

    @kept = $secure->filter_dirs( $missing );
}

is_deeply \@kept, [ $missing ], 'all: a missing directory is accepted';

is scalar @warnz, 0, 'all: a missing directory gives no warning';

is scalar( () = $secure->filter_dirs( undef ) ), 1
, 'all: an undef entry is accepted';

is_deeply [ $secure->filter_dirs( qw( c a b ) ) ], [ qw( c a b ) ]
, 'all: order is kept';

########################################################################
# set once
########################################################################

my @again
= (
    {
        name    => 'set explicitly: filter=same_owner croaks'
      , arg     => 'filter=same_owner'
    }
  , {
        name    => 'set explicitly: filter=all again croaks'
      , arg     => 'filter=all'
    }
  , {
        name    => 'set explicitly: bare filter croaks'
      , arg     => 'filter'
    }
);

for my $case ( @again )
{
    my ( $name, $arg ) = @{ $case }{ qw( name arg ) };

    eval { File::Util::SecureDir->import( $arg ); 1 };

    like $@, qr{ already \s 'all' }x, $name;
}

is $secure->filter, 'all', 'after refused requests: filter unchanged';

done_testing;
