package JE::Object::Function;

our $VERSION = '0.066';


use strict;
use warnings; no warnings 'utf8';
use Carp                 ;
use Scalar::Util 'blessed';

use overload
	fallback => 1,
	'&{}' => sub {
		my $self = shift;
		sub {
			my $ret = $self->call($self->global->upgrade(@_));
			typeof $ret eq 'undefined' ? undef : $ret
		}
	 };

our @ISA = 'JE::Object';

require JE::Code         ;
require JE::Number          ;
require JE::Object              ;
require JE::Object::Error::TypeError;
require JE::Parser                    ;
require JE::Scope                      ;

import JE::Code 'add_line_number';
sub add_line_number;

=head1 NAME

JE::Object::Function - JavaScript function class

=head1 SYNOPSIS

  use JE::Object::Function;

  # simple constructors:

  $f = new JE::Object::Function $scope, @argnames, $function;
  $f = new JE::Object::Function $scope, $function;

  # constructor that lets you do anything:

  $f = new JE::Object::Function {
          name             => $name,
          scope            => $scope,
          length           => $number_of_args,
          argnames         => [ @argnames ],
          function         => $function,
          function_args    => [ $arglist ],
          constructor      => sub { ... },
          constructor_args => [ $arglist ],
          downgrade        => 0,
  };


  $f->(@args);
  $f->call_with($obj, @args);

=head1 DESCRIPTION

All JavaScript functions are instances of this class. If you want to call
a JavaScript function from Perl, just treat is as a coderef (C<< $f->() >>)
or use the C<call_with> method (C<< $f->call_with($obj, @args) >>) if you
want to specify the invocant (the 'this' value).

=head1 OBJECT CREATION

=over 4

=item new 

Creates and returns a new function (see the next few items for its usage).
The new function will have a C<prototype> property that is an object with
a C<constructor> property that refers to the function itself.

The return value of the function will be upgraded if necessary (see 
L<UPGRADING VALUES|JE::Types/UPGRADING VALUES> in the JE::Types man page),
which is why C<new> I<has> to be given a reference to the global object
or the scope chain. (But see also L<JE/new_function> and L<JE/new_method>.)

A function written in Perl can return an lvalue if it wants to. Use
S<< C<new JE::LValue($object, 'property name')> >> to create it. To create 
an lvalue 
that
refers to a variable visible within the function's scope, use
S<< C<<< $scope->var('varname') >>> >> (this assumes that you have
shifted the scope object off C<@_> and called it C<$scope>; you also need
to call C<new> with hashref syntax and specify the C<function_args> [see
below]).

=item new JE::Object::Function $scope_or_global, @argnames, $function;

=item new JE::Object::Function $scope_or_global, $function;

C<$scope_or_global> is one of the following:

  - a global (JE) object
  - a scope chain (JE::Scope) object

C<@argnames> is a list of argument names, that JavaScript functions use to access the arguments.

$function is one of

  - a string containing the body of the function (JavaScript code)
  - a JE::Code object
  - a coderef

=item new JE::Object::Function { ... };

This is the big fancy way of creating a function that lets you do anything.
The elements of the hash ref passed to C<new> are as follows (they are
all optional, except for C<scope>):

=over 4

=item name

The name of the function. This is used only by C<toString>.

=item scope

A global object or scope chain object.

=item length

The number of arguments expected. If this is omitted, the number of
elements of C<argnames> will be used. If that is omitted, 0 will be used.
Note that this does not cause the argument list to be checked. It only
provides the C<length> property (and possibly, later, an C<arity> property)
for inquisitive scripts to look at.

=item argnames

An array ref containing the variable names that a JS function uses to 
access the 
arguments.

=item function

A coderef, string of JS code or JE::Code object (the body of the function).

This will be run when the function is called from JavaScript without the
C<new> keyword, or from Perl via the C<call> method.

=item function_args

This only applies when C<function> is a code ref. C<function_args> is an 
array ref, the elements being strings that indicated what arguments should
be passed to the Perl subroutine. The strings, and what they mean, are
as follows:

  self    the function object itself
  scope   the scope chain
  global  the global object
  this    the invocant
  args    the arguments passed to the function (as individual
          arguments)
  [args]  the arguments passed to the function (as an array ref)

If C<function_args> is omitted, 'args' will be assumed.

=item constructor

A code ref that creates and initialises a new object. This is called when
the C<new> keyword is used in JavaScript, or when the C<construct> method
is used in Perl.

If this is omitted, when C<new> or C<construct> is used, a new empty object 
will be created and passed to the
sub specified under C<function> as its 'this' value. The return value of 
the sub will be
returned I<if> it is an object; the (possibly modified) object originally
passed to the function will be returned otherwise.

