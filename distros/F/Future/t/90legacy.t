#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Future;

# done_cb
{
   my $f = Future->new;

   my $warnings;
   local $SIG{__WARN__} = sub { $warnings .= join "", @_; };

   my $cb = $f->done_cb;
   $cb->( 123 );

   is( $f->get, 123, '$f->get after done_cb invoked' );
   like( $warnings, qr/ is now deprecated/, 'Deprecation warning occured' );
}

# fail_cb
{
   my $f = Future->new;

   my $warnings;
   local $SIG{__WARN__} = sub { $warnings .= join "", @_; };

   my $cb = $f->fail_cb;
   $cb->( "oops\n" );

   is( $f->failure, "oops\n", '$f->failure after fail_cb invoked' );
   like( $warnings, qr/ is now deprecated/, 'Deprecation warning occured' );
}

# cancel_cb
{
   my $f = Future->new;

   my $warnings;
   local $SIG{__WARN__} = sub { $warnings .= join "", @_; };

   my $cb = $f->cancel_cb;
   $cb->();

   ok( $f->is_cancelled, '$f is cancelled after cancel_cb invoked' );
   like( $warnings, qr/ is now deprecated/, 'Deprecation warning occured' );
}

done_testing;
