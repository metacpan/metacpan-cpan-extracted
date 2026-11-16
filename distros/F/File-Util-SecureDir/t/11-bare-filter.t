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

# A bare 'filter' from the #! code makes the default explicit.  This
# file ends in other_no_write, reached before any filter_dirs call.

use File::Util::SecureDir qw( filter );

my $secure  = File::Util::SecureDir->new;
my $root    = tempdir( CLEANUP => 1 );

my $mkdir
= sub( $name, $mode )
{
    my $dir = catdir $root, $name;

    mkdir $dir or BAIL_OUT "Failed mkdir '$dir': $!";
    chmod $mode, $dir;

    $dir
};

########################################################################
# selection
########################################################################

is $secure->filter, 'other_no_write'
, 'bare filter: selects other_no_write without any filter_dirs call';

########################################################################
# the selected handler is other_no_write, not a permissive one
########################################################################

my $open   = $mkdir->( 'open',   0777 );
my $closed = $mkdir->( 'closed', 0755 );

is scalar( () = $secure->filter_dirs( $open ) ), 0
, 'bare filter: mode 0777 rejected';

is scalar( () = $secure->filter_dirs( $closed ) ), 1
, 'bare filter: mode 0755 accepted';

########################################################################
# set once
########################################################################

eval { File::Util::SecureDir->import( 'filter=all' ); 1 };

like $@, qr{ already \s 'other_no_write' }x
, 'bare filter: a later filter=all croaks';

is $secure->filter, 'other_no_write', 'bare filter: filter unchanged';

done_testing;
