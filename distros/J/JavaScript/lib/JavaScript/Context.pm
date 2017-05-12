package JavaScript::Context;

use strict;
use warnings;

use Carp qw(croak);
use Scalar::Util qw(weaken refaddr);

use JavaScript;

my %Context;
my %Runtime;

sub new {
    my ($pkg, $runtime) = @_;

    my $self = jsc_create($runtime->{_impl});

    my $ptr = $self->jsc_ptr;
    
    $Context{$ptr} = $self;
    weaken($Context{$ptr});
    $Runtime{$ptr} = $runtime;
    
    return $self;
}

sub eval {
    my ($self, $source, $name) = @_;

    # Figure out name of script in case it isn't supplied to us
    my @caller = caller();
    $name ||= "$caller[0] line $caller[2]";
    
    my $rval = jsc_eval($self, $source, $name);

    return $rval;
}

sub set_pending_exception {
    my ($self, $exception) = @_;

    if(!defined($exception)){
        return;
    }
    my $rval = jsc_set_pending_exception($self, $exception); 

    return $rval;
}

sub eval_file {
    my ($self, $file) = @_;

    local $/ = undef;

    open my $in, "<$file" || die $!;
    my $source = <$in>;
    close($in);

    my $rval = jsc_eval($self, $source, $file);

    return $rval;
}

sub find {
    my ($self, $context) = @_;

    my $ptr = ref $context ? $context->ptr : $context;
    
    if (!exists $Context{$ptr}) {
        croak "Can't find context $context";
    }
    
    return $Context{$ptr};
}

sub call {
    my $self     = shift;
    my $function = shift;
    my $args     = [@_];
    
    return jsc_call($self, $function, $args);
}

sub can {
    my ($self, $method) = @_;

    return jsc_can($self, $method);
}

# Functions for binding perl stuff into JS namespace
sub bind_function {
    my $self = shift;
    my %args;

    # Handle 2 arg declaration and old 4 arg declaration
    if (@_ == 2) {
        %args = (name => shift, func => shift);
    }
    else {
        %args = @_;
    }

    # Check for name
    die "Missing argument 'name'\n" unless(exists $args{name});
    # TODO: fix    die "Argument 'name' must match /^[A-Za-z0-9_]+\$/" unless($args{name} =~ /^[A-Za-z0-9\_]+$/);

    # Check for func
    die "Missing argument 'func'\n" unless(exists $args{func});
    die "Argument 'func' is not a CODE reference\n" unless(ref($args{func}) eq 'CODE');

    $self->bind_value($args{name} => $args{func});

    return;
}

sub _resolve_method {
    my ($inspect, $croak_on_failure) = @_;

    return undef if !defined $inspect;
    return $inspect if ref $inspect  eq 'CODE';

    my ($pkg, $method) = $inspect =~ /^(?:(.*)::)?(.*)$/;
    $pkg = caller(1) if !defined $pkg || $pkg eq q{};
    $pkg = caller(2) if $pkg eq 'JavaScript::Context';

    my $callback = $pkg->can($method);
    croak "Can't resolve ${pkg}::${method}" if !defined $callback && $croak_on_failure;

    return $callback;
}

sub _extract_methods {
    my ($args, @arg_keys) = @_;

    my $method = {};

    for my $arg (@arg_keys) {
        if (exists $args->{$arg} && defined $args->{$arg}) {
            my $arg = $args->{$arg};
            
            if (ref $arg eq 'HASH') {
                for my $name (keys %$arg) {
                    $method->{$name} = _resolve_method($arg->{$name}, 1);
                }
            }
            elsif(ref $arg eq 'ARRAY') {
                for my $name (@$arg) {
                    $method->{$name} = _resolve_method($name, 1);
                }
            }
            else {
                my @methods = split /\s+/, $arg;
                for my $name (@methods) {
                    $method->{$name} = _resolve_method($name, 1);
                }
            }
        }
    }

    return $method;
}

