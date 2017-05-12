package Hook::WrapSub;
$Hook::WrapSub::VERSION = '0.07';
use 5.006;
use strict;
use warnings;

use Exporter;
use Symbol;

our @ISA        = qw/ Exporter /;
our @EXPORT_OK  = qw/ wrap_subs unwrap_subs /;


sub wrap_subs(@) {
  my( $precall_cr, $postcall_cr );
  ref($_[0]) and $precall_cr = shift;
  ref($_[-1]) and $postcall_cr = pop;
  my @names = @_;

  my( $calling_package ) = caller;

  for my $name ( @names ) {

    my $fullname;
    my $sr = *{ qualify_to_ref($name,$calling_package) }{CODE};
    if ( defined $sr ) { 
      $fullname = qualify($name,$calling_package);
    }
    else {
      warn "Can't find subroutine named '$name'\n";
      next;
    }


    my $cr = sub {
      $Hook::WrapSub::UNWRAP and return $sr;

      #
      # this is a bunch of kludg to make a list of values
      # that look like a "real" caller() result.
      #

      my $up = 0;
      my @args = caller($up);
      while ( $args[0] =~ /Hook::WrapSub/ ) {
        $up++;
        @args = caller($up);
      }
      my @vargs = @args; # save temp
      while ( defined($args[3]) && $args[3] =~ /Hook::WrapSub/ ) {
        $up++;
        @args = caller($up);
      }
      $vargs[3] = $args[3];
      # now @vargs looks right.

      local $Hook::WrapSub::name = $fullname;
      local @Hook::WrapSub::result = ();
      local @Hook::WrapSub::caller = @vargs;
      my $wantarray = $Hook::WrapSub::caller[5];
#
# try to supply the same calling context to the nested sub:
#

      unless ( defined $wantarray ) {
        # void context
        &$precall_cr  if $precall_cr;
        &$sr;
        &$postcall_cr if $postcall_cr;
        return();
      }

      unless ( $wantarray ) {
        # scalar context
        &$precall_cr  if $precall_cr;
        $Hook::WrapSub::result[0] = &$sr;
        &$postcall_cr if $postcall_cr;
        return $Hook::WrapSub::result[0];
      }

      # list context
      &$precall_cr  if $precall_cr;
      @Hook::WrapSub::result = &$sr;
      &$postcall_cr if $postcall_cr;
      return( @Hook::WrapSub::result );
    };

    no warnings 'redefine';
    no strict 'refs';
    *{ $fullname } = $cr;
  }
}

sub unwrap_subs(@) {
  my @names = @_;

  my( $calling_package ) = caller;

  for my $name ( @names ) {
    my $fullname;
    my $sr = *{ qualify_to_ref($name,$calling_package) }{CODE};
    if ( defined $sr ) { 
      $fullname = qualify($name,$calling_package);
    }
    else {
      warn "Can't find subroutine named '$name'\n";
      next;
    }
    local $Hook::WrapSub::UNWRAP = 1;
    my $cr = $sr->();
    if ( defined $cr and $cr =~ /\bCODE\b/ ) {
      no strict 'refs';
      no warnings 'redefine';
      *{ $fullname } = $cr;
    }
    else {
      warn "Subroutine '$fullname' not wrapped!";
    }
  }
}

1;

=head1 NAME

Hook::WrapSub - wrap subs with pre- and post-call hooks

=head1 SYNOPSIS

  use Hook::WrapSub qw( wrap_subs unwrap_subs );

  wrap_subs \&before, 'some_func', 'another_func', \&after;

  unwrap_subs 'some_func';


=head1 DESCRIPTION

This module lets you wrap a function,
providing one or both of functions that are called just before and just after,
whenever the wrapped function is called.

There are a number of other modules that provide the same functionality
as this module, some of them better. Have a look at the list in SEE ALSO,
below, before you decide which to use.

=head2 wrap_subs

This function enables intercepting a call to any named
function; handlers may be added both before and after
the call to the intercepted function.

For example:

  wrap_subs \&before, 'some_func', \&after;

In this case, whenever the sub named 'some_func' is called,
the &before sub is called first, and the &after sub is called
afterwards.  These are both optional.  If you only want
to intercept the call beforehand:

  wrap_subs \&before, 'some_func';

You may pass more than one sub name:

  wrap_subs \&before, 'foo', 'bar', 'baz', \&after;

and each one will have the same hooks applied.

The sub names may be qualified.  Any unqualified names
are assumed to reside in the package of the caller.

The &before sub and the &after sub are both passed the
argument list which is destined for the wrapped sub.
This can be inspected, and even altered, in the &before
sub:

  sub before {  
    ref($_[1]) && $_[1] =~ /\bARRAY\b/
      or croak "2nd arg must be an array-ref!";
    @_ or @_ = qw( default values );
    # if no args passed, insert some default values
  }

