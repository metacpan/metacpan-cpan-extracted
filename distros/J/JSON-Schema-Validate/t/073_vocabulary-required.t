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

# NOTE:
# _compile_root checks $vocabulary during ->new. If a vocabulary URI is marked true
# and not present in $self->{vocab_support}, it dies. There is currently no constructor
# flag to pre-set ignore_unknown_required_vocab before compilation, so we just assert
# the die behaviour and a success case with all false.

my $with_required_vocab =
{
    '$schema'      => 'https://json-schema.org/draft/2020-12/schema',
    '$vocabulary'  =>
    {
        'https://example.org/vocab/alpha' => JSON::true,
        'https://example.org/vocab/beta'  => JSON::false, # optional
    },
    type           => 'object',
};

my $all_optional =
{
    '$schema'      => 'https://json-schema.org/draft/2020-12/schema',
    '$vocabulary'  =>
    {
        'https://example.org/vocab/alpha' => JSON::false,
    },
    type           => 'object',
};

# 1) Unknown required vocab -> dies at construction
{
    my $err;
    eval
    {
        my $x = JSON::Schema::Validate->new( $with_required_vocab );
        1;
    } or do{ $err = $@ };

    ok( $err, 'constructor dies when required vocabulary is not supported' );
    like( $err, qr/Required vocabulary not supported/i, 'die message mentions vocabulary' );
}

# 2) All vocab entries are optional (false) -> ok
{
    my $x;
    eval{ $x = JSON::Schema::Validate->new( $all_optional ) } or diag( $@ );
    ok( $x, 'constructor succeeds when all vocabularies are optional' );
}

done_testing();

__END__
