use strict;
use warnings;

use Test::More tests => 22;
use Test::NoWarnings;
use Test::Exception;

use_ok('Math::Util::CalculatedValue');
require_ok('Math::Util::CalculatedValue');

throws_ok { Math::Util::CalculatedValue->new({}) } qr/Attribute .* is required/, 'empty parameters, no object';
# Faily stuff
throws_ok { Math::Util::CalculatedValue->new({name        => 'test'}) } qr/Attribute .* is required/,            'only name';
throws_ok { Math::Util::CalculatedValue->new({set_by      => 'Test::More'}) } qr/Attribute .* is required/,      'only set_by';
throws_ok { Math::Util::CalculatedValue->new({description => 'ran for testing'}) } qr/Attribute .* is required/, 'only description';
throws_ok { Math::Util::CalculatedValue->new({base_amount => 0}) } qr/Attribute .* is required/,                 'only base_amount';
throws_ok { Math::Util::CalculatedValue->new({minimum     => 10}) } qr/Attribute .* is required/,                'only minumum amount';
throws_ok { Math::Util::CalculatedValue->new({maximum     => 50}) } qr/Attribute .* is required/,                'only maximum amount';
throws_ok { Math::Util::CalculatedValue->new({name => 'test', description => "ran for testing"}) } qr/Attribute .* is required/,
    'only name and description';
throws_ok { Math::Util::CalculatedValue->new({name => 'test', set_by => 'Test::More'}) } qr/Attribute .* is required/, 'only name and set_by';
throws_ok { Math::Util::CalculatedValue->new({description => 'ran for testing', set_by => 'Test::More'}) } qr/Attribute .* is required/,
    'only description and set_by';
throws_ok { Math::Util::CalculatedValue->new({name => 'test', base_amount => 0}) } qr/Attribute .* is required/,  'only name and base_amount';
throws_ok { Math::Util::CalculatedValue->new({name => 'test', minimum     => 50}) } qr/Attribute .* is required/, 'only name and minimum';
throws_ok { Math::Util::CalculatedValue->new({name => 'test', maximum     => 50}) } qr/Attribute .* is required/, 'only name and maximum';
throws_ok {
    Math::Util::CalculatedValue->new({
        name        => 'test',
        description => "ran for testing",
        set_by      => 'Test::More',
        base_amount => 345,
        minimum     => 50,
        maximum     => 10
    });
}
qr/Provided maximum \[10\] is less than the provided minimum \[50\]/, 'Maximum of less than minimum';

# Passy stuff
new_ok(
    'Math::Util::CalculatedValue' => [{
            name        => 'test',
            description => "ran for testing",
            set_by      => 'Test::More',
            base_amount => 0
        }]);
new_ok(
    'Math::Util::CalculatedValue' => [{
            name        => 'test',
            description => "ran for testing",
            set_by      => 'Test::More',
            base_amount => 345
        }]);
new_ok(
    'Math::Util::CalculatedValue' => [{
            name        => 'test',
            description => "ran for testing",
            set_by      => 'Test::More',
            base_amount => 345,
            minimum     => 50,
            maximum     => 100
        }]);
new_ok(
    'Math::Util::CalculatedValue' => [{
            name        => 'test',
            description => "ran for testing",
            set_by      => 'Test::More',
            base_amount => 345,
            minimum     => 50
        }]);
new_ok(
    'Math::Util::CalculatedValue' => [{
            name        => 'test',
            description => "ran for testing",
            set_by      => 'Test::More',
            base_amount => 345,
            maximum     => 100
        }]);