sub _extract_properties {
    my ($args, @arg_keys) = @_;

    my $property = {};

    for my $arg (@arg_keys) {
        if (exists $args->{$arg} && defined $args->{$arg}) {
            my $arg = $args->{$arg};

            if (ref $arg eq 'HASH') {
                for my $name (keys %{$arg}) {
                    if (ref $arg->{$name} eq 'HASH') {
                        my $getter = _resolve_method($arg->{$name}->{getter}, 1);
                        my $setter = _resolve_method($arg->{$name}->{setter}, 1);
                        $property->{$name} = [ $getter, $setter ];
                    }
                    elsif (ref $arg->{$name} eq 'ARRAY') {
                        my @callbacks = @{$arg->{$name}};
                        my $getter = _resolve_method(shift @callbacks, 1);
                        my $setter = _resolve_method(shift @callbacks, 1);
                        $property->{$name} = [ $getter, $setter ];
                    }
                    elsif (ref $arg->{$name} eq '') {
                        my $getter = sub {
                            return $_[0]->{$name};
                        };

                        my $setter = !($arg->{$name} & JS_PROP_READONLY) ? sub {
                            $_[0]->{$name} = $_[1];
                        } :  undef;

                        $property->{$name} = [ $getter, $setter ];
                    }
                }
            }
            elsif (ref $arg eq 'ARRAY') {
                
            }
            else {
                my @properties = split /\s+/, $arg;
                for my $name (@properties) {
                }
            }
        }
    }

    return $property;
}

sub bind_class {
    my $self = shift;
    my %args = @_;
    
    # Check if name argument is valid
    die "Missing argument 'name'\n" unless(exists $args{name});
    die "Argument 'name' must match /^[A-Za-z0-9_]+\$/" unless($args{name} =~ /^[A-Za-z0-9\_]+$/);
    
    # Check if constructor is supplied and it's an coderef
    my $cons; 
    $cons = _resolve_method($args{constructor}, 1) if exists $args{constructor};
    
    if (exists $args{flags}) {
        die "Argument 'flags' is not numeric\n" unless($args{flags} =~ /^\d+$/);
    } else {
        $args{flags} = 0;
    }
    
    unless (exists $args{package}) {
        $args{package} = undef;
    }
    
    my $name = $args{name};
    my $pkg = $args{package} || $name;
    
    # Create a default constructor
    if (!defined $cons) {
        $cons = sub {
            $pkg->new(@_);
        };
    }
    
    # Per-object methods
    my $fs = _extract_methods(\%args, qw(methods fs));

    # Per-class methods
    my $static_fs = _extract_methods(\%args, qw(static_methods static_fs));

    # Per-object properties
    my $ps = _extract_properties(\%args, qw(properties ps));

    # Per-class properties
    my $static_ps = _extract_properties(\%args, qw(static_properties static_ps));

    # Flags
    my $flags = $args{flags};
    
    jsc_bind_class($self, $name, $pkg, $cons, $fs, $static_fs, $ps, $static_ps, $flags);
    
    return;
}

sub bind_object {
    my ($self, $name, $object) = @_;

    $self->bind_value($name => $object);

    return;
}

