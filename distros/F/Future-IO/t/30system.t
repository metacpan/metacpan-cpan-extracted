#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use IO::Handle;

use Future::IO;
use Future::IO::System;

sub load_impl_supporting_waitpid
{
   # We need a Future::IO impl that can ->waitpid
   foreach my $impl (qw(
         Future::IO::Impl::UV
         Future::IO::Impl::Glib
         Future::IO::Impl::IOAsync
      )) {
      eval { require "$impl.pm" =~ s{::}{/}gr; 1 } or next;
      $impl->can( "waitpid" ) and return;

      # Clear that impl before trying again
      undef $Future::IO::IMPL;
   }

   plan skip_all => "Unable to find a Future::IO impl that supports ->waitpid";
}

load_impl_supporting_waitpid();

# system
{
   my $f = Future::IO::System->system( $^X, "-e", "exit 5" );

   is( scalar $f->get, 5<<8, 'Future::IO::System->system future yields exit status' );
}

# system_out
{
   my $f = Future::IO::System->system_out( $^X, "-e", "print qq(Hello, world\\n)" );

   my ( $exitcode, $out ) = $f->get;
   is( $exitcode, 0, 'exitcode from ->system_out Future' );
   is( $out, "Hello, world\n", 'out from ->system_out Future' );
}

# run with in+out
{
   my $f = Future::IO::System->run(
      argv     => [ $^X, "-e", "print uc( scalar <STDIN> );" ],
      in       => "hello, world",
      want_out => 1,
   );

   my ( $exitcode, $out ) = $f->get;
   is( $exitcode, 0, 'exitcode from ->run+in+out Future' );
   is( $out, "HELLO, WORLD", 'out from ->run+in+out Future' );
}

# run with out+err
{
   my $f = Future::IO::System->run(
      argv     => [ $^X, "-e", "print qq(OUT\\n); print STDERR qq(ERR\\n);" ],
      want_out => 1,
      want_err => 1,
   );

   my ( $exitcode, $out, $err ) = $f->get;
   is( $exitcode, 0, 'exitcode from ->run+out+err Future' );
   is( $out, "OUT\n", 'out from ->run+out+err Future' );
   is( $err, "ERR\n", 'err from ->run+out+err Future' );
}

done_testing;
