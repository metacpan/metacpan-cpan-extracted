#!/usr/bin/perl -w

use Test::Simple tests => 2;

use Filesys::SmbClientParser;

my $ical = Filesys::SmbClientParser->new;         # create an object
ok( defined $ical,"defined instance" );         # check that we got something
ok( $ical->isa('Filesys::SmbClientParser'),
  'Filesys::SmbClientParser instance');     # and it's the right class