=item constructor_args

Like C<function_args>, but the C<'this'> string does not apply. If 
C<constructor_args> is
omitted, the arg list will be set to
C<[ qw( scope args ) ]> (B<this might change>).

This is completely ignored if C<constructor> is
omitted.

=item downgrade (not yet implemented)

This applies only when C<function> or C<constructor> is a code ref. This
is a boolean indicating whether the arguments to the function should have 
their C<value> methods called automatically.; i.e., as though
S<<< C<< map $_->value, @args >> >>> were used instead of C<@args>.

=item no_proto

If this is set to true, the returned function will have no C<prototype>
property.

=back

=back

=head1 METHODS

=over 4

=item new JE::Object::Function

See L<OBJECT CREATION>.

=cut

sub new {
	# E 15.3.2
	my($class,$scope) = (shift,shift);
	my %opts;

	if(ref $scope eq 'HASH') {
		%opts = %$scope;
		$scope = $opts{scope};
	}
	else {
		%opts = @_ == 1  # bypass param-parsing for the sake of
		                 # efficiency
		? 	( function => shift )
		: 	( argnames => do {
				my $src = '(' . join(',', @_[0..$#_-1]) .
					')';
				$src =~ s/\p{Cf}//g;
				# ~~~ What should I do here for the file
				#     name and the starting line number?
				my $params = JE::Parser::_parse(
					params => $src, $scope
				);
				$@ and die $@;
				$params;
			  },
			  function => pop )
		;
	}

	defined blessed $scope
	    or croak "The 'scope' passed to JE::Object::Function->new (" .
		(defined $scope ? $scope : 'undef') . ") is not an object";

# ~~~ I should be able to remove the need for this to be a JE::Scope. Per-
#     haps it could be an array ref instead. That way, the caller won’t
#     have to bless something that we copy & bless further down anyway.
#     Right now, other parts of the code base rely on it, so it would
#     require a marathon debugging session.
	ref $scope ne 'JE::Scope' and $scope = bless [$scope], 'JE::Scope';
	my $global = $$scope[0];

	my $self = $class->SUPER::new($global, {
		prototype => $global->prototype_for('Function')
	});
	my $guts = $$self;

	$$guts{scope} = $scope;


	$opts{no_proto} or $self->prop({
		name     => 'prototype',
		dontdel  => 1,
		value    => JE::Object->new($global),
	})->prop({
		name     => 'constructor',
		dontenum => 1,
		value    => $self,
	});

	{ no warnings 'uninitialized';

	$$guts{function} =
	  ref($opts{function}) =~ /^(?:JE::Code|CODE)\z/ ? $opts{function}
	: length $opts{function} &&
		(
		  parse $global $opts{function} or die
		)
	;

	$self->prop({
		name     => 'length',
		value    => JE::Number->new($global, $opts{length} ||
		            (ref $opts{argnames} eq 'ARRAY'
		                ? scalar @{$opts{argnames}} : 0)),
		dontenum => 1,
		dontdel  => 1, 
		readonly => 1,
	});

	} #warnings back on

	$$guts{func_argnames} = [
		ref $opts{argnames} eq 'ARRAY' ? @{$opts{argnames}} : ()
	];
	$$guts{func_args} = [
		ref $opts{function_args} eq 'ARRAY'
		? @{$opts{function_args}} :
		'args'
	];

	if(exists $opts{constructor}) {
		$$guts{constructor} = $opts{constructor};
		$$guts{constructor_args} = [
			ref $opts{constructor_args} eq 'ARRAY'
			? @{$opts{constructor_args}} : ('scope', 'args')
				# ~~~ what is the most useful default here?
		];
	}
	if(exists $opts{name}) {
		$$guts{func_name} = $opts{name};
	}

	$self->prop({dontdel=>1, name=>'arguments',value=>$global->null});
	 	
	$self;
}


=item call_with ( $obj, @args )

Calls a function with the given arguments. The C<$obj> becomes the
function's invocant. This method is intended for general use from the Perl
side. The arguments (including C<$obj>) are automatically upgraded.

=cut

sub call_with {
 my $func = shift;
 my $ret = $func->apply( $func->global->upgrade(@_) );
 typeof $ret eq 'undefined' ? undef : $ret
}

=item call ( @args )

This method, intended mainly for internal use, calls a function with the 
given arguments, without upgrading them. The invocant (the 'this' value)
will be the global object. This is just a wrapper around C<apply>.

This method is very badly named and will probably be renamed in a future
version. Does anyone have any suggestions?

=cut

sub call {
	my $self = shift;
	$self->apply($$$self{global}, @_);
}




=item construct

This method, likewise intended mainly for internal use, calls the 
constructor, if this function has one (functions written in JS
don't have this). Otherwise, an object will be created and passed to the 
function as its invocant. The return value of the function will be
discarded, and the object (possibly modified) will be returned instead.

=cut

sub construct { # ~~~ we need to upgrade the args passed to construct, but 
                #     still retain the unupgraded values to pass to the 
                #     function *if* the function wants them downgraded
	my $self = shift;
	my $guts = $$self;
	my $global = $$guts{global};
	if(exists $$guts{constructor}
	   and ref $$guts{constructor} eq 'CODE') {
		my $code = $$guts{constructor};
		my @args;
		for(  @{ $$guts{constructor_args} }  ) {
			push @args,
			  $_ eq 'self'
			?	$self
			: $_ eq 'scope'
			?	_init_scope($self, $$guts{scope},
					[], @_)
			: $_ eq 'global'
			?	$global
			: $_ eq 'args'
			?	@_ # ~~~ downgrade if wanted
			: $_ eq '[args]'
			?	[@_] # ~~~ downgrade if wanted
			: 	undef;
		}
		# ~~~ What can we do to avoid the upgrade overhead for
		#     JS internal functions?
		return $global->upgrade($code->(@args));
	}
	else {
		# If the prototype property does not exist, then, since it
		# is undeletable, this can only be a function created with
		# no_proto => 1, i.e., an internal functions that’s meant
		# to die here.
		defined(my $proto = $self->prop('prototype'))
			or die JE::Object::Error::TypeError->new(
				$global, add_line_number
				+($$guts{func_name} || 'The function').
				    " cannot be called as a constructor");

		my $obj = JE::Object->new($global,
			!$proto->primitive ?
				{ prototype => $proto }
			: ()
		);
		my $return = $global->upgrade(
			$self->apply($obj, @_)
		);
		return $return->can('primitive') && !$return->primitive
			? $return
			: $obj;
	}
}




=item apply ( $obj, @args )

This method, intended mainly for internal use just like the two above,
calls the function with $obj as the invocant and @args as the args. No
upgrading occurs.

This method is very badly named and will probably be renamed in a future
version. Does anyone have any suggestions?

=cut

sub apply { # ~~~ we need to upgrade the args passed to apply, but still
            #     retain the unupgraded values to pass to the function *if*
            #     the function wants them downgraded
	my ($self, $obj) = (shift, shift);
	my $guts = $$self;
	my $global = $$guts{global};

	if(!blessed $obj or ref $obj eq 'JE::Object::Function::Call' 
	    or ref($obj) =~ /^JE::(?:Null|Undefined)\z/) {
		$obj = $global;
	}

	if(ref $$guts{function} eq 'CODE') {
		my @args;
		for(  @{ $$guts{func_args} }  ) {
			push @args,
			  $_ eq 'self'
			?	$self
			: $_ eq 'scope'
			?	_init_scope($self, $$guts{scope},
					$$guts{func_argnames}, @_)
			: $_ eq 'global'
			?	$global
			: $_ eq 'this'
			?	$obj
			: $_ eq 'args'
			?	@_ # ~~~ downgrade if wanted
			: $_ eq '[args]'
			?	[@_] # ~~~ downgrade if wanted
			: 	undef;
		}
		return $global->upgrade(
			# This list slice is necessary to work around a bug
			# in perl5.8.8 (but not in 5.8.6 or 5.10). Try
			# running this code to see what  I  mean:
			# 
			# bless ($foo=[]); sub bar{print "ok\n"}
			# $foo->bar(sub{warn;return "anything"}->())
			#
			(scalar $$guts{function}->(@args))[0]
		);
	}
	elsif ($$guts{function}) {
		my $at = $@;
		my $scope = _init_scope(
				$self, $$guts{scope},
				$$guts{func_argnames}, @_
			);
		my $time_bomb = bless [$self, $self->prop('arguments')],
			'JE::Object::Function::_arg_wiper';
		$self->prop('arguments', $$scope[-1]{-arguments});
		my $ret = $$guts{function}->execute(
			$obj->to_object, $scope, 2
		);
		defined $ret or die;
		$@ = $at;
		return $ret;
	}
	else {
if (!defined $global) { use Carp; Carp::cluck() }
		return $global->undefined;
	}
}

sub JE::Object::Function::_arg_wiper::DESTROY {
	$_[0][0] # function
	 ->prop(
	  'arguments', $_[0][1] # old arguments value
	 )
}

sub _init_scope { # initialise the new scope for the function call
	my($self, $scope, $argnames, @args) = @_;

	bless([ @$scope, JE::Object::Function::Call->new({
		global   => $$$self{global},
		argnames => $argnames,
		args     => [@args],
		function => $self,
	})], 'JE::Scope');
}




=item typeof

This returns the string 'function'.

=cut

sub typeof { 'function' }




=item class

This returns the string 'Function'.

=cut

sub class { 'Function' }




=item value

Not yet implemented.

=cut

sub value { die "JE::Object::Function::value is not yet implemented." }


#----------- PRIVATE SUBROUTINES ---------------#

# _init_proto takes the Function prototype (Function.prototype) as its sole
# arg and adds all the default properties thereto.

sub _init_proto {
	my $proto = shift;
	my $scope = $$proto->{global};

	# E 15.3.4
	$proto->prop({
		dontenum => 1,
		name => 'constructor',
		value => $scope->prop('Function'),
	});

	$proto->prop({
		name      => 'toString',
		value     => JE::Object::Function->new({
			scope    => $scope,
			name     => 'toString',
			no_proto => 1,
			function_args => ['this'],
			function => sub {
				my $self = shift;
				$self->isa(__PACKAGE__) or die new
					JE::Object::Error::TypeError
					$scope, add_line_number "Function."
					."prototype.toString can only be "
					."called on functions";
				my $guts = $$self;
				my $str = 'function ';
				JE::String->_new($scope,
				  'function ' .
				  ( exists $$guts{func_name} ?
				    $$guts{func_name} :
				    'anon'.$self->id) .
				  '(' .
				  join(',', @{$$guts{func_argnames}})
				  . ") {" .
				  ( ref $$guts{function}
				    eq 'JE::Code'
				    ? do {
				      my $code = 
				        $$guts{function};
				      my $offsets =
				        $$guts{function}
				          {tree}[0];
				      $code = substr ${$$code{source}},
				                     $$offsets[0],
				                     $$offsets[1] -
				                       $$offsets[0];
				      # We have to check for a final line
				      # break in case it ends with a sin-
				      # gle-line comment.
				      $code =~ /[\cm\cj\x{2028}\x{2029}]\z/
				      ? $code : $code . "\n"
				    }
				    : "\n    // [native code]\n"
				  ) . '}'
# ~~~ perhaps this should be changed so it doesn't comment out the
#     the [native code] thingy. That way an attempt to
#     eval the strung version will fail. (In this case, I need to add a
#     teest too make sure it dies.)
				);
			},
		}),
		dontenum  => 1,
	});
	$proto->prop({
		name      => 'apply',
		value     => JE::Object::Function->new({
			scope    => $scope,
			name     => 'apply',
			argnames => [qw/thisArg argArray/],
			no_proto => 1,
			function_args => ['this','args'],
			function => sub {
				my($self,$obj,$args) = @_;

				my $at = $@;

				no warnings 'uninitialized';
				if(defined $args and
				   ref($args) !~ /^JE::(Null|Undefined|
					Object::Function::Arguments)\z/x
				   and eval{$args->class} ne 'Array') {
					die JE::Object::Error::TypeError
					->new($scope, add_line_number
					      "Second argument to "
					      . "'apply' is of type '" . 
					      (eval{$args->class} ||
					       eval{$args->typeof} ||
					       ref $args) .
					      "', not 'Arguments' or " .
					      "'Array'");
				}
				$@ = $at;
				$args = $args->value if defined $args;
				$self->apply($obj, defined $args ?
					@$args : ());
			},
		}),
		dontenum  => 1,
	});
	$proto->prop({
		name      => 'call',
		value     => JE::Object::Function->new({
			scope    => $scope,
			name     => 'call',
			argnames => ['thisArg'],
			no_proto => 1,
			function_args => ['this','args'],
			function => sub {
				shift->apply(@_);
			},
		}),
		dontenum  => 1,
	});
}


#----------- THE REST OF THE DOCUMENTATION ---------------#

=back

=head1 OVERLOADING

You can use a JE::Object::Function as a coderef. The sub returned simply
invokes the C<call> method, so the following are equivalent:

  $function->call( $function->global->upgrade(@args) )
  $function->(@args)

The stringification, numification, boolification, and hash dereference ops
are also overloaded. See L<JE::Object>, which this class inherits from.

=head1 SEE ALSO

=over 4

=item JE

=item JE::Object

=item JE::Types

=item JE::Scope

=item JE::LValue

=back

=cut


package JE::Object::Function::Call;

our $VERSION = '0.066';

sub new {
	# See sub JE::Object::Function::_init_sub for the usage.

	my($class,$opts) = @_;
	my @args = @{$$opts{args}};
	my(%self,$arg_val);
	for(@{$$opts{argnames}}){
		$arg_val = shift @args;
		$self{-dontdel}{$_} = 1;
		$self{$_} = defined $arg_val ? $arg_val :
			$$opts{global}->undefined;
	}

	$self{-dontdel}{arguments} = 1;

	$self{'-global'}  = $$opts{global};
	# A call object's properties can never be accessed via bracket
	# syntax, so '-global' cannot conflict with properties, since the
	# latter have to be valid identifiers. Same 'pplies to dontdel, o'
	# course.
	
	# Note on arguments vs  -arguments:  ‘arguments’  represents the
	# actual ‘arguments’  property,  which may or may not refer to the
	# Arguments object,  depending on  whether  there  is  an  argument
	# named  ‘arguments’.  ‘-arguments’  always refers to the Arguments
	# object, which we need further up when we assign to the arguments
	# property of the function itself.

	$self{-arguments} = 
			JE::Object::Function::Arguments->new(
				$$opts{global},
				$$opts{function},
				\%self,
				$$opts{argnames},
				@{$$opts{args}},
			);
	unless (exists $self{arguments}) {
		$self{arguments} = $self{-arguments}
	};

	return bless \%self, $class;
}

sub prop {
	my ($self, $name)  =(shift,shift);

	if(ref $name eq 'HASH') {
		my $opts = $name;
		$name = $$opts{name};
		@_ = exists($$opts{value}) ? $$opts{value} : ();
		$$self{'-dontdel'}{$name} = !!$$opts{dontdel}
			if exists $$opts{dontdel};
	}

	if (@_ ) {
		return $$self{$name} = shift;
	}

	if (exists $$self{$name}) {
		return $$self{$name};
	}

	return
}

sub delete {
	my ($self,$varname) = @_;
	unless($_[2]) { # if $_[2] is true we delete it anyway
		exists $$self{-dontdel}{$varname}
			&& $$self{-dontdel}{$varname}
			&& return !1;
	}
	delete $$self{-dontdel}{$varname};
	delete $$self{$varname};
	return 1;
}

sub exists { exists $_[0]{$_[1]} }
sub prototype{}




package JE::Object::Function::Arguments;

our $VERSION = '0.066';

our @ISA = 'JE::Object';

sub new {
	my($class,$global,$function,$call,$argnames,@args) = @_;
	
	my $self = $class->SUPER::new($global);
	my $guts = $$self;

	$$guts{args_call} = $call;
	$self->prop({
		name => 'callee',
		value => $function,
		dontenum => 1,
	});
	$self->prop({
		name => 'length',
		value => JE::Number->new($global, scalar @args),
		dontenum => 1,
	});
	$$guts{args_length} = @args; # in case the length prop
	                              # gets changed

=begin pseudocode

Go through the named args one by one in reverse order, starting from $#args
if $#args < $#params

If an arg with the same name as the current one has been seen
	Create a regular numbered property for that arg.
Else
	Create a magical property.

=end pseudocode

=cut

	my (%seen,$name,$val);
	for (reverse 0..($#args,$#$argnames)[$#$argnames < $#args]) {
		($name,$val) = ($$argnames[$_], $args[$_]);
		if($seen{$name}++) {
			$self->prop({
				name => $_,
				value => $val,
				dontenum => 1,
			});
		}
		else {
			$$guts{args_magic}{$_} = $name;
		}
	}

	# deal with any extra properties
	for (@$argnames..$#args) {
		$self->prop({
			name => $_,
			value => $args[$_],
			dontenum => 1,
		});
	}

	$self;
}

sub prop {
	# Some properties are magically linked to properties of
	# the call object.

	my($self,$name) = @_;
	my $guts = $$self;
	if (exists $$guts{args_magic} and exists $$guts{args_magic}{$name})
	{
		return $$guts{args_call}->prop(
			$$guts{args_magic}{$name}, @_[2..$#_]
		);
	}
	SUPER::prop $self @_[1..$#_];
}

sub delete { 
	# Magical properties are still deleteable.
	my($self,$name) = @_;
	my $guts = $$self;
	if (exists $$guts{args_magic} and exists $$guts{args_magic}{$name})
	{
		delete $$guts{args_magic}{$name}
	}
	SUPER::delete $self @_[1..$#_];
}

sub value {
	my $self = shift;
	[ map $self->prop($_), 0..$$$self{args_length}-1 ];
}

1;
