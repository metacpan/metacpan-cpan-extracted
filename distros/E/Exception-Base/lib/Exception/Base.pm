#!/usr/bin/perl -c

package Exception::Base;

=head1 NAME

Exception::Base - Lightweight exceptions

=head1 SYNOPSIS

  # Use module and create needed exceptions
  use Exception::Base
     'Exception::Runtime',              # create new module
     'Exception::System',               # load existing module
     'Exception::IO',          => {
         isa => 'Exception::System' },  # create new based on existing
     'Exception::FileNotFound' => {
         isa => 'Exception::IO',        # create new based on previous
         message => 'File not found',   # override default message
         has => [ 'filename' ],         # define new rw attribute
         string_attributes => [ 'message', 'filename' ],
     };                                 # output message and filename

  # eval is used as "try" block
  eval {
    open my $file, '/etc/passwd'
      or Exception::FileNotFound->throw(
            message=>'Something wrong',
            filename=>'/etc/passwd');
  };
  # syntax for Perl >= 5.10
  use feature 'switch';
  if ($@) {
    given (my $e = Exception::Base->catch) {
      when ($e->isa('Exception::IO')) { warn "IO problem"; }
      when ($e->isa('Exception::Eval')) { warn "eval died"; }
      when ($e->isa('Exception::Runtime')) { warn "some runtime was caught"; }
      when ($e->matches({value=>9})) { warn "something happened"; }
      when ($e->matches(qr/^Error/)) { warn "some error based on regex"; }
      default { $e->throw; } # rethrow the exception
    }
  }
  # standard syntax for older Perl
  if ($@) {
    my $e = Exception::Base->catch;   # convert $@ into exception
    if ($e->isa('Exception::IO')) { warn "IO problem"; }
    elsif ($e->isa('Exception::Eval')) { warn "eval died"; }
    elsif ($e->isa('Exception::Runtime')) { warn "some runtime was caught"; }
    elsif ($e->matches({value=>9})) { warn "something happened"; }
    elsif ($e->matches(qr/^Error/)) { warn "some error based on regex"; }
    else { $e->throw; } # rethrow the exception
  }

  # $@ has to be recovered ASAP!
  eval { die "this die will be caught" };
  my $e = Exception::Base->catch;
  eval { die "this die will be ignored" };
  if ($e) {
     (...)
  }

  # the exception can be thrown later
  my $e = Exception::Base->new;
  # (...)
  $e->throw;

  # ignore our package in stack trace
  package My::Package;
  use Exception::Base '+ignore_package' => __PACKAGE__;

  # define new exception in separate module
  package Exception::My;
  use Exception::Base (__PACKAGE__) => {
      has => ['myattr'],
  };

  # run Perl with changed verbosity for debugging purposes
  $ perl -MException::Base=verbosity,4 script.pl

=head1 DESCRIPTION

This class implements a fully OO exception mechanism similar to
L<Exception::Class> or L<Class::Throwable>.  It provides a simple interface
allowing programmers to declare exception classes.  These classes can be
thrown and caught.  Each uncaught exception prints full stack trace if the
default verbosity is increased for debugging purposes.

The features of C<Exception::Base>:

=over 2

=item *

fast implementation of the exception class

=item *

fully OO without closures and source code filtering

=item *

does not mess with C<$SIG{__DIE__}> and C<$SIG{__WARN__}>

=item *

no external run-time modules dependencies, requires core Perl modules only

=item *

the default behavior of exception class can be changed globally or just for
the thrown exception

=item *

matching the exception by class, message or other attributes

=item *

matching with string, regex or closure function

=item *

creating automatically the derived exception classes (L<perlfunc/use>
interface)

=item *

easily expendable, see L<Exception::System> class for example

=item *

prints just an error message or dumps full stack trace

=item *

can propagate (rethrow) an exception

=item *

can ignore some packages for stack trace output

=item *

some defaults (i.e. verbosity) can be different for different exceptions

=back

=for readme stop

=cut

use 5.006;

use strict;
use warnings;

our $VERSION = '0.2501';


# Safe operations on symbol stash
BEGIN {
    eval {
        require Symbol;
        Symbol::qualify_to_ref('Symbol::qualify_to_ref');
    };
    if (not $@) {
        *_qualify_to_ref = \*Symbol::qualify_to_ref;
    }
    else {
        *_qualify_to_ref = sub ($;) { no strict 'refs'; \*{ $_[0] } };
    };
};


# Use weaken ref on stack if available
BEGIN {
    eval {
        require Scalar::Util;
        my $ref = \1;
        Scalar::Util::weaken($ref);
    };
    if (not $@) {
        *_HAVE_SCALAR_UTIL_WEAKEN = sub () { !! 1 };
    }
    else {
        *_HAVE_SCALAR_UTIL_WEAKEN = sub () { !! 0 };
    };
};


BEGIN {
    my %OVERLOADS = (fallback => 1);

=head1 OVERLOADS

=over

=item Boolean context

True value.  See C<to_bool> method.

  eval { Exception::Base->throw( message=>"Message", value=>123 ) };
  if ($@) {
     # the exception object is always true
  }

=cut

    $OVERLOADS{'bool'} = 'to_bool';

=item Numeric context

Content of attribute pointed by C<numeric_attribute> attribute.  See
C<to_number> method.

  eval { Exception::Base->throw( message=>"Message", value=>123 ) };
  print 0+$@;           # 123

=cut

    $OVERLOADS{'0+'}   = 'to_number';

=item String context

Content of attribute which is combined from C<string_attributes> attributes
with additional information, depended on C<verbosity> setting.  See
C<to_string> method.

  eval { Exception::Base->throw( message=>"Message", value=>123 ) };
  print "$@";           # "Message at -e line 1.\n"

=cut

    $OVERLOADS{'""'}   = 'to_string';

=item "~~"

Smart matching operator.  See C<matches> method.

  eval { Exception::Base->throw( message=>"Message", value=>123 ) };
  print "Message" ~~ $@;                          # 1
  print qr/message/i ~~ $@;                       # 1
  print ['Exception::Base'] ~~ $@;                # 1
  print 123 ~~ $@;                                # 1
  print {message=>"Message", value=>123} ~~ $@;   # 1

Warning: The smart operator requires that the exception object is a second
argument.

=back

=cut

    $OVERLOADS{'~~'}   = 'matches' if ($] >= 5.010);

    use overload;
    overload->import(%OVERLOADS);
};


# Constant regexp for numerify value check
use constant _RE_NUM_INT  => qr/^[+-]?\d+$/;


=head1 CONSTANTS

=over

=item ATTRS

Declaration of class attributes as reference to hash.

The attributes are listed as I<name> => {I<properties>}, where I<properties> is a
list of attribute properties:

=over

=item is

Can be 'rw' for read-write attributes or 'ro' for read-only attributes.  The
attribute is read-only and does not have an accessor created if 'is' property
is missed.

=item default

Optional property with the default value if the attribute value is not
defined.

=back

The read-write attributes can be set with C<new> constructor.  Read-only
attributes and unknown attributes are ignored.

The constant have to be defined in derived class if it brings additional
attributes.

  package Exception::My;
  use base 'Exception::Base';

  # Define new class attributes
  use constant ATTRS => {
    %{Exception::Base->ATTRS},       # base's attributes have to be first
    readonly  => { is=>'ro' },                   # new ro attribute
    readwrite => { is=>'rw', default=>'blah' },  # new rw attribute
  };

  package main;
  use Exception::Base ':all';
  eval {
    Exception::My->throw( readwrite => 2 );
  };
  if ($@) {
    my $e = Exception::Base->catch;
    print $e->readwrite;                # = 2
    print $e->defaults->{readwrite};    # = "blah"
  }

=back

=cut

