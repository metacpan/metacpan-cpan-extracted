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

# group_no_write rejects a directory that the group or others can write.
# The directories are ours, so the owner never decides the result.  This
# file ends in group_no_write.

use File::Util::SecureDir qw( filter=group_no_write );

my $secure  = File::Util::SecureDir->new;
my $root    = tempdir( CLEANUP => 1 );

########################################################################
# selection
########################################################################

is $secure->filter, 'group_no_write', 'group_no_write: selected';

########################################################################
# modes, one mode per test
########################################################################

my @casez
= (
    {
        name    => 'group_no_write: mode 0700 accepted'
      , mode    => 0700
      , expect  => 1
    }
  , {
        name    => 'group_no_write: mode 0750 accepted'
      , mode    => 0750
      , expect  => 1
    }
  , {
        name    => 'group_no_write: mode 0755 accepted'
      , mode    => 0755
      , expect  => 1
    }
  , {
        name    => 'group_no_write: mode 0720 rejected (group write only)'
      , mode    => 0720
      , expect  => 0
    }
  , {
        name    => 'group_no_write: mode 0770 rejected'
      , mode    => 0770
      , expect  => 0
    }
  , {
        name    => 'group_no_write: mode 0775 rejected'
      , mode    => 0775
      , expect  => 0
    }
  , {
        name    => 'group_no_write: mode 0702 rejected (other write only)'
      , mode    => 0702
      , expect  => 0
    }
  , {
        name    => 'group_no_write: mode 0757 rejected'
      , mode    => 0757
      , expect  => 0
    }
  , {
        name    => 'group_no_write: mode 0777 rejected'
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

like $@, qr{ already \s 'group_no_write' }x
, 'group_no_write: a later filter=all croaks';

is $secure->filter, 'group_no_write', 'group_no_write: filter unchanged';

done_testing;
