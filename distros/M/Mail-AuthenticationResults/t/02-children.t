#!perl
use 5.006;
use strict;
use warnings FATAL => 'all';
use lib 't';
use Test::More;
use Test::Exception;

use lib 'lib';
use Mail::AuthenticationResults::Header;
use Mail::AuthenticationResults::Header::Base;
use Mail::AuthenticationResults::Header::Comment;
use Mail::AuthenticationResults::Header::Entry;
use Mail::AuthenticationResults::Header::Group;
use Mail::AuthenticationResults::Header::SubEntry;

my ( $Header, $Base, $Comment, $Entry, $Group, $SubEntry );
my ( $Header2, $Base2, $Comment2, $Entry2, $Group2, $SubEntry2 );

sub setup {

    $Header = Mail::AuthenticationResults::Header->new();
    $Base = Mail::AuthenticationResults::Header::Base->new();
    $Comment = Mail::AuthenticationResults::Header::Comment->new();
    $Entry = Mail::AuthenticationResults::Header::Entry->new();
    $Group = Mail::AuthenticationResults::Header::Group->new();
    $SubEntry = Mail::AuthenticationResults::Header::SubEntry->new();

    $Header2 = Mail::AuthenticationResults::Header->new();
    $Base2 = Mail::AuthenticationResults::Header::Base->new();
    $Comment2 = Mail::AuthenticationResults::Header::Comment->new();
    $Entry2 = Mail::AuthenticationResults::Header::Entry->new();
    $Group2 = Mail::AuthenticationResults::Header::Group->new();
    $SubEntry2 = Mail::AuthenticationResults::Header::SubEntry->new();
}

setup();
dies_ok( sub{ $Header->add_child( $Header ) }, 'Header Header self dies' );
dies_ok( sub{ $Base->add_child( $Base ) }, 'Base Base self dies' );
dies_ok( sub{ $Comment->add_child( $Comment ) }, 'Comment Comment self dies' );
dies_ok( sub{ $Entry->add_child( $Entry ) }, 'Entry Entry self dies' );
dies_ok( sub{ $Group->add_child( $Group ) }, 'Group Group self dies' );
dies_ok( sub{ $SubEntry->add_child( $SubEntry ) }, 'SubEntry SubEntry self dies' );

setup();
dies_ok( sub{ $Header->add_child( $Header2 ) }, 'Header Header dies' );
dies_ok( sub{ $Header->add_child( $Base2 ) }, 'Header Base dies' );
dies_ok( sub{ $Header->add_child( $Comment2 ) }, 'Header Comment dies' );
lives_ok( sub{ $Header->add_child( $Entry2 ) }, 'Header Entry lives' );
dies_ok( sub{ $Header->add_child( $Group2 ) }, 'Header Group dies' );
dies_ok( sub{ $Header->add_child( $Entry2 ) }, 'Header Entry repeat dies' );
dies_ok( sub{ $Header->add_child( $SubEntry2 ) }, 'Header SubEntry dies' );

setup();
dies_ok( sub{ $Base->add_child( $Header2 ) }, 'Base Header dies' );
dies_ok( sub{ $Base->add_child( $Base2 ) }, 'Base Base dies' );
dies_ok( sub{ $Base->add_child( $Comment2 ) }, 'Base Comment dies' );
dies_ok( sub{ $Base->add_child( $Entry2 ) }, 'Base Entry dies' );
dies_ok( sub{ $Base->add_child( $Group2 ) }, 'Base Group dies' );
dies_ok( sub{ $Base->add_child( $SubEntry2 ) }, 'Base SubEntry dies' );

setup();
dies_ok( sub{ $Comment->add_child( $Header2 ) }, 'Comment Header dies' );
dies_ok( sub{ $Comment->add_child( $Base2 ) }, 'Comment Base dies' );
dies_ok( sub{ $Comment->add_child( $Comment2 ) }, 'Comment Comment dies' );
dies_ok( sub{ $Comment->add_child( $Entry2 ) }, 'Comment Entry dies' );
dies_ok( sub{ $Comment->add_child( $Group2 ) }, 'Comment Group dies' );
dies_ok( sub{ $Comment->add_child( $SubEntry2 ) }, 'Comment SubEntry dies' );

setup();
dies_ok( sub{ $Entry->add_child( $Header2 ) }, 'Entry Header dies' );
dies_ok( sub{ $Entry->add_child( $Base2 ) }, 'Entry Base dies' );
lives_ok( sub{ $Entry->add_child( $Comment2 ) }, 'Entry Comment lives' );
dies_ok( sub{ $Entry->add_child( $Comment2 ) }, 'Entry Comment repeat dies' );
dies_ok( sub{ $Entry->add_child( $Entry2 ) }, 'Entry Entry dies' );
dies_ok( sub{ $Entry->add_child( $Group2 ) }, 'Entry Group dies' );
lives_ok( sub{ $Entry->add_child( $SubEntry2 ) }, 'Entry SubEntry lives' );

setup();
dies_ok( sub{ $Group->add_child( $Header2 ) }, 'Group Header dies' );
dies_ok( sub{ $Group->add_child( $Base2 ) }, 'Group Base dies' );
lives_ok( sub{ $Group->add_child( $Comment2 ) }, 'Group Comment lives' );
lives_ok( sub{ $Group->add_child( $Comment2 ) }, 'Group Comment repeat lives' );
lives_ok( sub{ $Group->add_child( $Entry2 ) }, 'Group Entry lives' );
lives_ok( sub{ $Group->add_child( $Entry2 ) }, 'Group Entry repeat lives' );
lives_ok( sub{ $Group->add_child( $Group2 ) }, 'Group Group lives' );
lives_ok( sub{ $Group->add_child( $SubEntry2 ) }, 'Group SubEntry lives' );
lives_ok( sub{ $Group->add_child( $SubEntry2 ) }, 'Group SubEntry repeat lives' );
# Group repeats should not die, but should not result in duplicates

setup();
dies_ok( sub{ $SubEntry->add_child( $Header2 ) }, 'SubEntry Header dies' );
dies_ok( sub{ $SubEntry->add_child( $Base2 ) }, 'SubEntry Base dies' );
lives_ok( sub{ $SubEntry->add_child( $Comment2 ) }, 'SubEntry Comment lives' );
dies_ok( sub{ $SubEntry->add_child( $Comment2 ) }, 'SubEntry Comment repeat dies' );
dies_ok( sub{ $SubEntry->add_child( $Entry2 ) }, 'SubEntry Entry dies' );
dies_ok( sub{ $SubEntry->add_child( $Group2 ) }, 'SubEntry Group dies' );
dies_ok( sub{ $SubEntry->add_child( $SubEntry2 ) }, 'SubEntry SubEntry dies' );

done_testing();

