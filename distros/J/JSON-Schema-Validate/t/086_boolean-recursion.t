#!/usr/bin/env perl
use strict;
use warnings;
use lib './lib';
use Test::More;
use JSON ();

BEGIN
{
    use_ok( 'JSON::Schema::Validate' ) || BAIL_OUT( "Unable to load JSON::Schema::Validate" );
};

for my $compile ( 0, 1 )
{
    subtest "compile=$compile" => sub
    {
        my $check = sub
        {
            my( $schema, $data, $expected, $label ) = @_;
            my $js = JSON::Schema::Validate->new( $schema, compile => $compile );
            is( $js->validate( $data ) ? 1 : 0, $expected, $label ) or diag( $js->error );
        };
        $check->( { contains => JSON::false, unevaluatedItems => JSON::false }, [1], 0, 'false contains cannot annotate an item' );
        $check->( { contains => JSON::false, minContains => 0, unevaluatedItems => JSON::false }, [1], 0, 'unmatched item remains unevaluated' );
        $check->( { contains => JSON::false, minContains => 0 }, [1], 1, 'zero matches are permitted' );
        $check->( { contains => JSON::true, unevaluatedItems => JSON::false }, [1,2], 1, 'true contains annotates all items' );
        $check->( { contains => JSON::true, maxContains => 1 }, [1,2], 0, 'maxContains is still enforced' );
        $check->( { items => JSON::true, unevaluatedItems => JSON::false }, [1], 1, 'true items contributes annotations' );
        $check->( { items => JSON::false }, [1], 0, 'false items rejects an element' );
        $check->( { items => JSON::false }, [], 1, 'false items permits an empty array' );
        $check->( { prefixItems => [{ type => 'integer' }], items => JSON::false }, [1,2], 0, 'false items rejects trailing items' );
        $check->( { prefixItems => [{ type => 'integer' }], items => JSON::false }, [1], 1, 'false items permits a complete tuple' );
        $check->( { prefixItems => [{ type => 'integer' }], items => JSON::true, unevaluatedItems => JSON::false }, [1,2], 1, 'true items annotates trailing items' );
        $check->( { prefixItems => [JSON::false] }, [1], 0, 'false prefixItems rejects an element' );
        $check->( { allOf => [JSON::false] }, {}, 0, 'false allOf branch fails' );
        $check->( { anyOf => [JSON::false, { type => 'integer' }] }, 'x', 0, 'false anyOf branch fails' );
        $check->( { oneOf => [JSON::false, { type => 'integer' }] }, 1, 1, 'false branch does not count as a match' );
        $check->( { not => JSON::false }, {}, 1, 'not false succeeds' );
        $check->( { if => JSON::false, then => { type => 'integer' }, else => { type => 'string' } }, 'x', 1, 'false if selects else' );
        $check->( { if => JSON::true, then => JSON::false }, 'x', 0, 'true if selects false then' );
        $check->( { if => JSON::false, else => JSON::false }, 'x', 0, 'false if selects false else' );
        $check->( { properties => { a => JSON::false } }, { a => 1 }, 0, 'false property schema rejects a value' );
        $check->( { properties => { a => JSON::true }, unevaluatedProperties => JSON::false }, { a => 1 }, 1, 'true property schema contributes annotations' );
        $check->( { propertyNames => JSON::false }, { a => 1 }, 0, 'false propertyNames rejects a property' );
        $check->( { propertyNames => JSON::true, unevaluatedProperties => JSON::false }, { a => 1 }, 0, 'propertyNames does not annotate property values' );
        $check->( { dependentSchemas => { a => JSON::false } }, { a => 1 }, 0, 'false dependent schema rejects a triggered dependency' );
        $check->( { '$defs' => { deny => JSON::false }, '$ref' => '#/$defs/deny' }, {}, 0, 'reference to false rejects an instance' );
        $check->( { '$defs' => { allow => JSON::true }, properties => { a => { '$ref' => '#/$defs/allow' } }, unevaluatedProperties => JSON::false }, { a => 1 }, 1, 'reference to true permits and annotates a property' );

        my $js = JSON::Schema::Validate->new( { '$defs' => { deny => JSON::false }, '$ref' => '#/$defs/deny' }, compile => $compile );
        ok( !$js->validate(1), 'reference to false rejects a scalar' );
        is( $js->errors->[0]->keyword, 'false', 'false reference resolves rather than reporting an unresolved reference' );

        # Guard the test itself against a regression causing unbounded recursion.
        my $cycle = JSON::Schema::Validate->new( { anyOf => [{ type => 'integer' }, { '$ref' => '#' }] }, compile => $compile );
        my $rv;
        {
            local $SIG{ALRM} = sub { die( "Recursive validation exceeded the test deadline.\n" ); };
            eval
            {
                alarm(2);
                $rv = $cycle->validate(1);
                alarm(0);
            };
            alarm(0);
            is( $@, '', 'scalar recursion terminates' );
        }
        ok( $rv, 'the successful non-recursive branch remains valid' );
        ok( $cycle->validate({ a => 1 }), 'object recursion retains the existing guard policy' );

        # Independent resources may both use the root pointer or the same fragment.
        my $external = JSON::Schema::Validate->new( { allOf => [{ '$ref' => 'https://example.test/a' }, { '$ref' => 'https://example.test/b' }] }, compile => $compile );
        $external->set_resolver( sub { $_[0] =~ m{/a\z} ? { type => 'integer' } : { type => 'string' } } );
        ok( !$external->validate(1), 'external schemas at the same pointer are evaluated independently' );
        ok( !$external->validate('x'), 'external validators remain independent on a later call' );
        $external = JSON::Schema::Validate->new( { '$ref' => 'https://example.test/object' }, compile => $compile );
        $external->set_resolver( sub { return({ required => ['a'] }); } );
        ok( !$external->validate({ b => 1 }), 'an external root is not mistaken for active recursion' );
        ok( $external->validate({ a => 1 }), 'valid external root still passes' );
    };
}

done_testing;

__END__
