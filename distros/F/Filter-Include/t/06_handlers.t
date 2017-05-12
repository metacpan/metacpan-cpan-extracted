#!/usr/bin/perl

use Test::More tests => 7;

use IO::File;
use File::Spec;

use strict;
use Filter::Include (
  pre => sub {
    my($inc,$src) = @_;
    is $inc, 't/sample.pl', "Called pre source handler got filename";
    like $src, qr/test worked/, "Got the include '$inc' as expected";
  },
  post => sub {
    my($inc,$src) = @_;
    is $inc, 't/sample.pl', "Called post source handler got filename";
    like $src, qr/test worked/, "Got the include '$inc' as expected";
  },
  before => sub {
    my $src  = shift;
    unlike $src, qr/\Qok(1 => "test worked in sample file")/,
         "Haven't seen the include yet";
  },
  after => sub {
    my $src  = shift;
    like $src, qr/\Qok(1 => "test worked in sample file")/,
         "The include has been ... included";
  },
);

no warnings 'once';
# no. 1
include 't/sample.pl';
