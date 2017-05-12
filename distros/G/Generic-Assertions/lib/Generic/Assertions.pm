use 5.006;
use strict;
use warnings;

package Generic::Assertions;

our $VERSION = '0.001002';

# ABSTRACT: A Generic Assertion checking class

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Carp qw( croak carp );

sub new {
  my ( $class, @args ) = @_;
  if ( @args % 2 == 1 and not ref $args[0] ) {
    croak '->new() expects even number of arguments or a hash reference, got ' . scalar @args . ' argument(s)';
  }
  my $hash;
  if ( ref $args[0] ) {
    $hash = { args => $args[0] };
  }
  else {
    $hash = { args => {@args} };
  }
  my $self = bless $hash, $class;
  $self->BUILD;
  return $self;
}





sub BUILD {
  my ($self) = @_;
  my $tests = $self->_tests;
  for my $test ( keys %{$tests} ) {
    croak 'test ' . $test . ' must be a CodeRef' if not 'CODE' eq ref $tests->{$test};
  }
  my $handlers = $self->_handlers;
  for my $handler ( keys %{$handlers} ) {
    croak 'handler ' . $handler . ' must be a CodeRef' if not 'CODE' eq ref $handlers->{$handler};
  }
  croak 'input_transformer must be a CodeRef' if not 'CODE' eq ref $self->_input_transformer;
  return;
}

sub _args {
  my ($self) = @_;
  return $self->{args} if exists $self->{args};
  return ( $self->{args} = {} );
}

sub _tests {
  my ( $self, ) = @_;
  return $self->{tests} if exists $self->{tests};
  my %tests;
  for my $key ( grep { !/\A-/msx } keys %{ $self->_args } ) {
    $tests{$key} = $self->_args->{$key};
  }
  return ( $self->{tests} = { %tests, %{ $self->_args->{'-tests'} || {} } } );
}

sub _handlers {
  my ( $self, ) = @_;
  return $self->{handlers} if exists $self->{handlers};
  return ( $self->{handlers} = { %{ $self->_handler_defaults }, %{ $self->_args->{'-handlers'} || {} } } );
}

sub _handler_defaults {
  return {
    test => sub {
      my ($status) = @_;
      return $status;
    },
    log => sub {
      my ( $status, $message, $name, @slurpy ) = @_;
      carp sprintf 'Assertion < log %s > = %s : %s', $name, ( $status || '0' ), $message;
      return $slurpy[0];
    },
    should => sub {
      my ( $status, $message, $name, @slurpy ) = @_;
      carp "Assertion < should $name > failed: $message" unless $status;
      return $slurpy[0];
    },
    should_not => sub {
      my ( $status, $message, $name, @slurpy ) = @_;
      carp "Assertion < should_not $name > failed: $message" if $status;
      return $slurpy[0];
    },
    must => sub {
      my ( $status, $message, $name, @slurpy ) = @_;
      croak "Assertion < must $name > failed: $message" unless $status;
      return $slurpy[0];
    },
    must_not => sub {
      my ( $status, $message, $name, @slurpy ) = @_;
      croak "Assertion < must_not $name > failed: $message" if $status;
      return $slurpy[0];
    },
  };
}

sub _transform_input {
  my ( $self, $name, @slurpy ) = @_;
  return $self->_input_transformer->( $name, @slurpy );
}

sub _input_transformer {
  my ( $self, ) = @_;
  return $self->{input_transformer} if exists $self->{input_transformer};
  if ( exists $self->_args->{'-input_transformer'} ) {
    return ( $self->{input_transformer} = $self->_args->{'-input_transformer'} );
  }
  return ( $self->{input_transformer} = $self->_input_transformer_default );
}

sub _input_transformer_default {
  return sub { shift; return @_ };
}

# Dispatch the result of test name $test_name
sub _handle {    ## no critic (Subroutines::ProhibitManyArgs)
  my ( $self, $handler_name, $status_code, $message, $test_name, @slurpy ) = @_;
  return $self->_handlers->{$handler_name}->( $status_code, $message, $test_name, @slurpy );
}

