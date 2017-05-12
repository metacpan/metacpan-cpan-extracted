use strict;
use warnings;

use Test::More;
use Test::Exception;

use Lavoco::Web::App;

my @methods = qw( dev processes base _pid _socket templates start stop restart _handler filename config );

my $empty;

lives_ok { $empty = Lavoco::Web::App->new } "instantiated new ok";

foreach my $method ( @methods )
{
	can_ok( $empty, $method );
}



done_testing();
