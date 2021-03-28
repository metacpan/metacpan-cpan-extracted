#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use Feature::Compat::Try;

# try as final expression yields correct value
{
   my $scalar = do {
      try { 123 }
      catch ($e) { 456 }
   };
   is($scalar, 123, 'do { try } in scalar context');

   my @list = do {
      try { 1, 2, 3 }
      catch ($e) { 4, 5, 6 }
   };
   is_deeply(\@list, [1, 2, 3], 'do { try } in list context');
}

# catch as final expression yields correct value
{
   my $scalar = do {
      try { die "Oops" }
      catch ($e) { 456 }
   };
   is($scalar, 456, 'do { try/catch } in scalar context');

   my @list = do {
      try { die "Oops" }
      catch ($e) { 4, 5, 6 }
   };
   is_deeply(\@list, [4, 5, 6], 'do { try/catch } in list context');
}

done_testing;
