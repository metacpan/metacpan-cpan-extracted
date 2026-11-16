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

# Nothing here selects or latches a filter: this file ends with no
# filter set.

########################################################################
# load
########################################################################

use_ok( 'File::Util::SecureDir' )
or BAIL_OUT 'File::Util::SecureDir failed to load';

my $pkg = 'File::Util::SecureDir';

########################################################################
# interface exists
########################################################################

my @methodz = qw( new filter filter_dirs verbose debug import );

for my $method ( @methodz )
{
    ok $pkg->can( $method ), "interface: $method exists";
}

like $pkg->VERSION, qr{ \A v\d+ [.] \d+ [.] \d+ \z }x
, 'version: dotted-decimal v-string';

########################################################################
# singleton
########################################################################

is $pkg->new, $pkg, 'new: returns the package name';

is $pkg->new, $pkg->new, 'new: same value every time';

########################################################################
# filter accessor
########################################################################

is $pkg->filter, '', 'filter: empty before any filter is chosen';

eval { $pkg->filter( 'all' ); 1 };

like $@, qr{ read-only }x, 'filter: an argument croaks (read-only)';

is $pkg->filter, '', 'filter: still empty after the refused argument';

done_testing;
