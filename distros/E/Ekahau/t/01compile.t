#!/usr/bin/perl -w
 
use strict;
 
use Test::More tests => 7;
 
BEGIN {
  use_ok('Ekahau::Base');
  use_ok('Ekahau::License');
  use_ok('Ekahau');
  use_ok('Ekahau::Events');
  use_ok('Ekahau::Response'); # Response subclasses are used from Response class
  use_ok('Ekahau::Server');
  use_ok('Ekahau::Server::Test');
};
