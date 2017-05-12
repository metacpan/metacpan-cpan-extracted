use Kelp::Base -strict;
use Test::More;
use Kelp;

my $app = Kelp->new;
is $app->template( \'<: $bar :>', { bar => 'foo' } ), 'foo';
like $app->template( "home", { name => 'Julie' } ), qr'Hello, Julie';

done_testing;