sub bind_value {
    my ($self, $name, $object, $opt) = @_;

    my @paths = split /\./, $name;
    my $current;
    for my $num (0..$#paths) {
        my $parent = join('.', @paths[0..$num-1]);
        my $abs = join('.', @paths[0..$num]);

        if($self->eval($abs)) {
            # We don't want to be able to rebind without unbinding first
            croak "${name} already exists, unbind it first" if $num == $#paths;

            next;
        } else {
          $@ = undef;
        }
        
        jsc_bind_value($self, $parent,
                       $paths[$num], $num == $#paths ? $object : {});
    }
    
    return;
}

sub unbind_value {
    my ($self, $name, $object, $opt) = @_;

    my @paths = split /\./, $name;
    $name = pop @paths;
    my $parent = join(".", @paths);
    jsc_unbind_value($self, $parent, $name);
}

sub set_branch_handler {
    my ($self, $handler) = @_;

    $handler = _resolve_method($handler, 1);

    jsc_set_branch_handler($self, $handler);
}

sub compile {
    my $self = shift;
    my $source = shift;

    my $script = JavaScript::Script->new($self, $source);
    return $script;
}

sub get_version {
    my ($self, $version) = @_;
    return jsc_get_version($self);
}

sub set_version {
    my ($self, $version) = @_;
    jsc_set_version($self, $version);
    1;
}


{
    my %options_by_tag = (
        strict  => 1,
        xml     => 1 << 6,
        jit     => 1 << 11,
    );

    sub get_options {
        my ($self) = @_;
        my $options = jsc_get_options($self);
        return grep { $options & $options_by_tag{$_} } keys %options_by_tag;
    }
    
    sub has_options {
        my $self = shift;
    
        my %options = map { $_ => 1 } $self->get_options;
        
        !exists $options{$_} && return 0 for @_;

        return 1;
    }
    
    sub toggle_options {
        my $self = shift;
        
        my $options = 0;
        for (@_) {
            $options |= 1 if exists $options_by_tag{lc $_};
        }
        
        jsc_toggle_options($self, $options);
        
        1;
    }
}

sub _destroy {
    my $self = shift;
    return unless $self;
    my $ptr = $self->jsc_ptr;
    return unless exists $Context{$ptr};
    delete $Context{$ptr};
    jsc_destroy($self);

    delete $Runtime{$ptr};
    
    return 1;
}

sub DESTROY {
  my $self = shift;
  $self->_destroy();
}

END {
    while (my ($k, $v) = %Context) {
        if ($Context{$k}) {
            delete $Context{$k};
            $v->_destroy();
        }
    }
}

1;
__END__

=head1 NAME

JavaScript::Context - An object in which we can execute JavaScript

=head1 SYNOPSIS

  use JavaScript;

  # Create a runtime and a context
  my $rt = JavaScript::Runtime->new();
  my $cx = $rt->create_context();

  # Add a function which we can call from JavaScript
  $cx->bind_function(print => sub { print @_; });

  my $result = $cx->eval($source);

=head1 INTERFACE

=head2 INSTANCE METHODS

=over 4

=item bind_class ( %args )

Defines a new class that can be used from JavaScript in the contet.

It expects the following arguments

=over 4

=item name

The name of the class in JavaScript.

  name => "MyPackage",

=item constructor

A reference to a subroutine that returns the Perl object that represents
the JavaScript object. If omitted a default constructor will be supplied that
calls the method C<new> on the defined I<package> (or I<name> if no package is
defined).

  constructor => sub { MyPackage->new(@_); },

=item package

The name of the Perl package that represents this class. It will be passed as
first argument to any class methods and also used in the default constructor.

  package => "My::Package",

=item methods (fs)

A hash reference of methods that we define for instances of the class. In JavaScript this would be C<o = new MyClass(); o.method()>.

The key is used as the name of the function and the value should be either a reference to a subroutine or the name of the Perl subroutine to call.

  methods => { to_string => \&My::Package::to_string,
               random    => "randomize"
  }

=item static_methods (static_ps)

Like I<fs> but these are called on the class itself. In JavaScript this would be C<MyClass.method()>.

=item properties (ps)

A hash reference of properties that we define for instances of the class. In JavaScript this would be C<o = new MyClass(); f = o.property;>

The key is used as the name of the property and the value is used to specify what method to call as a get-operation and as a set-operation.
These can either be specified using references to subroutines or name of subroutines.
If the getter is undefined the property will be write-only and if the setter is undefined the property will be read-only.
You can specify the getter/setter using either an array reference, C<[\&MyClass::get_property, \&MyClass::set_property]>, a string, C<"MyClass::set_property MyClass::get_property"> or a hash reference, C<{ getter => "MyClass::get_property", setter => "MyClass::set_property" }>.

  ps => { length => [qw(get_length)],
          parent => { getter => \&MyClass::get_parent, setter => \&MyClass::set_parent },
        }

=item static_properties (static_ps)

Like I<ps> but these are defined on the class itself. In JavaScript this would be C<f = MyClass.property>.

=item flags

A bitmask of attributes for the class. Valid attributes are:

=over 4

=item JS_CLASS_NO_INSTANCE

Makes the class throw an exception if JavaScript tries to
instansiate the class.

=back

=back

=item bind_function ( name => $name, func => $subroutine )

=item bind_function ( $name => $subroutine )

Defines a Perl subroutine ($subroutine_ref) as a native function with the given I<$name>. The argument $subroutine can either be the name of a subroutine or a reference to one.

=item bind_object ( $name => $object )

Binds a Perl object to the context under a given name.

=item bind_value ( $name => $value )

Defines a value with a given name and value. Trying to redefine an already existing property throws an exception.

=item unbind_value ( $name )

Removed a property from the context or a specified object.

=item call ( $name, @arguments )

=item call ( $function, @arguments )

Calls a function with the given name I<$name> or the B<JavaScript::Function>-object
I<$function> and  passes the rest of the arguments to the JavaScript function.

=item can ( $name )

Returns true if there is a function with a given I<$name>, otherwise it returns false.

=item compile ( $source )

Pre-compiles the JavaScript given in I<$source> and returns a C<JavaScript::Script>-object that can be executed over and over again. If an error occures because of a compilation error it returns undef and $@ is set.

=item eval ( $source )

Evaluates the JavaScript code given in I<$source> and
returns the result from the last statement.

If there is a compilation error (such as a syntax error) or an uncaught exception
is thrown in JavaScript this method returns undef and $@ is set.

=item eval_file ( $path )

Evaluates the JavaScript code in the file specified by I<$path> and
returns the result from the last statement.

If there is a compilation error (such as a syntax error) or an uncaught exception
is thrown in JavaScript this method returns undef and $@ is set.

=item find ( $native_context )

Returns the C<JavaScript::Context>-object associated with a given native context.

=item set_branch_handler ( $handler )

Attaches an branch callback handler (a function that is called when a branch is performed) to the context. The argument I<$handler> may be a code-reference or the name of a subroutine.

To remove the handler call this method with an undefined argument.

The handler is called when a script branches backwards during execution, when a function returns and the end of the script. To continue execution the handler must return a true value. To abort execution either throw an exception or return a false value.

=item set_pending_exception ( $value )

Converts the I<$value> to JavaScript and sets it as the pending exception for the context. 

=item get_version ( )

Returns the runtime version of the context as a string, for exmaple C<1.7> or or C<ECMAv3>.

=item set_version ( $version )

Sets the runtime version of the context to that specified in the string I<$version>. Some features 
such as C<let> and C<yield> might not be enabled by default and thus must be turned on by 
specifying what JS version we're using.

A list of these can be found at L<http://developer.mozilla.org/en/docs/JSVersion> but may vary 
depending on the version of your runtime.

=item get_options ( )

Returns a list of the options currently enabled on the context.

=item has_options ( OPTION, ... )

Tests if the options are eneabled on the context.

=item toggle_options ( OPTION, ... )

Toggles the options on the context.

=back

=head2 OPTIONS

A number of options can be set on contexts. The following are understood (case-insensitive):

=over 4

=item strict

Warn on dubious practice.

=item xml

ECMAScript for XML (E4X) support: parse E<lt>!-- --E<gt> as a token, not backward compatible with the comment-hiding hack used in HTML script tags.

=item jit

Enable JIT compilation. Requires a SpiderMonkey with TraceMonkey.

=back

(Descriptions copied from jsapi.h and thus copyrighted under its license)

=begin PRIVATE

=head1 PRIVATE INTERFACE

=over 4

=item new ( $runtime )

Creates a new C<JavaScript::Context>-object in the supplied runtime.

=item jsc_create ( PCB_Runtime *runtime )

Creates a new context and returns a pointer to a C<PJS_Context> structure.

=item jsc_destroy ( PJS_Context *context )

Destroys the context and deallocates the memory occupied by it.

=item jsc_call ( PJS_Context *context, SV *function, SV *args)

Calls the function defined in I<function> with the arguments passed as an array reference in I<args>. The argument I<function> can either be a string (SVt_PV) or an C<JavaScript::Function> object. Returns the return value from the called function. If the function doesn't exist or a uncaught exception is thrown it returns undef and sets $@.

=item jsc_call_in_context ( PJS_Context *context, SV *function, SV *args, SV *rcx, char *class)

TDB

=item jsc_can ( PJS_Context *context, char *name )

Checks if the function defined by I<name> exists in the context and if so returns 1, otherwise it returns 0.

=item jsc_eval ( PJS_Context *context, char *source, char *name )

Evalutes the JavaScript code given in I<source> and returns the result from the last executed statement. The argument I<name> defines the name of the script to be used when reporting errors. If an error occures such as a compilation error (maybe due to syntax error) or an uncaught exception is thrown it returns undef and sets $@.

=item jsc_free_root ( PJS_Context *context, SV *root )

Removes the root on the JavaScript variable boxed by I<root> that prevents it from being garbage collected by the runtime.

=item jsc_bind_class ( PJS_Context *context, char *name, SV *constructor, SV *methods, SV *properties, SV *package, SV *flags )

Binds a class to the context.

=item jsc_bind_function ( PJS_Context *context, char *name, SV *function )

Binds a function to the context.

=item jsc_bind_value ( PJS_Context *context, char *parent, char *name, SV *object)

Defines a new named property in I<parent> with the value of I<object>.

=item jsc_unbind_value ( PJS_Context *context, char *parent, char *name)

Removes a new named property in I<parent>.

=item jsc_set_branch_handler ( PJS_Context *context, SV *handler )

Attaches a branch handler to the context. No check is made to see if I<handler> is a valid SVt_PVCV.

=item jsc_get_version ( PJS_Context *context )

Returns the version of the context as a string, for example "1.7"

=item jsc_set_version ( PJS_Context *context, const char *version) 

Set the version of the context to the one specified in version.

=item jsc_get_options ( PJS_Context *context )

Returns the options set on the undelying JSContext

=item jsc_toggle_options ( PJS_Context *context, U32 options )

Toggle the options on the underlying JSContext

=item jsc_ptr ( PJS_Context *context )

Return the address of the context for identification purposes.

=item jsc_set_pending_exception ( PJS_Context *context, SV *exception )

Set a pending exception on the context

=back

=end PRIVATE

=cut
