use strict;
use Test::More;
use Test::MockObject;

BEGIN
{
    eval "Gungho::Component::RobotRules";
    if ($@) {
        plan skip_all => "RobotRules is not enabled";
    } else {
        plan tests => 6;
    }

    use_ok("URI");
    use_ok("WWW::RobotRules::Parser");
    use_ok("Gungho::Component::RobotRules");
}

my $uri    = URI->new("http://search.cpan.org");
my $parser = WWW::RobotRules::Parser->new();
my $c      = Test::MockObject->new();
$c->set_always(user_agent => 'Gungho Crawler UserAgent');

{ # Disallow all paths for all user agents
    my $h = $parser->parse( $uri, <<EORULES );
User-Agent: *
Disallow: /
EORULES
    my $rule   = Gungho::Component::RobotRules::Rule->new($h);
    ok(! $rule->allowed($c, $uri), "should be disallwed");
}

{ # Disallow one path for all user agents
    my $h = $parser->parse( $uri, <<EORULES );
User-Agent: *
Disallow: /recent
EORULES
    my $rule   = Gungho::Component::RobotRules::Rule->new($h);
    ok($rule->allowed($c, $uri), "should be allowed");

    my $uri2 = $uri->clone;
    $uri2->path('/recent');
    ok(! $rule->allowed($c, $uri2), "should be disallowed");
}

