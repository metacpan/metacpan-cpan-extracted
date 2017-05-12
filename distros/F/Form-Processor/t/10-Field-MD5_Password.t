use strict;
use warnings;
use Encode;
use Test::More tests => 4;
use Digest::MD5;


my $class = 'Form::Processor::Field::MD5_Password';

eval { require Digest::MD5 };
skip( 'Skip: failed to load module Digets::MD5', 7 ) if $@;

my $form = my_form->new;

use_ok( $class );
my $field = $class->new(
    name => 'test_field',
    type => 'MD5_Password',
    form => $form,
);

ok( defined $field, 'new() called' );

my $pass = '4my_secret_password_123' . "\x{040C}";

$field->input( $pass );
$field->validate_field;
ok( !$field->has_error, 'Test for errors 1' );
is( $field->value, Digest::MD5::md5_hex( Encode::encode_utf8( $pass ) ), 'value returned' );


package my_form;
use strict;
use warnings;
use base 'Form::Processor';

sub profile {
    return {
        optional => {
            login    => 'Text',
            username => 'Text',
            password => 'MD5_Password',
        },
    };
}


sub params {
    return {
        login    => 'my4login55',
        username => 'my4username',
    };
}

