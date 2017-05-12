#!/usr/bin/perl

use lib qw(../blib/lib ../blib/arch);
use strict;
use warnings;

use Mac::CoreMIDI;

my $c = Mac::CoreMIDI::Client->new(name => 'Perl');

$c->CreateDestination("Perl destination", \&Read);

# my $d = MyEndpoint->new_destination(
#     name => 'Perl destination', client => $c);
# 
# my $s = MyEndpoint->new_source(
#     name => 'Perl source', client => $c);
    

sub Read {
    print "Someone sent me some data: >@_<\n";
}


Mac::CoreMIDI::RunLoopRun();
# 
# package MyEndpoint;
# 
# use base qw(Mac::CoreMIDI::Endpoint);
# 
# sub Read {
#     print "Someone sent me some data.\n";
# }
# 
# package MyClient;
# 
# use base qw(Mac::CoreMIDI::Client);
# 
# sub Update {
#     print "MIDI system was updated.\n";
# }
