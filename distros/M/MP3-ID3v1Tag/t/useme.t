#!/usr/bin/perl -w
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# $Id: useme.t,v 1.2 2000/03/14 18:29:05 sander Exp $
# $Source: /cvs/root/packages/perl/id3v1/t/useme.t,v $
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

BEGIN { $| =1;  print "1..1\n"; }
END { print "not ok 1\n" unless $loaded; }

require 5.004;
use strict;
use vars qw($loaded);
use MP3::ID3v1Tag;

$loaded = 1;
print "ok 1\n";
