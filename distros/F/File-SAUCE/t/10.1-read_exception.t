use Test::More tests => 4;

use strict;
use warnings;

use_ok( 'File::SAUCE' );

my $sauce = File::SAUCE->new;
isa_ok( $sauce, 'File::SAUCE' );

{
    eval { $sauce->read( file => 't/data/dne.txt' ); };
    ok( $@, 'Read (fail - file not found)' );
}

{
    eval { $sauce->read( invalid => 'data' ); };
    ok( $@, 'Read (fail - invalid input)' );
}
