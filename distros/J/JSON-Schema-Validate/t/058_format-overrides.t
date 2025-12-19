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

my $schema = { type => 'string', format => 'robotcode' };

my $js = JSON::Schema::Validate->new( $schema,
    format => 
    {
        robotcode => sub
        {
            my( $s ) = @_;
            return( 0 ) unless( defined( $s ) && !ref( $s ) );
            return( $s =~ /\AR[0-9]{3}\z/ ? 1 : 0 );
        },
    }
);

ok( $js->validate( 'R007' ), 'custom format passes' ) or diag( $js->error );
ok( !$js->validate( 'BOND' ), 'custom format fails' );

# Ensure builtins don't override user-provided format when registering them
$js->register_builtin_formats;
ok( $js->validate( 'R999' ), 'user-provided format preserved after register_builtin_formats' ) or diag( $js->error );

done_testing;

__END__
