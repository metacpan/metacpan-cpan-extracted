package Exception::Class::TCF;
use Exception::Class (
    'Exception::Class::TCF' => {
        'isa'    => 'Exception::Class::Base',
        'fields' => ['Message']
    }
);
use vars qw(@ISA @EXPORT @EXPORT_OK $VERSION);
require Exporter;
@ISA       = qw(Exporter Exception::Class::Base);
@EXPORT    = qw(&try &catch &throw &finally);
@EXPORT_OK = qw(&isThrowing &deactivate &handleWarn &handleDie &make);
$VERSION   = '0.03';

my $DEFAULT_UNCAUGHT = "Exception of type %s thrown but not caught";
my %PROTECTED = map { $_ => 1 } qw(Message);

sub UNIVERSAL::throw (@) {
    my ( $pack, $file, $line ) = caller;
    warn "Parsing problem with throw at $file line $line.\n";
    &Exception::Class::TCF::throw(@_)
}

sub UNIVERSAL::make (@) {
    my($pack,$file,$line) = caller;
    warn "Parsing problem with throw at $file line $line.\n";
    &Exception::Class::TCF::make(@_)
}

sub UNIVERSAL::catch (@) {
    &Exception::Class::TCF::catch(@_)
}

sub isException {
    my $class = shift;
    $class = ref $class if ref $class;
    &isBelow($class,'Exception::Class::TCF');
}

sub isBelow {
    my($class,$above) = @_;
    $class->isa($above) || $class->isa('Exception::Class::TCF::'.$above);
}

sub new {
    my($class) = shift; 
    unshift @_,'Message' if @_ % 2;
    my %args = @_;
    my $self = $class->SUPER::new( 'Message' => $args{'Message'} );
    bless $self, $class;
    for my $key ( keys %args ) {
        if ( $key ne 'Message' ) {
            $self->setFields( $key, $args{$key} );
        }
    }
    return $self;
}

sub make {
    my $class = shift;
    unless ($class =~ m/^Exception::Class::TCF::/o) {
        my $fclass = 'Exception::Class::TCF::' . $class;
        $class = $fclass if isException($fclass);
    }
    return $class->new(@_);
}

sub type {
    my $type = ref($_[0]) || $_[0];
    $type =~ s/^Exception::Class::TCF:://o;
    return $type;
}

sub setFields {
    my($self) = shift;
    if (ref $self) {
        my ( $key, $val );
        while ( ( $key, $val ) = splice @_, 2, 0 ) {
            next if $self->isProtected($val);
            $self->{$key} = $val;
        }
    }
    return $self;
}

sub hasField {
    ref($_[0]) && exists $_[0]->{$_[1]};
}

sub protectedFields { keys %PROTECTED }
sub isProtected { exists $PROTECTED{$_[1]} }

sub removeFields {
    my($self) = shift;
    if (ref $self) {
        my($name);
        foreach ($name) {
            next if $PROTECTED{$name};
            delete $self->{$name};
        } 
    }
    return $self;
}

sub getField {
    ref($_[0]) && $_[0]->{$_[1]};
}

sub setMessage {
    my ( $self, $msg ) = @_;
    if (ref $self) {
        $self->{'Message'} = $msg;
    }
    return $self;
}

sub message {
    ref($_[0]) && exists $_[0]->{'Message'} && $_[0]->{'Message'};
}

my $dTHROWING;
my ( @ARGS, $EXCEPTION, $CATCHING, $THROWING, @STACK );
my ( $HANDLE_DIE, $HANDLE_WARN );

###  These variables are used for the following purposes:
###  $EXCEPTION
###    contains the current active exception and
###  @ARGS
###    the remaining arguments to the throw that threw it.
###  $CATCHING
###    tells if we're in a handler (but haven't entered any 
###    try blocks in the handler).
###  $THROWING
###    tells if we have an active exception.
###  $dTHROWING
###    is used for shortlived communication between throw and try,
###    it is often the same as $THROWING but not always.
###  @STACK
###    is used for the stack needed to implement the scoping rules
###    for the active exception.
###  $HANDLE_DIE
###    set if an ordinary die should be considered as throwing
###    a Die exception
###  $HANDLE_WARN
###    set if a warn should be considered as throwing
###    a Warning exception

sub handleDie {
    $HANDLE_DIE = defined $_[0];
}

sub handleWarn {
    my $oldhw = $HANDLE_WARN;
    $HANDLE_WARN = $_[0];
}

