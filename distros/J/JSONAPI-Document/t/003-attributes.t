#! perl -w

use lib 't/lib';

use Test::Most;
use Test::MockModule;
use Test::MockObject;
use Test::JSONAPI;

use Moo::Role;

subtest 'attributes are taken from get_inflated_columns by default' => sub {
    my $method_called = 0;
    my $dbix_row_mock = Test::MockModule->new('DBIx::Class::Row');
    $dbix_row_mock->mock(
        get_inflated_columns => sub {
            my ($self, @rest) = @_;
            $method_called++;
            return $dbix_row_mock->original('get_inflated_columns')->($self, @rest);
        });

    my $t = Test::JSONAPI->new({ api_url => 'http://example.com/api' });

    my $post = $t->schema->resultset('Post')->find(1);

    $t->resource_document($post);
    is($method_called, 1, 'attrs method called once');
};

subtest 'custom attributes from role inclusion' => sub {
    my $method_called = 0;
    my $mock          = Test::MockObject->new();
    $mock->fake_module(
        'ResultSource',
        new         => sub { return bless {}, $_[0] },
        source_name => sub { 'random' });
    $mock->fake_module(
        'TestDocument',
        new => sub {
            my $self = bless {}, $_[0];
            Moo::Role->apply_roles_to_object($self, 'JSONAPI::Document::Role::Attributes');
        },
        id => sub {
            123;
        },
        attributes => sub {
            my ($self, $fields) = @_;
            $method_called++;
            is_deeply($fields, [qw/one two three/], 'sent sparse fields to custom method');
            return { test => 1 };
        },
        result_source => sub {
            ResultSource->new();
        });

    my $t = Test::JSONAPI->new({ api_url => 'http://example.com' });
    my $doc = $t->resource_document(TestDocument->new(), { fields => [qw/one two three/] });
    is($method_called, 1, 'attributes method called');
    is_deeply($doc->{attributes}, { test => 1 }, 'read attributes from custom method');
};

done_testing;
