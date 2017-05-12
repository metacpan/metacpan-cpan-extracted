=head1 PURPOSE

Testing required versus optional properties.

=cut

use Test::More;
use strict;
use warnings;
use JSON::Schema;

my $schema1 = JSON::Schema->new({
    type => 'object',
    properties => {
        mynumber => { required => 1 }
    },
	 additionalProperties => {},
});

my $schema2 = JSON::Schema->new({
    type => 'object',
    properties => {
        mynumber => { required => 0 }
    },
	 additionalProperties => {},
});

my $schema3 = JSON::Schema->new({
    type => 'object',
    properties => {
        mynumber => { optional => 1 }
    },
	 additionalProperties => {},
});

my $schema4 = JSON::Schema->new({
    type => 'object',
    properties => {
        mynumber => { optional => 0 }
    },
	 additionalProperties => {},
});

my $data1 = { mynumber => 1 };
my $data2 = { mynumbre => 1 };

my $result = $schema1->validate($data1);
ok $result, 'A'
  or map { diag "reason: $_" } $result->errors;

$result = $schema1->validate($data2);
ok !$result, 'B'
  or map { diag "reason: $_" } $result->errors;

$result = $schema2->validate($data1);
ok $result, 'C'
  or map { diag "reason: $_" } $result->errors;

$result = $schema2->validate($data2);
ok $result, 'D'
  or map { diag "reason: $_" } $result->errors;

$result = $schema3->validate($data1);
ok $result, 'E'
  or map { diag "reason: $_" } $result->errors;

$result = $schema3->validate($data2);
ok $result, 'F'
  or map { diag "reason: $_" } $result->errors;

$result = $schema4->validate($data1);
ok $result, 'G'
  or map { diag "reason: $_" } $result->errors;

$result = $schema4->validate($data2);
ok !$result, 'H'
  or map { diag "reason: $_" } $result->errors;

done_testing;

