package JSPL::Context;

use strict;
use warnings;

use Carp qw(croak);

use Scalar::Util qw(blessed weaken refaddr);

require JSPL::Script;

use overload '%{}' => sub { tie my %h, __PACKAGE__, $_[0]; \%h }, 
    fallback => 1;

my %Contexts;

our $CURRENT;

my %Flags = (
    'RaiseExceptions' => 1,
    'AutoTie' => 1,
    'ConvertRegExp' => 1,
    'Restricted' => 1,
    'ConstantsValue' => 1,
    'StrictEnable' => 0,
    'VOFixEnable' => 0,
    'XMLEnable' => 1,
);

$Flags{AnonFunFixEnable} = 0 if JSPL->does_support_anonfunfix;
$Flags{JITEnable} = 0 if JSPL->does_support_jit;

sub new {
    my $pkg = shift;
    my $runtime = shift;
    my $self = create($runtime, @_);
    my $id = $$self;
    $Contexts{$id} = $self;
    weaken($Contexts{$id});
    $self->{$_} = $Flags{$_} for keys %Flags;
    return $self;
}

sub _error_mangler {
    my $msg = shift;
    if($msg =~ /\n at -e line 0\n$/) {
	$msg =~ s/ at -e line 0\n$//;
    } elsif($msg =~ /at -e line 0/) {
	my $xpc = $Components::classes{'@mozilla.org/js/xpc/XPConnect;1'}
	    ->getService($Components::interfaces{'nsIXPConnect'});
	my $stf = $xpc->CurrentJSStack();
	$stf->QueryInterface($Components::interfaces{'nsIStackFrame'});
	my $end = "at " . $stf->filename . " line " . ($stf->lineNumber-1);
	$msg =~ s/at -e line 0/$end/;
    }
    warn($msg);
}

sub JSPL::_wrapctx {
    my $ictx = shift;
    my $prin = shift;
    my $stock = shift || 'stock';
    my $rt = bless JSPL::RawRT::create(0), 'JSPL::Runtime';
    eval "require JSPL::Runtime::\u$stock;"
	    or croak($@);
    my $self = $rt->create_context($stock, $ictx, $prin);
    $self->{"Restricted"} = 0;
    $Contexts{$$self} = $self; # Unweaken
    $SIG{__WARN__} = \&_error_mangler;
    warn("Imported context ready\n");
}

sub _destroy {
    my $ctx = shift;
    croak("Context $ctx not registered\n")
	unless exists $Contexts{$ctx};
    $Contexts{$ctx} = undef;
    delete $Contexts{$ctx};
}

sub eval {
    my ($self, $source, $name) = @_;
    $name ||= do {
	# Figure out name of script in case it isn't supplied to us
	my @caller = caller;
	"$caller[0] line $caller[2]";
    };
    if($^O eq 'MSWin32' && ref $source) {
	my $src = join '', <$source>;
	$source = $src;
    }
    if($] > 5.009) { # Avoid one stack frame
	@_ = ($self, undef, $source, $name);
	goto &jsc_eval;
    } else {
	$self->jsc_eval(undef, $source, $name);
    }
}

sub eval_file {
    $_[0]->jsc_eval(undef, undef, $_[1]);
}

sub id { ${$_[0]} }

sub find {
    my ($self, $context) = @_;
    return $context if ref $context;
    croak "Can't find context $context" unless $Contexts{$context};
    return $Contexts{$context};
}

sub current {
    $Contexts{$CURRENT} or croak("Not in a javascript context\n");
}

sub check_privileges {
    die "Not enough privileges\n" if $CURRENT && current->{Restricted};
}

sub call {
    my $self     = shift;
    my $function = shift;

    if($] > 5.009) { # Avoid one stack frame
	@_ = ($self, undef, $function, [ @_ ]);
	goto &jsc_call;
    } else {
	$self->jsc_call(undef, $function, [ @_ ]);
    }
}

