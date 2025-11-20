#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use lib './lib';
use open ':std' => 'utf8';
use Test::More;
use JSON ();

BEGIN
{
    use_ok( 'JSON::Schema::Validate' ) || BAIL_OUT( "Unable to load JSON::Schema::Validate" );
}

my $schema =
{
    '$schema' => 'https://json-schema.org/draft/2020-12/schema',
    type      => 'object',
    properties => { x => { type => 'integer' } },
};

# compile => 0 (lazy)
{
    my $js = JSON::Schema::Validate->new( $schema, compile => 0 );
    ok( ! $js->{compiled}, 'lazy new(): not compiled yet' );
    ok( $js->validate({ x => 1 }), 'first validate compiles and passes' );
    ok( $js->{compiled}, 'compiled after validate' );
}

# compile => 1 (eager)
{
    my $js = JSON::Schema::Validate->new( $schema, compile => 1 );
    ok( $js->{compiled}, 'eager new(): compiled immediately' );
}

# content_assert via constructor
{
    my $s =
    {
        '$schema' => 'https://json-schema.org/draft/2020-12/schema',
        type => 'object',
        required => [ 'p' ],
        properties =>
        {
            p => { type => 'string', contentEncoding => 'base64' },
        },
    };

    my $js = JSON::Schema::Validate->new( $s, content_assert => 1 );

    ok( ! $js->validate({ p => '!!!' }), 'invalid base64 fails when content_assert set in constructor' );
    like( $js->error.'', qr/contentEncoding 'base64' decode failed/i, 'has base64 decode error' );
}

# vocab_support + ignore_unknown_required_vocab
{
    my $sv =
    {
        '$schema'     => 'https://json-schema.org/draft/2020-12/schema',
        '$vocabulary' => { 'https://example.org/alpha' => JSON::true },
        type => 'null',
    };

    my $x;

    eval
    {
        $x = JSON::Schema::Validate->new(
            $sv,
            vocab_support => { },                          # none supported
            ignore_unknown_required_vocab => 1,            # ignore required unknown
            compile => 1
        );
        1;
    }
    or do
    {
        fail( "should not die when ignore_unknown_required_vocab=1" );
    };

    pass( "ignored unknown required vocab without dying" );
}

done_testing();

__END__