sub deactivate {
    if ($THROWING) {
        undef $EXCEPTION;
        undef @ARGS;
        $THROWING = $CATCHING = 0;
    }
}

sub dieMess {
    my($self) = @_;
    my($type) = $self->type;
    my $UNCAUGHT = $DEFAULT_UNCAUGHT;
    if ($self->hasField('DyingMessage')) {
        $UNCAUGHT = $self->getField('DyingMessage');
    }
    my $mess = sprintf $UNCAUGHT, $type;
    if ( $mess =~ m/\n$/o ) {
        return $mess;
    }
    else {
        my ( $pack, $file, $line ) = caller 2;
        ( $pack, $file, $line ) = caller 3 if ($pack eq 'Exception::Class::TCF');
        return "$mess at $file line $line\n";
    }
}

sub die {
    CORE::die $_[0]->dieMess;
}

sub isThrowing {
    $THROWING || $CATCHING;
}

sub throw (@) {
    my ( $self, @args ) = @_;
    # throw;
    unless (@_) {
        unless ( $CATCHING || $THROWING ) {
            $THROWING = 0;
            my ( $pack, $file, $line ) = caller;
            CORE::die "Rethrow without an active exception at $file line $line\n";
        }
        $EXCEPTION->throw(@ARGS);      ## To get correct inheritance
    }
    $self = make($self) unless ref $self;
    ### Check here that it is an exception? or in make?
    # Is in a try block
    if ( @STACK ) {
        $EXCEPTION = $self;
        @ARGS = @args;
        local $SIG{'__DIE__'} = 'IGNORE';
        $THROWING = 1;
        $dTHROWING = 1;
        CORE::die; ## Maybe $self->die(@args) so Warning does not throw?
    }
    # Thrown to the wolves
    else { 
        $self->die(@args);
    }
}

## We 'my' some functions to make them unchangeable from the outside

my $findException = sub {
    my($class,$excs) = @_;
    if ($class eq 'Exception::Class::TCF') {
        return grep($_ eq 'Default', @$excs) ? 'Default' : "";
    }
    my $fclass =  $class;
    $class =~ s/^Exception::Class::TCF:://o;
    return $class if $class eq 'Die' && !$HANDLE_DIE;
    foreach (@$excs) {
        return $_ if &isBelow($fclass,$_);
    }
    "";
};

my $popFrame = sub {
    ($EXCEPTION,$CATCHING,$THROWING,@ARGS) = @{pop @STACK};
};

my $pushFrame = sub {
    push @STACK,[$EXCEPTION,$CATCHING,$THROWING,@ARGS];
    $CATCHING =  $THROWING = 0;
    undef @ARGS;
    undef $EXCEPTION;
};

package Exception::Class::TCF::Warning;

package Exception::Class::TCF;

sub try (&@) {
    my($block,@catches) = @_;
    my($exc,@args,$res);
    &$pushFrame;
    $HANDLE_WARN &&
      local ( $SIG{'__WARN__'} =  sub { throw Exception::Class::TCF::Warning @_;  } );
    $dTHROWING = 0;
    $res = eval { &$block() };
    $exc = $EXCEPTION;
    @args = @ARGS;
    if ($@) {
          my($action,$type,%excs,@excs,$finalAction);
          while (($type,$action) = splice @catches,0,2) {
              unless (ref $action eq 'CODE') {
                  my($pack,$file,$line) = caller;
                  warn "Handler for exception key $type is not a function ",
                       "reference at $file line $line\n";
                  next;
              }
        
              $type =~ s/^Exception::Class::TCF:://o;
              $type = 'Exception::Class::TCF' if $type eq 'Default';
              if ($type eq 'Finally') {
                  $finalAction = $action if ref $action eq 'CODE';
                  next;
              }
              $excs{$type} = $action;
              push @excs,$type;
          }
          my $catchDie = exists $excs{'Die'};
           # A 'die', not a 'throw'
          unless ($dTHROWING) {
              if ($catchDie || $HANDLE_DIE) {
                  $exc = new Exception::Class::TCF::Die;
                  @args = ($@);
              }
              else {
                  &$popFrame();
                  CORE::die $@; 
              }
          }
          $dTHROWING = 0;
          my $class = ref($exc) ? ref($exc) : $exc;
          my $raisedType = &$findException($class,\@excs); 
          unless (exists $excs{$raisedType}) {
              &$popFrame;
              &$finalAction() if defined $finalAction;
              return $exc->throw(@args);
          }
          $CATCHING = 1;
          $res =  eval { &{$excs{$raisedType}}($exc,@args) };
          $CATCHING = 0;
          $exc = $EXCEPTION;
          @args = @ARGS;
          &$popFrame();
          &$finalAction() if defined $finalAction;
          return $exc->throw(@args) if $dTHROWING;
          CORE::die $@ if $@;
          return $res;
    }
    &$popFrame();
    my(%catches) = @catches;
    &{$catches{'Finally'}}() if ref $catches{'Finally'} eq 'CODE';
    $res;
}

