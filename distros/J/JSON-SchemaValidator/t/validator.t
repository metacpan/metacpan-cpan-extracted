use strict;
use warnings;

use Test::More;

use JSON::SchemaValidator;

my $validator = JSON::SchemaValidator->new;

subtest 'validate object' => sub {
    is_deeply $validator->validate([1], {type => 'object'})->errors,
      [
        {
            uri       => '#',
            message   => "Must be of type object",
            attribute => 'type',
            details   => ['object']
        }
      ];
};

subtest 'oneOf' => sub {
    my $result = $validator->validate(
        {},
        {
            type       => 'object',
            properties => {
                foo => {type => 'string'},
                bar => {type => 'string'},
            },
            oneOf => [{required => ['foo']}, {required => ['bar']}],
        }
    );

    is_deeply $result->errors,
      [
        {
            uri       => '#',
            message   => "Must be one of",
            attribute => 'oneOf',
            details   => [
                {
                    'uri'       => '#/foo',
                    'details'   => ['(true)'],
                    'attribute' => 'required',
                    'message'   => 'Required'
                },
                {
                    'details'   => ['(true)'],
                    'uri'       => '#/bar',
                    'message'   => 'Required',
                    'attribute' => 'required'
                }
            ]
        }
      ];
};

done_testing;
