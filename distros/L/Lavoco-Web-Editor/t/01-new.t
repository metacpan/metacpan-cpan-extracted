use strict;
use warnings;

use Test::More;
use Test::Exception;

use Lavoco::Web::Editor;

my @methods = qw( processes _base _pid _socket start stop restart _handler filename config _reload_config _template_tt );

my $empty;

lives_ok { $empty = Lavoco::Web::Editor->new } "instantiated new ok";

foreach my $method ( @methods )
{
	can_ok( $empty, $method );
}

done_testing();
