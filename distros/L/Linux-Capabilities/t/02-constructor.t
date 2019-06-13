use Test::More;
use Test::Exception;

use Linux::Capabilities;

my $obj = Linux::Capabilities->empty;
ok $obj, 'constructed';# "creating my capabilities set"

my $obj = Linux::Capabilities->new;
ok $obj, 'constructed';# "creating my capabilities set"

$obj = Linux::Capabilities->new("cap_chown=p");
ok $obj, 'constructed';# "creating capabilities set by string"

my $pid = $$;
$obj = Linux::Capabilities->new($$);
ok $obj, 'constructed';# "creating some(pid: $pid) proccess capabilities set"

my $bad_pid = 1234567890;
throws_ok(sub { Linux::Capabilities->new($bad_pid); }, qr/can't access proccess, pid: $bad_pid/, "constructing from bad pid");

my $bad_string = "bad_string";
throws_ok(sub { Linux::Capabilities->new($bad_string); }, qr/cap_from_text failed, input: $bad_string/, "constructing from bad string");

done_testing;