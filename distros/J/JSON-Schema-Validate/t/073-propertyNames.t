#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use Test::More;
use lib './lib';
use open ':std' => 'utf8';
use JSON ();
use JSON::Schema::Validate;

my $schema =
{
    type => 'object',
    propertyNames => { pattern => '^[a-z][a-z0-9_]*$' },
};

my $js = JSON::Schema::Validate->new( $schema );

ok(  $js->validate( { a1 => 1, foo_bar => 2 } ), 'valid property names' ) or diag $js->error;
ok( !$js->validate( { 'Bad-Name' => 1 } ),       'invalid property name violates pattern' );

done_testing;

__END__
