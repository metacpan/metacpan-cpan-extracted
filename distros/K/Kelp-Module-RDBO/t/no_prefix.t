use Kelp::Base -strict;
use Test::More;
use lib 't/lib';
use MyApp;

my $app = MyApp->new( mode => 'no_prefix' );

eval { $app->rdbo('Author')->new( name => 'George Orwell' ); };

ok !$@ or diag $@;

done_testing;
