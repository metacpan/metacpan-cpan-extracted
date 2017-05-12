#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 10;
use FindBin qw/ $Bin /;
use lib "$Bin/../lib";
use Data::Dumper;

# check module
use_ok( 'Getopt::Valid' );

# validator definition
my %validator = (
    name    => 'Test',
    version => '0.1.0',
    struct  => [
        'somestring|s=s!' => undef,
        'otherstring|o=s' => {
            constraint  => qr/^a/,
            required    => 1,
            description => 'This is the description for str'
        },
        'someint|i=i!' => 'This is the description for int',
        'somebool|b' => undef
    ]
);
my @valid_argv = ( '-s', 'lala', '--otherstring', 'a good string', '-i', 123, '-b' );
my @invalid_argv = ( '--otherstring', 'not a good string' );

# instanciate
ok( my $v = eval { Getopt::Valid->new( \%validator ) }, 'Object-mode: instanciate' );

# collect correct args
@ARGV = @valid_argv;
$v->collect_argv;

# validate correct
ok( scalar $v->validate, 'Object-mode: valid input' );

# test valid args
test_input( 'Object-mode: input found', $v->valid_args );


# collect invalid args
@ARGV = @invalid_argv;
$v->collect_argv;

# validate invalid
ok( ! scalar  $v->validate, 'Object-mode: invalid input' );

# check error messags
test_errors( 'Object-mode: errors', $v->errors );



# Functional for valid
@ARGV = @valid_argv;
ok( my $res = GetOptionsValid( \%validator ), 'Functional-mode: valid input' );

# test valid args
test_input( 'Functional-mode: input found', $res );

# Functional for invalid
@ARGV = @invalid_argv;
ok( ! GetOptionsValid( \%validator ), 'Functional-mode: invalid input' );

# check error messags
test_errors( 'Functional-mode: errors', @Getopt::Valid::ERRORS );


sub test_input {
    my ( $msg, $input_ref ) = @_;
    ok(
        defined $input_ref->{ otherstring } && $input_ref->{ otherstring } eq 'a good string'
        && defined $input_ref->{ someint } && $input_ref->{ someint } == 123
        && defined $input_ref->{ somebool } && $input_ref->{ somebool } == 1
        && defined $input_ref->{ somestring } && $input_ref->{ somestring } eq 'lala',
        $msg
    )
}

sub test_errors {
    my ( $msg, @errors ) = @_;
    my %errors = map { ( $_ => 1 ) } @errors;
    ok(
        $errors{ 'Required key "someint" not given' }
        && $errors{ 'Value of key "otherstring" is invalid' }
        && $errors{ 'Required key "somestring" not given' },
        $msg
    );
}