# Functions for binding perl stuff into JS namespace
sub bind_value {
    my ($self, $name, $object) = @_;
    my @paths = split /\./, $name;
    my $dest = pop @paths;
    my $this = $self->get_global;
    for(@paths) {
	$this = defined($this->{$_})
	    ? $this->{$_}
	    : ($this->{$_} = $self->new_object($this));
	my $isvis = $self->jsvisitor($this) or next;
	$this = $isvis;
    }
    croak "${name} already exists, unbind it first" if exists $this->{$dest};
    $this->{$dest} = $object;
}

sub bind_object {
    croak "The value must be a perl object" unless blessed $_[2];
    goto &bind_value;
}

sub unbind_value {
    my ($self, $name) = @_;

    my @paths = split /\./, $name;
    $name = pop @paths;
    my $parent = join('.', @paths);
    $self->jsc_unbind_value($parent, $name);
}

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
    croak "Missing argument 'name'\n" unless exists $args{name};
    # TODO: fix    die "Argument 'name' must match /^[A-Za-z0-9_]+\$/" unless($args{name} =~ /^[A-Za-z0-9\_]+$/);

    # Check for func
    croak "Missing argument 'func'\n" unless exists $args{func};
    $args{func} = _resolve_method($args{func}) unless ref($args{func});
    croak "Argument 'func' is not a CODE reference\n"
	unless 'CODE' eq ref $args{func};

    $self->bind_value($args{name} => $args{func});
}

sub bind_class {
    my $self = shift;
    my %args = @_;
    require JSPL::PerlClass;
    my $jsclass = JSPL::PerlClass->new(@_);
    $jsclass->bind($self, undef);
}

sub bind_all {
    my $self = shift;
    my @extras = ref($_[0]) eq 'HASH' ? %{$_[0]} : @_;
    while(my($k, $v) = splice(@extras, 0, 2)) {
	$self->bind_value($k => $v);
    }
}

sub can { $_[0]->jsc_can(undef, $_[1]); }

sub _resolve_method {
    my ($inspect, $croak_on_failure) = @_;

    return undef if !defined $inspect;
    return $inspect if ref $inspect  eq 'CODE';

    my ($pkg, $method) = $inspect =~ /^(?:(.*)::)?(.*)$/;
    my $deep = 1;
    $pkg = caller($deep++) if !defined $pkg || $pkg eq q{};
    while($pkg && $pkg =~ /^JSPL::/) {
	$pkg = caller($deep++);
    }
    croak "Can't resolve ${method}" unless defined $pkg;

    my $callback = $pkg->can($method);
    croak "Can't resolve ${pkg}::${method}" if !defined $callback && $croak_on_failure;

    return $callback;
}

sub set_branch_handler {
    my ($self, $handler) = @_;
    croak "'set_branch_handler' not available" if(JSPL::does_support_opcb);
    $handler = _resolve_method($handler, 1);
    $self->jsc_set_branch_handler($handler);
}

sub compile {
    my ($self, $source, $name) = @_;
    $name ||= do {
	# Figure out name of script in case it isn't supplied to us
	my @caller = caller;
	"$caller[0] line $caller[2]";
    };

    local $self->{RaiseExceptions} = 0;
    JSPL::Script->new($self, undef, $source, $name);
}

sub compile_file {
    local $_[0]->{RaiseExceptions} = 0;
    JSPL::Script->new($_[0], undef, undef, $_[1]);
}

