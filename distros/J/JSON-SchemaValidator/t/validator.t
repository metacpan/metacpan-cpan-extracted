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

done_testing;
