use strict;
use warnings;

use Test::More;

use JSON;
use JSON::SchemaValidator::Result;

subtest 'is success by default' => sub {
    my $result = JSON::SchemaValidator::Result->new;
    ok($result->is_success);
};

subtest 'not success when errors' => sub {
    my $result = JSON::SchemaValidator::Result->new;
    $result->add_error(
        message   => 'Error!',
        attribute => 'type',
        uri       => '#/field'
    );
    ok(!$result->is_success);
};

subtest 'return errors' => sub {
    my $result = JSON::SchemaValidator::Result->new;
    $result->add_error(
        message   => 'Error!',
        attribute => 'type',
        uri       => '#/field',
        details   => ['string']
    );
    is_deeply(
        $result->errors,
        [
            {
                message   => 'Error!',
                attribute => 'type',
                details   => ['string'],
                uri       => '#/field'
            }
        ]
    );
};

subtest 'add errors from other objects' => sub {
    my $result = JSON::SchemaValidator::Result->new;
    $result->add_error(
        message   => 'Error!',
        attribute => 'type',
        uri       => '#/field',
        details   => ['string']
    );

    my $subresult = JSON::SchemaValidator::Result->new(root => '#/field');
    $subresult->add_error(
        message   => 'Another error',
        uri       => '#/sub',
        attribute => 'type',
        details   => ['string']
    );

    $result->add_error($subresult);

    is_deeply(
        $result->errors,
        [
            {
                message   => 'Error!',
                attribute => 'type',
                details   => ['string'],
                uri       => '#/field'
            },
            {
                message   => 'Another error',
                attribute => 'type',
                details   => ['string'],
                uri       => '#/field/sub'
            }
        ]
    );
};

done_testing;