{
    my %options_by_tag = (
        strict  => scalar JSPL::_constant('JSOPTION_STRICT'),
        vofix   => scalar JSPL::_constant('JSOPTION_VAROBJFIX'), 
        xml     => scalar JSPL::_constant('JSOPTION_XML'),
    );
    $options_by_tag{anonfunfix} = scalar JSPL::_constant('JSOPTION_ANONFUNFIX')
	if JSPL->does_support_anonfunfix;
    $options_by_tag{jit} = scalar JSPL::_constant('JSOPTION_JIT')
	if JSPL->does_support_jit;

    sub get_options {
        my ($self) = @_;
        my $options = $self->jsc_get_options;
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
        
        $self->jsc_toggle_options($options);
    
        1;
    }

    sub TIEHASH { $_[1] }

    sub STORE {
	my($self, $key, $val) = @_;
	croak "There isn't a flag '$key' in context\n" unless exists $Flags{$key};
	if($key =~ /^(.+)Enable/) {
	    return if $JSPL::_gruntime; # Don't play with foreing context
	    my $op = lc($1);
	    my $ops = $self->jsc_get_options;
	    if($val) { $ops |= $options_by_tag{$op} }
	    else { $ops &= ~$options_by_tag{$op} }
	    $self->jsc_set_options($ops);
	    return;
	}
	$self->jsc_set_flag($key, $val + 0);
    }

    sub FETCH {
	my($self, $key) = @_;
	croak "There isn't a flag '$key' in context\n" unless exists $Flags{$key};
	if($key =~ /^(.+)Enable/) {
	    return if $JSPL::_gruntime; # Don't play with foreing context
	    my $op = lc($1);
	    my $ops = $self->jsc_get_options;
	    return $ops & $options_by_tag{$op} ? 1 : 0;
	}
	$self->jsc_get_flag($key);
    }
}

sub JSPL::_this {
    my $nthis = current->jsvisitor($JSPL::This);
    $nthis || $JSPL::This;
}

1;
__END__

=head1 NAME

JSPL::Context - An object in which we can execute JavaScript

=head1 SYNOPSIS

  use JSPL;

  my $ctx = JSPL::Runtime->new->create_context();

  # Add a function callable from javascript
  $ctx->bind_function(say => sub { print @_; });

  my $result = $ctx->eval($javascript_source);

=head1 DESCRIPTION

To interact with the SpiderMonkey JavaScript engine you need a JSPL::Context
instance. To create one you can use the method L<JSPL::Runtime/create_context>
or obtain the "stock" one with L<JSPL/stock_context>.

=head1 INTERFACE

=head2 INSTANCE METHODS

=over 4

=item get_global ( )

Returns the I<global object> associated with the JavaScript context, equivalent to
C<< $ctx->eval('this') >>

=item new_object ( )

Returns a newly born JavaScript Object. This is equivalent to
C<< $ctx->eval('({})') >>

=item get_controller ( )

Returns the L<JSPL::Controller> controller associated with the JavaScript
context.

=item bind_value ( $path => $value )

Defines a property with the given I<$path> and I<$value>.

I<$path> is a string that reference a property in the global object or a path to
deeper properties, creating empty Objects for any missing.

For example:

    $ctx->bind_value('foo' => $value); # Set 'foo' to $value

    $ctx->bind_value('foo.bar' => $value); # Create 'foo' as '{}' if needed
                                           # and set 'foo.bar' to $value

Trying to redefine an already existing property throws an exception, i.e. the last
component of I<$path> must not exists.

Returns C<$value>

=item bind_object ( $path => $value )

The same as L</bind_value> above, but check that I<$value> is an object (i.e. a
blessed reference), and throws otherwise.

=item bind_function ( name => $path, func => $subroutine )

=item bind_function ( $path => $subroutine )

Defines a Perl subroutine as a native function with the given I<$path>.
The argument $subroutine can either be the name of a subroutine or a reference 
to one.

The four arguments form should not be used in new code as can be deprecated in
the future.

=item bind_all ( $name1 => $value1, ... )

Calls C<bind_value> above for every pair of its arguments.  Allowing you to mass
populate the context.

=item unbind_value ( $path )

Remove a property from the context or a specified object.

=item call ( $name, @arguments )

=item call ( $function, @arguments )

Calls the JavaScript function named I<$name> or the L<JSPL::Function> instance
I<$function> and passes the rest of the arguments to the function.

=item can ( $name )

Check if in the context there is a function with a given I<$name>.
Returns a reference to the function if there otherwise returns C<undef>.

