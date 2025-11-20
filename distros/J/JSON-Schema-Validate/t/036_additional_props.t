#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use lib './lib';
use open ':std' => 'utf8';
use Test::More;
use JSON;

BEGIN
{
    use_ok( 'JSON::Schema::Validate' ) || BAIL_OUT( "Unable to load JSON::Schema::Validate" );
}

# Test that an empty 'additionalProperties' is a no-op.

subtest 'empty additionalProperties is no-op' => sub
{
    my $schema =
    {
        type => 'object',
        properties =>
        {
            x => { type => 'integer' },
        },
    };

    my $doc =
    {
        foo => 123,
    };

    my $js = JSON::Schema::Validate->new( $schema );
    my $res = $js->validate( $doc );
    ok( $res, "Object with extra property is valid") or diag( $js->error );

    $schema->{additionalProperties} = {};
    my $js2 = JSON::Schema::Validate->new( $schema );
    my $res2 = $js2->validate($doc);
    ok( $res2, "Same with added empty additionalProperties") or diag( $js2->error );
};

subtest 'false forbids additional properties' => sub
{
    my $js3 = JSON::Schema::Validate->new({ additionalProperties => JSON::false });
    ok( !$js3->validate({ foo  => "bar" }) ) or diag( $js3->error );
};

done_testing();

__END__
