#!perl -T
use warnings;
use strict;

use Test::More;

BEGIN { use_ok('Lab::Zhinst') };

my ($rv, $conn) = Lab::Zhinst->Init();
is($rv, 0, "Init retval");
isa_ok($conn, 'Lab::Zhinst');

($rv) = $conn->Connect('localhost', 8004);
is($rv, 0, "Connect retval");


($rv, my $implementations) = ziAPIListImplementations();
is($rv, 0, "ListImplementations retval");

# this test fails for LabOne 21.08 -> comment out for now

# is($implementations, "ziAPI_Core\nziAPI_AsyncSocket\nziAPI_ziServer1",
#     "ListImplementations");

($rv, my $api_level) = $conn->GetConnectionAPILevel();
is($rv, 0, "GetConnectionAPILevel retval");
is($api_level, 1, "GetConnectionAPILevel");

my $buffer_size = 100000;
($rv, my $nodes) = $conn->ListNodes("/", $buffer_size,
                                    ZI_LIST_NODES_ABSOLUTE | ZI_LIST_NODES_RECURSIVE);
is($rv, 0, "ListNodes retval");
like($nodes, qr{/zi/about/version}i, "ListNodes");

for my $getter (qw/GetValueD GetValueI/) {
    my ($rv, $value) = $conn->$getter('/zi/config/port');
    is($rv, 0, "$getter retval");
    is($value, 8004, "$getter");
}

($rv, my $value_b) = $conn->GetValueB('/zi/about/copyright', 100);
is($rv, 0, "GetValueB retval");
like($value_b, qr/Zurich Instruments/, "GetValueB");


($rv, my $error_string) = ziAPIGetError(ZI_ERROR_LENGTH);
is($rv, 0, "ziAPIGetError retval");
like($error_string, qr/Provided Buffer is too small/i, "ziAPIGetError");



#
# Data Streaming
#
{
    my $event = ziAPIAllocateEventEx();
    isa_ok($event, "Lab::Zhinst::ZIEvent");
    my $path = '/ZI/CONFIG/PORT';
    my ($rv) = $conn->Subscribe($path);
    is($rv, 0, "Subscribe retval");

    for (1..3) {
        ($rv) = $conn->GetValueAsPollData($path);
        is($rv, 0, "GetValueAsPollData retval");
    }

    for (1..3) {
        ($rv, my $data) = $conn->PollDataEx($event, 1000);
        is($rv, 0, "PollDataEx retval");

        is($data->{valueType}, ZI_VALUE_TYPE_INTEGER_DATA, "data valueType");
        is($data->{count}, 1, "data count");
        is_deeply($data->{values}, [8004], "data values");
    }

    ($rv, my $data) = $conn->PollDataEx($event, 1000);
    is($rv, 0, "PollDataEx retval");

    is($data->{valueType}, ZI_VALUE_TYPE_NONE, "data valueType");
    is($data->{count}, 0, "data count");
    is_deeply($data->{values}, [], "data values");

    ($rv) = $conn->UnSubscribe($path);
    is($rv, 0, "UnSubscribe retval");
}



($rv) = $conn->Disconnect();
is($rv, 0, "Disconnect retval");
done_testing();
