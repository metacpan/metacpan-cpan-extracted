use Test::More tests => 2;

use strict;
use warnings;

BEGIN {
    use_ok( 'File::SAUCE' );
}

my $sauce = File::SAUCE->new;
isa_ok( $sauce, 'File::SAUCE' );