BEGIN {
    my %ATTRS                    = ();

=head1 ATTRIBUTES

Class attributes are implemented as values of blessed hash.  The attributes
are also available as accessors methods.

=over

=cut

=item message (rw, default: 'Unknown exception')

Contains the message of the exception.  It is the part of the string
representing the exception object.

  eval { Exception::Base->throw( message=>"Message" ); };
  print $@->message if $@;

It can also be an array reference of strings and then the L<sprintf/perlfunc>
is used to get a message.

  Exception::Base->throw( message => ["%s failed", __PACKAGE__] );

=cut

    $ATTRS{message}              = { is => 'rw', default => 'Unknown exception' };

=item value (rw, default: 0)

Contains the value which represents numeric value of the exception object in
numeric context.

  eval { Exception::Base->throw( value=>2 ); };
  print "Error 2" if $@ == 2;

=cut

    $ATTRS{value}                = { is => 'rw', default => 0 };

=item verbosity (rw, default: 2)

Contains the verbosity level of the exception object.  It allows to change the
string representing the exception object.  There are following levels of
verbosity:

=over 2

=item C<0>

Empty string

=item C<1>

 Message

=item C<2>

 Message at %s line %d.

The same as the standard output of die() function.  It doesn't include
"at %s line %d." string if message ends with C<"\n"> character.  This is
the default option.

=item C<3>

 Class: Message at %s line %d
         %c_ = %s::%s() called in package %s at %s line %d
         ...propagated in package %s at %s line %d.
 ...

The output contains full trace of error stack without first C<ignore_level>
lines and those packages which are listed in C<ignore_package> and
C<ignore_class> settings.

=item S<4>

The output contains full trace of error stack.  In this case the
C<ignore_level>, C<ignore_package> and C<ignore_class> settings are meaning
only for first line of exception's message.

=back

If the verbosity is undef, then the default verbosity for exception objects is
used.

If the verbosity set with constructor (C<new> or C<throw>) is lower than 3,
the full stack trace won't be collected.

If the verbosity is lower than 2, the full system data (time, pid, tid, uid,
euid, gid, egid) won't be collected.

This setting can be changed with import interface.

  use Exception::Base verbosity => 4;

It can be also changed for Perl interpreter instance, i.e. for debugging
purposes.

  sh$ perl -MException::Base=verbosity,4 script.pl

=cut

    $ATTRS{verbosity}            = { is => 'rw', default => 2 };

=item ignore_package (rw)

Contains the name (scalar or regexp) or names (as references array) of
packages which are ignored in error stack trace.  It is useful if some package
throws an exception but this module shouldn't be listed in stack trace.

  package My::Package;
  use Exception::Base;
  sub my_function {
    do_something() or throw Exception::Base ignore_package=>__PACKAGE__;
    throw Exception::Base ignore_package => [ "My", qr/^My::Modules::/ ];
  }

This setting can be changed with import interface.

  use Exception::Base ignore_package => __PACKAGE__;

=cut

    $ATTRS{ignore_package}       = { is => 'rw', default => [ ] };

=item ignore_class (rw)

Contains the name (scalar) or names (as references array) of packages which
are base classes for ignored packages in error stack trace.  It means that
some packages will be ignored even the derived class was called.

  package My::Package;
  use Exception::Base;
  Exception::Base->throw( ignore_class => "My::Base" );

This setting can be changed with import interface.

  use Exception::Base ignore_class => "My::Base";

=cut

    $ATTRS{ignore_class}         = { is => 'rw', default => [ ] };

=item ignore_level (rw)

Contains the number of level on stack trace to ignore.  It is useful if some
package throws an exception but this module shouldn't be listed in stack
trace.  It can be used with or without I<ignore_package> attribute.

  # Convert warning into exception. The signal handler ignores itself.
  use Exception::Base 'Exception::My::Warning';
  $SIG{__WARN__} = sub {
    Exception::My::Warning->throw( message => $_[0], ignore_level => 1 );
  };

=cut

    $ATTRS{ignore_level}         = { is => 'rw', default => 0 };

=item time (ro)

Contains the timestamp of the thrown exception.  Collected if the verbosity on
throwing exception was greater than 1.

  eval { Exception::Base->throw( message=>"Message" ); };
  print scalar localtime $@->time;

=cut

    $ATTRS{time}                 = { is => 'ro' };

=item pid (ro)

Contains the PID of the Perl process at time of thrown exception.  Collected
if the verbosity on throwing exception was greater than 1.

  eval { Exception::Base->throw( message=>"Message" ); };
  kill 10, $@->pid;

=cut

    $ATTRS{pid}                  = { is => 'ro' };

=item tid (ro)

Contains the tid of the thread or undef if threads are not used.  Collected
if the verbosity on throwing exception was greater than 1.

=cut

    $ATTRS{tid}                  = { is => 'ro' };

=item uid (ro)

=cut

    $ATTRS{uid}                  = { is => 'ro' };

=item euid (ro)

=cut

    $ATTRS{euid}                 = { is => 'ro' };


=item gid (ro)

=cut

    $ATTRS{gid}                  = { is => 'ro' };

=item egid (ro)

Contains the real and effective uid and gid of the Perl process at time of
thrown exception.  Collected if the verbosity on throwing exception was
greater than 1.

=cut

    $ATTRS{egid}                 = { is => 'ro' };

=item caller_stack (ro)

Contains the error stack as array of array with information about caller
functions.  The first 8 elements of the array's row are the same as first 8
elements of the output of C<caller> function.  Further elements are optional
and are the arguments of called function.  Collected if the verbosity on
throwing exception was greater than 1.  Contains only the first element of
caller stack if the verbosity was lower than 3.

If the arguments of called function are references and
C<L<Scalar::Util>::weaken> function is available then reference is weakened.

  eval { Exception::Base->throw( message=>"Message" ); };
  ($package, $filename, $line, $subroutine, $hasargs, $wantarray,
  $evaltext, $is_require, @args) = $@->caller_stack->[0];

=cut

    $ATTRS{caller_stack}         = { is => 'ro' };

=item propagated_stack (ro)

Contains the array of array which is used for generating "...propagated at"
message.  The elements of the array's row are the same as first 3 elements of
the output of C<caller> function.

=cut

    $ATTRS{propagated_stack}     = { is => 'ro' };

=item max_arg_len (rw, default: 64)

Contains the maximal length of argument for functions in backtrace output.
Zero means no limit for length.

  sub a { Exception::Base->throw( max_arg_len=>5 ) }
  a("123456789");

=cut

    $ATTRS{max_arg_len}          = { is => 'rw', default => 64 };

=item max_arg_nums (rw, default: 8)

Contains the maximal number of arguments for functions in backtrace output.
Zero means no limit for arguments.

  sub a { Exception::Base->throw( max_arg_nums=>1 ) }
  a(1,2,3);

=cut

    $ATTRS{max_arg_nums}         = { is => 'rw', default => 8 };

=item max_eval_len (rw, default: 0)

Contains the maximal length of eval strings in backtrace output.  Zero means
no limit for length.

  eval "Exception->throw( max_eval_len=>10 )";
  print "$@";

=cut

    $ATTRS{max_eval_len}         = { is => 'rw', default => 0 };

=item defaults

Meta-attribute contains the list of default values.

  my $e = Exception::Base->new;
  print defined $e->{verbosity}
    ? $e->{verbosity}
    : $e->{defaults}->{verbosity};

=cut

    $ATTRS{defaults}             = { };

=item default_attribute (default: 'message')

Meta-attribute contains the name of the default attribute.  This attribute
will be set for one argument throw method.  This attribute has meaning for
derived classes.

  use Exception::Base 'Exception::My' => {
      has => 'myattr',
      default_attribute => 'myattr',
  };

  eval { Exception::My->throw("string") };
  print $@->myattr;    # "string"

=cut

    $ATTRS{default_attribute}    = { default => 'message' };

=item numeric_attribute (default: 'value')

Meta-attribute contains the name of the attribute which contains numeric value
of exception object.  This attribute will be used for representing exception
in numeric context.

  use Exception::Base 'Exception::My' => {
      has => 'myattr',
      numeric_attribute => 'myattr',
  };

  eval { Exception::My->throw(myattr=>123) };
  print 0 + $@;    # 123

=cut

    $ATTRS{numeric_attribute}    = { default => 'value' };

=item eval_attribute (default: 'message')

Meta-attribute contains the name of the attribute which is filled if error
stack is empty.  This attribute will contain value of C<$@> variable.  This
attribute has meaning for derived classes.

  use Exception::Base 'Exception::My' => {
      has => 'myattr',
      eval_attribute => 'myattr'
  };

  eval { die "string" };
  print $@->myattr;    # "string"

=cut

    $ATTRS{eval_attribute}       = { default => 'message' };

=item string_attributes (default: ['message'])

Meta-attribute contains the array of names of attributes with defined value
which are joined to the string returned by C<to_string> method.  If none of
attributes are defined, the string is created from the first default value of
attributes listed in the opposite order.

  use Exception::Base 'Exception::My' => {
      has => 'myattr',
      myattr => 'default',
      string_attributes => ['message', 'myattr'],
  };

  eval { Exception::My->throw( message=>"string", myattr=>"foo" ) };
  print $@->myattr;    # "string: foo"

  eval { Exception::My->throw() };
  print $@->myattr;    # "default"

=back

=cut

    $ATTRS{string_attributes}    = { default => [ 'message' ] };

    *ATTRS = sub () { \%ATTRS };
};