The return value, if TRUE, can be called:

    if(my $date = $ctx->can('Date')) { # 'Date' is there
	print $date->(time * 1000); # Now
    }

=item compile ( $source )

Compiles the javascript code given in I<$source>, and returns a
L<JSPL::Script> instance that can be executed over and over again without
paying the compilation overhead every time.

If a compilation error occurs returns undef and sets $@.

=item compile_file ( $file_name )

Compiles the javascript code in I<$file_name>, returns a
L<JSPL::Script> instance that can be executed over and over again without
paying the compilation overhead every time.

If a compilation error occurs returns C<undef> and sets C<$@>.

=item eval ( $source )

Evaluates the javascript code given in I<$source> and returns the result from
the last statement. Any uncaught exception in JavaScript will cause a C<croak>.
See L</RaiseExceptions>

=item eval_file ( $path )

Evaluates the javascript code in the file specified by I<$path> and returns the
result from the last statement.

If there is a compilation error (such as a syntax error) or an uncaught
exception is thrown in javascript this method returns C<undef> and C<$@> is set.

=item bind_class ( $jsclass )

Bind a native class created L<with JSPL::PerlClass>

=item check_privileges ( )

To be used inside perl code called from javascript. Check that the
context isn't restricted, otherwise dies with the error "Not enough privileges";

=item set_branch_handler ( $handler )

[ B<DEPRECATED>. The support API was removed from SpiderMonkey v1.8+, calling
C<set_branch_handler> in that case will thrown a fatal error.
See L<JSPL::Context::Timeout> for a supported way to control a runaway script. ]

Attaches a branch callback handler (a function that is called when a branch is
performed) to the context. The argument I<$handler> may be a code-reference or
the name of a subroutine.

To remove the handler call this method with an undefined argument.

The handler is called when a script branches backwards during execution, when a
function returns and the end of the script. To continue execution the handler
must return a true value. To abort execution either throw an exception or
return a false value.

=item id ( )

Returns the "Context ID" of the calling context. Every context has an integer
associated with it that can be used to identify a particular context.

See L</find>.

=item get_version ( )

Returns the runtime version of the context as a string, for example C<1.7> or
or C<ECMAv3>.

=item set_version ( $version )

Sets the runtime version of the context to that specified in the string
I<$version>. Some features such as C<let> and C<yield> might not be enabled by
default and thus must be turned on by specifying what JavaScript engine version
we're using.

A list of these can be found at
L<http://developer.mozilla.org/en/docs/JSVersion> but may vary depending on the
version of your runtime.

=back

=head2 CLASS METHODS

There are available the following class methods

=over 4

=item find ( $ContextId )

Returns the C<JSPL::Context> object associated with a given I<$ContextId>
if exists or C<undef> if not.

See L</id>.

=item current ( )

Returns the current JSPL::Context object.

To be used by perl subroutines designed to be called by javascript land when
they need the context with in they are being called.

When there aren't an active context, it dies with the error
"Not in a javascript context".

=item jsvisitor (REFERENCE_TO_SOMETHING)

Returns the L<JSPL::Visitor> associated to the perl "thing" for which
I<REFERENCE_TO_THING> is a reference for, if any. Otherwise returns C<undef>.

I<REFERENCE_TO_SOMETHING> can be a reference to anything.

=back

=head2	CONTEXT OPTIONS

There are a few options that change the operation of the context,
those can be manipulated using the context handle as a HASH reference,
all options are booleans so any value setted will be TRUE or FALSE as by
perl rules and can be made C<local> for localized changes.

  {
    local $ctx->{OptionFoo} = 1;
    # This code uses a TRUE OptionFoo;
    ...
  }
  # From here, OptionFoo uses its previous value
  ...

The currently defined options are:

=over 4

=item AutoTie

If TRUE the wrapped instances of C<Array> or C<Object> when returned to
perl will be automatically I<tied> in real perl ARRAYs or HASHes, and your perl
code will not see instances of L<JSPL::Object> or L<JSPL::Array> unless you
explicitly use the C<tied> perl function.