sub catch (@) {
    return @_;
}

sub finally (&) {
    return ('Finally',$_[0]);
}

package Exception::Class::TCF::Die;
use vars '@ISA';
@ISA = qw(Exception::Class::TCF::Error);

package Exception::Class::TCF::Error;
use vars '@ISA';
@ISA = qw(Exception::Class::TCF);

sub die {
    die $_[0]->dieMess;
}

package Exception::Class::TCF::Warning;
use vars '@ISA';
@ISA = qw(Exception::Class::TCF);

sub die {
    warn $_[0]->dieMess;
}

1;

__DATA__

=head1 NAME

Exception::Class::TCF - Java/C++ style exception handling

=head1 SYNOPSIS

try BLOCK [ [catch] NAME FUN_REF ]*

throw [ EXCEPTION LIST ]

  package EnclosureException;
  @ISA = qw(Exception::Class::TCF);
  
  package main;
  
  use Exception::Class::TCF;
  
  try {
      if ($Lost) {
          throw new EnclosureException Message => "Help!";
      }
      else {
          throw Error;
      }
  }
  catch 'EnclosureException' => sub { 
      warn "Message ",$_[0]->message," received.\n" 
  },
  'Default' => sub { 
      warn $_[0]->type, " exception ignored, trace:", $_[0]->trace 
  };

=head1 DESCRIPTION

The C<Exception::Class::TCF> module provides the possibility of
executing a code block and specifying actions when different
exceptions are raised. The C<try> function takes as its argument a
code block followed by a list of pairs of exception package names and
function references, representing the action to take if a subclass of
that package is raised. To increase readability the keyword C<catch>
may be inserted before any name-action pair. The return value of
C<try> is the return value of the block if no exception is thrown and
the return value of the action of the chosen action in case one is
found.

Even though the builtin C<die> is used in the implementation any
explicit use of C<die> within the dynamic scope is ignored by the
exception mechanism and thus works as usual. On the other hand an
C<eval> block will catch a thrown exception if it has not been caught
by a C<try> block. The clean-up routines after such a block may call
C<throw> as in the next section.

=head2 How to create an exception context.

An exception context in which thrown exceptions are handled is created
using C<try> as in

    try { throw 'Error' } 
      catch 'Default' => sub { warn "Wow" };

The first argument is a code block (or a function reference). It will
be referred to as a C<try> block and any code executed inside it
(including psossibly nested calls of functions in it) will be said to
be I<in the dynamic scope of the block>. After the try block follows a
sequence of exception name - handling code pairs. The name will be
referred to as the I<exception key> and the corresponding code the
I<handler> (or I<catch handler>) for that key. An C<exception> is
either the name of a package inheriting from the package
C<Exception::Class::TCF> or an object blessed in such a package. In
both cases the name of the package will be referred to as the I<name>
of the exception. All exception keys has to be names of exceptions
except the special exception key C<Default> which is the name for
exceptions of package C<Exception::Class::TCF>. In order not to
clutter package name space, package names are normally prefixed by the
C<Exception::Class::TCF::> prefix. To increase readability this
prefix may be removed in exception key names and when calling C<throw>
with a package name as first argument.

The exception key may also be the string C<Finally>. This does not
correspond to an exception but instead its handler will be called just
before the C<try> function returns. Its value will be ignored
however.
 
As C<new> is a virtual function it can not be called with these shortened 
package names. For this on can use C<Exception::Class::TCF::make> instead.

=head2 How to raise an exception.

An exception is raised by calling the function C<throw> with the
exception as first argument. C<throw> is a prototyped function (See
L<perlsub/Prototypes>) so that one may dispense with parentheses.

      throw Exception::Class::TCF;

      throw 'MyException', "Serious problems";
        # is the same as
      throw('MyException', "Serious problems");

      throw new Exception::Class::TCF::Error Message => "Hello up there!";
        # is the same as
      throw make 'Error', Message => "Hello up there!";
        # and as
      Exception::Class::TCF::Error->new(Message => "Hello up there!")->throw;

