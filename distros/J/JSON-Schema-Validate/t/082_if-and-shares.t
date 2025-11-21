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
}

# Handy helper to validate and optionally dump errors on failure
sub _check
{
    my( $schema, $instance, $label, $expect_ok ) = @_;

    my $js = JSON::Schema::Validate->new( $schema );
    my $ok = $js->validate( $instance );

    if( $expect_ok )
    {
        ok( $ok, "$label is valid" )
            or diag _dump_errors( $js );
    }
    else
    {
        ok( !$ok, "$label is invalid as expected" )
            or diag "Unexpectedly valid.\n";
        diag( _dump_errors( $js ) ) if( $DEBUG );
    }
}

sub _dump_errors
{
    my( $js ) = @_;
    my $errs = $js->errors || [];
    return "No errors\n" unless( @$errs );

    my @h = map { $_->as_hash } @$errs;
    my $json = JSON->new->canonical(1)->pretty;
    return "Errors:\n" . $json->encode( \@h );
}

# -------------------------------------------------------------------------
# 1. if/then regression: 'if' must NOT leak 'required' errors
# -------------------------------------------------------------------------

my $schema_if_then =
{
    '$schema'    => 'https://json-schema.org/draft/2020-12/schema',
    type         => 'object',
    additionalProperties => JSON::false,
    properties   =>
    {
        flag => { type => 'boolean' },
        x    => { type => 'integer' },
        y    => { type => 'integer' },
    },
    allOf =>
    [
        {
            if =>
            {
                properties => { flag => { const => JSON::true } },
                required   => [ 'flag' ],
            },
            then =>
            {
                required => [ 'x' ],
            },
        },
    ],
};

# Old bug: this used to fail because 'if' contained "required: ['flag']"
# and errors from 'if' leaked even when the condition was false.
_check(
    $schema_if_then,
    { 'y' => 1 },
    'if/then: condition false, no x required',
    1,
);

# When flag is true and x is missing, we MUST fail.
_check(
    $schema_if_then,
    { flag => JSON::true },
    'if/then: flag=true, x required and missing',
    0,
);

# When flag is true and x is present, it must pass.
_check(
    $schema_if_then,
    { flag => JSON::true, x => 42 },
    'if/then: flag=true, x present',
    1,
);

# -------------------------------------------------------------------------
# 2. shares: oneOf(simple total, classes) + conditional voting logic
# -------------------------------------------------------------------------

