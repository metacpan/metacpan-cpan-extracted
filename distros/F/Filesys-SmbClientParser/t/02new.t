#!/usr/bin/env perl -w
# bug reported by andreas Dahl

use strict;
use Test::More;
plan tests => 3;
use Filesys::SmbClientParser;

my $ical = Filesys::SmbClientParser->new("/bin/ls"); # create an object
ok( defined $ical,"defined instance" );         # check that we got something
ok( $ical->isa('Filesys::SmbClientParser'),
  'Filesys::SmbClientParser instance');   #       and it's the right class
is($ical->{SMBLIENT},"/bin/ls", "Set smbclient with new");
