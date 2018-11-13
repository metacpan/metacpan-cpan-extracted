use strict;
use warnings;

use Data::Dumper;
use Test::More;

my $CLASS = 'Geo::OLC::XS';

sub main {
    use_ok($CLASS);

    done_testing;
    return 0;
}

exit main();
