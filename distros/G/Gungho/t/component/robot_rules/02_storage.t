use strict;
use Test::More (tests => 5);
use Test::MockObject::Extends;

BEGIN
{
    use_ok("Gungho::Component::RobotRules::Storage");
}

{
    # Test base class (everything should be virtual)
    my $mock = Test::MockObject::Extends->new( 'Gungho::Component::RobotRules::Storage' );

    # These should be virtual methods. 
    foreach my $method qw(get_rule put_rule get_pending_robots_txt push_pending_robots_txt) {
        eval { $mock->$method };
        like($@, qr/is not overridden/);
    }
}