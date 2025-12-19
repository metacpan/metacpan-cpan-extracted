#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use lib './lib';
use open ':std' => 'utf8';
use Test::More;
use JSON ();
our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;

BEGIN
{
    use_ok( 'JSON::Schema::Validate' ) || BAIL_OUT( "Unable to load JSON::Schema::Validate" );
};

# A schema designed to produce MULTIPLE errors when fed bad data,
# without tripping a single early "type" return at the root.
my $schema =
{
    '$schema' => 'https://json-schema.org/draft/2020-12/schema',
    type      => 'object',
    required  => [ 'a', 'b', 'c' ],
    properties =>
    {
        a => { type => 'integer' },
        b => { type => 'string', minLength => 3 },
        c => { type => 'array', minItems => 2 },
    },
    additionalProperties => 0,
};

my $js = JSON::Schema::Validate->new( $schema, max_errors => 10 );

ok( $js, "Validator object created" );

subtest 'is_valid() returns true for valid data' => sub
{
    my $data =
    {
        a => 42,
        b => 'abcd',
        c => [1, 2],
    };

    ok( $js->is_valid( $data ), "is_valid() returns true for valid data" );
    ok( !$js->error, "No last error recorded for valid data" );
};

subtest 'is_valid() returns false for invalid data and stores one error' => sub
{
    my $bad =
    {
        a => 'nope',    # type error (integer expected)
        b => 'x',       # minLength error
        c => [1],     # minItems error
    };

    ok( !$js->is_valid( $bad ), "is_valid() returns false for invalid data" );

    my $err = $js->error;
    ok( $err, "error() returns an error object after invalid validation" );

    my $errors = $js->errors;
    ok( ref( $errors ) eq 'ARRAY', "errors() returns an array reference" );
    is( scalar( @$errors ), 1, "Only one error recorded when using is_valid()" );

    # Structure checks (field names matter!)
    ok( defined( $err->{keyword} ) || ( ref( $err ) && $err->can( 'keyword' ) ), "Error contains keyword field" );
    ok( defined( $err->{path} )    || ( ref( $err ) && $err->can( 'path' ) ),    "Error contains path field" );

    # IMPORTANT: JSON::Schema::Validate uses schema_pointer (not schema_ptr)
    ok(
        ( defined( $err->{schema_pointer} ) || ( ref( $err ) && $err->can( 'schema_pointer' ) ) ),
        "Error contains schema_pointer field"
    );
};

subtest 'validate() collects multiple errors with max_errors' => sub
{
    # This one triggers MULTIPLE errors:
    # - missing required: b, c  (2 errors)
    # - a present but wrong type (1 error)
    my $bad =
    {
        a => 'nope',
    };

    # Use object max_errors (10)
    ok( !$js->validate( $bad ), "validate() returns false for invalid data" );

    my $errors = $js->errors;
    ok( ref( $errors ) eq 'ARRAY', "errors() returns an array reference" );
    ok( scalar( @$errors ) > 1, "validate() collects more than one error using object max_errors" );
};

subtest 'validate() option override max_errors works' => sub
{
    my $bad =
    {
        a => 'nope',
    };

    ok( !$js->validate( $bad, max_errors => 1 ), "validate(..., max_errors => 1) returns false" );

    my $errors = $js->errors;
    is( scalar( @$errors ), 1, "validate(..., max_errors => 1) limits errors to 1" );
};

done_testing();

__END__