(The last as C<Exception::Class::TCF::Error> inherits from
C<Exception::Class::TCF> which is where C<throw> lives.)

C<throw> without any arguments can also be used to rethrow the
I<active exception>. If no exception is active C<throw> raises a
C<die> with the argument "Rethrow without an active exception at FILE
line LINE\n" where B<FILE> and B<LINE> refer to the place where the
exception was thrown. To test if there is an active exception one may
use C<Exception::Class::TCF::isThrowing>.

The rules for determining the active exception are the
following. 

=over 4

=item *

Before entering a C<try> block the active exception (if there is one)
will be put away and no exception will be active. When the C<try>
block is exited the original active exception is restored or there
will be no active exception if none existed.

=item *

Whenever an exception is thrown it becomes the active exception.

=item *

The active exception may be cleared using
C<Exception::Class::TCF::deactivate> which will clear the active
exception (and do nothing if there is none). This is primarily useful
when an C<eval> block has caught an exception (see next paragraph).

=item *

Thus normally there will only be an active exception in a handler (and
it will be the exception thrown) and then only when one stays at the
same "try level"; if one enters a C<try> block inside a handler the
active exception will be temporarily cleared (not clearing it would
seem to lead to mental confusion as to which collection of handlers
will handle the rethrown exception). There is however one other
situation that may create active exceptions. As C<throw> uses C<die>
internally, any C<eval> block will catch a thrown exception and that
exception will remain active as the enclosing C<try> block has not
been left (if there is no enclosing C<try> block the C<throw> will
already have been turned into an ordinary C<die>). The clean-up
routines for such an C<eval> block can use
C<Exception::Class::TCF::isThrowing> to check if the C<die> was due
to a C<throw> and could then decide to C<throw> the exception or maybe
clear it using C<Exception::Class::TCF::deactivate>.

=back

=head2 How long an exception lives

The throw mechanism keeps a reference to a thrown exception as long as
it can still be rethrown. Hence a C<DESTROY> method for the exception
will not be called until the exception may no longer be thrown (and
possibly even later if there are some references to it outside the
mechanism).

=head2 How a handler is chosen.

The exception that is raised in the dynamic scope of a try block is
supposed to be a reference blessed in a package inheriting from the
package C<Exception::Class::TCF> or the name of such a package. When
raised, by calling C<throw> on it, each exception key is considered
and it is checked whether or not the thrown exception inherits from
the package corresponding to the exception key. The first such
exception key is then picked out and its catch handler is called. If
none is found the exception is rethrown to be caught by another
C<try> block enclosing the given. (This description is not quite true
for the exception name C<Die>. See L<"PREDEFINED EXCEPTIONS">.)

If no enclosing block exists, the virtual function C<die> is called on
the exception. The default behaviour of C<die> is to call the builtin
C<die> with string argument the string obtained by calling C<sprintf>
with the I<name of the exception> (i.e. either its own name if it is a
package name or the name of its package) as second argument. The first
argument is the default string "Exception of type %s thrown but not
caught" unless the exception is an object and its C<DyingMessage> has
been set in which case the value of that field is used.

Thus the following code

     try { throw 'Error' };

will result in C<die> being called with the argument "Exception of
type Error thrown but not caught". (Actually when the string does not
end with a newline a string of the type "at FILE line LINE\n" is added
where B<FILE> and B<LINE> refers to where C<throw> was called. The
following will have the same effect:

    throw 'Error';

=head2 How a handler is called.

A chosen action will be called with the same argument list as the
C<throw>. Thus the exception will be the first argument. For example

     try {
        throw 'Error', "basement";
     } catch 'Default' =>  sub { warn "Mouse found in $_[1]\n" };

will print 

   Mouse found in basement

on C<STDERR>.

=head1 CLASS INTERFACE

=head2 Exported functions

The package C<Exception::Class::TCF> exports the following functions 

=over 4

=item try BLOCK [ [catch] EXCEPTION_NAME => FUN_REF ]*C<>

sets up an environment where a thrown exception in the dynamic scope
of BLOCK (and not caught by some inner C<try> block) is matched
against the EXCEPTION_NAME's and if matched the corresponding FUN_REF
is called. If no matching is found the exception is rethrown.

