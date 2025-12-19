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
};

# Builtin date-time accepts RFC3339; we override to force a very strict Z-only, no fraction.

my $js = JSON::Schema::Validate->new(
    {
        type => 'object',
        properties => 
        {
            when => { type => 'string', format => 'date-time' },
        },
        required => [ 'when' ],
    },
    format => 
    {
        'date-time' => sub
        {
            my( $s ) = @_;
            return 0 unless( defined( $s ) && !ref( $s ) );
            return( $s =~ /\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z\z/ ? 1 : 0 );
        },
    },
);

ok(  $js->validate({ when => '2011-11-11T11:11:11Z' }), 'override pass' ) or diag( $js->error );
ok( !$js->validate({ when => '2011-11-11T11:11:11+09:00' }), 'override blocks offset' );
ok( !$js->validate({ when => '2011-11-11T11:11:11.123Z' }),  'override blocks fraction' );

done_testing;

__END__
