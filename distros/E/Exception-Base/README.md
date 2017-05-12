[![Build Status](https://travis-ci.org/dex4er/perl-Exception-Base.png?branch=master)](https://travis-ci.org/dex4er/perl-Exception-Base)

# NAME

Exception::Base - Lightweight exceptions

# SYNOPSIS

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

# DESCRIPTION

This class implements a fully OO exception mechanism similar to
[Exception::Class](https://metacpan.org/pod/Exception::Class) or [Class::Throwable](https://metacpan.org/pod/Class::Throwable).  It provides a simple interface
allowing programmers to declare exception classes.  These classes can be
thrown and caught.  Each uncaught exception prints full stack trace if the
default verbosity is increased for debugging purposes.

The features of `Exception::Base`:

- fast implementation of the exception class
- fully OO without closures and source code filtering
- does not mess with `$SIG{__DIE__}` and `$SIG{__WARN__}`
- no external run-time modules dependencies, requires core Perl modules only
- the default behavior of exception class can be changed globally or just for
the thrown exception
- matching the exception by class, message or other attributes
- matching with string, regex or closure function
- creating automatically the derived exception classes (["use" in perlfunc](https://metacpan.org/pod/perlfunc#use)
interface)
- easily expendable, see [Exception::System](https://metacpan.org/pod/Exception::System) class for example
- prints just an error message or dumps full stack trace
- can propagate (rethrow) an exception
- can ignore some packages for stack trace output
- some defaults (i.e. verbosity) can be different for different exceptions

# OVERLOADS

- Boolean context

    True value.  See `to_bool` method.

        eval { Exception::Base->throw( message=>"Message", value=>123 ) };
        if ($@) {
           # the exception object is always true
        }

- Numeric context

    Content of attribute pointed by `numeric_attribute` attribute.  See
    `to_number` method.

        eval { Exception::Base->throw( message=>"Message", value=>123 ) };
        print 0+$@;           # 123

- String context

    Content of attribute which is combined from `string_attributes` attributes
    with additional information, depended on `verbosity` setting.  See
    `to_string` method.

        eval { Exception::Base->throw( message=>"Message", value=>123 ) };
        print "$@";           # "Message at -e line 1.\n"

- "~~"

    Smart matching operator.  See `matches` method.

        eval { Exception::Base->throw( message=>"Message", value=>123 ) };
        print "Message" ~~ $@;                          # 1
        print qr/message/i ~~ $@;                       # 1
        print ['Exception::Base'] ~~ $@;                # 1
        print 123 ~~ $@;                                # 1
        print {message=>"Message", value=>123} ~~ $@;   # 1

    Warning: The smart operator requires that the exception object is a second
    argument.

# CONSTANTS

- ATTRS

    Declaration of class attributes as reference to hash.

    The attributes are listed as _name_ => {_properties_}, where _properties_ is a
    list of attribute properties:

    - is

        Can be 'rw' for read-write attributes or 'ro' for read-only attributes.  The
        attribute is read-only and does not have an accessor created if 'is' property
        is missed.

    - default

        Optional property with the default value if the attribute value is not
        defined.

    The read-write attributes can be set with `new` constructor.  Read-only
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

# ATTRIBUTES

Class attributes are implemented as values of blessed hash.  The attributes
are also available as accessors methods.

- message (rw, default: 'Unknown exception')

    Contains the message of the exception.  It is the part of the string
    representing the exception object.

        eval { Exception::Base->throw( message=>"Message" ); };
        print $@->message if $@;

    It can also be an array reference of strings and then the ["perlfunc" in sprintf](https://metacpan.org/pod/sprintf#perlfunc)
    is used to get a message.

        Exception::Base->throw( message => ["%s failed", __PACKAGE__] );

- value (rw, default: 0)

    Contains the value which represents numeric value of the exception object in
    numeric context.

        eval { Exception::Base->throw( value=>2 ); };
        print "Error 2" if $@ == 2;

- verbosity (rw, default: 2)

    Contains the verbosity level of the exception object.  It allows to change the
    string representing the exception object.  There are following levels of
    verbosity:

    - `0`

        Empty string

    - `1`

            Message

    - `2`

            Message at %s line %d.

        The same as the standard output of die() function.  It doesn't include
        "at %s line %d." string if message ends with `"\n"` character.  This is
        the default option.

    - `3`

            Class: Message at %s line %d
                    %c_ = %s::%s() called in package %s at %s line %d
                    ...propagated in package %s at %s line %d.
            ...

        The output contains full trace of error stack without first `ignore_level`
        lines and those packages which are listed in `ignore_package` and
        `ignore_class` settings.

    - 4

        The output contains full trace of error stack.  In this case the
        `ignore_level`, `ignore_package` and `ignore_class` settings are meaning
        only for first line of exception's message.

    If the verbosity is undef, then the default verbosity for exception objects is
    used.

    If the verbosity set with constructor (`new` or `throw`) is lower than 3,
    the full stack trace won't be collected.

    If the verbosity is lower than 2, the full system data (time, pid, tid, uid,
    euid, gid, egid) won't be collected.

    This setting can be changed with import interface.

        use Exception::Base verbosity => 4;

    It can be also changed for Perl interpreter instance, i.e. for debugging
    purposes.

        sh$ perl -MException::Base=verbosity,4 script.pl

- ignore\_package (rw)

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

- ignore\_class (rw)

    Contains the name (scalar) or names (as references array) of packages which
    are base classes for ignored packages in error stack trace.  It means that
    some packages will be ignored even the derived class was called.

        package My::Package;
        use Exception::Base;
        Exception::Base->throw( ignore_class => "My::Base" );

    This setting can be changed with import interface.

        use Exception::Base ignore_class => "My::Base";

- ignore\_level (rw)

    Contains the number of level on stack trace to ignore.  It is useful if some
    package throws an exception but this module shouldn't be listed in stack
    trace.  It can be used with or without _ignore\_package_ attribute.

        # Convert warning into exception. The signal handler ignores itself.
        use Exception::Base 'Exception::My::Warning';
        $SIG{__WARN__} = sub {
          Exception::My::Warning->throw( message => $_[0], ignore_level => 1 );
        };

- time (ro)

    Contains the timestamp of the thrown exception.  Collected if the verbosity on
    throwing exception was greater than 1.

        eval { Exception::Base->throw( message=>"Message" ); };
        print scalar localtime $@->time;

- pid (ro)

    Contains the PID of the Perl process at time of thrown exception.  Collected
    if the verbosity on throwing exception was greater than 1.

        eval { Exception::Base->throw( message=>"Message" ); };
        kill 10, $@->pid;

- tid (ro)

    Contains the tid of the thread or undef if threads are not used.  Collected
    if the verbosity on throwing exception was greater than 1.

- uid (ro)
- euid (ro)
- gid (ro)
- egid (ro)

    Contains the real and effective uid and gid of the Perl process at time of
    thrown exception.  Collected if the verbosity on throwing exception was
    greater than 1.

- caller\_stack (ro)

    Contains the error stack as array of array with information about caller
    functions.  The first 8 elements of the array's row are the same as first 8
    elements of the output of `caller` function.  Further elements are optional
    and are the arguments of called function.  Collected if the verbosity on
    throwing exception was greater than 1.  Contains only the first element of
    caller stack if the verbosity was lower than 3.

    If the arguments of called function are references and
    `[Scalar::Util](https://metacpan.org/pod/Scalar::Util)::weaken` function is available then reference is weakened.

        eval { Exception::Base->throw( message=>"Message" ); };
        ($package, $filename, $line, $subroutine, $hasargs, $wantarray,
        $evaltext, $is_require, @args) = $@->caller_stack->[0];

- propagated\_stack (ro)

    Contains the array of array which is used for generating "...propagated at"
    message.  The elements of the array's row are the same as first 3 elements of
    the output of `caller` function.

- max\_arg\_len (rw, default: 64)

    Contains the maximal length of argument for functions in backtrace output.
    Zero means no limit for length.

        sub a { Exception::Base->throw( max_arg_len=>5 ) }
        a("123456789");

- max\_arg\_nums (rw, default: 8)

    Contains the maximal number of arguments for functions in backtrace output.
    Zero means no limit for arguments.

        sub a { Exception::Base->throw( max_arg_nums=>1 ) }
        a(1,2,3);

- max\_eval\_len (rw, default: 0)

    Contains the maximal length of eval strings in backtrace output.  Zero means
    no limit for length.

        eval "Exception->throw( max_eval_len=>10 )";
        print "$@";

- defaults

    Meta-attribute contains the list of default values.

        my $e = Exception::Base->new;
        print defined $e->{verbosity}
          ? $e->{verbosity}
          : $e->{defaults}->{verbosity};

- default\_attribute (default: 'message')

    Meta-attribute contains the name of the default attribute.  This attribute
    will be set for one argument throw method.  This attribute has meaning for
    derived classes.

        use Exception::Base 'Exception::My' => {
            has => 'myattr',
            default_attribute => 'myattr',
        };

        eval { Exception::My->throw("string") };
        print $@->myattr;    # "string"

- numeric\_attribute (default: 'value')

    Meta-attribute contains the name of the attribute which contains numeric value
    of exception object.  This attribute will be used for representing exception
    in numeric context.

        use Exception::Base 'Exception::My' => {
            has => 'myattr',
            numeric_attribute => 'myattr',
        };

        eval { Exception::My->throw(myattr=>123) };
        print 0 + $@;    # 123

- eval\_attribute (default: 'message')

    Meta-attribute contains the name of the attribute which is filled if error
    stack is empty.  This attribute will contain value of `$@` variable.  This
    attribute has meaning for derived classes.

        use Exception::Base 'Exception::My' => {
            has => 'myattr',
            eval_attribute => 'myattr'
        };

        eval { die "string" };
        print $@->myattr;    # "string"

- string\_attributes (default: \['message'\])

    Meta-attribute contains the array of names of attributes with defined value
    which are joined to the string returned by `to_string` method.  If none of
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

# IMPORTS

- `use Exception::Base '_attribute_' =` _value_;>

    Changes the default value for _attribute_.  If the _attribute_ name has no
    special prefix, its default value is replaced with a new _value_.

        use Exception::Base verbosity => 4;

    If the _attribute_ name starts with "`+`" or "`-`" then the new _value_
    is based on previous value:

    - If the original _value_ was a reference to array, the new _value_ can
    be included or removed from original array.  Use array reference if you
    need to add or remove more than one element.

            use Exception::Base
                "+ignore_packages" => [ __PACKAGE__, qr/^Moose::/ ],
                "-ignore_class" => "My::Good::Class";

    - If the original _value_ was a number, it will be incremented or
    decremented by the new _value_.

            use Exception::Base "+ignore_level" => 1;

    - If the original _value_ was a string, the new _value_ will be
    included.

            use Exception::Base "+message" => ": The incuded message";

- `use Exception::Base '_Exception_', ...;`

    Loads additional exception class module.  If the module is not available,
    creates the exception class automatically at compile time.  The newly created
    class will be based on `Exception::Base` class.

        use Exception::Base qw{ Exception::Custom Exception::SomethingWrong };
        Exception::Custom->throw;

- `use Exception::Base '_Exception_' =` { isa => _BaseException_, version => _version_, ... };>

    Loads additional exception class module.  If the module's version is lower
    than given parameter or the module can't be loaded, creates the exception
    class automatically at compile time.  The newly created class will be based on
    given class and has the given $VERSION variable.

    - isa

        The newly created class will be based on given class.

            use Exception::Base
              'Exception::My',
              'Exception::Nested' => { isa => 'Exception::My };

    - version

        The class will be created only if the module's version is lower than given
        parameter and will have the version given in the argument.

            use Exception::Base
              'Exception::My' => { version => 1.23 };

    - has

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

    - message
    - verbosity
    - max\_arg\_len
    - max\_arg\_nums
    - max\_eval\_len
    - _other attribute having default property_

        The class will have the default property for the given attribute.

        use Exception::Base
          'Exception::WithDefault' => { message => 'Default message' },
          'Exception::Reason' => {
              has => [ 'reason' ],
              string_attributes => [ 'message', 'reason' ] };

# CONSTRUCTORS

- new(\[%_args_\])

    Creates the exception object, which can be thrown later.  The system data
    attributes like `time`, `pid`, `uid`, `gid`, `euid`, `egid` are not
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

- `CLASS`->throw(\[%_args_\]\])

    Creates the exception object and immediately throws it with `die` system
    function.

        open my $fh, $file
          or Exception::Base->throw( message=>"Can not open file: $file" );

    The `throw` is also exported as a function.

        open my $fh, $file
          or throw 'Exception::Base' => message=>"Can not open file: $file";

The `throw` can be also used as a method.

# METHODS

- `$obj`->throw(\[%_args_\])

    Immediately throws exception object.  It can be used for rethrowing existing
    exception object.  Additional arguments will override the attributes in
    existing exception object.

        $e = Exception::Base->new;
        # (...)
        $e->throw( message=>"thrown exception with overridden message" );

        eval { Exception::Base->throw( message=>"Problem", value=>1 ) };
        $@->throw if $@->value;

- `$obj`->throw(_message_, \[%_args_\])

    If the number of _args_ list for arguments is odd, the first argument is a
    message.  This message can be overridden by message from _args_ list.

        Exception::Base->throw( "Problem", message=>"More important" );
        eval { die "Bum!" };
        Exception::Base->throw( $@, message=>"New message" );

- _CLASS_->throw($_exception_, \[%_args_\])

    Immediately rethrows an existing exception object as an other exception class.

        eval { open $f, "w", "/etc/passwd" or Exception::System->throw };
        # convert Exception::System into Exception::Base
        Exception::Base->throw($@);

- _CLASS_->catch(\[$_variable_\])

    The exception is recovered from _variable_ argument or `$@` variable if
    _variable_ argument was empty.  Then also `$@` is replaced with empty string
    to avoid an endless loop.

    The method returns an exception object if exception is caught or undefined
    value otherwise.

        eval { Exception::Base->throw; };
        if ($@) {
            my $e = Exception::Base->catch;
            print $e->to_string;
        }

    If the value is not empty and does not contain the `Exception::Base` object,
    new exception object is created with class _CLASS_ and its message is based
    on previous value with removed `" at file line 123."` string and the last end
    of line (LF).

        eval { die "Died\n"; };
        my $e = Exception::Base->catch;
        print ref $e;   # "Exception::Base"

- matches(_that_)

    Checks if the exception object matches the given argument.

    The `matches` method overloads `~~` smart matching operator.  Warning: The
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

    If argument is a numeric value, the argument matches if `value` attribute
    matches.

        eval { Exception::Base->throw( value=>123, message=>456 ) } );
        print $@->matches( 123 );                                # matches
        print $@->matches( 456 );                                # doesn't

    If an attribute contains array reference, the array will be `sprintf`-ed
    before matching.

        eval { Exception::Base->throw( message=>["%s", "Message"] ) };
        print $@->matches( "Message" );                          # matches
        print $@->matches( qr/Message/ );                        # matches
        print $@->matches( qr/[0-9]/ );                          # doesn't

    The `match` method matches for special keywords:

    - -isa

        Matches if the object is a given class.

            eval { Exception::Base->new( message=>"Message" ) };
            print $@->matches( { -isa=>"Exception::Base" } );            # matches
            print $@->matches( { -isa=>["X::Y", "Exception::Base"] } );  # matches

    - -has

        Matches if the object has a given attribute.

            eval { Exception::Base->new( message=>"Message" ) };
            print $@->matches( { -has=>"Message" } );                    # matches

    - -default

        Matches against the default attribute, usually the `message` attribute.

            eval { Exception::Base->new( message=>"Message" ) };
            print $@->matches( { -default=>"Message" } );                # matches

- to\_string

    Returns the string representation of exception object.  It is called
    automatically if the exception object is used in string scalar context.  The
    method can be used explicitly.

        eval { Exception::Base->throw; };
        $@->{verbosity} = 1;
        print "$@";
        $@->verbosity = 4;
        print $@->to_string;

- to\_number

    Returns the numeric representation of exception object.  It is called
    automatically if the exception object is used in numeric scalar context.  The
    method can be used explicitly.

        eval { Exception::Base->throw( value => 42 ); };
        print 0+$@;           # 42
        print $@->to_number;  # 42

- to\_bool

    Returns the boolean representation of exception object.  It is called
    automatically if the exception object is used in boolean context.  The method
    can be used explicitly.

        eval { Exception::Base->throw; };
        print "ok" if $@;           # ok
        print "ok" if $@->to_bool;  # ok

- get\_caller\_stacktrace

    Returns an array of strings or string with caller stack trace.  It is
    implicitly used by `to_string` method.

- PROPAGATE

    Checks the caller stack and fills the `propagated_stack` attribute.  It is
    usually used if `die` system function was called without any arguments.

- \_collect\_system\_data

    Collects system data and fills the attributes of exception object.  This
    method is called automatically if exception if thrown or created by
    `new` constructor.  It can be overridden by derived class.

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

- \_make\_accessors

    Creates accessors for each attribute.  This static method should be called in
    each derived class which defines new attributes.

        package Exception::My;
        # (...)
        BEGIN {
          __PACKAGE__->_make_accessors;
        }

- package

    Returns the package name of the subroutine which thrown an exception.

- file

    Returns the file name of the subroutine which thrown an exception.

- line

    Returns the line number for file of the subroutine which thrown an exception.

- subroutine

    Returns the subroutine name which thrown an exception.

# SEE ALSO

Repository: [http://github.com/dex4er/perl-Exception-Base](http://github.com/dex4er/perl-Exception-Base)

There are more implementation of exception objects available on CPAN.  Please
note that Perl has built-in implementation of pseudo-exceptions:

    eval { die { message => "Pseudo-exception", package => __PACKAGE__,
                 file => __FILE__, line => __LINE__ };
    };
    if ($@) {
      print $@->{message}, " at ", $@->{file}, " in line ", $@->{line}, ".\n";
    }

The more complex implementation of exception mechanism provides more features.

- [Error](https://metacpan.org/pod/Error)

    Complete implementation of try/catch/finally/otherwise mechanism.  Uses nested
    closures with a lot of syntactic sugar.  It is slightly faster than
    `Exception::Base` module for failure scenario and is much slower for success
    scenario.  It doesn't provide a simple way to create user defined exceptions.
    It doesn't collect system data and stack trace on error.

- [Exception::Class](https://metacpan.org/pod/Exception::Class)

    More Perlish way to do OO exceptions.  It is similar to `Exception::Base`
    module and provides similar features but it is 10x slower for failure
    scenario.

- [Exception::Class::TryCatch](https://metacpan.org/pod/Exception::Class::TryCatch)

    Additional try/catch mechanism for [Exception::Class](https://metacpan.org/pod/Exception::Class).  It is 15x slower for
    success scenario.

- [Class::Throwable](https://metacpan.org/pod/Class::Throwable)

    Elegant OO exceptions similar to [Exception::Class](https://metacpan.org/pod/Exception::Class) and `Exception::Base`.
    It might be missing some features found in `Exception::Base` and
    [Exception::Class](https://metacpan.org/pod/Exception::Class).

- [Exceptions](https://metacpan.org/pod/Exceptions)

    Not recommended.  Abandoned.  Modifies `%SIG` handlers.

- [TryCatch](https://metacpan.org/pod/TryCatch)

    A module which gives new try/catch keywords without source filter.

- [Try::Tiny](https://metacpan.org/pod/Try::Tiny)

    Smaller, simpler and slower version of [TryCatch](https://metacpan.org/pod/TryCatch) module.

The `Exception::Base` does not depend on other modules like
[Exception::Class](https://metacpan.org/pod/Exception::Class) and it is more powerful than [Class::Throwable](https://metacpan.org/pod/Class::Throwable).  Also it
does not use closures as [Error](https://metacpan.org/pod/Error) and does not pollute namespace as
[Exception::Class::TryCatch](https://metacpan.org/pod/Exception::Class::TryCatch).  It is also much faster than
[Exception::Class::TryCatch](https://metacpan.org/pod/Exception::Class::TryCatch) and [Error](https://metacpan.org/pod/Error) for success scenario.

The `Exception::Base` is compatible with syntax sugar modules like
[TryCatch](https://metacpan.org/pod/TryCatch) and [Try::Tiny](https://metacpan.org/pod/Try::Tiny).

The `Exception::Base` is also a base class for enhanced classes:

- [Exception::System](https://metacpan.org/pod/Exception::System)

    The exception class for system or library calls which modifies `$!` variable.

- [Exception::Died](https://metacpan.org/pod/Exception::Died)

    The exception class for eval blocks with simple ["die" in perlfunc](https://metacpan.org/pod/perlfunc#die).  It can also
    handle [$SIG{\_\_DIE\_\_}](https://metacpan.org/pod/perlvar#SIG) hook and convert simple ["die" in perlfunc](https://metacpan.org/pod/perlfunc#die)
    into an exception object.

- [Exception::Warning](https://metacpan.org/pod/Exception::Warning)

    The exception class which handle [$SIG{\_\_WARN\_\_}](https://metacpan.org/pod/pervar#SIG) hook and
    convert simple ["warn" in perlfunc](https://metacpan.org/pod/perlfunc#warn) into an exception object.

# EXAMPLES

## New exception classes

The `Exception::Base` module allows to create new exception classes easily.
You can use ["import" in perlfunc](https://metacpan.org/pod/perlfunc#import) interface or [base](https://metacpan.org/pod/base) module to do it.

The ["import" in perlfunc](https://metacpan.org/pod/perlfunc#import) interface allows to create new class with new
read-write attributes.

    package Exception::Simple;
    use Exception::Base (__PACKAGE__) => {
      has => qw{ reason method },
      string_attributes => qw{ message reason method },
    };

For more complex exceptions you can redefine `ATTRS` constant.

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

# PERFORMANCE

There are two scenarios for ["eval" in perlfunc](https://metacpan.org/pod/perlfunc#eval) block: success or failure.
Success scenario should have no penalty on speed.  Failure scenario is usually
more complex to handle and can be significantly slower.

Any other code than simple `if ($@)` is really slow and shouldn't be used if
speed is important.  It means that any module which provides try/catch syntax
sugar should be avoided: [Error](https://metacpan.org/pod/Error), [Exception::Class::TryCatch](https://metacpan.org/pod/Exception::Class::TryCatch), [TryCatch](https://metacpan.org/pod/TryCatch),
[Try::Tiny](https://metacpan.org/pod/Try::Tiny).  Be careful because simple `if ($@)` has many gotchas which are
described in [Try::Tiny](https://metacpan.org/pod/Try::Tiny)'s documentation.

The `Exception::Base` module was benchmarked with other implementations for
simple try/catch scenario.  The results
(Perl 5.10.1 x86\_64-linux-thread-multi) are following:

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

The `Exception::Base` module was written to be as fast as it is
possible.  It does not use internally i.e. accessor functions which are
slower about 6 times than standard variables.  It is slower than pure
die/eval for success scenario because it is uses OO mechanisms which are slow
in Perl.  It can be a little faster if some features are disables, i.e. the
stack trace and higher verbosity.

You can find the benchmark script in this package distribution.

# BUGS

If you find the bug or want to implement new features, please report it at
[https://github.com/dex4er/perl-Exception-Base/issues](https://github.com/dex4er/perl-Exception-Base/issues)

The code repository is available at
[http://github.com/dex4er/perl-Exception-Base](http://github.com/dex4er/perl-Exception-Base)

# AUTHOR

Piotr Roszatycki &lt;dexter@cpan.org>

# LICENSE

Copyright (c) 2007-2015 Piotr Roszatycki &lt;dexter@cpan.org>.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See [http://dev.perl.org/licenses/artistic.html](http://dev.perl.org/licenses/artistic.html)
