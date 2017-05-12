#!/usr/bin/env perl

use Test::More tests => 8;
use Test::Exception;
use File::Temp;

use strict;
use warnings;
use IO::EditPrompt;

throws_ok { IO::EditPrompt->new( 'fail' ); } qr/not a hashref/, 'bad new: string parameter';
throws_ok { IO::EditPrompt->new( [] ); } qr/not a hashref/, 'bad new: array ref';
throws_ok { IO::EditPrompt->new( { tmpdir => 'xyzzy' } ); } qr/not a directory/, 'bad new: tmpdir not directory';

isa_ok( IO::EditPrompt->new(), 'IO::EditPrompt', 'new: no params' );
isa_ok( IO::EditPrompt->new({}), 'IO::EditPrompt', 'new: empty hash supplied' );
isa_ok( IO::EditPrompt->new({ def_editor => 'nano' }), 'IO::EditPrompt', 'new: default editor supplied' );
isa_ok( IO::EditPrompt->new({ editor => 'nano' }), 'IO::EditPrompt', 'new: editor supplied' );
{
    my $dir = File::Temp->newdir();
    isa_ok( IO::EditPrompt->new({ tmpdir => $dir }), 'IO::EditPrompt', 'new: tmpdir supplied' );
}