# Cache for class' ATTRS
my %Class_Attributes;


# Cache for class' defaults
my %Class_Defaults;


# Cache for $obj->isa(__PACKAGE__)
my %Isa_Package;


=head1 IMPORTS

=over

=item C<use Exception::Base 'I<attribute>' => I<value>;>

Changes the default value for I<attribute>.  If the I<attribute> name has no
special prefix, its default value is replaced with a new I<value>.

  use Exception::Base verbosity => 4;

If the I<attribute> name starts with "C<+>" or "C<->" then the new I<value>
is based on previous value:

=over

=item *

If the original I<value> was a reference to array, the new I<value> can
be included or removed from original array.  Use array reference if you
need to add or remove more than one element.

  use Exception::Base
      "+ignore_packages" => [ __PACKAGE__, qr/^Moose::/ ],
      "-ignore_class" => "My::Good::Class";

=item *

If the original I<value> was a number, it will be incremented or
decremented by the new I<value>.

  use Exception::Base "+ignore_level" => 1;

=item *

If the original I<value> was a string, the new I<value> will be
included.

  use Exception::Base "+message" => ": The incuded message";

=back

=item C<use Exception::Base 'I<Exception>', ...;>

Loads additional exception class module.  If the module is not available,
creates the exception class automatically at compile time.  The newly created
class will be based on C<Exception::Base> class.

  use Exception::Base qw{ Exception::Custom Exception::SomethingWrong };
  Exception::Custom->throw;

=item C<use Exception::Base 'I<Exception>' => { isa => I<BaseException>, version => I<version>, ... };>

Loads additional exception class module.  If the module's version is lower
than given parameter or the module can't be loaded, creates the exception
class automatically at compile time.  The newly created class will be based on
given class and has the given $VERSION variable.

=over

=item isa

The newly created class will be based on given class.

  use Exception::Base
    'Exception::My',
    'Exception::Nested' => { isa => 'Exception::My };

=item version

The class will be created only if the module's version is lower than given
parameter and will have the version given in the argument.

  use Exception::Base
    'Exception::My' => { version => 1.23 };

=item has

The class will contain new rw attribute (if parameter is a string) or new rw
attributes (if parameter is a reference to array of strings) or new rw or ro
attributes (if parameter is a reference to hash of array of strings with rw
and ro as hash key).

  use Exception::Base
    'Exception::Simple' => { has => 'field' },
    'Exception::More' => { has => [ 'field1', 'field2' ] },
    'Exception::Advanced' => { has => {
        ro => [ 'field1', 'field2' ],
        rw => [ 'field3' ]
    } };

=item message

=item verbosity

=item max_arg_len

=item max_arg_nums

=item max_eval_len

=item I<other attribute having default property>

The class will have the default property for the given attribute.

=back

  use Exception::Base
    'Exception::WithDefault' => { message => 'Default message' },
    'Exception::Reason' => {
        has => [ 'reason' ],
        string_attributes => [ 'message', 'reason' ] };

=back

=cut

# Create additional exception packages
sub import {
    my $class = shift;

    while (defined $_[0]) {
        my $name = shift @_;
        if ($name eq ':all') {
            # do nothing for backward compatibility
        }
        elsif ($name =~ /^([+-]?)([a-z0-9_]+)$/) {
            # Lower case: change default
            my ($modifier, $key) = ($1, $2);
            my $value = shift;
            $class->_modify_default($key, $value, $modifier);
        }
        else {
            # Try to use external module
            my $param = {};
            $param = shift @_ if defined $_[0] and ref $_[0] eq 'HASH';

            my $version = defined $param->{version} ? $param->{version} : 0;

            if (caller ne $name) {
                next if eval { $name->VERSION($version) };

                # Package is needed
                {
                    local $SIG{__DIE__};
                    eval {
                        $class->_load_package($name, $version);
                    };
                };
                if ($@) {
                    # Die unless can't load module
                    if ($@ !~ /Can\'t locate/) {
                        Exception::Base->throw(
                            message => ["Can not load available %s class: %s", $name, $@],
                            verbosity => 1
                        );
                    };
                }
                else {
                    # Module is loaded: go to next
                    next;
                };
            };

            next if $name eq __PACKAGE__;

            # Package not found so it have to be created
            if ($class ne __PACKAGE__) {
                Exception::Base->throw(
                    message => ["Exceptions can only be created with %s class", __PACKAGE__],
                    verbosity => 1
                );
            };
            $class->_make_exception($name, $version, $param);
        }
    }

    return $class;
};


=head1 CONSTRUCTORS

=over

=item new([%I<args>])

Creates the exception object, which can be thrown later.  The system data
attributes like C<time>, C<pid>, C<uid>, C<gid>, C<euid>, C<egid> are not
filled.

If the key of the argument is read-write attribute, this attribute will be
filled. Otherwise, the argument will be ignored.

  $e = Exception::Base->new(
           message=>"Houston, we have a problem",
           unknown_attr => "BIG"
       );
  print $e->{message};

The constructor reads the list of class attributes from ATTRS constant
function and stores it in the internal cache for performance reason.  The
defaults values for the class are also stored in internal cache.

=item C<CLASS>-E<gt>throw([%I<args>]])

Creates the exception object and immediately throws it with C<die> system
function.

  open my $fh, $file
    or Exception::Base->throw( message=>"Can not open file: $file" );

The C<throw> is also exported as a function.

  open my $fh, $file
    or throw 'Exception::Base' => message=>"Can not open file: $file";

=back

The C<throw> can be also used as a method.

=cut

# Constructor
sub new {
    my ($self, %args) = @_;

    my $class = ref $self || $self;

    my $attributes;
    my $defaults;

    # Use cached value if available
    if (not defined $Class_Attributes{$class}) {
        $attributes = $Class_Attributes{$class} = $class->ATTRS;
        $defaults = $Class_Defaults{$class} = {
            map { $_ => $attributes->{$_}->{default} }
                grep { defined $attributes->{$_}->{default} }
                    (keys %$attributes)
        };
    }
    else {
        $attributes = $Class_Attributes{$class};
        $defaults = $Class_Defaults{$class};
    };

    my $e = {};

    # If the attribute is rw, initialize its value. Otherwise: ignore.
    no warnings 'uninitialized';
    foreach my $key (keys %args) {
        if ($attributes->{$key}->{is} eq 'rw') {
            $e->{$key} = $args{$key};
        };
    };

    # Defaults for this object
    $e->{defaults} = { %$defaults };

    bless $e => $class;

    # Collect system data and eval error
    $e->_collect_system_data;

    return $e;
};


=head1 METHODS

=over

=item C<$obj>-E<gt>throw([%I<args>])

Immediately throws exception object.  It can be used for rethrowing existing
exception object.  Additional arguments will override the attributes in
existing exception object.

  $e = Exception::Base->new;
  # (...)
  $e->throw( message=>"thrown exception with overridden message" );

  eval { Exception::Base->throw( message=>"Problem", value=>1 ) };
  $@->throw if $@->value;

=item C<$obj>-E<gt>throw(I<message>, [%I<args>])

