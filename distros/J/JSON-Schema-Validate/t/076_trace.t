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
};

my $schema =
{
    '$schema' => 'https://json-schema.org/draft/2020-12/schema',
    type      => 'object',
    required  => [ 'name' ],
    properties =>
    {
        name => { type => 'string', minLength => 2 },
        age  => { type => 'integer', minimum => 0 },
    },
};

my $js = JSON::Schema::Validate->new(
    $schema,
    trace        => 1,
    trace_limit  => 10,
    trace_sample => 1,
    compile      => 1,
);

ok( ! $js->validate({ name => 'A', age => -1 }), 'invalid instance triggers errors' );

my $trace = $js->get_trace;
ok( ref($trace) eq 'ARRAY', 'get_trace returns an arrayref' );
ok( @$trace <= 10, 'trace respects trace_limit' );

# We cannot assert exact structure, but we can expect a few entries
ok( scalar(@$trace) >= 1, 'some trace entries recorded' );

# Toggle trace off and confirm no accumulation
$js->trace(0);
$js->validate({ name => 'AB', age => 1 }) or diag( $js->error );

my $trace2 = $js->get_trace;
ok( ref($trace2) eq 'ARRAY', 'get_trace still returns an arrayref' );
ok( @$trace2 == 0 || @$trace2 <= @$trace, 'no new entries when trace is off' );

done_testing();

__END__