=item catch EXCEPTION_NAME => FUN_REF, LIST

gives syntactic sugar for the handler part of a C<try>. That means
that the following three expressions are equivalent.

     try {} 'Default' => sub {}, 
                  NewException => sub { die };

     try {} catch 'Default' => sub {}, 
                  NewException => sub { die };

     try {} catch 'Default' => sub {}, 
            catch 'NewException' => sub { die };

=item finally FUN_REF

is just syntactic sugar for C<Finally => FUN_REF> and hence can be
used as follows

     try {} 'Default' => sub {}, finally {...};

or alone

     try {} finally {...};

=item throw EXCEPTION, ARGS

throws EXCEPTION - the ARGS are passed to the action that catches the
exception.

If used without arguments it can be used to rethrow an exception in
either of the following situations:

=over 4

=item *

Throw an exception out of a handler which is handling it.

=item * 

Throw an exception in the same C<try> block that it was originally
thrown. This is possible if it was originally caught by an C<eval>
block. An example may look like this.

  try {
     eval {
         &mayDie if $daring; # may exit by a die
         throw 'Exception::Class::TCF' if $exit;
     }
     throw if &Exception::Class::TCF::isThrowing;
     warn "Died on me!\n" if $@;
  } catch 'Default' => 
           sub { warn "Something exited\n" };

=back

=back

=head2 Public functions

Apart from these the following functions may also be imported from
C<Exception::Class::TCF> (using the C<import> or C<use> mechanism).

=over 4

=item make EXCEPTION_NAME, LIST

an interface to C<new> which allows EXCEPTION_NAME to be without the
prefix C<Exception::Class::TCF::>. C<make> checks to see if EXCEPTION_NAME is the
name of an exception type, if not it checks if
Exception::Class::TCF::EXCEPTION_NAME is such a name and if it is B<Exception::Class::TCF::>
is prepended to EXCEPTION_NAME. If it in this way finds an exception
type it calls

   new EXCEPTION_NAME LIST

if not it returns C<undef>.

=item deactivate

Clears the active exception if there is one and does nothing if not.

=item isThrowing

Returns a true value exactly if one is still inside a dynamic C<try>
block in which the latest exception was thrown or a handler for that
block. This means that one is allowed to call C<throw> without
arguments to rethrow the exception.

=item handleDie FLAG

If FLAG is true subsequent invocations of C<die> in a C<try> block
will throw an exception of name C<Die> (See L<"PREDEFINED EXCEPTIONS">) 
with the string that C<die> constructs as first
argument. If FLAG is turned off this behaviour will be turned off. The
default behaviour is that an exception key named 'Die' will catch a
C<die> but no searching for exception keys above C<Die> in the
inheritance will be made.

=item handleWarn FLAG

If FLAG is true, at a subsequent entry to a C<try> block a signal
handler for C<__WARN__> (See L<perlvar/SIG>) will be installed.  When
C<warn> is called it will throw an exception of type C<Warning> (See
L<"PREDEFINED EXCEPTIONS">) unless C<handleWarn> has been called with
a false argument in the mean time, in which case it will call the usual
warn. When leaving a C<try> block (or one of its handlers) this signal
handler will be deinstalled and any old value restored. If FLAG is false
this feature will be turned off.

As this requires fiddling with the C<__WARN__> handler it could be
somewhat dangerous and lead to unexpected results. Thus C<handleWarn>
may be removed in future versions if disadvantages will turn out to
outweigh advantages.

=back

=head2 Public virtual functions

The following are the public virtual functions of C<Exception::Class::TCF>.

=over 4

=item new EXCEPTION_NAME [ VALUE ] [KEY => VALUE]*C<>

creates an exception in the package EXCEPTION_NAME and for each
KEY-VALUE PAIR the VALUE is stored in a field of name KEY. The fields
may also be set using C<setFields> so that 

      $exc = new Exception::Class::TCF::Error 'Timeout' => 5;

is equivalent to

      $exc = new Exception::Class::TCF::Error; 
      setFields $exc 'Timeout' => 5;

(Unless C<Timeout> should happen to be a protected field in which case
the second version will not set any fields.)

In the case of the field named C<Message> the key may be dispensed
with provided that it comes first (in other words if the list of
arguments - minus the exception name - has odd order, C<Finally> is
prepended to it).

=item die EXCEPTION ARGS