If the number of I<args> list for arguments is odd, the first argument is a
message.  This message can be overridden by message from I<args> list.

  Exception::Base->throw( "Problem", message=>"More important" );
  eval { die "Bum!" };
  Exception::Base->throw( $@, message=>"New message" );

=item I<CLASS>-E<gt>throw($I<exception>, [%I<args>])

Immediately rethrows an existing exception object as an other exception class.

  eval { open $f, "w", "/etc/passwd" or Exception::System->throw };
  # convert Exception::System into Exception::Base
  Exception::Base->throw($@);

=cut

# Create the exception and throw it or rethrow existing
sub throw {
    my $self = shift;

    my $class = ref $self || $self;

    my $old_e;

    if (not ref $self) {
        # CLASS->throw
        if (not ref $_[0]) {
            # Throw new exception
            if (scalar @_ % 2 == 0) {
                # Throw normal error
                die $self->new(@_);
            }
            else {
                # First argument is a default attribute; it can be overridden with normal args
                my $argument = shift;
                my $e = $self->new(@_);
                my $default_attribute = $e->{defaults}->{default_attribute};
                $e->{$default_attribute} = $argument if not defined $e->{$default_attribute};
                die $e;
            };
        }
        else {
            # First argument is an old exception
            $old_e = shift;
        };
    }
    else {
        # $e->throw
        $old_e = $self;
    };

    # Rethrow old exception with replaced attributes
    no warnings 'uninitialized';
    my %args = @_;
    my $attrs = $old_e->ATTRS;
    foreach my $key (keys %args) {
        if ($attrs->{$key}->{is} eq 'rw') {
            $old_e->{$key} = $args{$key};
        };
    };
    $old_e->PROPAGATE;
    if (ref $old_e ne $class) {
        # Rebless old object for new class
        bless $old_e => $class;
    };

    die $old_e;
};


=item I<CLASS>-E<gt>catch([$I<variable>])

The exception is recovered from I<variable> argument or C<$@> variable if
I<variable> argument was empty.  Then also C<$@> is replaced with empty string
to avoid an endless loop.

The method returns an exception object if exception is caught or undefined
value otherwise.

  eval { Exception::Base->throw; };
  if ($@) {
      my $e = Exception::Base->catch;
      print $e->to_string;
  }

If the value is not empty and does not contain the C<Exception::Base> object,
new exception object is created with class I<CLASS> and its message is based
on previous value with removed C<" at file line 123."> string and the last end
of line (LF).

  eval { die "Died\n"; };
  my $e = Exception::Base->catch;
  print ref $e;   # "Exception::Base"

=cut

