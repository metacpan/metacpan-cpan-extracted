=head1 PURPOSE

Various tests validating integers - mostly maxima and minima.

=cut

use Test::More;
use strict;
use warnings;
use JSON::Schema;

my $schema = JSON::Schema->new({
    type => 'object',
    properties => {
        mynumber => { type => 'integer', minimum => 1, maximum=>4 }
    }
});

subtest 'maximum minimum integer' => sub {
    my $data = { mynumber => 1 };
    my $result = $schema->validate($data);
    ok $result, 'min'
        or map { diag "reason: $_" } $result->errors;

    $data = { mynumber => 4 };
    $result = $schema->validate($data);
    ok $result, 'max'
        or map { diag "reason: $_" } $result->errors;

    $data = { mynumber => 2 };
    $result = $schema->validate($data);
    ok $result, 'in the middle'
        or map { diag "reason: $_" } $result->errors;

    $data = { mynumber => 0};
    $result = $schema->validate($data);
    ok !$result, 'too small'
        or map { diag "reason: $_" } $result->errors;

    $data = { mynumber => -1 };
    $result = $schema->validate($data);
    ok !$result, 'too small and neg'
        or map { diag "reason: $_" } $result->errors;

    $data = { mynumber => 5 };
    $result = $schema->validate($data);
    ok !$result, 'too big'
        or map { diag "reason: $_" } $result->errors;

    done_testing;
};

done_testing;

