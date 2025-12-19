#!/usr/bin/env perl
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

# A tiny recursive list via $dynamicRef/$dynamicAnchor:
my $schema =
{
    '$id' => 'https://example.org/s/root',
    '$dynamicAnchor' => 'Node',
    type => 'object',
    properties => 
    {
        value => { type => 'integer' },
        next  => { '$dynamicRef' => '#Node' },
    },
    required => [ 'value' ],
    additionalProperties => JSON::false,
};

my $ok1 = { value => 1 };
my $ok2 = { value => 1, next => { value => 2, next => { value => 3 } } };
my $bad = { value => 1, next => { value => 'x' } };

my $js = JSON::Schema::Validate->new( $schema );

ok(  $js->validate( $ok1 ), 'single node ok' ) or diag( $js->error );
ok(  $js->validate( $ok2 ), 'chain ok' ) or diag( $js->error );
ok( !$js->validate( $bad ), 'fails: non-integer value in chain' );

done_testing;

__END__
