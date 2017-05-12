#!/usr/bin/perl -w
use strict;

use Data::Dumper;
use Labyrinth::Plugin::Event::Types;
use Labyrinth::Test::Harness;
use Test::More tests => 12;

my @plugins = qw(
    Labyrinth::Plugin::Event::Types
);

# -----------------------------------------------------------------------------
# Set up

my $loader = Labyrinth::Test::Harness->new( keep => 1 );
my $dir = $loader->directory;

my $res = $loader->prep(
    sql     => [ "$dir/cgi-bin/db/plugin-base.sql","t/data/test-base.sql" ],
    files   => { 
        't/data/phrasebook.ini' => 'cgi-bin/config/phrasebook.ini'
    },
    config  => {
        'INTERNAL'  => { logclear => 0 }
    }
);
diag($loader->error)    unless($res);

SKIP: {
    skip "Unable to prep the test environment", 12  unless($res);

    $res = is($loader->labyrinth(@plugins),1);
    diag($loader->error)    unless($res);

    # -------------------------------------------------------------------------
    # Select method
    
    is(Labyrinth::Plugin::Event::Types->EventTypeSelect(),       '<select id="eventtypeid" name="eventtypeid"><option value="1">Conference</option><option value="2">Workshop</option><option value="3">Hackathon</option><option value="4">User Group</option><option value="5">Social Meeting</option><option value="6">Technical Meeting</option><option value="7">Special</option></select>');
    is(Labyrinth::Plugin::Event::Types->EventTypeSelect(1),      '<select id="eventtypeid" name="eventtypeid"><option value="1" selected="selected">Conference</option><option value="2">Workshop</option><option value="3">Hackathon</option><option value="4">User Group</option><option value="5">Social Meeting</option><option value="6">Technical Meeting</option><option value="7">Special</option></select>');
    is(Labyrinth::Plugin::Event::Types->EventTypeSelect(1,1),    '<select id="eventtypeid" name="eventtypeid"><option value="0">Select An Event Type</option><option value="1" selected="selected">Conference</option><option value="2">Workshop</option><option value="3">Hackathon</option><option value="4">User Group</option><option value="5">Social Meeting</option><option value="6">Technical Meeting</option><option value="7">Special</option></select>');
    is(Labyrinth::Plugin::Event::Types->EventTypeSelect(1,0),    '<select id="eventtypeid" name="eventtypeid"><option value="1" selected="selected">Conference</option><option value="2">Workshop</option><option value="3">Hackathon</option><option value="4">User Group</option><option value="5">Social Meeting</option><option value="6">Technical Meeting</option><option value="7">Special</option></select>');
    is(Labyrinth::Plugin::Event::Types->EventTypeSelect(undef,1),'<select id="eventtypeid" name="eventtypeid"><option value="0">Select An Event Type</option><option value="1">Conference</option><option value="2">Workshop</option><option value="3">Hackathon</option><option value="4">User Group</option><option value="5">Social Meeting</option><option value="6">Technical Meeting</option><option value="7">Special</option></select>');
    is(Labyrinth::Plugin::Event::Types->EventTypeSelect(undef,0),'<select id="eventtypeid" name="eventtypeid"><option value="1">Conference</option><option value="2">Workshop</option><option value="3">Hackathon</option><option value="4">User Group</option><option value="5">Social Meeting</option><option value="6">Technical Meeting</option><option value="7">Special</option></select>');

    is(Labyrinth::Plugin::Event::Types->EventType(1),'Conference');
    is(Labyrinth::Plugin::Event::Types->EventType(9),'');

    my $cgiparams = $loader->params;
    is($cgiparams->{eventtypeid},undef);
    my $types = Labyrinth::Plugin::Event::Types->new;
    $types->SetType1;
    is($cgiparams->{eventtypeid},1);
    $types->SetType9;
    is($cgiparams->{eventtypeid},0);
}