The &after sub is also passed this list.  Modifications
to it will (obviously) not be seen by the wrapped sub,
but the caller will see the changes, if it happens to
be looking.

Here's an example that causes a certain method call
to be redirected to a specific object.  (Note, we 
use splice to change $_[0], because assigning directly
to $_[0] would cause the change to be visible to the caller,
due to the magical aliasing nature of @_.)

  my $handler_object = new MyClass;

  Hook::WrapSub::wrap_subs
    sub { splice @_, 0, 1, $handler_object },
    'MyClass::some_method';

  my $other_object = new MyClass;
  $other_object->some_method;

  # even though the method is invoked on
  # $other_object, it will actually be executed
  # with a 0'th argument = $handler_obj,
  # as arranged by the pre-call hook sub.

=head2 Package Variables

There are some Hook::WrapSub package variables defined,
which the &before and &after subs may inspect.

=over 4

=item $Hook::WrapSub::name 

This is the fully qualified name of the wrapped sub.

=item @Hook::WrapSub::caller

This is a list which strongly resembles the result of a
call to the built-in function C<caller>; it is provided
because calling C<caller> will in fact produce confusing
results; if your sub is inclined to call C<caller>,
have it look at this variable instead.

=item @Hook::WrapSub::result

This contains the result of the call to the wrapped sub.
It is empty in the &before sub.  In the &after sub, it
will be empty if the sub was called in a void context,
it will contain one value if the sub was called in a
scalar context; otherwise, it may have any number of
elements.  Note that the &after function is not prevented
from modifying the contents of this array; any such
modifications will be seen by the caller!


=back

This simple example shows how Hook::WrapSub can be
used to log certain subroutine calls:

  sub before {
    print STDERR <<"    EOF";
      About to call $Hook::WrapSub::name( @_ );
      Wantarray=$Hook::WrapSub::caller[5]
    EOF
  }

  sub after {
    print STDERR <<"    EOF";
      Called $Hook::WrapSub::name( @_ );
      Result=( @Hook::WrapSub::result )
    EOF
    @Hook::WrapSub::result 
      or @Hook::WrapSub::result = qw( default return );
    # if the sub failed to return something...
  }

Much more elaborate uses are possible.  Here's one
one way it could be used with database operations:

  my $dbh; # initialized elsewhere.

  wrap_subs
    sub {
      $dbh->checkpoint
    },

    'MyDb::update',
    'MyDb::delete',

    sub {
      # examine result of sub call:
      if ( $Hook::WrapSub::result[0] ) {
        # success
        $dbh->commit;
      }
      else {
        # failure
        $dbh->rollback;
      }
    };

=head2  unwrap_subs

This removes the most recent wrapping of the named subs.

NOTE: Any given sub may be wrapped an unlimited
number of times.  A "stack" of the wrappings is
maintained internally.  wrap_subs "pushes" a wrapping,
and unwrap_subs "pops".


=head1 SEE ALSO

L<Hook::LexWrap> provides a similar capability to C<Hook::WrapSub>,
but has the benefit that the C<caller()> function works correctly
within the wrapped subroutine.

L<Sub::Prepend> lets you provide a sub that will be called before
a named sub. The C<caller()> function works correctly in the
wrapped sub.

L<Sub::Mage> provides a number of related functions.
You can provide pre- and post-call hooks,
you can temporarily override a function and then restore it later,
and more.

L<Class::Hook> lets you add pre- and post-call hooks around any
methods called by your code. It doesn't support functions.

L<Hook::Scope> lets you register callbacks that will be invoked
when execution leaves the scope they were registered in.

L<Hook::PrePostCall> provides an OO interface for wrapping
a function with pre- and post-call hook functions.
Last updated in 1997, and marked as alpha.

L<Hook::Heckle> provides an OO interface for wrapping pre- and post-call
hooks around functions or methods in a package. Not updated sinc 2003,
and has a 20% failed rate on CPAN Testers.

L<Moose::Manual::MethodModifiers> describes L<Moose>'s mechanism
for hooking a superclass's method.
The I<before> and I<after> subs are called immediately before or
after the specified methods are called.
The I<around> sub wraps the superclass method,
and can even decide not to invoke the superclass method.

L<Class::Method::Modifiers> provides a L<Moose>-style mechanism
for a subclass to have I<before>, I<after>, or I<around>
method modifiers.

L<Class::Wrap> provides the C<wrap()> function, which takes a coderef
and a package name. The coderef is invoked every time a method in
the package is called.

L<Sub::Versive> lets you stack pre- and post-call hooks.
Last updated in 2001.

=head1 REPOSITORY

L<https://github.com/neilb/Hook-WrapSub>

=head1 AUTHOR

This module was written by John Porter E<lt>jdporter@min.netE<gt>

It is now being maintained by Neil Bowers.

=head1 COPYRIGHT

This is free software.  This software may be modified and/or
distributed under the same terms as Perl itself.

=cut

