use strict;
use warnings;
use Test::More;

use lib 'lib';
use lib '../XS-JIT/blib/lib';
use lib '../XS-JIT/blib/arch';

use Hypersonic;

plan tests => 10;

# Test multi-parameter path parsing in route registration

# Test 1: Single parameter path registration
{
    my $server = Hypersonic->new(cache_dir => '_test_cache_mp1');
    $server->get('/users/:id' => sub {
        my ($req) = @_;
        my $id = $req->id;
        return qq({"id":"$id"});
    });
    
    my $route = $server->{routes}[0];
    is(scalar @{$route->{params}}, 1, 'Single param path has 1 param');
    is($route->{params}[0]{name}, 'id', 'Param name is "id"');
    is($route->{params}[0]{position}, 1, 'Param position is 1 (users is 0)');
    is($route->{dynamic}, 1, 'Route is marked dynamic');
}

# Test 2: Multi-parameter path registration
{
    my $server = Hypersonic->new(cache_dir => '_test_cache_mp2');
    $server->get('/users/:user_id/posts/:post_id' => sub {
        my ($req) = @_;
        my $id = $req->id; # id is last segment
        return qq({"user":"$id"});
    });
    
    my $route = $server->{routes}[0];
    is(scalar @{$route->{params}}, 2, 'Multi param path has 2 params');
    is($route->{params}[0]{name}, 'user_id', 'First param is user_id');
    is($route->{params}[1]{name}, 'post_id', 'Second param is post_id');
    is($route->{dynamic}, 1, 'Route is marked dynamic');
}

# Test 3: Path segments parsing
{
    my $server = Hypersonic->new(cache_dir => '_test_cache_mp3');
    $server->get('/api/v1/users/:id/comments/:comment_id' => sub {
        my ($req) = @_;
        return '{}';
    });
    
    my $route = $server->{routes}[0];
    is(scalar @{$route->{segments}}, 6, 'Path has 6 segments');
    
    my @expected = ('api', 'v1', 'users', ':id', 'comments', ':comment_id');
    is_deeply($route->{segments}, \@expected, 'Segments parsed correctly');
}

# Cleanup
for my $i (1..3) {
    my $dir = "_test_cache_mp$i";
    system("rm -rf $dir") if -d $dir;
}

done_testing();