called when EXCEPTION is thrown outside of a C<try> block. This
includes when it is thrown in a handler of a C<try> block not contained
in another block.

=item type EXCEPTION

returns the type of the exception, which is the exception itself if it
is a package name and the name of its package if it is not. If the
package name is prefixed with C<Exception::Class::TCF::> that prefix is removed.

=item setFields EXCEPTION [KEY => VALUE]*C<>

for each KEY-VALUE PAIR the VALUE is stored in a field of name KEY. If
EXCEPTION is a name nothing is done.

=item getField EXCEPTION KEY

returns the value of the field KEY if the field is set and C<undef> if
it isn't.

=item removeFields EXCEPTION KEYS

removes the fields with names in KEYS from the exception.

=item hasField EXCEPTION KEY

return a true value exactly when EXCEPTION has a field named KEY.

=item protectedFields EXCEPTION

some fields may be protected which means that they can not be
modified. C<protectedFields> returns a list of the names of the fields
that can not be modified using C<removeFields> or C<setFields>.

=item setMessage EXCEPTION VALUE

sets the message field of EXCEPTION to VALUE.

=item C<message> EXCEPTION

is equivalent to 

    getField EXCEPTION Message.


=back

All these virtual functions except C<new> accepts either the name of a
package inheriting from C<Exception::Class::TCF> or a reference blessed in such a
package (C<new> only accepts a package name). The former case should
be kept in mind when overriding any of these functions in a
subclass. In the latter case the reference is assumed to have been
created with C<new>.

=head2 Implementation details.

These details are not likely to change but should not be considered
part of the public interface.

The exception objects are implemented as references to hashes. The
field I<Message> is reserved for internal use by C<message> and
C<setMessage>. The field I<DyingMessage> is used for the message given
when the exception is thrown outside a C<try> block. Arguments to
C<new> are stored in the hash.

=head1 PREDEFINED EXCEPTIONS

While any number of exception types may be created by making classes
inheriting from C<Exception::Class::TCF> some are predefined to give
standard names to standard exceptions. All of these packages are in
the package C<Exception::Class::TCF> and their names all start with C<Exception::Class::TCF::>.

=over 4

=item Exception::Class::TCF

is the root class of all exceptions. Throwing exceptions of this type
is not encouraged, use exceptions at the next level.

=item Exception::Class::TCF::Error

is the class of errors. Its only special feature is that when thrown
outside of a C<try> block C<die> is called.

=item Exception::Class::TCF::Warning

is the class of less serious errors. Its only special feature is that 
when thrown outside of a C<try> block C<warn> rather than C<die> is
called. It is also the exception type which is thrown by C<warn> when
the interpretation of calls by C<warn> as throwing an exception has
been enabled (See L</handleWarn>). 

=item Exception::Class::TCF::Die

is the exception that conceptually is raised when C<die> is called
inside a C<try> block or catch handler. It has the special feature
that normally a C<Die> exception is not caught by exception keys
higher up in hierarchy. This behaviour can be changed (See L</handleDie>).

=item Exception::Class::TCF::AssertFailure

is the exception thrown when an assertion has failed. Its package
contains the function C<assert> (which may be imported by other packages).

=item assert BLOCK LIST

BLOCK is evaluated and if it returns a false value, an exception of
type C<AssertFailure> is created using C<new> with LIST as argument
and then thrown. For instance

   use Exception::Class::TCF;
   use Exception::Class::TCF::AssertFailure qw(&assert);

   sub fac {
     my($n) = shift;
     assert { $n >= 0 && int($n) == $n }
          'Message' => "$n is not a positive integer.\n";
     $n == 0 ? 1 : &fac($n -1)*$n;
     }

   try { fac(-3) } 
     catch 'AssertFailure' => 
         sub { warn $_[0]->message };

=back

=head1 EXAMPLES

Examples of tricky uses of C<try> may be found in B<t/Exception.t> in
the distribution.

=head1 FEATURES RISKING EXTINCTION

The use of L</handleWarn> risks messing up C<__WARN__> signals and may
therefore be removed, it depends on how much trouble it causes vs. how
useful it turns out to be.

=head1 BUGS

None in the library (that I am aware of). 

=head1 AUTHOR

This module has been written by Torsten Ekedahl (B<teke@matematik.su.se>),
and subsequently modified to subclass L<Exception::Class> and rechristened
by Rutger Vos (B<rvosa@sfu.ca>).

=cut
#'
