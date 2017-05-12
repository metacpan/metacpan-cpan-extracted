#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use MVC::Neaf::X::Form;

my $prof = MVC::Neaf::X::Form->new({
    foo => [ REQUIRED => '\d+' ],
    bar => '\w+',
    baz => [ qr/b\w+/ ],
});

my $form;

$form = $prof->validate( { foo => 42, rubbish => 777 } );
ok( $form->is_valid, "Valid form" );
is_deeply( $form->error, {}, "No errors");
is_deeply( $form->data,  { foo => 42 }, "Valid data" );
is_deeply( $form->raw,   { foo => 42 }, "Raw data, rubbish omitted" );
$form->error( foo => "Not 42" );
ok( !$form->is_valid, "Invalidated by custom error" );

is ($form->as_url, "foo=42", "as_url works");
my $sign = $form->sign( key => "secret" );
like( $sign, qr[[A-Za-z_0-9./?=]+], "Signature ascii" );

$form = $prof->validate( { bar => 'xxx', baz => 'xxx' } );
ok (!$form->is_valid, "Invalid form now" );
is_deeply( $form->data, { bar => 'xxx' }, "Clean partial data got through");
is_deeply( $form->error, { foo => 'REQUIRED', baz => 'BAD_FORMAT' }
    , "Error details as expected");

$form = $prof->validate( { foo => 42, bar => '' } );
ok ( $form->is_valid, "Valid with empty value" );
is_deeply( $form->data, { foo => 42 }, "Empty value skipped" );

is( $form->sign( key => "secret" ), $sign, "Signature reproduces");

$form = $prof->validate( { foo => '' } );
ok (!$form->is_valid, "Invalid with empty REQUIRED value" );

done_testing;
