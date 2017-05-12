#!/usr/bin/perl -w
# vim: set filetype=perl expandtab shiftwidth=2 softtabstop=2 :
use utf8;
use Gtk2::TestHelper tests => 21, at_least_version => [ 2, 18, 0 ];

my $buffer = Gtk2::EntryBuffer->new();
isa_ok( $buffer, 'Gtk2::EntryBuffer' );
is( $buffer->get_text(), '' );
is( $buffer->get_bytes(), 0 );
is( $buffer->get_length(), 0 );

my $text = "Lorem ipsum dolor sit amet, consectetur adipisicing elit";

$buffer = Gtk2::EntryBuffer->new($text);
isnt( $buffer->get_text(), '' );
is( $buffer->get_length(), length($text) );
is( $buffer->get_bytes(), length($text) );

my $utf8_text = "♥ Lorem ipsum dolor sit amet, consectetur adipisicing elit";
$buffer->set_text($utf8_text);
is( $buffer->get_length(), length($utf8_text) );
is( $buffer->get_bytes(), length($utf8_text) + 2 ); # ♥ == 0xE2 0x99 0xA5
is( $buffer->get_text(), $utf8_text );

$buffer = Gtk2::EntryBuffer->new(substr($utf8_text, 0, 5));
is( $buffer->get_text(), '♥ Lor' );
is( $buffer->get_length(), 5 );
is( $buffer->get_bytes(), 7 );

$buffer->insert_text(0, 'Do ');
is( $buffer->get_text(), 'Do ♥ Lor' );

$buffer->insert_text(-1, 'em ipsum');
is( $buffer->get_text(), 'Do ♥ Lorem ipsum' );

$buffer->delete_text(10, -1);
is( $buffer->get_text(), 'Do ♥ Lorem' );

$buffer->delete_text();
is( $buffer->get_bytes(), 0 );

$buffer->set_max_length(23);
is( $buffer->get_max_length(), 23 );

$buffer->emit_inserted_text(0, 'Lorem', 5);
$buffer->emit_deleted_text(0, 5);

SKIP: {
  skip 'new stuff', 3
    unless Gtk2->CHECK_VERSION(2, 18, 0);
  ok( defined Gtk2::GTK_ENTRY_BUFFER_MAX_SIZE() );
  ok( eval <<__CODE__ );
package Tmp;
use Gtk2 qw/GTK_ENTRY_BUFFER_MAX_SIZE/;
Test::More::ok( defined GTK_ENTRY_BUFFER_MAX_SIZE() );
1;
__CODE__
}
