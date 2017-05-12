use strict;
use Test::More (tests => 7);
use URI;

BEGIN
{
    use_ok("GunghoX::FollowLinks::Rule", "FOLLOW_ALLOW", "FOLLOW_DENY");
    use_ok("GunghoX::FollowLinks::Rule::Fresh");
}

my $rule = GunghoX::FollowLinks::Rule::Fresh->new(
    storage => {
        module => "Memory",
    }
);

ok($rule);
isa_ok($rule, "GunghoX::FollowLinks::Rule::Fresh");

my $url = URI->new("http://search.cpan.org");

is( $rule->apply(undef, undef, $url, undef), FOLLOW_ALLOW);
is( $rule->apply(undef, undef, $url, undef), FOLLOW_DENY);
is( $rule->apply(undef, undef, $url, undef), FOLLOW_DENY);