When FALSE the wrapper instances will be returned directly.

The default value is TRUE

=item ConstantsValue

If TRUE perl's "Constant Functions" defined in perl namespaces, when reflected
to javascript will be seen as true constants attributes. When FALSE they will
be seen as normal functions, so to obtain its values they must be called.

The default value is TRUE

=item ConvertRegExp

If TRUE all instances of javascript C<RegExp> will be converted to perl
RegExp, when FALSE they will be wrapped in L<JSPL::Object> instances in the
normal way.

The default value is TRUE

=item RaiseExceptions

When TRUE all I<untrapped> exceptions in javascript space will raise a perl
fatal exception.  Set it to FALSE cause that exceptions results in only setting
C<$@> and the operation returns C<undef>.

The default value is TRUE

=item StrictEnable

Warn on dubious practice. Defaults to FALSE.

=item XMLEnable

In E4X (ECMAScript for XML) parse C<E<lt>!-- --E<gt>> as a token.
Defaults to TRUE.

=item JITEnable

Enable JIT compilation. Requires a SpiderMonkey with TraceMonkey.
Defaults to FALSE.

=back

=begin PRIVATE

=head1 PRIVATE INTERFACE

=over 4

=item new ( $runtime )

Creates a new C<JSPL::Context>-object in the supplied runtime.

=item create ( $runtime )

Creates a new context in JSPL::Runtime $runtime returns it.

=item get_options ( )

Returns a list of the SpiderMonkey engine options currently enabled on the context.

=item has_options ( OPTION, ... )

Tests if the SpiderMonkey engine options are enabled on the context.

=item toggle_options ( OPTION, ... )

Toggles the SpiderMonkey engine options on the context.

=item jsc_call ( PJS_Context *context, PSObject *this, SV *function, SV *args)

Calls the function defined in I<function> with the arguments passed as an array
reference in I<args>. In the javascript side the function is called as a
instance of I<this>, or the global object if I<this> is NULL. The argument
I<function> can either be a string (SVt_PV) or an C<JSPL::Function>
object. Returns the return value from the called function. If the function
doesn't exist or a uncaught exception is thrown it returns undef and sets $@.

=item jsc_can ( PJS_Context *context, char *name )

Checks if the function defined by I<name> exists in the context and if so
returns 1, otherwise it returns 0.

=item jsc_eval ( PJS_Context *context, PJS_Object *this, char *source, char *name )

Evalutes the javascript code given in I<source> in the context of I<this> or
the global object if I<this> is NULL and returns the result from the last
executed statement. The argument I<name> defines the name of the script to be
used when reporting errors. If an error occures such as a compilation error
(maybe due to syntax error) or an uncaught exception is thrown it returns undef
and sets $@.

=item jsc_free_root ( PJS_Context *context, SV *root )

Removes the root on the javascript variable boxed by I<root> that prevents it
from being garbage collected by the runtime.

=item jsc_unbind_value ( PJS_Context *context, char *parent, char *name)

Removes a new named property in I<parent>.

=item jsc_set_branch_handler ( PJS_Context *context, SV *handler )

Attaches a branch handler to the context.

=item jsc_begin_request

TBD

=item jsc_end_request

TBD

=item jsc_get_version ( PJS_Context *context )

Returns the version of the context as a string, for example "1.7"

=item jsc_set_version ( PJS_Context *context, const char *version) 

Set the version of the context to the one specified in version.

=item jsc_get_options ( PJS_Context *context )

Returns the options set on the undelying JSContext

=item jsc_set_options ( PJS_Context *context, U32 options)

Set the requested options

=item jsc_toggle_options ( PJS_Context *context, U32 options )

Toggle the options on the underlying JSContext

=item jsc_rta ( PJS_Context *context )

Returns the JSPL::Runtime that created this context.

=item jsc_set_flag ( PJS_Context *ctx, flag, value )

Set context flags

=item jsc_get_flag ( PJS_Context *ctx, flag )

Get context flags

=back

=end PRIVATE

=cut