my $shares_def =
{
    type  => 'object',
    oneOf =>
    [
        # Option 1: simple regular common/preferred shares
        {
            type                 => 'object',
            additionalProperties => JSON::false,
            properties           =>
            {
                total               => { type => 'integer', minimum => 1 },
                is_golden           => { type => 'boolean' },
                has_no_voting_right => { type => 'boolean' },
                voting_right        => { type => 'integer', minimum => 1 },
            },
            required => [ 'total' ],
            allOf =>
            [
                # If is_golden is true, voting_right >= 2 and has_no_voting_right must not be true
                {
                    if =>
                    {
                        properties => { is_golden => { const => JSON::true } },
                        required   => [ 'is_golden' ],
                    },
                    then =>
                    {
                        required   => [ 'voting_right' ],
                        properties =>
                        {
                            voting_right        => { minimum => 2 },
                            has_no_voting_right => { not => { const => JSON::true } },
                        },
                    },
                },
                # If has_no_voting_right is true, voting_right must not be present and is_golden must not be true
                {
                    if =>
                    {
                        properties => { has_no_voting_right => { const => JSON::true } },
                        required   => [ 'has_no_voting_right' ],
                    },
                    then =>
                    {
                        not =>
                        {
                            anyOf =>
                            [
                                { required => [ 'voting_right' ] },
                                {
                                    properties =>
                                    {
                                        is_golden => { const => JSON::true },
                                    },
                                    required => [ 'is_golden' ],
                                },
                            ],
                        },
                    },
                },
            ],
        },

        # Option 2: one or more classes of common/preferred shares
        {
            type                 => 'object',
            additionalProperties => JSON::false,
            required             => [ 'classes' ],
            properties           =>
            {
                classes =>
                {
                    type     => 'array',
                    minItems => 1,
                    items    =>
                    {
                        type                 => 'object',
                        additionalProperties => JSON::false,
                        properties           =>
                        {
                            class               => { type => 'string', pattern => '^[A-Z]$' },
                            total               => { type => 'integer', minimum => 1 },
                            is_golden           => { type => 'boolean' },
                            has_no_voting_right => { type => 'boolean' },
                            voting_right        => { type => 'integer', minimum => 1 },
                        },
                        required => [ 'class', 'total' ],
                        allOf =>
                        [
                            {
                                if =>
                                {
                                    properties => { is_golden => { const => JSON::true } },
                                    required   => [ 'is_golden' ],
                                },
                                then =>
                                {
                                    required   => [ 'voting_right' ],
                                    properties =>
                                    {
                                        voting_right        => { type => 'integer', minimum => 2 },
                                        has_no_voting_right => { not => { const => JSON::true } },
                                    },
                                },
                            },
                            {
                                if =>
                                {
                                    properties => { has_no_voting_right => { const => JSON::true } },
                                    required   => [ 'has_no_voting_right' ],
                                },
                                then =>
                                {
                                    not =>
                                    {
                                        anyOf =>
                                        [
                                            { required => [ 'voting_right' ] },
                                            {
                                                properties =>
                                                {
                                                    is_golden => { const => JSON::true },
                                                },
                                                required => [ 'is_golden' ],
                                            },
                                        ],
                                    },
                                },
                            },
                        ],
                    },
                },
            },
        },
    ],
};

my $schema_shares =
{
    '$schema'             => 'https://json-schema.org/draft/2020-12/schema',
    type                  => 'object',
    additionalProperties  => JSON::false,
    required              => [ 's' ],
    properties            => { 's' => $shares_def },
};

# 2.1 Simple shares branch: should match first oneOf schema
_check(
    $schema_shares,
    { 's' => { total => 10000 } },
    'shares: simple total only',
    1,
);

# 2.2 Classes branch: your real-life example should pass
_check(
    $schema_shares,
    {
        's' =>
        {
            classes =>
            [
                {
                    class        => 'A',
                    total        => 6000,
                    is_golden    => JSON::true,
                    voting_right => 10,
                },
                {
                    class               => 'B',
                    total               => 3000,
                    has_no_voting_right => JSON::true,
                },
                {
                    class => 'C',
                    total => 1000,
                },
            ],
        },
    },
    'shares: classes example (A golden, B no vote, C normal)',
    1,
);

# 2.3 Invalid: golden class without voting_right should fail
_check(
    $schema_shares,
    {
        's' =>
        {
            classes =>
            [
                {
                    class     => 'A',
                    total     => 100,
                    is_golden => JSON::true,
                    # voting_right missing -> then/required must fire
                },
            ],
        },
    },
    'shares: golden class missing voting_right',
    0,
);

# 2.4 Invalid: no-voting class but also voting_right present
_check(
    $schema_shares,
    {
        's' =>
        {
            classes =>
            [
                {
                    class               => 'B',
                    total               => 100,
                    has_no_voting_right => JSON::true,
                    voting_right        => 1,
                },
            ],
        },
    },
    'shares: has_no_voting_right but voting_right present',
    0,
);

# 2.5 Invalid: object with both total and classes must fail oneOf (matches 2)
_check(
    $schema_shares,
    {
        's' =>
        {
            total   => 100,
            classes =>
            [
                {
                    class => 'A',
                    total => 100,
                },
            ],
        },
    },
    'shares: both total and classes present (violates oneOf)',
    0,
);

# 2.6 Invalid: object with neither total nor classes -> matches 0 branches
_check(
    $schema_shares,
    { 's' => { foo => 1 } },
    'shares: neither total nor classes present (violates oneOf)',
    0,
);

done_testing();

__END__
