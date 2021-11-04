use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Object::Pad;
class Example isa IO::AsyncX::Notifier {
    use Ryu::Observable;
    has $slot_to_populate = "empty";
    has $slot_to_leave_alone = "untouched";
    has $observable_slot { Ryu::Observable->new };

    method populated () { $slot_to_populate }
    method untouched () { $slot_to_leave_alone }
    method observable () { $observable_slot }
}

my $obj = new_ok('Example', [ slot_to_populate => "not empty" ]);
is($obj->populated, 'not empty', 'start with expected value for slot');
is($obj->untouched, 'untouched', 'control var is untouched');
is($obj->observable->value, undef, 'observable starts undefined');
$obj->observable->set_string('');
$obj->configure(
    slot_to_populate => 'new value',
    observable_slot => 'changed data',
);
is($obj->populated, 'new value', 'start with expected default value for slot');
is($obj->untouched, 'untouched', 'control var is untouched');
is($obj->observable->value, 'changed data', 'observable picks up new data too');
like(exception {
    $obj->configure(
        unknown_key => 'new value',
    );
}, qr/Unrecognised configuration/i, 'throws an exception when given unknown keys');

done_testing;
