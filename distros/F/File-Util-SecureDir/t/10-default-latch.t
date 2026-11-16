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

# No filter is chosen by the #! code (this file), so the first call to
# filter_dirs latches the default, other_no_write.  This file ends in
# other_no_write.  Checks that need the unlatched state come first.

use File::Util::SecureDir;

my $secure  = File::Util::SecureDir->new;
my $root    = tempdir( CLEANUP => 1 );

# plain-perl fixture: a directory of the given mode, owned by us.

my $mkdir
= sub( $name, $mode )
{
    my $dir = catdir $root, $name;

    mkdir $dir or BAIL_OUT "Failed mkdir '$dir': $!";
    chmod $mode, $dir;

    $dir
};

########################################################################
# before the latch
########################################################################

is $secure->filter, '', 'default: no filter before the first filter_dirs';

########################################################################
# the first filter_dirs latches the default
########################################################################

my @none = $secure->filter_dirs;

is scalar @none, 0, 'filter_dirs: an empty list gives an empty list';

is $secure->filter, 'other_no_write', 'default: first filter_dirs latches it';

########################################################################
# other_no_write against directory modes, one mode per test
########################################################################

my @casez
= (
    {
        name    => 'other_no_write: mode 0700 accepted'
      , mode    => 0700
      , expect  => 1
    }
  , {
        name    => 'other_no_write: mode 0755 accepted'
      , mode    => 0755
      , expect  => 1
    }
  , {
        name    => 'other_no_write: mode 0770 accepted (group write is fine)'
      , mode    => 0770
      , expect  => 1
    }
  , {
        name    => 'other_no_write: mode 0775 accepted (group write is fine)'
      , mode    => 0775
      , expect  => 1
    }
  , {
        name    => 'other_no_write: mode 0702 rejected (other write only)'
      , mode    => 0702
      , expect  => 0
    }
  , {
        name    => 'other_no_write: mode 0757 rejected'
      , mode    => 0757
      , expect  => 0
    }
  , {
        name    => 'other_no_write: mode 0777 rejected'
      , mode    => 0777
      , expect  => 0
    }
);

for my $case ( @casez )
{
    my ( $name, $mode, $expect ) = @{ $case }{ qw( name mode expect ) };

    my $dir   = $mkdir->( sprintf( 'm%04o', $mode ), $mode );
    my @clean = $secure->filter_dirs( $dir );

    is scalar @clean, $expect, $name;
}

########################################################################
# lists: order and mixtures
########################################################################

my @good = map { $mkdir->( "good$_", 0755 ) } 1 .. 3;
my $bad  = $mkdir->( 'bad', 0777 );

is_deeply [ $secure->filter_dirs( @good[ 2, 0, 1 ] ) ]
, [ @good[ 2, 0, 1 ] ]
, 'filter_dirs: accepted directories keep the order given';

is_deeply [ $secure->filter_dirs( $good[0], $bad, $good[1] ) ]
, [ @good[ 0, 1 ] ]
, 'filter_dirs: a rejected directory is dropped, the rest keep their order';

is scalar( () = $secure->filter_dirs( $bad, $bad ) ), 0
, 'filter_dirs: all rejected gives an empty list';

########################################################################
# a directory that cannot be read is rejected with one warning
########################################################################

my $missing = catdir $root, 'no-such-dir';
my @warnz   = ();
my @gone    = ();

{
    local $SIG{ __WARN__ } = sub { push @warnz, @_ };

    @gone = $secure->filter_dirs( $missing );
}

is scalar @gone, 0, 'missing directory: rejected';

is scalar @warnz, 1, 'missing directory: exactly one warning';

like $warnz[0], qr{ \Q$missing\E }x, 'missing directory: warning names the path';

########################################################################
# the filter is set once: a later request croaks and changes nothing
########################################################################

my @again
= (
    {
        name    => 'after the latch: filter=all croaks'
      , arg     => 'filter=all'
    }
  , {
        name    => 'after the latch: filter=other_no_write croaks'
      , arg     => 'filter=other_no_write'
    }
  , {
        name    => 'after the latch: filter=same_owner croaks'
      , arg     => 'filter=same_owner'
    }
  , {
        name    => 'after the latch: bare filter croaks'
      , arg     => 'filter'
    }
);

for my $case ( @again )
{
    my ( $name, $arg ) = @{ $case }{ qw( name arg ) };

    eval { File::Util::SecureDir->import( $arg ); 1 };

    like $@, qr{ already \s 'other_no_write' }x, $name;
}

is $secure->filter, 'other_no_write', 'after refused requests: filter unchanged';

done_testing;
