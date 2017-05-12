#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use IO::Async::Test;
use IO::Async::Loop 0.62;  # 'getaddrinfo' resolver name

use Future;

use IO::Async::Resolver::StupidCache;

my $loop = IO::Async::Loop->new;
testing_loop( $loop );

my $resolve_count;

{
   package MockResolver;

   sub new { bless {}, shift }

   sub resolve
   {
      shift;
      my %args = @_;

      my $type = $args{type};

      if( $type eq "getaddrinfo" ) {
         my %data = @{ $args{data} };

         $data{host} eq "localhost" or
            die "Expected 'host' to be localhost";

         $resolve_count++;
         return Future->new->done(
            "", # err
            { family => 1, socktype => 1, protocol => 1, addr => "ADDR" },
         );
      }
      elsif( $type eq "getnameinfo" ) {
         $resolve_count++;
         return Future->new->done( [ "HOST", "SERVICE" ] );
      }
      else {
         die "Not sure how to mock resolver type $type";
      }
   }
}

my $resolver = IO::Async::Resolver::StupidCache->new(
   source => MockResolver->new,
);

$loop->add( $resolver );

# resolve type=getaddrinfo
{
   $resolve_count = 0;

   my $f = $resolver->resolve(
      type => "getaddrinfo",
      data => [
         host => "localhost",
         service => 0,
      ]
   );

   wait_for { $f->is_ready };

   my ( $err, @res ) = $f->get;

   ok( !$err, 'resolve does not fail' );

   is( $resolve_count, 1, 'Count 1 after first resolve' );

   $resolver->resolve(
      type => "getaddrinfo",
      data => [ host => "localhost", service => 0 ]
   )->get for 1 .. 2;

   is( $resolve_count, 1, 'Count still 1 after two more resolves' );

   # getaddrinfo has to sort keys

   $resolver->resolve(
      type => "getaddrinfo",
      data => [ service => 0, host => "localhost" ]
   )->get for 1 .. 2;

   is( $resolve_count, 1, 'Count still 1 after resolve in different order' );
}

# ->getaddrinfo shortcut
{
   $resolve_count = 0;

   my $f = $resolver->getaddrinfo(
      host => "localhost",
      service => "http",
   );

   wait_for { $f->is_ready };

   my @res = $f->get;

   is( $resolve_count, 1, 'Count 1 after first ->getaddrinfo' );

   $resolver->getaddrinfo(
      host => "localhost",
      service => "http",
   )->get for 1 .. 2;

   is( $resolve_count, 1, 'Count still 1 after two more ->getaddrinfo calls' );
}

# ->getnameinfo shortcut
{
   $resolve_count = 0;

   my $f = $resolver->getnameinfo(
      addr => "ADDR_HERE", # deliberately not valid
   );

   wait_for { $f->is_ready };

   my ( $host, $service ) = $f->get;

   is( $resolve_count, 1, 'Count 1 after first ->getnameinfo' );

   $resolver->getnameinfo(
      addr => "ADDR_HERE",
   )->get for 1 .. 2;

   is( $resolve_count, 1, 'Count still 1 after two more ->getnameinfo calls' );
}

$loop->remove( $resolver );

done_testing;
