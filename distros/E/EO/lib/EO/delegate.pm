package EO::delegate;

use strict;
use warnings;

use EO;
use EO::Class;
use EO::Method;

our $VERSION = 0.96;
our $AUTOLOAD;

sub import {
  my $this = shift;
  my $what  = shift;
  my $caller = caller();

  my $class = EO::Class->new_with_classname( $caller );

  ##
  ## create a delegate_error method in the class, this will getset the method
  ##  to be called when we need to throw/record an exception
  ##
  my $error_method = EO::Method->new();
  $error_method->name('delegate_error');
  $error_method->reference(
			   sub {
			     my $self = shift;
			     if (@_) {
			       $self->{ _delegate_error } = shift;
			       return $self;
			     }
			     $self->{ _delegate_error } ||= 'throw';
			     return $self->{ _delegate_error };
			   }
			  );

  ##
  ## create a delegate method in the class, this will getset the delegate
  ##  that is to be used
  ##
  my $delegate_method = EO::Method->new();
  $delegate_method->name( 'delegate' );
  $delegate_method->reference(
			      sub {
				my $self = shift;
				if (@_) {
				  $self->{ _delegate_to } = shift;
				  return $self;
				}
				return $self->{ _delegate_to };
			      }
			     );

  my $resolver_method = EO::Method->new();
  $resolver_method->name( 'AUTOLOAD' );
  $resolver_method->reference(
			      sub {
				my $self = shift;
				my $meth = substr($AUTOLOAD, rindex($AUTOLOAD, ':') + 1);
				my $delegate = $self->delegate || return undef;
				if (my $sub = $delegate->can($meth)) {
				  $sub->( $self->delegate, @_ );
				} else {
				  my $class = ref($self->delegate);
				  my $from_class = ref($self);
				  my $text = "Can't locate object method \"$meth\" via package"
				              . "$class delegated from $from_class";
				  my $on_error = $self->delegate_error();
				  local($Error::Depth) = $Error::Depth + 1;
				  EO::Error::Method::NotFound->$on_error(
									 text => $text,
									 file => __FILE__,
									 line => __LINE__
									);
				  return undef;
				}
			      }
			     );

  $class->add_method( $error_method );
  $class->add_method( $delegate_method );
  $class->add_method( $resolver_method );

  if (!$caller->can('DESTROY')) {
    $class->add_method( EO::Method->new()->name( 'DESTROY' )->reference( sub {} ) );
  }
}

1;

__END__

=head1 NAME

EO::delegate - delegate responsibility for unresolved messages to another class

=head1 SYNOPSIS

  package Foo;
  use EO;
  our @ISA = qw( EO );
  use EO::delegate;

  package main;

  my $thing = Foo->new();
  $thing->delegate( SomeClass->new() );
  $thing->delegate_error( 'throw' );

  eval {
    $thing->some_method;
  };
  if ($@) {
    if ($@->isa('EO::Error::Method::NotFound') {
      # ... handle method not found exception
    } else {
      # ... handle other exceptions
    }
  }

=head1 DESCRIPTION

EO::delegate provides a simple means of setting up a delegate for
the a class.  By importing this package into your namespace you have two new
methods available to you - the C<delegate> method, which gets and sets the
delegate, and the C<delegate_error> method, which gets and sets the method
to call on the exception if any are raised.

By default delegate_error will be set to 'throw', but it may be useful to set
it to 'record' if you don't wish the delegate to cause your program to die.

=head1 EXCEPTIONS

=over 4

=item EO::Error::Method::NotFound

In the case that a method that is forwarded to a delegate is not available in that delegate an
EO::Error::Method::NotFound exception is thrown or recorded, depending on whether delegate_error
returns C<throw> or C<record>.

=back

=head1 AUTHOR

  James A. Duncan <jduncan@fotango.com>
  Arthur Bergman <abergman@fotango.com>

=head1 COPYRIGHT

Copyright 2003 Fotango Ltd. All Rights Reserved.

This module is released under the same terms as Perl itself.

=cut
