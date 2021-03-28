package Math::ModInt::Event;

use 5.006;
use strict;
use warnings;
use Carp qw(croak);
use Math::ModInt::Event::Trap;

# ----- class data -----

BEGIN {
    require Exporter;
    our @ISA        = qw(Exporter);
    our @EXPORT_OK  = qw(
        AnyEvent Unrecoverable Recoverable UsageError Nonexistent
        LoadingFailure UndefinedResult DifferentModuli
    );
    our @CARP_NOT   = qw(Math::ModInt);
    our $VERSION    = '0.013';
}

# Math::ModInt::Event=ARRAY(...)

# ............ index ............   # ............ value ............
use constant F_DESCRIPTION  => 0;   # a short event description string
use constant NFIELDS        => 1;

# ----- private subroutines -----

# create a new event subclass and return a singleton instance of that class
# - description string is made of the words in the camel-case class name
# - parent class is taken from optional parent object or defaults to Event.
sub _make {
    my ($class, $parent) = @_;
    my $description = lc join q[ ], split /(?<=[a-z])(?=[A-Z])/, $class;
    $class  = join '::', __PACKAGE__, $class;
    eval join '', '@', $class, '::ISA = qw(', ref $parent || __PACKAGE__, ')';
    return bless [$description], $class;
}

# ----- public methods -----

# singleton event constructors:

use constant AnyEvent            => _make('AnyEvent');
use constant   Unrecoverable     => _make('Unrecoverable',   AnyEvent);
use constant     UsageError      => _make('UsageError',      Unrecoverable);
use constant     Nonexistent     => _make('Nonexistent',     Unrecoverable);
use constant     LoadingFailure  => _make('LoadingFailure',  Unrecoverable);
use constant   Recoverable       => _make('Recoverable',     AnyEvent);
use constant     UndefinedResult => _make('UndefinedResult', Recoverable);
use constant     DifferentModuli => _make('DifferentModuli', Recoverable);

sub description {
    my ($this) = @_;
    return $this->[F_DESCRIPTION];
}

sub is_recoverable { 0 }
sub Math::ModInt::Event::Recoverable::is_recoverable { 1 }

sub trap {
    my ($this, $handler) = @_;
    return Math::ModInt::Event::Trap->new($this, $handler);
}

sub raise {
    my ($this, @details) = @_;
    Math::ModInt::Event::Trap->broadcast($this, @details);
    return $this;
}

1;

__END__

=head1 NAME

Math::ModInt::Event - managing events triggered by Math::ModInt

=head1 VERSION

This documentation refers to version 0.013 of Math::ModInt::Event.

=head1 SYNOPSIS

  # application interface:

  use Math::ModInt qw(mod);
  use Math::ModInt::Event qw(UndefinedResult DifferentModuli AnyEvent);

  $a = mod(0, 2);
  $b = mod(1, 3);

  $trap = DifferentModuli->trap('warn');
  $c = $a + $b;          # warns
  undef $trap;
  $c = $a + $b;          # remains silent

  UndefinedResult->trap('die');         # define a static trap
  $c = $a->inverse;      # raises exception (i.e. calls "die")

  sub my_handler {
      my ($event, @details) = @_;
      # ... insert code here ...
      return 1;          # boolean, whether other handlers may be called
  }

  $trap = AnyEvent->trap( \&my_handler );
  $c = $a + $b;         # calls my_handler(DifferentModuli, $a, $b)
  $c = $a->inverse;     # calls my_handler(UndefinedResult)

  # library module interface:

  UndefinedResult->raise;
  DifferentModuli->raise($this, $that);

=head1 DESCRIPTION

By default, Math::ModInt does not raise exceptions or issue warnings
on arithmetic faults or incompatible operands.  It just replaces
the result of the faulty expression by a special object representing
an undefined value.

Math::ModInt::Event can be used to alter this behaviour.  It provides
hooks to trap occurences of undefined results or incompatible
operands.  Applications can opt to have warning messages issued on
STDERR, exceptions raised, or custom event handlers called upon
these events.

Other types of errors can be trapped similarly, but will always
raise exceptions if no active traps do so.  The general rule is
that errors are considered recoverable where a Math::ModInt object
can convey the error condition, and unrecoverable where conversions
to and from Math::ModInt are involved or the application interface
is formally violated.

=head2 Constructors

Available event types are accessible through class methods with one
of the names listed below.  They form a hierarchical structure
with C<AnyEvent> at the root.

These constructors can also be imported and called like plain
parameter-less subroutines.

