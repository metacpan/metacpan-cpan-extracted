#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Refcount;

use IO::Async::Notifier;

{
   my $notifier = IO::Async::Notifier->new(
      notifier_name => "test1",
   );

   ok( defined $notifier, '$notifier defined' );
   isa_ok( $notifier, "IO::Async::Notifier", '$notifier isa IO::Async::Notifier' );

   is_oneref( $notifier, '$notifier has refcount 1 initially' );

   is( $notifier->notifier_name, "test1", '$notifier->notifier_name' );

   ok( !exception { $notifier->configure; },
      '$notifier->configure no params succeeds' );

   ok( exception { $notifier->configure( oranges => 1 ) },
      '$notifier->configure an unknown parameter fails' );

   my %other;
   no warnings 'redefine';
   local *IO::Async::Notifier::configure_unknown = sub {
      shift;
      %other = @_;
   };

   ok( !exception { $notifier->configure( oranges => 3 ) },
       '$notifier->configure with configure_unknown succeeds' );

   is_deeply( \%other, { oranges => 3 }, '%other after configure_unknown' );
}

# weaseling
{
   my $notifier = IO::Async::Notifier->new;

   my @args;
   my $mref = $notifier->_capture_weakself( sub { @args = @_ } );

   is_oneref( $notifier, '$notifier has refcount 1 after _capture_weakself' );

   $mref->( 123 );
   is_deeply( \@args, [ $notifier, 123 ], '@args after invoking $mref' );

   my @callstack;
   $notifier->_capture_weakself( sub {
      my $level = 0;
      push @callstack, [ (caller $level++)[0,3] ] while defined caller $level;
   } )->();

   is_deeply( \@callstack,
              [ [ "main", "main::__ANON__" ] ],
              'trampoline does not appear in _capture_weakself callstack' );

   undef @args;

   $mref = $notifier->_replace_weakself( sub { @args = @_ } );

   is_oneref( $notifier, '$notifier has refcount 1 after _replace_weakself' );

   my $outerself = bless [], "OtherClass";
   $mref->( $outerself, 456 );
   is_deeply( \@args, [ $notifier, 456 ], '@args after invoking replacer $mref' );

   isa_ok( $outerself, "OtherClass", '$outerself unchanged' );

   ok( exception { $notifier->_capture_weakself( 'cannotdo' ) },
       '$notifier->_capture_weakself on unknown method name fails' );
}

# Subclass
{
   my @subargs;
   {
      package TestNotifier;
      use base qw( IO::Async::Notifier );

      sub frobnicate { @subargs = @_ }
   }

   my $subn = TestNotifier->new;

   my $mref = $subn->_capture_weakself( 'frobnicate' );

   is_oneref( $subn, '$subn has refcount 1 after _capture_weakself on named method' );

   $mref->( 456 );
   is_deeply( \@subargs, [ $subn, 456 ], '@subargs after invoking $mref on named method' );

   undef @subargs;

   # Method capture
   {
      my @newargs;

      no warnings 'redefine';
      local *TestNotifier::frobnicate = sub { @newargs = @_; };

      $mref->( 321 );

      is_deeply( \@subargs, [], '@subargs empty after TestNotifier::frobnicate replacement' );
      is_deeply( \@newargs, [ $subn, 321 ], '@newargs after TestNotifier::frobnicate replacement' );
   }

   undef @subargs;

   $subn->invoke_event( 'frobnicate', 78 );
   is_deeply( \@subargs, [ $subn, 78 ], '@subargs after ->invoke_event' );

   undef @subargs;

   is_deeply( $subn->maybe_invoke_event( 'frobnicate', 'a'..'c' ),
              [ $subn, 'a'..'c' ],
              'return value from ->maybe_invoke_event' );

   is( $subn->maybe_invoke_event( 'mangle' ), undef, 'return value from ->maybe_invoke_event on missing event' );

   undef @subargs;

   my $cb = $subn->make_event_cb( 'frobnicate' );

   is( ref $cb, "CODE", '->make_event_cb returns a CODE reference' );
   is_oneref( $subn, '$subn has refcount 1 after ->make_event_cb' );

   $cb->( 90 );
   is_deeply( \@subargs, [ $subn, 90 ], '@subargs after ->make_event_cb->()' );

   isa_ok( $subn->maybe_make_event_cb( 'frobnicate' ), "CODE", '->maybe_make_event_cb yields CODE ref' );
   is( $subn->maybe_make_event_cb( 'mangle' ), undef, '->maybe_make_event_cb on missing event yields undef' );

   undef @subargs;

   is_oneref( $subn, '$subn has refcount 1 finally' );
}

# parent/child
{
   my $parent = IO::Async::Notifier->new;
   my $child = IO::Async::Notifier->new;

   is_oneref( $parent, '$parent has refcount 1 initially' );
   is_oneref( $child, '$child has refcount 1 initially' );

   $parent->add_child( $child );

   is( $child->parent, $parent, '$child->parent is $parent' );
   is_deeply( [ $parent->children ], [ $child ], '$parent->children' );

   is_oneref( $parent, '$parent has refcount 1 after add_child' );
   is_refcount( $child, 2, '$child has refcount 2 after add_child' );

   ok( exception { $parent->add_child( $child ) }, 'Adding child again fails' );

   $parent->remove_child( $child );

   is_oneref( $child, '$child has refcount 1 after remove_child' );
   is_deeply( [ $parent->children ], [], '$parent->children now empty' );
}

# invoke_error
{
   my $parent = IO::Async::Notifier->new;
   my $child = IO::Async::Notifier->new;

   $parent->add_child( $child );

   # invoke_error no handler
   ok( exception { $parent->invoke_error( "It went wrong", wrong => ) },
       'Exception thrown from ->invoke_error with no handler' );

   # invoke_error handler
   my $err;
   $parent->configure( on_error => sub { $err = $_[1] } );

   ok( !exception { $parent->invoke_error( "It's still wrong", wrong => ) },
       'Exception not thrown from ->invoke_error with handler' );
   is( $err, "It's still wrong", '$message to on_error' );

   ok( !exception { $child->invoke_error( "Wrong on child", wrong => ) },
       'Exception not thrown from ->invoke_error on child' );
   is( $err, "Wrong on child", '$message to parent on_error' );
}

done_testing;
