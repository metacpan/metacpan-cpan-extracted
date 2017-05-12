#!/usr/bin/perl

#   $Id: example-01.pl,v 1.1 2007-08-19 11:19:47 adam Exp $

#   Standard module loading
use strict;
use 5.010;
use utf8;
use warnings;
use Log::Trivial;

#   Create a logging object
my $logger = Log::Trivial->new(
    log_file  => './example.log',
    log_tag   => $$,
    set_level => 3,
);

#   Do stuff

#   Log it
$logger->write( 'Stuff worked' );

#   Do more stuff

#   Log that too
$logger->write( 'Did more stuff' );


