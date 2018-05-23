#! perl -w

use lib 't/lib';

use Test::Most;
use Test::MockModule;
use Test::JSONAPI;

my $method_called = 0;
my $dbix_row_mock = Test::MockModule->new('DBIx::Class::Row');
$dbix_row_mock->mock(
    get_inflated_columns => sub {
        my ($self, @rest) = @_;
        $method_called++;
        return $dbix_row_mock->original('get_inflated_columns')->($self, @rest);
    });

my $t = Test::JSONAPI->new({ api_url => 'http://example.com/api' });

is($t->attributes_via, 'get_inflated_columns', 'default attrs method');

my $post = $t->schema->resultset('Post')->find(1);

$t->resource_document($post);
is($method_called, 1, 'attrs method called once');

subtest 'custom attributes via constructor' => sub {

    # Cheating, provide a custom method to an already there object
    $dbix_row_mock->mock(
        to_hash => sub {
            $method_called++;
            return ();
        });

    $t = Test::JSONAPI->new({ api_url => 'http://example.com', attributes_via => 'to_hash' });
    $t->resource_document($post);
    is($method_called, 2, 'attributes method called');
};

subtest 'custom attributes via method argument' => sub {
    $dbix_row_mock->mock(
        another_hash_method => sub {
            $method_called++;
            return ();
        });

    $t = Test::JSONAPI->new({ api_url => 'http://example.com', attributes_via => 'to_hash' });
    $t->resource_document($post, { attributes_via => 'another_hash_method' });
    is($method_called, 3, 'attributes method called');
};

done_testing;
