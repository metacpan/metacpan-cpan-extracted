#!/usr/bin/perl
use strict;
use vars qw($VERSION);
use Getopt::Std::Strict 'dhv';
use LEOCHARRE::Dir ':all';
use Cwd;
use Carp;
$VERSION = sprintf "%d.%02d", q$Revision: 1.2 $ =~ /(\d+)/g;

printf "[%30s]: %s\n", $_, $ENV{$_} for sort keys %ENV;




exit;