# Perform $test_name and return its result
sub _test {
  my ( $self, $test_name, @slurpy ) = @_;
  my $tests = $self->_tests;
  if ( not exists $tests->{$test_name} ) {
    croak sprintf q[INVALID ASSERTION %s ( avail: %s )], $test_name, ( join q[,], keys %{$tests} );
  }
  return $tests->{$test_name}->(@slurpy);
}

# Long form
# ->_assert( should => exist => path('./foo'))
# ->should( exist => path('./foo'))
sub _assert {
  my ( $self, $handler_name, $test_name, @slurpy ) = @_;
  my (@input) = $self->_transform_input( $test_name, @slurpy );
  my ( $status, $message ) = $self->_test( $test_name, @input );
  return $self->_handle( $handler_name, $status, $message, $test_name, @input );
}

for my $handler (qw( should must should_not must_not test log )) {
  my $code = sub {
    my ( $self, $name, @slurpy ) = @_;
    return $self->_assert( $handler, $name, @slurpy );
  };
  {
    ## no critic (TestingAndDebugging::ProhibitNoStrict])
    no strict 'refs';
    *{ __PACKAGE__ . q[::] . $handler } = $code;
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Generic::Assertions - A Generic Assertion checking class

=head1 VERSION

version 0.001002

=head1 ALPHA

This is pre-release code, and as such C<API> is very much subject to change.

Best attempts at being consolidated is already made, but there's no guarantees at this time
things won't change and break C<API> without warning.

=head1 SYNOPSIS

  use Generic::Assertions;
  use Path::Tiny qw(path);

  my $assert = Generic::Assertions->new(
    exist => sub {
      return (1, "Path $_[0] exists") if path($_[0])->exists;
      return (0, "Path $_[0] does not exist");
    },
  );

  ...

  sub foo {
    my ( $path ) = @_;

    # carp unless $path exists with "Path $path does not exist"
    $assert->should( exist => $path );

    # carp if $path exists with "Path $path exists"
    $assert->should_not( exist => $path );

    # croak unless $path exists with "Path $path does not exist"
    $assert->must( exist => $path );

    # Lower level way to use the assertion simply to return truth value
    # without side effects.
    if ( $assert->test( exist => $path ) ) {

    }

    # carp unconditionally showing the test result and its message
    $assert->log( exist => $path );
  }

=head1 DESCRIPTION

C<Generic::Assertions> allows you to create portable containers of classes of assertions, and allows keeping
severity of assertions from their implementation.

Basic implementation entails

=over 4

=item * Defining a list of things to test for

=item * Returning a pair of ( OK / NOT_OK , "reason" ) for the tests conclusion

=item * [optional] Defining a default handler for various classes of severity ( C<should>, C<must> etc. )

=item * [optional] Defining an input transform (eg: always converting the first argument to a path)

=item * Invoking the assertion at the callpoint as C<< $instance->severity_level( test_name => @args_for_test ) >>

=back

=head1 METHODS

=head2 C<new>

Constructs a Generic::Assertions object.

  my $assertion = Generic::Assertions->new( ARGS );

The following forms of C<ARGS> is supported:

  ->new(   key => value    );
  ->new({  key => value   });

All C<keys> without a C<-> prefix are assumed to be test names, and are equivalent to:

  ->new( -tests => { key => value } );

=head3 C<-tests>

All tests must have a simple string key, and a C<CodeRef> value.

An example test looks like:

   sub {
      my ( @slurpy ) = @_;
      if ( -e $slurpy[0] ) {
        return ( 1, "$slurpy[0] exists" );
      }
      return ( 0, "$slurpy[1] does not exist" );
   }

That is, each test must return either a C<true> value or a C<false> value.
And each test must return a string describing the condition.

This is so it composes nicely:

  $ass->should( exist => $foo ); # warns "$foo does not exist" if it doesn't
  $ass->should_not( exist => $foo ); # warns "$foo exists" if it does.

Note the test itself can only see the arguments passed directly to it at the calling point.

=head3 C<-handlers>

Each of the various assertion types have a handler underlying them, which can be overridden
during construction.

  ->new( -handlers => { should => sub { ... } } );

This for instance will override the default handler for "should" and will be invoked
somewhere after the result from

  $assertion->should(  )

Is obtained.

An example handler approximating the default C<should> handler.

  sub {
    my ( $status, $message, $name, @slurpy ) = @_;
    # $status is the 0/1 returned by the test.
    # $message is the message the test gave.
    # $name is the name of the test invoked ( ie: ->should( foo => ... )
    # @slurpy is the arguments passed from the user to the test.
    carp $message if $status;
    return $slurpy[0];
  }

Its worth noting that handlers dictate in entirety:

=over 4

=item * What calls will be invoked in response to the fail/pass returned by the test

=item * What will be returned to the caller who invoked the test

=back

For instance, the C<test> handler is simply:

  sub {
    my ( $status ) = @_;
    return $status;
  }

And you could perhaps change that to

  sub {
    my ( $status, $message ) = @_;
    return $message;
  }

And then invoking

  ->test( foo => @args );

Would return C<foo>'s message instead of its return value.

Use this power with care.

=head4 Custom Handlers

You can of course define custom handlers outside the core functionality,
except of course they won't be accessible as convenient methods.

You can perhaps invoke them via

  ->_assert( $handler_name, $test_name, @slurpy_args )

But it would be probably nicer for you to sub-class C<Generic::Assertions> and make
it available as a native method:

  ->$handler_name( $test_name, @slurpy_args )

=head3 C<-input_transformer>

You can specify a C<CodeRef> through which all tests get passed as a primary step.

  ->new(
    -input_transformer => sub {
      # Gets both the name, and all the tests arguments
      my ( $name, $path )  = @_;
      # Returns a substitute argument list
      return path( $path );
    },
    exist => sub {
      return ( 0, "$_[0] does not exist" ) unless $_[0]->exists;
      return ( 1, "$_[1] exists" );
    },
  );

  ...
  # The following code will now check that foo.pm exist
  # and if it exists, return a path() object for it as $rval.
  # If foo.pm does not exist, it will warn.
  #
  # $rval will be a path object in both cases.
  my $rval = $ass->should( exist => "./foo.pm" );

  # Under default configuration, this is basically the same as:
  sub should_exist {
    my @args = @_;
    my $path = path($args[0]);
    if ( not $path->exists() ) {
      warn "$path does not exist";
    }
    return $path;
  }
  my $rval = $thing->should_exist("./foo.pm");
  # Except of course more composable.

=head2 C<test>

Default implementation simply returns the result of the given test.

  if ( $assertion->test( test_name => @args ) ) {

  }

=head2 C<log>

Default implementation 'carp's the message and status given by C<test_name>, and returns C<$args[0]>

  $assertion->log( test_name => @args );

=head2 C<should>

Default implementation carps if C<test_name> returns C<false> with the message provided by C<test_name>.
It then returns C<$args[0]>

  $assertion->should( test_name => @args );

=head2 C<should_not>

Default implementation carps if C<test_name> returns C<true> with the message provided by C<test_name>.
It then returns C<$args[0]>

  $assertion->should_not( test_name => @args );

=head2 C<must>

Default implementation croaks if C<test_name> returns C<false> with the message provided by C<test_name>.

  $assertion->must( test_name => @args );

=head2 C<must_not>

Default implementation croaks if C<test_name> returns C<true> with the message provided by C<test_name>.

  $assertion->must_not( test_name => @args );

=for Pod::Coverage BUILD

=head1 THANKS

To David Golden/xdg for oversight on some of the design concerns on this module.

It would be for sure much uglier than it presently is without his help :)

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
