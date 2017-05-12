#!/usr/bin/perl -w

use strict;
use lib 'lib';
use Java::JVM::Classfile::Perl;

my $c = Java::JVM::Classfile::Perl->new(shift || "HelloWorld.class");

my $perl = $c->as_perl;
#print $perl;
print eval $perl;