=over 4

=item I<UndefinedResult>

C<UndefinedResult> returns a Math::ModInt::Event object representing
events that occur when an arithmetic expression yields an undefined
result.

=item I<DifferentModuli>

C<DifferentModuli> returns a Math::ModInt::Event object representing
events that occur when operands with different moduli are mixed
within a single expression.  Such operands are incompatible.  Handlers
will receive both operands as extra parameters.

=item I<Recoverable>

C<Recoverable> returns an event object representing any recoverable
event, i.e. C<UndefinedResult> and C<DifferentModuli>.

=item I<UsageError>

C<UsageError> returns an event object representing usage error
events.  Events of this type are triggered if a method detects being
called with incorrect parameters.  Note that not every conceivable
kind of wrong usage can be detected this way -- it may just as soon
trigger a simple perl runtime error.  Handlers will get a hint text
indicating what was wrong as an extra parameter.

=item I<Nonexistent>

C<Nonexistent> returns an event object representing access to
nonexistent object attributes.  In particular, residue and modulus
of the undefined Math::ModInt placeholder object are nonexistent.
The extra handler parameter is a hint text indicating which attribute
could not be accessed.

=item I<LoadingFailure>

C<LoadingFailure> returns an event object signalling problems to
load an extension that had been available at the time Math::ModInt
was installed, but not anymore.  The extra handler parameter is the
package name of the defunct extension.  You probably need to
re-install Math::ModInt to resolve the situation.

=item I<Unrecoverable>

C<Unrecoverable> returns an event object representing any unrecoverable
event, i.e. C<UsageError>, C<Nonexistent>, and C<LoadingFailure>.

=item I<AnyEvent>

C<AnyEvent> returns a Math::ModInt::Event object acting as a parent
for all other events.  Traps for this pseudo-event will catch all
events.

=back

=head2 Object Methods

=over 4

=item I<description>

The object method C<description> takes no parameters and returns a
string naming the event.

=item I<is_recoverable>

The object method C<is_recoverable> takes no parameters and returns
a boolean value telling whether all events of the type represented
by the object are recoverable.

=item I<trap>

The object method C<trap> arranges for a given action to be performed
each time an event of the type represented by the object is raised.
Its argument can be a coderef to be called, or one of the strings
C<"ignore"> or C<"warn"> or C<"die">, to ignore an event, trigger
a warning message or runtime exception, respectively.

It returns a new trap object.  If this object is no longer referenced,
the previous behaviour is restored.  Consequently, the result can be
stored in a variable to keep the trap enabled, and the variable undefined
to deactivate the trap.

If called in void context, however, C<trap> declares a static
handler, which is not bound to an object.

Multiple actions connected to the same event type are performed in
reverse order they have been declared by C<trap>.  If an event
handler calls C<die> or C<exit> or returns a false value, no other
handlers still pending are called.

=item I<raise>

The object method C<raise> is used by library modules to trigger an
event of the type represented by the object.  It takes additional
details as optional arguments.  It returns the object it was invoked
on.

=item I<isa>

The object method C<isa> can be used to inspect the event hierarchy.
It takes a fully qualified type of an event object and returns a
boolean value telling whether the invocant is an instance of the
given type, i.e. either precisely of the same type or in one of its
subcategories.

=back

=head1 EXPORT

By default, Math::ModInt::Event does not export anything into the
caller's namespace.  Each event type, though, is also the name of
a constructor that can explicitly be imported.

=head1 DIAGNOSTICS

Standard warnings print C<"warning:"> and the name of the event
(like C<"undefined result">) on STDERR, followed by a caller source
code location.

Standard error messages print C<"error:"> and the name of the event
(like C<"undefined result">) on STDERR, followed by a caller source
code location.  Unless caught in an C<eval> block, program execution
stops thereafter.

User-defined actions can issue customized messages or perform other
tasks at the discretion of the programmer.  If they return, program
execution will either continue or be stopped with an exception,
depending on whether the event was recoverable.

=head1 SEE ALSO

=over 4

=item *

L<Math::ModInt::Event::Trap>

=item *

L<Math::ModInt>

=back

=head1 AUTHOR

Martin Becker, E<lt>becker-cpan-mp I<at> cozap.comE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2010-2021 Martin Becker, Blaubeuren.

This library is free software; you can distribute it and/or modify it
under the terms of the Artistic License 2.0 (see LICENSE file).

=head1 DISCLAIMER OF WARRANTY

This library is distributed in the hope that it will be useful,
but without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut
