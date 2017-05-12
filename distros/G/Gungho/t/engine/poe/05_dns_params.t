use strict;
use Test::More;
BEGIN
{
    eval "use Gungho::Engine::POE";
    if ($@) {
        plan(skip_all => "POE not available");
    } else {
        plan(tests => 3);
        use_ok("Gungho::Inline");
    }
}

my %dns_params = (
                     # key => value
    timeout     => [ &POE::Component::Client::DNS::SF_TIMEOUT, 10 ],
    nameservers => [ &POE::Component::Client::DNS::SF_NAMESERVERS,  [ map { "127.0.0.$_" } (1..10) ] ]
);

Gungho::Inline->run(
    {
        user_agent => "Install Test For Gungho $Gungho::VERSION",
        engine => {
            module => q(POE),
            config => {
                dns => { map { ($_ => $dns_params{$_}->[1]) } keys %dns_params }
            },
        },
    },
    {
        provider => sub {
            my ($p, $c) = @_;
            my $r = $c->engine->resolver;
            while (my ($name, $data) = each %dns_params) {
                my($key, $value) = (@$data);
                is_deeply($r->[$key], $value, "DNS preference $name = $value");
            }
            undef;
        },
        handler => sub { },
    },
);
