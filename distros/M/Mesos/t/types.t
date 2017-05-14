use Test::More;
use strict;
use warnings;

use Types::Standard qw(slurpy Dict);
use Type::Params qw(validate);

BEGIN {
    use_ok('Mesos::Types');
    Mesos::Types->import(':all');
}

my $framework_constructor = {
    user => "test-user",
    name => "test-name",    
};
my $accepts_framework = sub {
    my ($framework) = validate(\@_, FrameworkInfo);
    return $framework;
};
isa_ok(
    $accepts_framework->($framework_constructor),
    'Mesos::FrameworkInfo',
    'coerced FrameworkInfo',
);

my %framework_hash = (
    framework => $framework_constructor,
);
my $accepts_framework_hash = sub {
    my ($params) = validate(\@_, slurpy Dict[framework => FrameworkInfo]);
    return $params->{framework};
};
isa_ok(
    $accepts_framework_hash->(%framework_hash),
    'Mesos::FrameworkInfo',
    'coerced hash with FrameworkInfo',
);

done_testing;
