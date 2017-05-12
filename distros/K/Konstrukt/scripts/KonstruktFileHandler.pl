#!/usr/bin/perl

use strict;
use warnings;

use Cwd;
use Konstrukt::Handler::File;

#create filehandler and handle file request
my $handler = Konstrukt::Handler::File->new(getcwd(), $ARGV[0]);
$handler->handler();
