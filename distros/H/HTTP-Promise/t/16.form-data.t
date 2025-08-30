#!/usr/bin/perl
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use vars qw( $DEBUG );
    use Test2::V0;
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

use strict;
use warnings;

use ok( 'HTTP::Promise::Parser' );

my $p = HTTP::Promise::Parser->new( debug => $DEBUG ) || bail_out( HTTP::Promise::Parser->error );
my $ent = $p->parse( 't/testin/post-multipart-form-data-07.txt' );
isa_ok( $ent => ['HTTP::Promise::Entity'], 'parser returns an HTTP::Promise::Entity object' );
diag( "Parsing failed: ", $p->error ) if( $DEBUG && !defined( $ent ) );
SKIP:
{
    skip( 'parser failed', 4 ) if( !defined( $ent ) );
    $ent->debug( $DEBUG );
    is( $ent->headers->type, 'multipart/form-data', 'type is multipart/form-data' );
    is( $ent->parts->length, 4, 'number of parts' );
    my $form = $ent->as_form_data;
    isa_ok( $form => ['HTTP::Promise::Body::Form::Data'], 'as_form_data' );
    SKIP:
    {
        is( $form->size, 4, '4 fields found for form-data' );
        diag( "Fields set in \$form are: ", $form->keys->join( ', ' )->scalar ) if( $DEBUG );
        isa_ok( $form->{category}->body, ['HTTP::Promise::Body::Scalar'], 'field category body' );
        isa_ok( $form->{location}->body, ['HTTP::Promise::Body::Scalar'], 'field location body' );
        isa_ok( $form->{tengu}->body, ['HTTP::Promise::Body'], 'field tengu body' );
        isa_ok( $form->{oni}->body, ['HTTP::Promise::Body'], 'field oni body' );
        is( $form->{category}->name, 'category', 'field category name' );
        is( $form->{location}->name, 'location', 'field location name' );
        is( $form->{tengu}->name, 'tengu', 'field tengu name' );
        is( $form->{oni}->name, 'oni', 'field oni name' );
        is( $form->{category}->value, 'Folklore', 'field category body' );
        is( $form->{location}->value, 'Japan', 'field location body' );
        is( $form->{tengu}->body->length, 843, 'file #1 (Tengu) size' );
        is( $form->{oni}->body->length, 1017, 'file #2 (Oni) size' );
        is( $form->{tengu}->headers->content_type, 'image/png', 'file #1 (Tengu) mime-type' );
        is( $form->{oni}->headers->content_type, 'image/png', 'file #1 (Tengu) mime-type' );
        is( $form->{tengu}->headers->content_encoding, 'base64', 'file #1 (Tengu) mime-type' );
        is( $form->{oni}->headers->content_encoding, 'base64', 'file #1 (Tengu) mime-type' );
        my $res = $form->as_string( boundary => $ent->headers->boundary, fields => [qw( category location tengu oni )] );
        diag( "Error as_string: ", $form->error ) if( $DEBUG );
        diag( $res ) if( $DEBUG );
        is( $res, $ent->body_as_string, 'as_string' );
    };
    # diag( $ent->as_string ) if( $DEBUG );
};

done_testing();

__END__

