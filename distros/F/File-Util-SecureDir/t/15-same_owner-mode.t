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

# same_owner is the strictest filter: the group and other write bits are
# checked as in group_no_write, and then the owner.  Ownership is tested
# in 14-same_owner-euid.t.  Here every directory is ours, so the owner
# check always passes and only the mode decides.  This file ends in
# same_owner.

use File::Util::SecureDir qw( filter=same_owner );

my $secure  = File::Util::SecureDir->new;
my $root    = tempdir( CLEANUP => 1 );

########################################################################
# modes, one mode per test
########################################################################

my @casez
= (
    {
        name    => 'same_owner: own directory, mode 0700 accepted'
      , mode    => 0700
      , expect  => 1
    }
  , {
        name    => 'same_owner: own directory, mode 0755 accepted'
      , mode    => 0755
      , expect  => 1
    }
  , {
        name    => 'same_owner: own directory, mode 0720 rejected'
      , mode    => 0720
      , expect  => 0
    }
  , {
        name    => 'same_owner: own directory, mode 0775 rejected'
      , mode    => 0775
      , expect  => 0
    }
  , {
        name    => 'same_owner: own directory, mode 0702 rejected'
      , mode    => 0702
      , expect  => 0
    }
  , {
        name    => 'same_owner: own directory, mode 0777 rejected'
      , mode    => 0777
      , expect  => 0
    }
);

for my $case ( @casez )
{
    my ( $name, $mode, $expect ) = @{ $case }{ qw( name mode expect ) };

    my $dir = catdir $root, sprintf 'm%04o', $mode;

    mkdir $dir or BAIL_OUT "Failed mkdir '$dir': $!";
    chmod $mode, $dir;

    is scalar( () = $secure->filter_dirs( $dir ) ), $expect, $name;
}

########################################################################
# set once
########################################################################

eval { File::Util::SecureDir->import( 'filter=all' ); 1 };

like $@, qr{ already \s 'same_owner' }x
, 'same_owner: a later filter=all croaks';

is $secure->filter, 'same_owner', 'same_owner: filter unchanged';

done_testing;