# Recover $@ variable and return exception object
sub catch {
    my ($self) = @_;

    my $class = ref $self || $self;

    my $e;
    my $new_e;


    if (@_ > 1) {
        # Recover exception from argument
        $e = $_[1];
    }
    else {
        # Recover exception from $@ and clear it
        $e = $@;
        $@ = '';
    };

    if (ref $e and do { local $@; local $SIG{__DIE__}; eval { $e->isa(__PACKAGE__) } }) {
        # Caught exception
        $new_e = $e;
    }
    elsif ($e eq '') {
        # No error in $@
        $new_e = undef;
    }
    else {
        # New exception based on error from $@. Clean up the message.
        while ($e =~ s/\t\.\.\.propagated at (?!.*\bat\b.*).* line \d+( thread \d+)?\.\n$//s) { };
        $e =~ s/( at (?!.*\bat\b.*).* line \d+( thread \d+)?\.)?\n$//s;
        $new_e = $class->new;
        my $eval_attribute = $new_e->{defaults}->{eval_attribute};
        $new_e->{$eval_attribute} = $e;
    };

    return $new_e;
};


=item matches(I<that>)

Checks if the exception object matches the given argument.

The C<matches> method overloads C<~~> smart matching operator.  Warning: The
second argument for smart matching operator needs to be scalar.

If the argument is a reference to array, it is checked if the object is a
given class.

  use Exception::Base
    'Exception::Simple',
    'Exception::Complex' => { isa => 'Exception::Simple };
  eval { Exception::Complex->throw() };
  print $@->matches( ['Exception::Base'] );                    # matches
  print $@->matches( ['Exception::Simple', 'Exception::X'] );  # matches
  print $@->matches( ['NullObject'] );                         # doesn't

If the argument is a reference to hash, attributes of the exception
object is matched.

  eval { Exception::Base->throw( message=>"Message", value=>123 ) };
  print $@->matches( { message=>"Message" } );             # matches
  print $@->matches( { value=>123 } );                     # matches
  print $@->matches( { message=>"Message", value=>45 } );  # doesn't

If the argument is a single string, regexp or code reference or is undefined,
the default attribute of the exception object is matched (usually it is a
"message" attribute).

  eval { Exception::Base->throw( message=>"Message" ) };
  print $@->matches( "Message" );                          # matches
  print $@->matches( qr/Message/ );                        # matches
  print $@->matches( qr/[0-9]/ );                          # doesn't
  print $@->matches( sub{/Message/} );                     # matches
  print $@->matches( sub{0} );                             # doesn't
  print $@->matches( undef );                              # doesn't

If argument is a numeric value, the argument matches if C<value> attribute
matches.

  eval { Exception::Base->throw( value=>123, message=>456 ) } );
  print $@->matches( 123 );                                # matches
  print $@->matches( 456 );                                # doesn't

If an attribute contains array reference, the array will be C<sprintf>-ed
before matching.

  eval { Exception::Base->throw( message=>["%s", "Message"] ) };
  print $@->matches( "Message" );                          # matches
  print $@->matches( qr/Message/ );                        # matches
  print $@->matches( qr/[0-9]/ );                          # doesn't

The C<match> method matches for special keywords:

=over

=item -isa

Matches if the object is a given class.

  eval { Exception::Base->new( message=>"Message" ) };
  print $@->matches( { -isa=>"Exception::Base" } );            # matches
  print $@->matches( { -isa=>["X::Y", "Exception::Base"] } );  # matches

=item -has

Matches if the object has a given attribute.

  eval { Exception::Base->new( message=>"Message" ) };
  print $@->matches( { -has=>"Message" } );                    # matches

=item -default

Matches against the default attribute, usually the C<message> attribute.

  eval { Exception::Base->new( message=>"Message" ) };
  print $@->matches( { -default=>"Message" } );                # matches

=back

=cut

# Smart matching.
sub matches {
    my ($self, $that) = @_;

    my @args;

    my $default_attribute = $self->{defaults}->{default_attribute};
    my $numeric_attribute = $self->{defaults}->{numeric_attribute};

    if (ref $that eq 'ARRAY') {
        @args = ( '-isa' => $that );
    }
    elsif (ref $that eq 'HASH') {
        @args = %$that;
    }
    elsif (ref $that eq 'Regexp' or ref $that eq 'CODE' or not defined $that) {
        @args = ( $that );
    }
    elsif (ref $that) {
        return '';
    }
    elsif ($that =~ _RE_NUM_INT) {
        @args = ( $numeric_attribute => $that );
    }
    else {
        @args = ( $that );
    };

    return '' unless @args;

    # Odd number of arguments - first is default attribute
    if (scalar @args % 2 == 1) {
        my $val = shift @args;
        if (ref $val eq 'ARRAY') {
            my $arrret = 0;
            foreach my $arrval (@{ $val }) {
                if (not defined $arrval) {
                    $arrret = 1 if not $self->_string_attributes;
                }
                elsif (not ref $arrval and $arrval =~ _RE_NUM_INT) {
                    no warnings 'numeric', 'uninitialized';
                    $arrret = 1 if $self->{$numeric_attribute} == $arrval;
                }
                elsif (not $self->_string_attributes) {
                    next;
                }
                else {
                    local $_ = join ': ', $self->_string_attributes;
                    if (ref $arrval eq 'CODE') {
                        $arrret = 1 if $arrval->();
                    }
                    elsif (ref $arrval eq 'Regexp') {
                        $arrret = 1 if /$arrval/;
                    }
                    else {
                        $arrret = 1 if $_ eq $arrval;
                    };
                };
                last if $arrret;
            };
            # Fail unless at least one condition is true
            return '' if not $arrret;
        }
        elsif (not defined $val) {
            return '' if $self->_string_attributes;
        }
        elsif (not ref $val and $val =~ _RE_NUM_INT) {
            no warnings 'numeric', 'uninitialized';
            return '' if $self->{$numeric_attribute} != $val;
        }
        elsif (not $self->_string_attributes) {
            return '';
        }
        else {
            local $_ = join ': ', $self->_string_attributes;
            if (ref $val eq 'CODE') {
                return '' if not $val->();
            }
            elsif (ref $val eq 'Regexp') {
                return '' if not /$val/;
            }
            else {
                return '' if $_ ne $val;
            };
        };
        return 1 unless @args;
    };

    my %args = @args;
    while (my($key,$val) = each %args) {
        if ($key eq '-default') {
            $key = $default_attribute;
        };

        if ($key eq '-isa') {
            if (ref $val eq 'ARRAY') {
                my $arrret = 0;
                foreach my $arrval (@{ $val }) {
                    next if not defined $arrval;
                    $arrret = 1 if $self->isa($arrval);
                    last if $arrret;
                };
                return '' if not $arrret;
            }
            else {
                return '' if not $self->isa($val);
            };
        }
        elsif ($key eq '-has') {
            if (ref $val eq 'ARRAY') {
                my $arrret = 0;
                foreach my $arrval (@{ $val }) {
                    next if not defined $arrval;
                    $arrret = 1 if exists $self->ATTRS->{$arrval};
                    last if $arrret;
                };
                return '' if not $arrret;
            }
            else {
                return '' if not $self->ATTRS->{$val};
            };
        }
        elsif (ref $val eq 'ARRAY') {
            my $arrret = 0;
            foreach my $arrval (@{ $val }) {
                if (not defined $arrval) {
                    $arrret = 1 if not defined $self->{$key};
                }
                elsif (not defined $self->{$key}) {
                    next;
                }
                else {
                    local $_ = ref $self->{$key} eq 'ARRAY'
                               ? sprintf(
                                     @{$self->{$key}}[0],
                                     @{$self->{$key}}[1..$#{$self->{$key}}]
                                 )
                               : $self->{$key};
                    if (ref $arrval eq 'CODE') {
                        $arrret = 1 if $arrval->();
                    }
                    elsif (ref $arrval eq 'Regexp') {
                        $arrret = 1 if /$arrval/;
                    }
                    else {
                        $arrret = 1 if $_ eq $arrval;
                    };
                };
                last if $arrret;
            };
            return '' if not $arrret;
        }
        elsif (not defined $val) {
            return '' if exists $self->{$key} && defined $self->{$key};
        }
        elsif (not ref $val and $val =~ _RE_NUM_INT) {
            no warnings 'numeric', 'uninitialized';
            return '' if $self->{$key} != $val;
        }
        elsif (not defined $self->{$key}) {
            return '';
        }
        else {
            local $_ = ref $self->{$key} eq 'ARRAY'
                       ? sprintf(
                             @{$self->{$key}}[0],
                             @{$self->{$key}}[1..$#{$self->{$key}}]
                         )
                       : $self->{$key};

            if (ref $val eq 'CODE') {
                return '' if not $val->();
            }
            elsif (ref $val eq 'Regexp') {
                return '' if not /$val/;
            }
            else {
                return '' if $_ ne $val;
            };
        };
    };

    return 1;
}


=item to_string

Returns the string representation of exception object.  It is called
automatically if the exception object is used in string scalar context.  The
method can be used explicitly.

  eval { Exception::Base->throw; };
  $@->{verbosity} = 1;
  print "$@";
  $@->verbosity = 4;
  print $@->to_string;

=cut

# Convert an exception to string
sub to_string {
    my ($self) = @_;

    my $verbosity = defined $self->{verbosity}
                    ? $self->{verbosity}
                    : $self->{defaults}->{verbosity};

    my $message = join ': ', $self->_string_attributes;

    if ($message eq '') {
        foreach (reverse @{ $self->{defaults}->{string_attributes} }) {
            $message = $self->{defaults}->{$_};
            last if defined $message;
        };
    };

    if ($verbosity == 1) {
        return $message if $message =~ /\n$/;

        return $message . "\n";
    }
    elsif ($verbosity == 2) {
        return $message if $message =~ /\n$/;

        my @stacktrace = $self->get_caller_stacktrace;
        return $message . $stacktrace[0] . ".\n";
    }
    elsif ($verbosity >= 3) {
        return ref($self) . ': ' . $message . $self->get_caller_stacktrace;
    };

    return '';
};


=item to_number

Returns the numeric representation of exception object.  It is called
automatically if the exception object is used in numeric scalar context.  The
method can be used explicitly.

  eval { Exception::Base->throw( value => 42 ); };
  print 0+$@;           # 42
  print $@->to_number;  # 42

=cut

# Convert an exception to number
sub to_number {
    my ($self) = @_;

    my $numeric_attribute = $self->{defaults}->{numeric_attribute};

    no warnings 'numeric';
    return 0+ $self->{$numeric_attribute} if defined $self->{$numeric_attribute};
    return 0+ $self->{defaults}->{$numeric_attribute} if defined $self->{defaults}->{$numeric_attribute};
    return 0;
};


=item to_bool

Returns the boolean representation of exception object.  It is called
automatically if the exception object is used in boolean context.  The method
can be used explicitly.

  eval { Exception::Base->throw; };
  print "ok" if $@;           # ok
  print "ok" if $@->to_bool;  # ok

=cut

# Convert an exception to bool (always true)
sub to_bool {
    return !! 1;
};


=item get_caller_stacktrace

Returns an array of strings or string with caller stack trace.  It is
implicitly used by C<to_string> method.

=cut

# Stringify caller backtrace. Stolen from Carp
sub get_caller_stacktrace {
    my ($self) = @_;

    my @stacktrace;

    my $tid_msg = '';
    $tid_msg = ' thread ' . $self->{tid} if $self->{tid};

    my $verbosity = defined $self->{verbosity}
                    ? $self->{verbosity}
                    : $self->{defaults}->{verbosity};

    my $ignore_level = defined $self->{ignore_level}
                       ? $self->{ignore_level}
                       : defined $self->{defaults}->{ignore_level}
                         ? $self->{defaults}->{ignore_level}
                         : 0;

    # Skip some packages for first line
    my $level = 0;
    while (my %c = $self->_caller_info($level++)) {
        next if $self->_skip_ignored_package($c{package});
        # Skip ignored levels
        if ($ignore_level > 0) {
            --$ignore_level;
            next;
        };
        push @stacktrace, sprintf " at %s line %s%s",
                              defined $c{file} && $c{file} ne '' ? $c{file} : 'unknown',
                              $c{line} || 0,
                              $tid_msg;
        last;
    };
    # First line have to be filled even if everything was skipped
    if (not @stacktrace) {
        my %c = $self->_caller_info(0);
        push @stacktrace, sprintf " at %s line %s%s",
                              defined $c{file} && $c{file} ne '' ? $c{file} : 'unknown',
                              $c{line} || 0,
                              $tid_msg;
    };
    if ($verbosity >= 3) {
        # Reset the stack trace level only if needed
        if ($verbosity >= 4) {
            $level = 0;
        };
        # Dump the caller stack
        while (my %c = $self->_caller_info($level++)) {
            next if $verbosity == 3 and $self->_skip_ignored_package($c{package});
            push @stacktrace, "\t$c{wantarray}$c{sub_name} called in package $c{package} at $c{file} line $c{line}";
        };
        # Dump the propagated stack
        foreach (@{ $self->{propagated_stack} }) {
            my ($package, $file, $line) = @$_;
            # Skip ignored package
            next if $verbosity <= 3 and $self->_skip_ignored_package($package);
            push @stacktrace, sprintf "\t...propagated in package %s at %s line %d.",
                                  $package,
                                  defined $file && $file ne '' ? $file : 'unknown',
                                  $line || 0;
        };
    };

    return wantarray ? @stacktrace : join("\n", @stacktrace) . "\n";
};


=item PROPAGATE

Checks the caller stack and fills the C<propagated_stack> attribute.  It is
usually used if C<die> system function was called without any arguments.

=cut

# Propagate exception if it is rethrown
sub PROPAGATE {
    my ($self) = @_;

    # Fill propagate stack
    my $level = 1;
    while (my @c = caller($level++)) {
            # Skip own package
            next if ! defined $Isa_Package{$c[0]}
                      ? $Isa_Package{$c[0]} = do { local $@; local $SIG{__DIE__}; eval { $c[0]->isa(__PACKAGE__) } }
                      : $Isa_Package{$c[0]};
            # Collect the caller stack
            push @{ $self->{propagated_stack} }, [ @c[0..2] ];
            last;
    };

    return $self;
};


# Return a list of values of default string attributes
sub _string_attributes {
    my ($self) = @_;

    return map { ref $_ eq 'ARRAY'
                 ? sprintf(@$_[0], @$_[1..$#$_])
                 : $_ }
           grep { defined $_ and (ref $_ or $_ ne '') }
           map { $self->{$_} }
           @{ $self->{defaults}->{string_attributes} };
};


=item _collect_system_data

Collects system data and fills the attributes of exception object.  This
method is called automatically if exception if thrown or created by
C<new> constructor.  It can be overridden by derived class.

  package Exception::Special;
  use base 'Exception::Base';
  use constant ATTRS => {
    %{Exception::Base->ATTRS},
    'special' => { is => 'ro' },
  };
  sub _collect_system_data {
    my $self = shift;
    $self->SUPER::_collect_system_data(@_);
    $self->{special} = get_special_value();
    return $self;
  }
  BEGIN {
    __PACKAGE__->_make_accessors;
  }
  1;

Method returns the reference to the self object.

=cut

# Collect system data and fill the attributes and caller stack.
sub _collect_system_data {
    my ($self) = @_;

    # Collect system data only if verbosity is meaning
    my $verbosity = defined $self->{verbosity} ? $self->{verbosity} : $self->{defaults}->{verbosity};
    if ($verbosity >= 2) {
        $self->{time} = CORE::time();
        $self->{tid}  = threads->tid if defined &threads::tid;
        @{$self}{qw < pid uid euid gid egid >} =
                (     $$, $<, $>,  $(, $)    );

        # Collect stack info
        my @caller_stack;
        my $level = 1;

        while (my @c = do { package DB; caller($level++) }) {
            # Skip own package
            next if ! defined $Isa_Package{$c[0]} ? $Isa_Package{$c[0]} = do { local $@; local $SIG{__DIE__}; eval { $c[0]->isa(__PACKAGE__) } } : $Isa_Package{$c[0]};
            # Collect the caller stack
            my @args = @DB::args;
            if (_HAVE_SCALAR_UTIL_WEAKEN) {
                foreach (@args) {
                    Scalar::Util::weaken($_) if ref $_;
                };
            };
            my @stacktrace_element = ( @c[0 .. 7], @args );
            push @caller_stack, \@stacktrace_element;
            # Collect only one entry if verbosity is lower than 3 and skip ignored packages
            last if $verbosity == 2 and not $self->_skip_ignored_package($stacktrace_element[0]);
        };
        $self->{caller_stack} = \@caller_stack;
    };

    return $self;
};


# Check if package should be ignored
sub _skip_ignored_package {
    my ($self, $package) = @_;

    my $ignore_package = defined $self->{ignore_package}
                     ? $self->{ignore_package}
                     : $self->{defaults}->{ignore_package};

    my $ignore_class = defined $self->{ignore_class}
                     ? $self->{ignore_class}
                     : $self->{defaults}->{ignore_class};

    if (defined $ignore_package) {
        if (ref $ignore_package eq 'ARRAY') {
            if (@{ $ignore_package }) {
                do { return 1 if defined $_ and (ref $_ eq 'Regexp' and $package =~ $_ or ref $_ ne 'Regexp' and $package eq $_) } foreach @{ $ignore_package };
            };
        }
        else {
            return 1 if ref $ignore_package eq 'Regexp' ? $package =~ $ignore_package : $package eq $ignore_package;
        };
    }
    if (defined $ignore_class) {
        if (ref $ignore_class eq 'ARRAY') {
            if (@{ $ignore_class }) {
                return 1 if grep { do { local $@; local $SIG{__DIE__}; eval { $package->isa($_) } } } @{ $ignore_class };
            };
        }
        else {
            return 1 if do { local $@; local $SIG{__DIE__}; eval { $package->isa($ignore_class) } };
        };
    };

    return '';
};


# Return info about caller. Stolen from Carp
sub _caller_info {
    my ($self, $i) = @_;
    my %call_info;
    my @call_info = ();

    @call_info = @{ $self->{caller_stack}->[$i] }
        if defined $self->{caller_stack} and defined $self->{caller_stack}->[$i];

    @call_info{
        qw{ package file line subroutine has_args wantarray evaltext is_require }
    } = @call_info[0..7];

    unless (defined $call_info{package}) {
        return ();
    };

    my $sub_name = $self->_get_subname(\%call_info);
    if ($call_info{has_args}) {
        my @args = map {$self->_format_arg($_)} @call_info[8..$#call_info];
        my $max_arg_nums = defined $self->{max_arg_nums} ? $self->{max_arg_nums} : $self->{defaults}->{max_arg_nums};
        if ($max_arg_nums > 0 and $#args+1 > $max_arg_nums) {
            $#args = $max_arg_nums - 2;
            push @args, '...';
        };
        # Push the args onto the subroutine
        $sub_name .= '(' . join (', ', @args) . ')';
    }
    $call_info{file} = 'unknown' unless $call_info{file};
    $call_info{line} = 0 unless $call_info{line};
    $call_info{sub_name} = $sub_name;
    $call_info{wantarray} = $call_info{wantarray} ? '@_ = ' : '$_ = ';

    return wantarray() ? %call_info : \%call_info;
};


# Figures out the name of the sub/require/eval. Stolen from Carp
sub _get_subname {
    my ($self, $info) = @_;
    if (defined($info->{evaltext})) {
        my $eval = $info->{evaltext};
        if ($info->{is_require}) {
            return "require $eval";
        }
        else {
            $eval =~ s/([\\\'])/\\$1/g;
            return
                "eval '" .
                $self->_str_len_trim($eval, defined $self->{max_eval_len} ? $self->{max_eval_len} : $self->{defaults}->{max_eval_len}) .
                "'";
        };
    };

    return ($info->{subroutine} eq '(eval)') ? 'eval {...}' : $info->{subroutine};
};


# Transform an argument to a function into a string. Stolen from Carp
sub _format_arg {
    my ($self, $arg) = @_;

    return 'undef' if not defined $arg;

    if (do { local $@; local $SIG{__DIE__}; eval { $arg->isa(__PACKAGE__) } } or ref $arg) {
        return q{"} . overload::StrVal($arg) . q{"};
    };

    $arg =~ s/\\/\\\\/g;
    $arg =~ s/"/\\"/g;
    $arg =~ s/`/\\`/g;
    $arg = $self->_str_len_trim($arg, defined $self->{max_arg_len} ? $self->{max_arg_len} : $self->{defaults}->{max_arg_len});

    $arg = "\"$arg\"" unless $arg =~ /^-?[\d.]+\z/;

    no warnings 'once', 'utf8';   # can't disable critic for utf8...
    if (not defined *utf8::is_utf{CODE} or utf8::is_utf8($arg)) {
        $arg = join('', map { $_ > 255
            ? sprintf("\\x{%04x}", $_)
            : chr($_) =~ /[[:cntrl:]]|[[:^ascii:]]/
                ? sprintf("\\x{%02x}", $_)
                : chr($_)
        } unpack("U*", $arg));
    }
    else {
        $arg =~ s/([[:cntrl:]]|[[:^ascii:]])/sprintf("\\x{%02x}",ord($1))/eg;
    };

    return $arg;
};


# If a string is too long, trims it with ... . Stolen from Carp
sub _str_len_trim {
    my (undef, $str, $max) = @_;
    $max = 0 unless defined $max;
    if ($max > 2 and $max < length($str)) {
        substr($str, $max - 3) = '...';
    };

    return $str;
};


# Modify default values for ATTRS
sub _modify_default {
    my ($self, $key, $value, $modifier) = @_;

    my $class = ref $self || $self;

    # Modify entry in ATTRS constant. Its elements are not constant.
    my $attributes = $class->ATTRS;

    if (not exists $attributes->{$key}->{default}) {
        Exception::Base->throw(
              message => ["%s class does not implement default value for `%s' attribute", $class, $key],
              verbosity => 1
        );
    };

    # Make a new anonymous hash reference for attribute
    $attributes->{$key} = { %{ $attributes->{$key} } };

    # Modify default value of attribute
    if ($modifier eq '+') {
        my $old = $attributes->{$key}->{default};
        if (ref $old eq 'ARRAY' or ref $value eq 'Regexp') {
            my @new = ref $old eq 'ARRAY' ? @{ $old } : $old;
            foreach my $v (ref $value eq 'ARRAY' ? @{ $value } : $value) {
                next if grep { $v eq $_ } ref $old eq 'ARRAY' ? @{ $old } : $old;
                push @new, $v;
            };
            $attributes->{$key}->{default} = [ @new ];
        }
        elsif ($old =~ /^\d+$/) {
            $attributes->{$key}->{default} += $value;
        }
        else {
            $attributes->{$key}->{default} .= $value;
        };
    }
    elsif ($modifier eq '-') {
        my $old = $attributes->{$key}->{default};
        if (ref $old eq 'ARRAY' or ref $value eq 'Regexp') {
            my @new = ref $old eq 'ARRAY' ? @{ $old } : $old;
            foreach my $v (ref $value eq 'ARRAY' ? @{ $value } : $value) {
                @new = grep { $v ne $_ } @new;
            };
            $attributes->{$key}->{default} = [ @new ];
        }
        elsif ($old =~ /^\d+$/) {
            $attributes->{$key}->{default} -= $value;
        }
        else {
            $attributes->{$key}->{default} = $value;
        };
    }
    else {
        $attributes->{$key}->{default} = $value;
    };

    # Redeclare constant
    {
        no warnings 'redefine';
        *{_qualify_to_ref("${class}::ATTRS")} = sub () {
            +{ %$attributes };
        };
    };

    # Reset cache
    %Class_Attributes = %Class_Defaults = ();

    return $self;
};


=item _make_accessors

Creates accessors for each attribute.  This static method should be called in
each derived class which defines new attributes.

  package Exception::My;
  # (...)
  BEGIN {
    __PACKAGE__->_make_accessors;
  }

=cut

# Create accessors for this class
sub _make_accessors {
    my ($self) = @_;

    my $class = ref $self || $self;

    no warnings 'uninitialized';
    my $attributes = $class->ATTRS;
    foreach my $key (keys %{ $attributes }) {
        next if ref $attributes->{$key} ne 'HASH';
        if (not $class->can($key)) {
            next if not defined $attributes->{$key}->{is};
            if ($attributes->{$key}->{is} eq 'rw') {
                *{_qualify_to_ref($class . '::' . $key)} = sub :lvalue {
                    @_ > 1 ? $_[0]->{$key} = $_[1]
                           : $_[0]->{$key};
                };
            }
            else {
                *{_qualify_to_ref($class . '::' . $key)} = sub {
                    $_[0]->{$key};
                };
            };
        };
    };

    return $self;
};


=item package

Returns the package name of the subroutine which thrown an exception.

=item file

Returns the file name of the subroutine which thrown an exception.

=item line

Returns the line number for file of the subroutine which thrown an exception.

=item subroutine

Returns the subroutine name which thrown an exception.

=back

=cut

# Create caller_info() accessors for this class
sub _make_caller_info_accessors {
    my ($self) = @_;

    my $class = ref $self || $self;

    foreach my $key (qw{ package file line subroutine }) {
        if (not $class->can($key)) {
            *{_qualify_to_ref($class . '::' . $key)} = sub {
                my $self = shift;
                my $ignore_level = defined $self->{ignore_level}
                                 ? $self->{ignore_level}
                                 : defined $self->{defaults}->{ignore_level}
                                   ? $self->{defaults}->{ignore_level}
                                   : 0;
                my $level = 0;
                while (my %c = $self->_caller_info($level++)) {
                    next if $self->_skip_ignored_package($c{package});
                    # Skip ignored levels
                    if ($ignore_level > 0) {
                        $ignore_level --;
                        next;
                    };
                    return $c{$key};
                };
            };
        };
    };

    return $self;
};


# Load another module without eval q{}
sub _load_package {
    my ($class, $package, $version) = @_;

    return unless $package;

    my $file = $package . '.pm';
    $file =~ s{::}{/}g;

    require $file;

    # Check version if first element on list is a version number.
    if (defined $version and $version =~ m/^\d/) {
        $package->VERSION($version);
    };

    return $class;
};


# Create new exception class
sub _make_exception {
    my ($class, $package, $version, $param) = @_;

    return unless $package;

    my $isa = defined $param->{isa} ? $param->{isa} : __PACKAGE__;
    $version = 0.01 if not $version;

    my $has = defined $param->{has} ? $param->{has} : { rw => [ ], ro => [ ] };
    if (ref $has eq 'ARRAY') {
        $has = { rw => $has, ro => [ ] };
    }
    elsif (not ref $has) {
        $has = { rw => [ $has ], ro => [ ] };
    };
    foreach my $mode ('rw', 'ro') {
        if (not ref $has->{$mode}) {
            $has->{$mode} = [ defined $has->{$mode} ? $has->{$mode} : () ];
        };
    };

    # Base class is needed
    if (not defined do { local $SIG{__DIE__}; eval { $isa->VERSION } }) {
        eval {
            $class->_load_package($isa);
        };
        if ($@) {
            Exception::Base->throw(
                message => ["Base class %s for class %s can not be found", $isa, $package],
                verbosity => 1
            );
        };
    };

    # Handle defaults for object attributes
    my $attributes;
    {
        local $SIG{__DIE__};
        eval {
            $attributes = $isa->ATTRS;
        };
    };
    if ($@) {
        Exception::Base->throw(
            message => ["%s class is based on %s class which does not implement ATTRS", $package, $isa],
            verbosity => 1
        );
    };

    # Create the hash with overridden attributes
    my %overridden_attributes;
    # Class => { has => { rw => [ "attr1", "attr2", "attr3", ... ], ro => [ "attr4", ... ] } }
    foreach my $mode ('rw', 'ro') {
        foreach my $attribute (@{ $has->{$mode} }) {
            if ($attribute =~ /^(isa|version|has)$/ or $isa->can($attribute)) {
                Exception::Base->throw(
                    message => ["Attribute name `%s' can not be defined for %s class", $attribute, $package],
                );
            };
            $overridden_attributes{$attribute} = { is => $mode };
        };
    };
    # Class => { message => "overridden default", ... }
    foreach my $attribute (keys %{ $param }) {
        next if $attribute =~ /^(isa|version|has)$/;
        if (not exists $attributes->{$attribute}->{default}
            and not exists $overridden_attributes{$attribute})
        {
            Exception::Base->throw(
                message => ["%s class does not implement default value for `%s' attribute", $isa, $attribute],
                verbosity => 1
            );
        };
        $overridden_attributes{$attribute} = {};
        $overridden_attributes{$attribute}->{default} = $param->{$attribute};
        foreach my $property (keys %{ $attributes->{$attribute} }) {
            next if $property eq 'default';
            $overridden_attributes{$attribute}->{$property} = $attributes->{$attribute}->{$property};
        };
    };

    # Create the new package
    *{_qualify_to_ref("${package}::VERSION")} = \$version;
    *{_qualify_to_ref("${package}::ISA")} = [ $isa ];
    *{_qualify_to_ref("${package}::ATTRS")} = sub () {
        +{ %{ $isa->ATTRS }, %overridden_attributes };
    };
    $package->_make_accessors;

    return $class;
};


# Module initialization
BEGIN {
    __PACKAGE__->_make_accessors;
    __PACKAGE__->_make_caller_info_accessors;
};


1;


=begin plantuml

class Exception::Base <<exception>> {
  +ignore_class : ArrayRef = []
  +ignore_level : Int = 0
  +ignore_package : ArrayRef = []
  +max_arg_len : Int = 64
  +max_arg_nums : Int = 8
  +max_eval_len : Int = 0
  +message : Str|ArrayRef[Str] = "Unknown exception"
  +value : Int = 0
  +verbosity : Int = 2
  ..
  +caller_stack : ArrayRef
  +egid : Int
  +euid : Int
  +gid : Int
  +pid : Int
  +propagated_stack : ArrayRef
  +tid : Int
  +time : Int
  +uid : Int
  ..
  #defaults : HashRef
  #default_attribute : Str = "message"
  #numeric_attribute : Str = "value"
  #eval_attribute : Str = "message"
  #string_attributes : ArrayRef[Str] = ["message"]
  ==
  +new( args : Hash ) <<create>>
  +throw( args : Hash = undef ) <<create>>
  +throw( message : Str, args : Hash = undef ) <<create>>
  ..
  +catch() : Exception::Base
  +catch( variable : Any ) : Exception::Base
  +matches( that : Any ) : Bool {overload="~~"}
  +to_string() : Str {overload='""'}
  +to_number() : Num {overload="0+"}
  +to_bool() : Bool {overload="bool"}
  +get_caller_stacktrace() : Array[Str]|Str
  +PROPAGATE()
  ..
  +ATTRS() : HashRef <<constant>>
  ..
  #_collect_system_data()
  #_make_accessors() <<static>>
  #_make_caller_info_accessors() <<static>>
}

=end plantuml

=head1 SEE ALSO

Repository: L<http://github.com/dex4er/perl-Exception-Base>

There are more implementation of exception objects available on CPAN.  Please
note that Perl has built-in implementation of pseudo-exceptions:

  eval { die { message => "Pseudo-exception", package => __PACKAGE__,
               file => __FILE__, line => __LINE__ };
  };
  if ($@) {
    print $@->{message}, " at ", $@->{file}, " in line ", $@->{line}, ".\n";
  }

The more complex implementation of exception mechanism provides more features.

=over

=item L<Error>

Complete implementation of try/catch/finally/otherwise mechanism.  Uses nested
closures with a lot of syntactic sugar.  It is slightly faster than
C<Exception::Base> module for failure scenario and is much slower for success
scenario.  It doesn't provide a simple way to create user defined exceptions.
It doesn't collect system data and stack trace on error.

=item L<Exception::Class>

More Perlish way to do OO exceptions.  It is similar to C<Exception::Base>
module and provides similar features but it is 10x slower for failure
scenario.

=item L<Exception::Class::TryCatch>

Additional try/catch mechanism for L<Exception::Class>.  It is 15x slower for
success scenario.

=item L<Class::Throwable>

Elegant OO exceptions similar to L<Exception::Class> and C<Exception::Base>.
It might be missing some features found in C<Exception::Base> and
L<Exception::Class>.

=item L<Exceptions>

Not recommended.  Abandoned.  Modifies C<%SIG> handlers.

=item L<TryCatch>

A module which gives new try/catch keywords without source filter.

=item L<Try::Tiny>

Smaller, simpler and slower version of L<TryCatch> module.

=back

The C<Exception::Base> does not depend on other modules like
L<Exception::Class> and it is more powerful than L<Class::Throwable>.  Also it
does not use closures as L<Error> and does not pollute namespace as
L<Exception::Class::TryCatch>.  It is also much faster than
L<Exception::Class::TryCatch> and L<Error> for success scenario.

The C<Exception::Base> is compatible with syntax sugar modules like
L<TryCatch> and L<Try::Tiny>.

The C<Exception::Base> is also a base class for enhanced classes:

=over

=item L<Exception::System>

The exception class for system or library calls which modifies C<$!> variable.

=item L<Exception::Died>

The exception class for eval blocks with simple L<perlfunc/die>.  It can also
handle L<$SIG{__DIE__}|perlvar/%SIG> hook and convert simple L<perlfunc/die>
into an exception object.

=item L<Exception::Warning>

The exception class which handle L<$SIG{__WARN__}|pervar/%SIG> hook and
convert simple L<perlfunc/warn> into an exception object.

=back

=head1 EXAMPLES

=head2 New exception classes

The C<Exception::Base> module allows to create new exception classes easily.
You can use L<perlfunc/import> interface or L<base> module to do it.

The L<perlfunc/import> interface allows to create new class with new
read-write attributes.

  package Exception::Simple;
  use Exception::Base (__PACKAGE__) => {
    has => qw{ reason method },
    string_attributes => qw{ message reason method },
  };

For more complex exceptions you can redefine C<ATTRS> constant.

  package Exception::Complex;
  use base 'Exception::Base';
  use constant ATTRS => {
    %{ Exception::Base->ATTRS },     # SUPER::ATTRS
    hostname => { is => 'ro' },
    string_attributes => qw{ hostname message },
  };
  sub _collect_system_data {
    my $self = shift;
    my $hostname = `hostname`;
    chomp $hostname;
    $self->{hostname} = $hostname;
    return $self->SUPER::_collect_system_data(@_);
  }

=head1 PERFORMANCE

There are two scenarios for L<perlfunc/eval> block: success or failure.
Success scenario should have no penalty on speed.  Failure scenario is usually
more complex to handle and can be significantly slower.

Any other code than simple C<if ($@)> is really slow and shouldn't be used if
speed is important.  It means that any module which provides try/catch syntax
sugar should be avoided: L<Error>, L<Exception::Class::TryCatch>, L<TryCatch>,
L<Try::Tiny>.  Be careful because simple C<if ($@)> has many gotchas which are
described in L<Try::Tiny>'s documentation.

The C<Exception::Base> module was benchmarked with other implementations for
simple try/catch scenario.  The results
(Perl 5.10.1 x86_64-linux-thread-multi) are following:

  -----------------------------------------------------------------------
  | Module                              | Success sub/s | Failure sub/s |
  -----------------------------------------------------------------------
  | eval/die string                     |       3715708 |        408951 |
  -----------------------------------------------------------------------
  | eval/die object                     |       4563524 |        191664 |
  -----------------------------------------------------------------------
  | Exception::Base eval/if             |       4903857 |         11291 |
  -----------------------------------------------------------------------
  | Exception::Base eval/if verbosity=1 |       4790762 |         18833 |
  -----------------------------------------------------------------------
  | Error                               |        117475 |         26694 |
  -----------------------------------------------------------------------
  | Class::Throwable                    |       4618545 |         12678 |
  -----------------------------------------------------------------------
  | Exception::Class                    |        643901 |          3493 |
  -----------------------------------------------------------------------
  | Exception::Class::TryCatch          |        307825 |          3439 |
  -----------------------------------------------------------------------
  | TryCatch                            |        690784 |        294802 |
  -----------------------------------------------------------------------
  | Try::Tiny                           |        268780 |        158383 |
  -----------------------------------------------------------------------

The C<Exception::Base> module was written to be as fast as it is
possible.  It does not use internally i.e. accessor functions which are
slower about 6 times than standard variables.  It is slower than pure
die/eval for success scenario because it is uses OO mechanisms which are slow
in Perl.  It can be a little faster if some features are disables, i.e. the
stack trace and higher verbosity.

You can find the benchmark script in this package distribution.

=head1 BUGS

If you find the bug or want to implement new features, please report it at
L<https://github.com/dex4er/perl-Exception-Base/issues>

The code repository is available at
L<http://github.com/dex4er/perl-Exception-Base>

=for readme continue

=head1 AUTHOR

Piotr Roszatycki <dexter@cpan.org>

=head1 LICENSE

Copyright (c) 2007-2015 Piotr Roszatycki <dexter@cpan.org>.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://dev.perl.org/licenses/artistic.html>
