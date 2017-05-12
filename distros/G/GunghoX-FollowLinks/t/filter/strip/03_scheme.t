use strict;
use Test::More (tests => 4);
use Test::MockObject;
use Class::Null;

BEGIN
{
    use_ok("GunghoX::FollowLinks::Filter::Strip");
}

{
    my $filter = GunghoX::FollowLinks::Filter::Strip->new();
    ok($filter);

    my $uri    = URI->new('mailto:foo@example.com');
    my $c      = Test::MockObject->new;
    $c->mock(log => sub { Class::Null->new });

    $filter->apply($c, $uri);

#    ok( ! $uri->userinfo ); # not applicable
    ok( ! $uri->query );
    ok( ! $uri->fragment );
}