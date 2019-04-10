
BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    print qq{1..0 # SKIP these tests are for release candidate testing\n};
    exit
  }
}

use Test::More;
use Device::Firewall::PaloAlto;

my $fw = Device::Firewall::PaloAlto->new(verify_hostname => 0)->auth;
ok($fw, "Firewall Object") or BAIL_OUT("Unable to connect to FW object: @{[$fw->error]}");


my $counters = $fw->op->global_counters;
isa_ok($counters, 'Device::Firewall::PaloAlto::Op::GlobalCounters');

# Name that doesn't exist returns false
ok(! $counters->name('non_existent_name'), 'No Counter' );

for my $counter ($counters->to_array) {
    my $name = $counter->name;
    my $c = $counters->name($name);
    isa_ok($c, 'Device::Firewall::PaloAlto::Op::GlobalCounter');
    cmp_ok($c->value, '==', $counter->value, 'Counter Values');

    like($c->value, qr(\d+), 'Counter Value');
    like($c->rate, qr(\d+), 'Counter Rate');
    
}

done_testing();
    
