#!/usr/bin/perl

use v5.20;
use warnings;

use Test2::V0;

use Future::IO;
use Future::IO::Resolver;

Future::IO->load_best_impl;

# res_query metacpan.org IN A
{
   my $f = Future::IO::Resolver->res_query(
      dname => "metacpan.org",
      # class IN is default
      type  => 1, # A
   );

   my $answer = $f->get;

   ok( length $answer, 'Got an answer to ->res_query' );
   # Since we got *a* result, we'll not further inspect the inner details, as
   # that just makes a fragile test that often fails on weirdly set up machines
}

# res_search metacpan.org IN A
{
   my $f = Future::IO::Resolver->res_search(
      dname => "metacpan.org",
      # class IN is default
      type  => 1, # A
   );

   my $answer = $f->get;

   ok( length $answer, 'Got an answer to ->res_search' );
   # Since we got *a* result, we'll not further inspect the inner details, as
   # that just makes a fragile test that often fails on weirdly set up machines
}

done_testing;
