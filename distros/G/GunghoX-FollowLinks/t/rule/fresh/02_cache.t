use strict;
use Test::More;
use URI;

BEGIN
{
    eval "use Cache::Memory";
    if ($@) {
        plan skip_all => "Cache::Memory not installed";
    } else {
        plan tests => 7;
        use_ok("GunghoX::FollowLinks::Rule", "FOLLOW_ALLOW", "FOLLOW_DENY");
        use_ok("GunghoX::FollowLinks::Rule::Fresh");
    }
}

my $rule = GunghoX::FollowLinks::Rule::Fresh->new(
    storage => {
        module => "Cache",
        config => {
            cache => {
                module => "+Cache::Memory",
                config => {
                    namespace => "GunghoX-FreshLinks",
                    default_expires => "10 sec",
                }
            }
        }
    }
);

ok($rule);
isa_ok($rule, "GunghoX::FollowLinks::Rule::Fresh");

my $url = URI->new("http://search.cpan.org");

is( $rule->apply(undef, undef, $url, undef), FOLLOW_ALLOW);
is( $rule->apply(undef, undef, $url, undef), FOLLOW_DENY);

diag('sleeping for 10');
sleep 10;
is( $rule->apply(undef, undef, $url, undef), FOLLOW_ALLOW);

