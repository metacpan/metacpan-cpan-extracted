use strict;
use Test::More (tests => 21);
use Test::MockObject;
use Class::Null;

BEGIN
{
    use_ok("GunghoX::FollowLinks::Filter::Strip");
}

{
    my $filter = GunghoX::FollowLinks::Filter::Strip->new();
    ok($filter);

    my $uri    = URI->new('http://user:password@server.com/?hoge=bar#foo');
    my $c      = Test::MockObject->new;
    $c->mock(log => sub { Class::Null->new });

    $filter->apply($c, $uri);

    ok( ! $uri->userinfo );
    ok( ! $uri->query );
    ok( ! $uri->fragment );
}

{
    my $filter = GunghoX::FollowLinks::Filter::Strip->new(strip_userinfo => 0);
    ok($filter);

    my $uri    = URI->new('http://user:password@server.com/?hoge=bar#foo');
    my $c      = Test::MockObject->new;
    $c->mock(log => sub { Class::Null->new });

    $filter->apply($c, $uri);

    ok(   $uri->userinfo );
    ok( ! $uri->query );
    ok( ! $uri->fragment );
}

{
    my $filter = GunghoX::FollowLinks::Filter::Strip->new(strip_query => 0);
    ok($filter);

    my $uri    = URI->new('http://user:password@server.com/?hoge=bar#foo');
    my $c      = Test::MockObject->new;
    $c->mock(log => sub { Class::Null->new });

    $filter->apply($c, $uri);

    ok( ! $uri->userinfo );
    ok(   $uri->query );
    ok( ! $uri->fragment );
}

{
    my $filter = GunghoX::FollowLinks::Filter::Strip->new(strip_fragment => 0);
    ok($filter);

    my $uri    = URI->new('http://user:password@server.com/?hoge=bar#foo');
    my $c      = Test::MockObject->new;
    $c->mock(log => sub { Class::Null->new });

    $filter->apply($c, $uri);

    ok( ! $uri->userinfo );
    ok( ! $uri->query );
    ok(   $uri->fragment );
}

{
    my $filter = GunghoX::FollowLinks::Filter::Strip->new();
    ok($filter);

    my $uri    = URI->new('http://%E2%D3%F4%A5@hoge');
    my $c      = Test::MockObject->new;
    $c->mock(log => sub { Class::Null->new });

    $filter->apply($c, $uri);

    ok( ! $uri->userinfo );
    ok( ! $uri->query );
    ok( ! $uri->fragment );
}

1;