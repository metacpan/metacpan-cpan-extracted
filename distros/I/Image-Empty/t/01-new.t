use strict;
use warnings;

use Test::More;
use Test::Exception;

use Image::Empty;

my @methods = qw( type length filename disposition content );

my $empty;

lives_ok { $empty = Image::Empty->new } "instantiated new ok";

foreach my $method ( @methods )
{
	can_ok( $empty, $method );
}



done_testing();
