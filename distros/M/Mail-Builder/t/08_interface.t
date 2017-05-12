# -*- perl -*-

# t/08_interface.t - some interface tests

use Test::Most tests => 22 + 1;
use Test::NoWarnings;

use Mail::Builder;
use Email::Address;

lives_ok {
    my $object = Mail::Builder->new({
        from    => 'from@test1.com',
        to      => 'to@test1.com',
        subject => 'Test 1',
    });

    is($object->to->length,1,'Recipients ok');
    is($object->to->item(0)->email,'to@test1.com','To email ok');
    is($object->from->email,'from@test1.com','From email ok');
} 'Object 1 ok';

lives_ok {
    my $object = Mail::Builder->new({
        from    => {
            name    => 'Test2 From',
            email   => 'from@test2.com'
        },
        to      => {
            name    => 'Test2 To',
            email   => 'to@test2.com'
        },
        cc      => [
            {
                name    => 'Test2 CC',
                email   => 'cc1@test2.com'
            },
            'cc2@test2.com',
        ],
        subject => 'Test 2',
    });

    is($object->to->length,1,'Recipients ok');
    is($object->to->item(0)->email,'to@test2.com','To email ok');
    is($object->to->item(0)->name,'Test2 To','To name ok');

    is($object->cc->length,2,'CC ok');
    is($object->cc->item(0)->email,'cc1@test2.com','CC1 email ok');
    is($object->cc->item(0)->name,'Test2 CC','CC2 name ok');
    is($object->cc->item(1)->email,'cc2@test2.com','CC2 email ok');
    is($object->from->email,'from@test2.com','From email ok');

} 'Object 1 ok';

lives_ok {
    my $cc1 = Mail::Builder::Address->new( email => 'cc1@test3.com');
    my $cc2 = Mail::Builder::Address->new( email => 'cc2@test3.com');

    my $object = Mail::Builder->new({
        from    => ['from@test3.com','Test3 From'],
        to      => [['to@test3.com','Test3 To']],
        cc      => [$cc1,$cc2,'cc3@test3.com'],
        subject => 'Test 3',
    });

    is($object->to->length,1,'Recipients ok');
    is($object->to->item(0)->email,'to@test3.com','To email ok');
    is($object->to->item(0)->name,'Test3 To','To name ok');
    is($object->from->email,'from@test3.com','From email ok');
    is($object->cc->length,3,'CC ok');
    is($object->cc->item(0)->email,'cc1@test3.com','CC1 email ok');
    is($object->cc->item(1)->email,'cc2@test3.com','CC2 email ok');
    is($object->cc->item(2)->email,'cc3@test3.com','CC3 email ok');

} 'Object 1 ok';

