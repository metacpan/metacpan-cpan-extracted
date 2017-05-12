package JE;

# If you are looking at the source code (which you are obviously doing
# if you are reading this),  note that  '# ~~~'  is my way of  marking
# something to be done still (except in this sentence).

# Note also that comments like "# E 7.1" refer to the indicated
# clause (7.1 in this case) in the ECMA-262 standard.

use 5.008004;
use strict;
use warnings; no warnings 'utf8';

our $VERSION = '0.066';

use Carp 'croak';
use JE::Code 'add_line_number';
use JE::_FieldHash;
use Scalar::Util 1.09 qw'blessed refaddr weaken';

our @ISA = 'JE::Object';

require JE::Null     ;
require JE::Number     ;
require JE::Object      ;
require JE::Object::Function;
require JE::Parser                             ;
require JE::Scope                             ;
require JE::String                          ;
require JE::Undefined                     ;

=encoding UTF-8

=head1 NAME

JE - Pure-Perl ECMAScript (JavaScript) Engine

=head1 VERSION

Version 0.066 (alpha release)

The API is still subject to change. If you have the time and the interest, 
please experiment with this module (or even lend a hand :-).
If you have any ideas for the API, or would like to help with development,
please e-mail the author.

=head1 SYNOPSIS

  use JE;

  $j = new JE; # create a new global object

  $j->eval('({"this": "that", "the": "other"}["this"])');
  # returns "that"

  $parsed = $j->parse('new Array(1,2,3)');
 
  $rv = $parsed->execute; # returns a JE::Object::Array
  $rv->value;             # returns a Perl array ref

  $obj = $j->eval('new Object');
  # create a new object

  $foo = $j->{document}; # get property
  $j->{document} = $obj; # set property
  $j->{document} = {};   # gets converted to a JE::Object
  $j->{document}{location}{href}; # autovivification

  $j->method(alert => "text"); # invoke a method


  # create global function from a Perl subroutine:
  $j->new_function(print => sub { print @_, "\n" } );

  $j->eval(<<'--end--');
          function correct(s) {
                  s = s.replace(/[EA]/g, function(s){
                          return ['E','A'][+(s=='E')]
                  })
                  return s.charAt(0) +
                         s.substring(1,4).toLowerCase() +
                         s.substring(4)
          }
          print(correct("ECMAScript")) // :-)
  --end--

=head1 DESCRIPTION

JE, short for JavaScript::Engine (imaginative, isn't it?), is a pure-Perl 
JavaScript engine. Here are some of its
strengths:

=over 4

=item -

Easy to install (no C compiler necessary*)

=item -

The parser can be extended/customised to support extra (or
fewer) language features (not yet complete)

=item -

All JavaScript datatypes can be manipulated directly from Perl (they all
have overloaded operators)

=item -

The JavaScript datatypes provide C<TO_JSON> methods for compatibility with
L<JSON.pm|JSON>.

=back

JE's greatest weakness is that it's slow (well, what did you expect?).  It
also uses and leaks lots of memory.  (There is an experimental
L<JE::Destroyer (q.v.)|JE::Destroyer> module that solves this if you load
it first and then call C<JE::Destroyer::destroy($j)> on the JE object when
you have finished with it.)

* If you are using perl 5.9.3 or lower, then L<Tie::RefHash::Weak> is
required. Recent versions of it require L<Variable::Magic>, an XS module
(which requires a compiler of course), but version 0.02 of the former is
just pure Perl with no XS dependencies.

There is currently an experimental version of the run-time engine, which is
supposed to be faster, although it currently makes compilation slower. (If
you serialise the compiled code and use that, you should notice a
speed-up.) It will eventually replace the current one when it is complete.
(It does not yet respect tainting or max_ops, or report line numbers
correctly.) You can activate it by setting to 1 the ridiculously named
YES_I_WANT_JE_TO_OPTIMISE environment variable, which is just a
temporary hack that will later be removed.

=head1 USAGE

=head2 Simple Use

If you simply need to run a few JS functions from Perl, create a new JS
environment like this:

  my $je = new JE;

If necessary, make Perl subroutines available to JavaScript:

  $je->new_function(warn => sub { warn @_ });
  $je->new_function(ok => \&Test::More::ok);

Then pass the JavaScript functions to C<eval>:

  $je->eval(<<'___');

  function foo() {
      return 42
  }
  // etc.
  ___

  # or perhaps:
  use File::Slurp;
  $je->eval(scalar read_file 'functions.js');

Then you can access those function from Perl like this:

  $return_val = $je->{foo}->();
  $return_val = $je->eval('foo()');

The return value will be a special object that, when converted to a string,
boolean or number, will behave exactly as in JavaScript. You can also use
it as a hash, to access or modify its properties. (Array objects can be
used as arrays, too.) To call one of its
JS methods, you should use the C<method> method:
C<< $return_val->method('foo') >>. See L<JE::Types> for more information.

=head2 Custom Global Objects

To create a custom global object, you have to subclass JE. For instance,
if all you need to do is add a C<self> property that refers to the global
object, then override the C<new> method like this:

  package JEx::WithSelf;
  @ISA = 'JE';
  sub new {
      my $self = shift->SUPER::new(@_);
      $self->{self} = $self;
      return $self;
  }

=head2 Using Perl Objects from JS

See C<bind_class>, below.

=head2 Writing Custom Data Types

See L<JE::Types>.

=head1 METHODS

See also L<< C<JE::Object> >>, which this
class inherits from, and L<< C<JE::Types> >>.

=over 4

=item $j = JE->new( %opts )

This class method constructs and returns a new JavaScript environment, the
JE object itself being the global object.

The (optional) options it can take are C<max_ops> and C<html_mode>, which
correspond to the methods listed below.

=cut

our $s = qr.[\p{Zs}\s\ck]*.;

sub new {
	my $class = shift;

	# I can't use the usual object and function constructors, since
	# they both rely on the existence of  the global object and its
	# 'Object' and 'Function' properties.

	if(ref $class) {
		croak "JE->new is a class method and cannot be called " .
			"on a" . ('n' x ref($class) =~ /^[aoeui]/i) . ' ' .
			 ref($class). " object."
	}

	# Commented lines here are just for reference:
	my $self = bless \{
		#prototype => (Object.prototype)
		#global => ...
		keys => [],
		props => {
			Object => bless(\{
				#prototype => (Function.prototype)
				#global => ...
				#scope => bless [global], JE::Scope
				func_name => 'Object',
				func_argnames => [],
				func_args => ['global','args'],
				function => sub { # E 15.2.1
					return JE::Object->new( @_ );
				},
				constructor_args => ['global','args'],
				constructor => sub {
					return JE::Object->new( @_ );
				},
				keys => [],
				props => {
					#length => JE::Number->new(1),
					prototype => bless(\{
						#global => ...
						keys => [],
						props => {},
					}, 'JE::Object')
				},
				prop_readonly => {
					prototype => 1,
					length    => 1,
				 },
				prop_dontdel  => {
					prototype => 1,
					length    => 1,
				 },
			}, 'JE::Object::Function'),
			Function => bless(\{
				#prototype => (Function.prototype)
				#global => ...
				#scope => bless [global], JE::Scope
				func_name => 'Function',
				func_argnames => [],
				func_args => ['scope','args'],
				function => sub { # E 15.3.1
					JE::Object::Function->new(
						$${$_[0][0]}{global},
						@_[1..$#_]
					);
				},
				constructor_args => ['scope','args'],
				constructor => sub {
					JE::Object::Function->new(
						$${$_[0][0]}{global},
						@_[1..$#_]
					);
				},
				keys => [],
				props => {
					#length => JE::Number->new(1),
					prototype => bless(\{
						#prototype=>(Object.proto)
						#global => ...
						func_argnames => [],
						func_args => [],
						function => '',
						keys => [],
						props => {},
					}, 'JE::Object::Function')
				},
				prop_readonly => {
					prototype => 1,
					length    => 1,
				 },
				prop_dontdel  => {
					prototype => 1,
					length    => 1,
				 },
			}, 'JE::Object::Function'),
		},
	}, $class;

	my $obj_proto =
	    (my $obj_constr  = $self->prop('Object'))  ->prop('prototype');
	my $func_proto =
	    (my $func_constr = $self->prop('Function'))->prop('prototype');

	$self->prototype( $obj_proto );
	$$$self{global} = $self;

	$obj_constr->prototype( $func_proto );
	$$$obj_constr{global} = $self;
	my $scope = $$$obj_constr{scope} =  bless [$self], 'JE::Scope';

	$func_constr->prototype( $func_proto );
	$$$func_constr{global} = $self;
	$$$func_constr{scope} = $scope;

	$$$obj_proto{global} = $self;

	$func_proto->prototype( $obj_proto );
	$$$func_proto{global} = $self;

	$obj_constr ->prop(
	    {name=>'length',dontenum=>1,value=>new JE::Number $self,1}
	);
	$func_constr->prop(
	    {name=>'length',dontenum=>1,value=>new JE::Number $self,1}
	);
	$func_proto->prop({name=>'length', value=>0, dontenum=>1});

	if($JE::Destroyer) {
		JE::Destroyer'register($_) for $obj_constr, $func_constr;
	}

	# Before we add anything else, we need to make sure that our global
	# true/false/undefined/null values are available.
	@{$$self}{qw{ t f u n }} = (
		JE::Boolean->new($self, 1),
		JE::Boolean->new($self, 0),
		JE::Undefined->new($self),
		JE::Null->new($self),
	);

	$self->prototype_for('Object', $obj_proto);
	$self->prototype_for('Function', $func_proto);
	JE::Object::_init_proto($obj_proto);
	JE::Object::Function::_init_proto($func_proto);


	# The rest of the constructors
	# E 15.1.4
	$self->prop({
		name => 'Array',
		autoload =>
			'require JE::Object::Array;
			 JE::Object::Array::_new_constructor($global)',
		dontenum => 1,
	});
	$self->prop({
		name => 'String',
		autoload =>
			'require JE::Object::String;
			JE::Object::String::_new_constructor($global)',
		dontenum => 1,
	});
	$self->prop({
		name => 'Boolean',
		autoload =>
		    'require JE::Object::Boolean;
		    JE::Object::Boolean::_new_constructor($global)',
		dontenum => 1,
	});
	$self->prop({
		name => 'Number',
		autoload =>
			'require JE::Object::Number;
			JE::Object::Number::_new_constructor($global)',
		dontenum => 1,
	});
	$self->prop({
		name => 'Date',
		autoload =>
			'require JE::Object::Date;
			JE::Object::Date::_new_constructor($global)',
		dontenum => 1,
	});
	$self->prop({
		name => 'RegExp',
		autoload => 
			'require JE::Object::RegExp;
			 JE::Object::RegExp->new_constructor($global)',
		dontenum => 1,
	});
	$self->prop({
		name => 'Error',
		autoload =>
			'require JE::Object::Error;
			 JE::Object::Error::_new_constructor($global)',
		dontenum => 1,
	});
	# No EvalError
	$self->prop({
		name => 'RangeError',
		autoload => 'require JE::Object::Error::RangeError;
		             JE::Object::Error::RangeError
		              ->_new_subclass_constructor($global)',
		dontenum => 1,
	});
	$self->prop({
		name => 'ReferenceError',
		autoload => 'require JE::Object::Error::ReferenceError;
		             JE::Object::Error::ReferenceError
		              ->_new_subclass_constructor($global)',
		dontenum => 1,
	});
	$self->prop({
		name => 'SyntaxError',
		autoload => 'require JE::Object::Error::SyntaxError;
		             JE::Object::Error::SyntaxError
		              ->_new_subclass_constructor($global)',
		dontenum => 1,
	});
	$self->prop({
		name => 'TypeError',
		autoload => 'require JE::Object::Error::TypeError;
		             JE::Object::Error::TypeError
		              ->_new_subclass_constructor($global)',
		dontenum => 1,
	});
	$self->prop({
		name => 'URIError',
		autoload => 'require JE::Object::Error::URIError;
		             JE::Object::Error::URIError
		              ->_new_subclass_constructor($global)',
		dontenum => 1,
	});

	# E 15.1.1
	$self->prop({
		name      => 'NaN',
		value     => JE::Number->new($self, 'NaN'),
		dontenum  => 1,
		dontdel   => 1,
	});
	$self->prop({
		name      => 'Infinity',
		value     => JE::Number->new($self, 'Infinity'),
		dontenum  => 1,
		dontdel   => 1,
	});
	$self->prop({
		name      => 'undefined',
		value     => $self->undefined,
		dontenum  => 1,
		dontdel   => 1,
	});


	# E 15.1.2
	$self->prop({
		name      => 'eval',
		value     => JE::Object::Function->new({
			scope    => $self,
			name     => 'eval',
			argnames => ['x'],
			function_args => [qw< args >],
			function => sub {
				my($code) = @_;
				return $self->undefined unless defined
					$code;
				return $code if typeof $code ne 'string';
				my $old_at = $@; # hope it's not tied
				defined (my $tree = 
					($JE::Code::parser||$self)
					->parse($code))
					or die;
				my $ret = execute $tree
					$JE::Code::this,
					$JE::Code::scope, 1;

				ref $@ ne '' and die;
				
				$@ = $old_at;
				$ret;
			},
			no_proto => 1,
		}),
		dontenum  => 1,
	});
	$self->prop({
		name  => 'parseInt',
		value => JE::Object::Function->new({
			scope  => $self,
			name   => 'parseInt', # E 15.1.2.2
			argnames => [qw/string radix/],
			no_proto => 1,
			function_args => [qw< scope args >],
			function => sub {
				my($scope,$str,$radix) = @_;
				$radix = defined $radix
				 ? $radix->to_number->value
				 : 0;
				$radix == $radix and $radix != $radix+1
					or $radix = 0;
				
				if(defined $str) {
					($str = $str->to_string)
						=~ s/^$s//;
				} else { $str = 'undefined' };
				my $sign = $str =~ s/^([+-])//
					? (-1,1)[$1 eq '+']
					:  1;
				$radix = (int $radix) % 2 ** 32;
				$radix -= 2**32 if $radix >= 2**31;
				$radix ||= $str =~ /^0x/i
				?	16
				:	10
				;
				$radix == 16 and
					$str =~ s/^0x//i;

				$radix < 2 || $radix > 36 and return
					JE::Number->new($self,'nan');
					
				my @digits = (0..9, 'a'..'z')[0
					..$radix-1];
				my $digits = join '', @digits;
				$str =~ /^([$digits]*)/i;
				$str = $1;

				my $ret;
				if(!length $str){
					$ret= 'nan' ;
				}
				elsif($radix == 10) {
					$ret= $sign * $str;
				}
				elsif($radix == 16) {
					$ret= $sign * hex $str;
				}
				elsif($radix == 8) {
					$ret= $sign * oct $str;
				}
				elsif($radix == 2) {
					$ret= $sign * eval
						"0b$str";
				}
				else { my($num, $place);
				for (reverse split //, $str){
					$num += ($_ =~ /[0-9]/ ? $_
					    : ord(uc) - 55) 
					    * $radix**$place++
				}
				$ret= $num*$sign;
				}

				return JE::Number->new($self,$ret);
			},
		}),
		dontenum  => 1,
	});
	$self->prop({
		name  => 'parseFloat',
		value => JE::Object::Function->new({
			scope  => $self,
			name   => 'parseFloat', # E 15.1.2.3
			argnames => [qw/string/],
			no_proto => 1,
			function_args => [qw< scope args >],
			function => sub {
				my($scope,$str,$radix) = @_;
				
				defined $str or $str = '';
				ref $str eq 'JE::Number' and return $str;
				ref $str eq 'JE::Object::Number'
				 and return $str->to_number;
				return JE::Number->new($self, $str =~
					/^$s
					  (
					    [+-]?
					    (?:
					      (?=[0-9]|\.[0-9]) [0-9]*
					      (?:\.[0-9]*)?
					      (?:[Ee][+-]?[0-9]+)?
					        |
					      Infinity
					    )
					  )
					/ox
					?  $1 : 'nan');
			},
		}),
		dontenum  => 1,
	});
	$self->prop({
		name  => 'isNaN',
		value => JE::Object::Function->new({
			scope  => $self,
			name   => 'isNaN',
			argnames => [qw/number/],
			no_proto => 1,
			function_args => ['args'],
			function => sub {
				JE::Boolean->new($self,
					!defined $_[0] ||
					shift->to_number->id eq 'num:nan');
			},
		}),
		dontenum  => 1,
	});
	$self->prop({
		name  => 'isFinite',
		value => JE::Object::Function->new({
			scope  => $self,
			name   => 'isFinite',
			argnames => [qw/number/],
			no_proto => 1,
			function_args => ['args'],
			function => sub {
				my $val = shift;
				JE::Boolean->new($self,
					defined $val &&
					($val = $val->to_number->value)
						== $val &&
					$val + 1 != $val
				);
			},
		}),
		dontenum  => 1,
	});

	# E 15.1.3
	$self->prop({
		name  => 'decodeURI',
		autoload => q{ require 'JE/escape.pl';
		    JE::Object::Function->new({
		        scope  => $global,
		        name   => 'decodeURI',
		        argnames => [qw/encodedURI/],
		        no_proto => 1,
		        function_args => ['scope','args'],
		        function => \&JE'_decodeURI,
		    })
		},
		dontenum  => 1,
	});
	$self->prop({
		name  => 'decodeURIComponent',
		autoload => q{ require 'JE/escape.pl';
		    JE::Object::Function->new({
			scope  => $global,
			name   => 'decodeURIComponent',
			argnames => [qw/encodedURIComponent/],
			no_proto => 1,
			function_args => ['scope','args'],
			function => \&JE'_decodeURIComponent
		    })
		},
		dontenum  => 1,
	});
	$self->prop({
		name  => 'encodeURI',
		autoload => q{ require 'JE/escape.pl';
		    JE::Object::Function->new({
			scope  => $global,
			name   => 'encodeURI',
			argnames => [qw/uri/],
			no_proto => 1,
			function_args => ['scope','args'],
			function => \&JE'_encodeURI,
		    })
		},
		dontenum  => 1,
	});
	$self->prop({
		name  => 'encodeURIComponent',
		autoload => q{ require 'JE/escape.pl';
		    JE::Object::Function->new({
			scope  => $global,
			name   => 'encodeURIComponent',
			argnames => [qw/uriComponent/],
			no_proto => 1,
			function_args => ['scope','args'],
			function => \&JE'_encodeURIComponent,
		    })
		},
		dontenum  => 1,
	});

	# E 15.1.5 / 15.8
	$self->prop({
		name  => 'Math',
		autoload => 'require JE::Object::Math;
		             JE::Object::Math->new($global)',
		dontenum  => 1,
	});

	# E B.2
	$self->prop({
		name  => 'escape',
		autoload => q{
			require 'JE/escape.pl';
			JE::Object::Function->new({
				scope  => $global,
				name   => 'escape',
				argnames => [qw/string/],
				no_proto => 1,
				function_args => ['scope','args'],
				function => \&JE'_escape,
			})
		},
		dontenum  => 1,
	});
	$self->prop({
		name  => 'unescape',
		autoload => q{
			require 'JE/escape.pl';
			JE::Object::Function->new({
				scope  => $global,
				name   => 'unescape',
				argnames => [qw/string/],
				no_proto => 1,
				function_args => ['scope','args'],
				function => \&JE'_unescape,
			})
		},
		dontenum  => 1,
	});


	# Constructor args
	my %args = @_;
	$$$self{max_ops} = delete $args{max_ops};
	$$$self{html_mode} = delete $args{html_mode};

	$self;
}




=item $j->parse( $code, $filename, $first_line_no )

C<parse> parses the code contained in C<$code> and returns a parse
tree (a JE::Code object).

If the syntax is not valid, C<undef> will be returned and C<$@> will 
contain an
error message. Otherwise C<$@> will be a null string.

The JE::Code class provides the method 
C<execute> for executing the 
pre-compiled syntax tree.

C<$filename> and C<$first_line_no>, which are both optional, will be stored
inside the JE::Code object and used for JS error messages. (See also
L<add_line_number|JE::Code/FUNCTIONS> in the JE::Code man page.)

=item $j->compile( STRING )

Just an alias for C<parse>.

=cut

sub parse {
	goto &JE::Code::parse;
}
*compile = \&parse;


=item $j->eval( $code, $filename, $lineno )

C<eval> evaluates the JavaScript code contained in C<$code>. E.g.:

  $j->eval('[1,2,3]') # returns a JE::Object::Array which can be used as
                      # an array ref

If C<$filename> and C<$lineno> are specified, they will be used in error
messages. C<$lineno> is the number of the first line; it defaults to 1.

If an error occurs, C<undef> will be returned and C<$@> will contain the
error message. If no error occurs, C<$@> will be a null string.

This is actually just
a wrapper around C<parse> and the C<execute> method of the
JE::Code class.

If the JavaScript code evaluates to an lvalue, a JE::LValue object will be
returned. You can use this like any other return value (e.g., as an array
ref if it points to a JS array). In addition, you can use the C<set> and
C<get> methods to set/get the value of the property to which the lvalue
refers. (See also L<JE::LValue>.) E.g., this will create a new object
named C<document>:

  $j->eval('this.document')->set({});

Note that I used C<this.document> rather than just C<document>, since the
latter would throw an error if the variable did not exist.

=cut

sub eval {
	my $code = shift->parse(@_);
	$@ and return;

	$code->execute;
}




=item $j->new_function($name, sub { ... })

=item $j->new_function(sub { ... })

This creates and returns a new function object. If $name is given,
it will become a property of the global object.

Use this to make a Perl subroutine accessible from JavaScript.

For more ways to create functions, see L<JE::Object::Function>.

This is actually a method of JE::Object, so you can use it on any object:

  $j->{Math}->new_function(double => sub { 2 * shift });


=item $j->new_method($name, sub { ... })

This is just like C<new_function>, except that, when the function is
called, the subroutine's first argument (number 0) will be the object
with which the function is called. E.g.:

  $j->eval('String.prototype')->new_method(
          reverse => sub { scalar reverse shift }
  );
  # ... then later ...
  $j->eval(q[ 'a string'.reverse() ]); # returns 'gnirts a'


=item $j->max_ops

=item $j->max_ops( $new_value )

Use this to set the maximum number of operations that C<eval> (or
JE::Code's C<execute>) will run before terminating. (You can use this for
runaway scripts.) The exact method of counting operations 
is consistent from one run to another, but is not guaranteed to be consistent between versions of JE. In the current implementation, an
operation means an expression or sub-expression, so a simple C<return>
statement with no arguments is not counted.

With no arguments, this method returns the current value.

As shorthand, you can pass C<< max_ops => $foo >> to the constructor.

If the number of operations is exceeded, then C<eval> will return undef and
set C<$@> to a 'max_ops (xxx) exceeded.

=cut

sub max_ops {
	my $self = shift;
	if(@_) { $$$self{max_ops} = shift; return }
	else { return $$$self{max_ops} }
}


=item $j->html_mode

=item $j->html_mode( $new_value )

Use this to turn on 'HTML mode', in which HTML comment delimiters are
treated much like C<//>. C<new_value> is a boolean. Since this violates 
ECMAScript, it is off by  default. 

With no arguments, this method returns the current value.

As shorthand, you can pass C<< html_mode => 1 >> to the constructor.

=cut

sub html_mode {
	my $self = shift;
	if(@_) { $$$self{html_mode} = shift; return }
	else { return $$$self{html_mode} }
}


=item $j->upgrade( @values )

This method upgrades the value or values given to it. See 
L<JE::Types/UPGRADING VALUES> for more detail.


If you pass it more
than one
argument in scalar context, it returns the number of arguments--but that 
is subject to change, so don't do that.

=cut

fieldhash my %wrappees;

sub upgrade {
	my @__;
	my $self = shift;
	my($classes,$proxy_cache);
	for (@_) {
		if (defined blessed $_) {
			$classes or ($classes,$proxy_cache) =
				@$$self{'classes','proxy_cache'};
			my $ident = refaddr $_;
			my $class = ref;
			push @__, exists $$classes{$class}
			    ? exists $$proxy_cache{$ident}
			        ? $$proxy_cache{$ident}
			        : ($$proxy_cache{$ident} =
			            exists $$classes{$class}{wrapper}
			                ? do {
			                   weaken( $wrappees{
			                    my $proxy
			                     = $$classes{$class}{wrapper}(
			                        $self,$_
			                       )
			                   } = $_);
			                   $proxy
			                  }
			                : JE::Object::Proxy->new($self,$_)
			           )
			    : $_;
		} else {
			push @__,
			  !defined()
			?	$self->undefined
			: ref($_) eq 'ARRAY'
			?	JE::Object::Array->new($self, $_)
			: ref($_) eq 'HASH'
			?	JE::Object->new($self, { value => $_ })
			: ref($_) eq 'CODE'
			?	JE::Object::Function->new($self, $_)
			: $_ eq '0' || $_ eq '-0'
			?	JE::Number->new($self, 0)
			:	JE::String->new($self, $_)
			;
		}
	}
	@__ > 1 ? @__ : @__ == 1 ? $__[0] : ();
}

sub _upgr_def {
# ~~~ maybe I should make this a public method named upgrade_defined
	return defined $_[1] ? shift->upgrade(shift) : undef
}


=item $j->undefined

Returns the JavaScript undefined value.

=cut

sub undefined {
	$${+shift}{u}
}




=item $j->null

Returns the JavaScript null value.

=cut

sub null {
	$${+shift}{n}
}



=item $j->true

Returns the JavaScript true value.

=item $j->false

Returns the JavaScript false value.

=cut

sub true  { $${+shift}{t} }
sub false { $${+shift}{f} }




=item $j->bind_class( LIST )

(This method can create a potential security hole. Please see L</BUGS>,
below.)

=back

=head2 Synopsis

 $j->bind_class(
     package => 'Net::FTP',
     name    => 'FTP', # if different from package
     constructor => 'new', # or sub { Net::FTP->new(@_) }

     methods => [ 'login','get','put' ],
     # OR:
     methods => {
         log_me_in => 'login', # or sub { shift->login(@_) }
         chicken_out => 'quit',
     }
     static_methods => {
         # etc. etc. etc.
     }
     to_primitive => \&to_primitive # or a method name
     to_number    => \&to_number
     to_string    => \&to_string

     props => [ 'status' ],
     # OR:
     props => {
         status => {
             fetch => sub { 'this var never changes' }
             store => sub { system 'say -vHysterical hah hah' }
         },
         # OR:
         status => \&fetch_store # or method name
     },
     static_props => { ... }

     hash  => 1, # Perl obj can be used as a hash
     array => 1, # or as an array
     # OR (not yet implemented):
     hash  => 'namedItem', # method name or code ref
     array => 'item',       # likewise
     # OR (not yet implemented):
     hash => {
         fetch => 'namedItem',
         store => sub { shift->{+shift} = shift },
     },
     array => {
         fetch => 'item',
         store => sub { shift->[shift] = shift },
     },

     isa => 'Object',
     # OR:
     isa => $j->{Object}{prototype},
 );
 
 # OR:
 
 $j->bind_class(
     package => 'Net::FTP',
     wrapper => sub { new JE_Proxy_for_Net_FTP @_ }
 );


=head2 Description

(Some of this is random order, and probably needs to be rearranged.)

This method binds a Perl class to JavaScript. LIST is a hash-style list of 
key/value pairs. The keys, listed below, are all optional except for 
C<package> or
C<name>--you must specify at least one of the two.

Whenever it says you can pass a method name to a particular option, and
that method is expected to return a value (i.e., this does not apply to
C<< props => { property_name => { store => 'method' } } >>), you may append
a colon and a data type (such as ':String') to the method name, to indicate
to what JavaScript type to convert the return value. Actually, this is the
name of a JS function to which the return value will be passed, so 'String'
has to be capitalised. This also means than you can use 'method:eval' to
evaluate the return value of 'method' as JavaScript code. One exception to
this is that the special string ':null' indicates that Perl's C<undef>
should become JS's C<null>, but other values will be converted the default
way. This is useful, for instance, if a method should return an object or
C<null>, from JavaScript's point of view. This ':' feature does not stop
you from using double colons in method names, so you can write
C<'Package::method:null'> if you like, and rest assured that it will split
on the last colon. Furthermore, just C<'Package::method'> will also work.
It won't split it at all.

=over 4

=item package

The name of the Perl class. If this is omitted, C<name> will be used
instead.

=item name

The name the class will have in JavaScript. This is used by
C<Object.prototype.toString> and as the name of the constructor. If 
omitted, C<package> will be used.

=item constructor => 'method_name'

=item constructor => sub { ... }

If C<constructor> is given a string, the constructor will treat it as the
name of a class method of C<package>.

If it is a coderef, it will be used as the constructor.

If this is omitted, the constructor will raise an error when called. If
there is already a constructor with the same name, however, it will be left
as it is (though methods will still be added to its prototype object). This
allows two Perl classes to be bound to a single JavaScript class:

 $j->bind_class( name => 'Foo', package => 'Class::One', methods => ... );
 $j->bind_class( name => 'Foo', package => 'Class::Two' );

=item methods => [ ... ]

=item methods => { ... }

If an array ref is supplied, the named methods will be bound to JavaScript
functions of the same names.

If a hash ref is used, the keys will be the
names of the methods from JavaScript's point of view. The values can be
either the names of the Perl methods, or code references.

=item static_methods

Like C<methods> but they will become methods of the constructor itself, not
of its C<prototype> property.

=item to_primitive => sub { ... }

=item to_primitive => 'method_name'

When the object is converted to a primitive value in JavaScript, this
coderef or method will be called. The first argument passed will, of
course, be the object. The second argument will be the hint ('number' or
'string') or will be omitted.

If to_primitive is omitted, the usual valueOf and
toString methods will be tried as with built-in JS
objects, if the object does not have overloaded string/boolean/number
conversions. If the object has even one of those three, then conversion to
a primitive will be the same as in Perl.

If C<< to_primitive => undef >> is specified, primitivisation
without a hint (which happens with C<< < >> and C<==>) will throw a 
TypeError.

=item to_number

If this is omitted, C<to_primitive($obj, 'number')> will be
used.
If set to undef, a TypeError will be thrown whenever the
object is numified.

=item to_string

If this is omitted, C<to_primitive($obj, 'string')> will be
used.
If set to undef, a TypeError will be thrown whenever the
object is strung.

=item props => [ ... ]

=item props => { ... }

Use this to add properties that will trigger the provided methods or
subroutines when accessed. These property definitions can also be inherited
by subclasses, as long as, when the subclass is registered with 
C<bind_class>, the superclass is specified as a string (via C<isa>, below).

If this is an array ref, its elements will be the names of the properties.
When a property is retrieved, a method of the same name is called. When a
property is set, the same method is called, with the new value as the
argument.

If a hash ref is given, for each element, if the value is a simple scalar,
the property named by the key will trigger the method named by the value.
If the value is a coderef, it will be called with the object as its
argument when the variable is read, and with the object and
the new
value as its two arguments when the variable is set.
If the value is a hash ref, the C<fetch> and C<store> keys will be
expected to be either coderefs or method names. If only C<fetch> is given,
the property will be read-only. If only C<store> is given, the property 
will
be write-only and will appear undefined when accessed. (If neither is 
given,
it will be a read-only undefined property--really useful.)

=item static_props

Like C<props> but they will become properties of the constructor itself, 
not
of its C<prototype> property.

=item hash

If this option is present, then this indicates that the Perl object 
can be used
as a hash. An attempt to access a property not defined by C<props> or
C<methods> will result in the retrieval of a hash element instead (unless
the property name is a number and C<array> is specified as well).

=begin comment

There are several values this option can take:

 =over 4

 =item *

One of the strings '1-way' and '2-way' (also 1 and 2 for short). This will
indicate that the object being wrapped can itself be used as a hash.

=end comment

The value you give this option should be one of the strings '1-way' and
'2-way' (also 1 and 2 for short).

If
you specify '1-way', only properties corresponding to existing hash 
elements will be linked to those elements;
properties added to the object from JavaScript will
be JavaScript's own, and will not affect the wrapped object. (Consider how
node lists and collections work in web browsers.)

If you specify '2-way', an attempt to create a property in JavaScript will
be reflected in the underlying object.

=begin comment

=item *

A method name (that does not begin with a number). This method will be
called on the object with the object as the first arg (C<$_[0]>), the
property name as the second, and, if an assignment is being made, the new
value as the third. This will be a one-way hash.

=item *

A reference to a subroutine. This sub will be called with the same
arguments as a method. Again, this will be a one-way hash.

=item *

A hash with C<store> and C<fetch> keys, which should be set to method names
or coderefs. Actually, you may omit C<store> to create a one-way binding,
as per '1-way', above, except that the properties that correspond to hash
keys will be read-only as well.

 =back

=end comment

B<To do:> Make this accept '1-way:String', etc.

=item array

This is just like C<hash>, but for arrays. This will also create a property
named 'length'.

=for comment
if passed '1-way' or '2-way'.

B<To do:> Make this accept '1-way:String', etc.

=begin comment

=item keys

This should be a method name or coderef that takes the object as its first 
argument and
returns a list of hash keys. This only applies if C<hash> is specified
and passed a method name, coderef, or hash.

=end comment

=item unwrap => 1

If you specify this and it's true, objects passed as arguments to the 
methods or code
refs specified above are 'unwrapped' if they are proxies for Perl objects
(see below). And null and undefined are converted to C<undef>.

This is experimental right now. I might actually make this the default.
Maybe this should provide more options for fine-tuning, or maybe what is
currently the default behaviour should be removed. If
anyone has any opinions on this, please e-mail the author. 

=item isa => 'ClassName'

=item isa => $prototype_object

(Maybe this should be renamed 'super'.)

The name of the superclass. 'Object' is the default. To make this new
class's prototype object have no prototype, specify
C<undef>. Instead of specifying the name of the superclass, you 
can
provide the superclass's prototype object.

If you specify a name, a constructor function by that name must already
exist, or an exception will be thrown. (I supposed I could make JE smart
enough to defer retrieving the prototype object until the superclass is
registered. Well, maybe later.)

=item wrapper => sub { ... }

If C<wrapper> is specified, all other arguments will be ignored except for
C<package> (or C<name> if C<package> is not present).

When an object of the Perl class in question is 'upgraded,' this subroutine
will be called with the global object as its first argument and the object
to be 'wrapped' as the second. The subroutine is expected to return
an object compatible with the interface described in L<JE::Types>.

If C<wrapper> is supplied, no constructor will be created.

=back

After a class has been bound, objects of the Perl class will, when passed
to JavaScript (or the C<upgrade> method), appear as instances of the
corresponding JS class. Actually, they are 'wrapped up' in a proxy object 
(a JE::Object::Proxy 
object), that provides the interface that JS operators require (see 
L<JE::Types>). If the 
object is passed back to Perl, it is the I<proxy,>
not the original object that is returned. The proxy's C<value> method will
return the original object. I<But,> if the C<unwrap> option above is used
when a class is bound, the original Perl object will be passed to any 
methods or properties belonging to that class. B<This behaviour is still
subject to change.> See L</unwrap>, above. 

Note that, if you pass a Perl object to JavaScript before binding its 
class,
JavaScript's reference to it (if any) will remain as it is, and will not be
wrapped up inside a proxy object.

To use Perl's overloading within JavaScript, well...er, you don't have to
do
anything. If the object has C<"">, C<0+> or C<bool> overloading, that will
automatically be detected and used.

=cut

sub _split_meth { $_[0] =~ /(.*[^:]):([^:].*)/s ? ($1, $2) : $_[0] }
# This function splits a method specification  of  the  form  'method:Func'
# into its two constituent parts, returning ($_[0],undef) if it is a simple
# method name.  The  [^:]  parts of the regexp are  to  allow  things  like
# "HTML::Element::new:null"  and to prevent  "Foo::bar"  from being turned
# into qw(Foo: bar).

sub _cast {
	my ($self,$val,$type) = @_;
	return $self->upgrade($val) unless defined $type;
	if($type eq 'null') {
		defined $val ? $self->upgrade($val) : $self->null
	}
	else {
		$self->prop($type)->call($self->upgrade($val));
	}
}

sub _unwrap {
	my ($self)  = shift;
	my @ret;
	for(@_){
		push @ret,
		   ref =~  # Check the most common classes for efficiency.
		    /^JE::(?:Object::Proxy(?:::Array)?|Undefined|Null)\z/
			? $_->value
		 : exists $wrappees{$_}
			? $wrappees{$_}
			: $_
	}
	@ret;
}

sub bind_class {
	require JE::Object::Proxy;

	my $self = shift;
	my %opts = @_;
#{ no warnings;
#warn refaddr $self, " ", $opts{name} , ' ' ,$opts{package}; }


	# &upgrade relies on this, because it
	# takes the value of  ->{proxy_cache},
	# sticks it in a scalar, then modifies
	# it through that scalar.
	$$$self{proxy_cache} ||= &fieldhash({}); # & to bypass prototyping

	if(exists $opts{wrapper}) { # special case
		my $pack = $opts{qw/name package/[exists $opts{package}]};
		$$$self{classes}{$pack} = {wrapper => $opts{wrapper}};
		return;
	}

	my($pack, $class);
	if(exists $opts{package}) {
		$pack = "$opts{package}";
		$class = exists $opts{name} ? $opts{name} : $pack;
	}
	else {
		$class = $opts{name};
		$pack = "$class";
	}
		
	my %class = ( name => $class );
	$$$self{classes}{$pack} = $$$self{classes_by_name}{$class} =
		\%class;

	my $unwrap = delete $opts{unwrap};

	my ($constructor,$proto,$coderef);
	if (exists $opts{constructor}) {
		my $c = $opts{constructor};

		$coderef = ref eq 'CODE'
			? sub { $self->upgrade(scalar &$c(@_)) }
			: sub { $self->upgrade(scalar $pack->$c(@_)) };
	}
	else {
		$coderef = sub {
			die JE::Code::add_line_number(
				"$class cannot be instantiated");
		 };
		$constructor = $self->prop($class);
		defined $constructor and $constructor->typeof ne 'function'
		 and $constructor = undef;
	}
	$class{prototype} = $proto = ( $constructor || $self->prop({
		name => $class,
		value => $constructor = JE::Object::Function->new({
			name => $class,
			scope => $self,
			function => $coderef,
			function_args => ['args'],
			constructor => $coderef,
			constructor_args => ['args'],
		}),
	}) )->prop('prototype');

	my $super;
	if(exists $opts{isa}) {
		my $isa = $opts{isa};
		$proto->prototype(
		    !defined $isa || defined blessed $isa
		      ? $isa
		      : do {
		        $super = $isa;
		        defined(my $super_constr = $self->prop($isa)) ||
			  croak("JE::bind_class: The $isa" .
		                " constructor does not exist");
		        $super_constr->prop('prototype')
		      }
		);
	}

	if(exists $opts{methods}) {
		my $methods = $opts{methods};
		if (ref $methods eq 'ARRAY') { for (@$methods) {
			my($m, $type) = _split_meth $_;
			if (defined $type) {
				$proto->new_method(
					$m => $unwrap
					? sub {
					  $self->_cast(
					    scalar shift->value->$m(
					      $self->_unwrap(@_)),
					    $type
					  );
					}
					: sub {
					  $self->_cast(
					    scalar shift->value->$m(@_),
					    $type
					  );
					}
				);
			}else {
				$proto->new_method(
					$m => $unwrap
					? sub { shift->value->$m(
						$self->_unwrap(@_)) }
					: sub { shift->value->$m(@_) },
				);
			}
		}} else { # it'd better be a hash!
		while( my($name, $m) = each %$methods) {
			if(ref $m eq 'CODE') {
				$proto->new_method(
					$name => $unwrap
					? sub {
					    &$m($self->_unwrap(@_))
					  }
					: sub {
					    &$m($_[0]->value,@_[1..$#_])
					  }
				);
			} else {
				my ($method, $type) = _split_meth $m;
				$proto->new_method(
				  $name => defined $type
				    ? $unwrap
				      ? sub {
				        $self->_cast(
				          scalar shift->value->$method(
				            $self->_unwrap(@_)),
				          $type
				        );
				      }
				      : sub {
				        $self->_cast(
				          scalar shift->value->$method(@_),
				          $type
				        );
				      }
				    : $unwrap
				      ? sub { shift->value->$m(
				              $self->_unwrap(@_)) }
				      : sub { shift->value->$m(@_) },
				);
			}
		}}
	}

	if(exists $opts{static_methods}) {
		my $methods = $opts{static_methods};
		if (ref $methods eq 'ARRAY') { for (@$methods) {
			my($m, $type) = _split_meth $_;
			$constructor->new_function(
				$m => defined $type
					? $unwrap
					  ? sub { $self->_cast(
					      scalar $pack->$m(
					        $self->_unwrap(@_)), $type
					  ) }
					  : sub { $self->_cast(
						scalar $pack->$m(@_), $type
					  ) }
					: $unwrap
					  ? sub { $pack->$m(
						$self->_unwrap(@_)) }
					  : sub { $pack->$m(@_) }
			);
			 # new_function makes the functions  enumerable,
			 # unlike new_method. This code is here to make
			 # things consistent. I'll delete it if someone
			 # convinces me otherwise. (I can't make
			 # up my mind.)
			$constructor->prop({
				name => $m, dontenum => 1
			});
		}} else { # it'd better be a hash!
		while( my($name, $m) = each %$methods) {
			if(ref $m eq 'CODE') {
				$constructor->new_function(
					$name => $unwrap
					? sub {
					    @_ = $self->_unwrap(@_);
					    unshift @_, $pack;
					    goto $m;
					}
					: sub {
					    unshift @_, $pack;
					    goto $m;
					}
				);
			} else {
				($m, my $type) = _split_meth $m;
				$constructor->new_function(
					$name => defined $type
						? sub { $self->_cast(
							scalar $pack->$m,
							$type
						) }
						: $unwrap
						  ? sub { $pack->$m(
						    $self->_unwrap(@_)) }
						  : sub { $pack->$m(@_) },
				);
			}
			 # new_function makes the functions  enumerable,
			 # unlike new_method. This code is here to make
			 # things consistent. I'll delete it if someone
			 # convinces me otherwise. (I can't make
			 # up my mind.)
			$constructor->prop({
				name => $name, dontenum => 1
			});
		}}
	}

	for(qw/to_primitive to_string to_number/) {
		exists $opts{$_} and $class{$_} = $opts{$_}
	}

	# The properties enumerated by the 'props' option need to be made
	# instance properties, since assignment never falls through to the
	# prototype,  and a fetch routine is passed the property's  actual
	# owner;  i.e., the prototype, if it is an inherited property.  So
	# we'll make a list of argument lists which &JE::Object::Proxy::new
	# will take care of passing to each object's prop method.
	{ my %props;
	if(exists $opts{props}) {
		my $props = $opts{props};
		$class{props} = \%props;
		if (ref $props eq 'ARRAY') {
		    for(@$props) {
			my ($p,$type) = _split_meth $_;
			$props{$p} = [
				fetch => defined $type
				  ? sub {
				    $self->_cast(
				      scalar $_[0]->value->$p, $type
				    )
				  }
				  : sub {
				    $self->upgrade(scalar $_[0]->value->$p)
				  },
				store => $unwrap
					? sub { $_[0]->value->$p(
						$self->_unwrap($_[1])) }
					: sub { $_[0]->value->$p($_[1]) },
			];
		    }
		} else { # it'd better be a hash!
		while( my($name, $p) = each %$props) {
			my @prop_args;
			if (ref $p eq 'HASH') {
				if(exists $$p{fetch}) {
				    my $fetch = $$p{fetch};
				    @prop_args = ( fetch =>
				        ref $fetch eq 'CODE'
				        ? sub { $self->upgrade(
				            scalar &$fetch($_[0]->value)
				        ) }
				        : do {
					  my($f,$t) = _split_meth $fetch;
					  defined $t ? sub { $self->_cast(
				            scalar shift->value->$f, $t
				          ) }
				          : sub { $self->upgrade(
				              scalar shift->value->$fetch
				          ) }
				        }
				    );
				}
				else { @prop_args =
					(value => $self->undefined);
				}
				if(exists $$p{store}) {
				    my $store = $$p{store};
				    push @prop_args, ( store =>
				        ref $store eq 'CODE'
				        ? $unwrap
					  ? sub {
				            &$store($_[0]->value,
				              $self->_unwrap($_[1]))
				          }
				          : sub {
				            &$store($_[0]->value, $_[1])
				          }
				        : $unwrap
				          ? sub {
				            $_[0]->value->$store(
				              $self->_unwrap($_[1]))
				          }
				          : sub {
				            $_[0]->value->$store($_[1])
				          }
				    );
				}
				else {
					push @prop_args, readonly => 1;
				}
			}
			else {
				if(ref $p eq 'CODE') {
					@prop_args = (
					    fetch => sub { $self->upgrade(
				                scalar &$p($_[0]->value)
				            ) },
					    store => $unwrap
					    ? sub {
				              &$p(
					        scalar $_[0]->value,
					        $self->_unwrap($_[1])
					      )
				            }
					    : sub {
				              &$p(
					        scalar $_[0]->value, $_[1]
					      )
				            },
					);
				}else{
					($p, my $t) = _split_meth($p);
					@prop_args = (
					    fetch => defined $t
					    ? sub { $self->_cast(
				                scalar $_[0]->value->$p, $t
				              ) }
					    : sub { $self->upgrade(
				                scalar $_[0]->value->$p
				              ) },
					    store => $unwrap
					    ? sub {
				                $_[0]->value->$p(
					          $self->_unwrap($_[1]))
				            }
					    : sub {
				                $_[0]->value->$p($_[1])
				            },
					);
				}
			}
			$props{$name} = \@prop_args;
		}}
	}
	if(defined $super){
		$class{props} ||= \%props;
		{
			my $super_props =
				$$$self{classes_by_name}{$super}{props}
				|| last;
			for (keys %$super_props) {
				exists $props{$_} or
					$props{$_} = $$super_props{$_}
			}
		}
	}}

	if(exists $opts{static_props}) {
		my $props = $opts{static_props};
		if (ref $props eq 'ARRAY') { for (@$props) {
			my($p,$t) = _split_meth $_;
			$constructor->prop({
				name => $p,
				fetch => defined $t
				  ? sub { $self->_cast(
				      scalar $pack->$p, $t
				    ) }
				  : sub { $self->upgrade(
				      scalar $pack->$p
				    ) },
				store => $unwrap
				  ? sub {$pack->$p($self->_unwrap($_[1]))}
				  : sub { $pack->$p($_[1]) },
			});
		}} else { # it'd better be a hash!
		while( my($name, $p) = each %$props) {
			my @prop_args;
			if (ref $p eq 'HASH') {
				if(exists $$p{fetch}) {
				    my $fetch = $$p{fetch};
				    @prop_args = ( fetch =>
				        ref $fetch eq 'CODE'
				        ? sub {
				            $self->upgrade(
					        scalar &$fetch($pack))
				        }
				        : do {
				            my($f,$t) = _split_meth $fetch;
				            defined $t ? sub {
				              $self->_cast(
				                scalar $pack->$f,$t)
				            }
				            : sub {
				              $self->upgrade(
				                scalar $pack->$f)
				            }
				        }
				    );
				}
				else { @prop_args =
					(value => $self->undefined);
				}
				if(exists $$p{store}) {
				    my $store = $$p{store};
				    push @prop_args, ( store =>
				        ref $store eq 'CODE'
				        ? $unwrap
				          ? sub {
				            &$store($pack,
				                    $self->_unwrap($_[1]))
				          }
				          : sub {
				            &$store($pack, $_[1])
				          }
				        : $unwrap
				          ? sub {
				            $pack->$store(
				                  $self->_unwrap($_[1]))
				          }
				          : sub {
				            $pack->$store($_[1])
				          }
				    );
				}
				else {
					push @prop_args, readonly => 1;
				}
			}
			else {
				if(ref $p eq 'CODE') {
					@prop_args = (
					    fetch => sub {
				                $self->upgrade(
					          scalar &$p($pack))
				            },
					    store => $unwrap
					    ? sub {
				                &$p($pack,
					            $self->_unwrap($_[1]))
				            }
					    : sub {
				                &$p($pack, $_[1])
				            },
					);
				} else {
					($p, my $t) = _split_meth $p;
					@prop_args = (
					    fetch => defined $t
					    ? sub {
				                $self->_cast(
					          scalar $pack->$p,$t)
				              }
					    : sub {
				                $self->upgrade(
					          scalar $pack->$p)
				              },
					    store => $unwrap
					    ? sub {
				                $pack->$p(
					          $self->_unwrap($_[1]))
				            }
					    : sub {
				                $pack->$p($_[1])
				            },
					);
				}
			}
			$constructor->prop({name => $name, @prop_args});
		}}
	}

	# ~~~ needs to be made more elaborate
# ~~~ for later:	exists $opts{keys} and $class{keys} = $$opts{keys};



	# $class{hash}{store} will be a coderef that returns true or false,
	# depending on whether it was able to write the property. With two-
	# way hash bindings, it will always return true

	if($opts{hash}) {
		if(!ref $opts{hash} # ) {
			#if(
			&& $opts{hash} =~ /^(?:1|(2))/) {
				$class{hash} = {
					fetch => sub { exists $_[0]{$_[1]}
						? $self->upgrade(
						    $_[0]{$_[1]})
						: undef
					},
					store => $1 # two-way?
					  ? sub { $_[0]{$_[1]}=$_[2]; 1 }
					  : sub {
						exists $_[0]{$_[1]} and
						   ($_[0]{$_[1]}=$_[2], 1)
					  },
				};
				$class{keys} ||= sub { keys %{$_[0]} };
			}
		else { croak
			"Invalid value for the 'hash' option: $opts{hash}";
		}

=begin comment

# I haven't yet figured out a logical way for this to work:

			else { # method name
				my $m = $opts{hash};
				$class{hash} = {
					fetch => sub {
						$self->_upgr_def(
						  $_[0]->value->$m($_[1])
						)
					},
					store => sub {
					  my $wrappee = shift->value;
					  defined $wrappee->$m($_[0]) &&
					    ($wrappee->$m(@_), 1)
					},
				};
			}
		} elsif (ref $opts{hash} eq 'CODE') {
			my $cref = $opts{hash};
			$class{hash} = {
				fetch => sub {
					$self->_upgr_def(
				            &$cref($_[0]->value, $_[1])
					)
				},
				store => sub {
				  my $wrappee = shift->value;
				  defined &$cref($wrappee, $_[0]) &&
				    (&$cref($wrappee, @_), 1)
				},
			};
		} else { # it'd better be a hash!
			my $opt = $opts{hash_elem};
			if(exists $$opt{fetch}) {
				my $fetch = $$opt{fetch};
				$class{hash}{fetch} =
				        ref $fetch eq 'CODE'
				        ? sub { $self-> _upgr_def(
				            &$fetch($_[0]->value, $_[1])
				        ) }
				        : sub { $self-> _upgr_def(
				            shift->value->$fetch(shift)
				        ) }
				;
			}
			if(exists $$opt{store}) {
				my $store = $$opt{store};
				$class{hash}{store} =
				        ref $store eq 'CODE'
				        ? sub {
				  	  my $wrappee = shift->value;
				  	  defined &$store($wrappee, $_[0])
					  and &$store($wrappee, @_), 1
				        }
				        : sub {
				  	  my $wrappee = shift->value;
				  	  defined $wrappee->$store($_[0])
					  and &$store($wrappee, @_), 1
				            $_[0]->value->$store(@_[1,2])
				        }
				;
			}
		}

=end comment

=cut

	}

	if($opts{array}) {
			if($opts{array} =~ /^(?:1|(2))/) {
				$class{array} = {
					fetch => sub { $_[1] < @{$_[0]}
						? $self->upgrade(
						    $_[0][$_[1]])
						: undef
					},
					store => $1 # two-way?
					  ? sub { $_[0][$_[1]]=$_[2]; 1 }
					  : sub {
						$_[1] < @{$_[0]} and
						   ($_[0]{$_[1]}=$_[2], 1)
					  },
				};
			}
		else { croak
		    "Invalid value for the 'array' option: $opts{array}";
		}

=begin comment

	} elsif (exists $opts{array_elem}) {
		if (!ref $opts{array_elem}) {
			my $m = $opts{array_elem};
			$class{array} = {
				fetch => sub {
					$self->upgrade(
						$_[0]->value->$m($_[1])
					)
				},
				store => sub { $_[0]->value->$m(@_[1,2]) },
			};
		} else { # it'd better be a hash!
			my $opt = $opts{array_elem};
			if(exists $$opt{fetch}) {
				my $fetch = $$opt{fetch};
				$class{array}{fetch} =
				        ref $fetch eq 'CODE'
				        ? sub { $self->upgrade(
				            &$fetch($_[0]->value, $_[1])
				        ) }
				        : sub { $self->upgrade(
				            shift->value->$fetch(shift)
				        ) }
				;
			}
			if(exists $$opt{store}) {
				my $store = $$opt{store};
				$class{array}{store} =
				        ref $store eq 'CODE'
				        ? sub {
				            &$store($_[0]->value, @_[1,2])
				        }
				        : sub {
				            $_[0]->value->$store(@_[1,2])
				        }
				;
			}
		}

=end comment

=cut

	}

	weaken $self; # we've got closures

	return # nothing
}

=over

=item $j->new_parser

This returns a parser object (see L<JE::Parser>) which allows you to
customise the way statements are parsed and executed (only partially
implemented).

=cut

sub new_parser {
	JE::Parser->new(shift);
}




=item $j->prototype_for( $class_name )

=item $j->prototype_for( $class_name, $new_val )

Mostly for internal use, this method is used to store/retrieve the
prototype objects used by JS's built-in data types. The class name should
be 'String', 'Number', etc., but you can actually store anything you like
in here. :-)

=cut

sub prototype_for {
	my $self = shift;
	my $class = shift;
	if(@_) {
		return $$$self{pf}{$class} = shift
	}
	else {
		return $$$self{pf}{$class} ||
		  ($self->prop($class) || return undef)->prop('prototype');
	}
}



=back

=cut



1;
__END__

=head1 TAINTING

If a piece of JS code is tainted, you can still run it, but any strings or
numbers returned, assigned or passed as arguments by the tainted code will
be tainted (even if it did not originated from within the code). E.g.,

  use Taint::Util;
  taint($code = "String.length");
  $foo = 0 + new JE  ->eval($code);  # $foo is now tainted

This does not apply to string or number I<objects>, but, if the code
created the object, then its internal value I<will> be tainted, because it
created the object by passing a simple string or number argument to a 
constructor.

=head1 IMPLEMENTATION NOTES

Apart from items listed under L</BUGS>, below, JE follows the ECMAScript v3
specification. There are cases in which ECMAScript leaves the precise
semantics to the discretion of the implementation. Here is the behaviour in
such cases:

=over 4

=item *

The global C<parseInt> can interpret its first argument either as decimal 
or octal if it begins with a 0 not followed by 'x', and the second argument
is omitted. JE uses decimal.

=item *

Array.prototype.toLocaleString uses ',' as the separator.

=back

The spec. states that, whenever it (the spec.), say to throw a
SyntaxError, an implementation may provide other behaviour instead. Here
are some instances of this:

=over

=item *

C<return> may be used outside a function. It's like an 'exit' statement,
but it can return a value:

  var thing = eval('return "foo"; this = statement(is,not) + executed')

=item *

C<break> and C<continue> may be used outside of loops. In which case they
act like C<return> without arguments.

=item *

Reserved words (except C<case> and C<break>) can be used as identifiers 
when there is no ambiguity.

=item *

Regular expression syntax that is not valid ECMAScript in general follows
Perl's behaviour. (See L<JE::Object::RegExp> for the exceptions.)

=back

JE also supports the C<escape> and C<unescape> global functions (not part
of ECMAScript proper, but in the appendix).

=head1 BUGS

To report bugs, please e-mail the author.

=head2 Bona Fide Bugs

=over 4

=item *

C<bind_class> has a security hole: An object method’s corresponding
Function object can be applied to any Perl object or class from within JS.
(E.g., if you have allowed a Foo object's C<wibbleton> method to be called
from JS,
then a Bar object's method of the same name can be, too.)

Fixing this is a bit complicated. If anyone would like to help, please let
me know. (The problem is that the same code would be repeated a dozen times
in C<bind_class>'s closures--a maintenance nightmare likely to result in
more security bugs. Is there any way to eliminate all those closures?)

=item *

The JE::Scope class, which has an C<AUTOLOAD> sub that 
delegates methods to the global object, does not yet implement 
the C<can> method, so if you call $scope->can('to_string')
you will get a false return value, even though scope objects I<can>
C<to_string>.

=item *

C<hasOwnProperty> does not work properly with arrays and arguments objects.

=item *

Sometimes line numbers reported in error messages are off. E.g., in the
following code--

  foo(
      (4))

--, if C<foo> is not a function, line 2 will be reported instead of line 1.

=item *

Currently, [:blahblahblah:]-style character classes don’t work if followed
by a character class escape (\s, \d, etc.) within the class.
C</[[:alpha:]\d]/> is interpreted as C</[\[:alph]\d\]/>.

=item *

If, in perl 5.8.x, you call the C<value> method of a JE::Object that has a
custom fetch subroutine for one of its enumerable properties that throws an
exception, you'll get an 'Attempt to free unreferenced scalar' warning.

=begin comment

This is not really a bug, come to think of it. It probably should be an
error (as it is); maybe the error message could be improved.

=item *

Currently, if you take a Perl object whose class has been bound with
C<bind_class> and assign it to a JS function's C<prototype> property, and
then call the function's constructor (via C<new> in JS or the C<construct>
method in Perl), and then call a method that belongs to the aforementioned
Perl class on the resulting object, you can't expect reasonable results.
You'll probably just get a meaningless error message.

=end comment

=item *

On Solaris in perl 5.10.0, the Date class can cause an 'Out of memory'
error which I find totally inexplicable. Patches welcome. (I don't have
Solaris, so I can't experiment with it.)

=item *

Case-tolerant regular expressions allow a single character to match
multiple characters, and vice versa, in those cases where a character's
uppercase equivalent is more than one character; e.g., C</ss/> can match 
the double S ligature. This is contrary to the ECMAScript spec. See the
source code of JE::Object::RegExp for more details.

=item *

Currently any assignment that causes an error will result in the 'Cannot assign to a non-lvalue' error message, even if it was for a different 
cause. For instance, a custom C<fetch> routine might die.

=item *

The parser doesn’t currently support Unicode escape sequences in a regular
expression literal’s flags. It currently passes them through verbatim to
the RegExp constructor, which then croaks.

=item *

Under perl 5.8.8, the following produces a double free; something I need to
look into:

  "".new JE  ->eval(q| Function('foo','return[a]')() | )

=item *

The C<var> statement currently evaluates the rhs before the lhs, which is
wrong. This affects the following, which should return 5, but returns
undefined:

  with(o={x:1})var x = (delete x,5); return o.x

=item *

Currently if a try-(catch)-finally statement’s C<try> and C<catch> blocks
don't return anything, the return value is taken from the C<finally> block.
This is incorrect. There should be no return value. In other words, this
should return 3:

  eval(' 3; try{}finally{5} ')

=item *

Compound assignment operators (+=, etc.) currently get the value of the rhs
first, which is wrong. The following should produce "1b", but gives "2b":

  a = 1;  a += (a=2,"b")

=item *

Serialisation of RegExp objects with Data::Dump::Streamer is currently
broken (and has been since 0.022).

=back

=head2 Limitations

=over 4

=item *

JE is not necessarily IEEE 754-compliant. It depends on the OS. For this
reason the Number.MIN_VALUE and Number.MAX_VALUE properties may not have
the same values as ECMAScript,
and sometimes rounding (via C<toPrecision>, etc.) goes the wrong way.

=item *

A Perl subroutine called from JavaScript can sneak past a C<finally> block and avoid triggering it:

  $j = new JE;
  $j->new_function(outta_here => sub { last outta });
  outta: {
      $j->eval('
          try { x = 1; outta_here() }
          finally { x = 2 }
      ');
  }
  print $j->{x}, "\n";

=item *

NaN and Infinity do not work properly on some Windows compilers.  32-bit
ActivePerl seems not to work, but I have been told 64-bit is OK.
Strawberry Perl works fine, which is what most people are using.

=back

=head2 Incompatibilities with ECMAScript...

...that are probably due to typos in the spec.

=over 4

=item *

In a try-catch-finally statement, if the 'try' block throws an error and
the 'catch' and 'finally' blocks exit normally--i.e., not as a result of
throw/return/continue/break--, the error
originally thrown within the 'try' block is supposed to be propagated,
according to the spec. JE does not re-throw the error. (This is consistent 
with other ECMAScript
implementations.)

I believe there is a typo in the spec. in clause 12.14, in the 'I<TryStatement> : B<try> I<Block Catch Finally>' algorithm. Step 5 should
probably read 'Let I<C> = Result(4),' rather than 'If Result(4).type is not B<normal>, Let I<C> = Result(4).'

=item *

If the expression between the two colons in a C<for(;;)> loop header is
omitted, the expression before the first colon is not supposed to be
evaluated. JE does evaluate it, regardless of whether the expression
between the two colons is present.

I think this is also a typo in the spec. In the first algorithm in clause
12.6.3, step 1 should probably read 'If I<ExpressionNoIn> is not present,
go to step 4,' rather than 'If the first I<Expression> is not present, go
to step 4.'

=item *

The C<setTime> method of a Date object does what one would expect (it sets
the number of milliseconds stored in the Date object and returns that
number).
According to the obfuscated definition in the ECMAScript specification, it 
should always set it to NaN and return NaN.

I think I've found I<yet another> typo in the spec. In clause 15.9.5.27,
'Result(1)' and and 'Result(2)' are probably supposed to be 'Result(2)' and
'Result(3)', respectively.

=back

=head1 PREREQUISITES

perl 5.8.4 or higher

Scalar::Util 1.14 or higher

Exporter 5.57 or higher

Tie::RefHash::Weak, for perl versions earlier than 5.9.4

The TimeDate distribution (more precisely, Time::Zone and 
Date::Parse)

Encode 2.08 or higher

B<Note:> JE will probably end up with Unicode::Collate in
the list of dependencies.

=head1 AUTHOR, COPYRIGHT & LICENSE

Copyright (C) 2007-14 Father Chrysostomos <sprout [at] cpan
[dot] org>

This program is free software; you may redistribute it and/or modify
it under the same terms as perl.

Some of the code was derived from L<Data::Float>, which is copyrighted (C)
2006, 2007, 2008 by Andrew Main (Zefram).

=head1 ACKNOWLEDGEMENTS

Some of the

Thanks to Max Maischein, Kevin Cameron, Chia-liang Kao and Damyan Ivanov
for their
contributions,

to Andy Armstrong, Yair Lenga, Alex Robinson, Christian Forster, Imre Rad,
Craig Mackenna and Toby Inkster
for their suggestions,

and to the CPAN Testers for their helpful reports.

=head1 SEE ALSO

The other JE man pages, especially the following (the rest are listed on
the L<JE::Types> page):

=over 4

=item L<JE::Destroyer>

=item L<JE::Types>

=item L<JE::Object>

=item L<JE::Object::Function>

=item L<JE::LValue>

=item L<JE::Scope>

=item L<JE::Code>

=item L<JE::Parser>

=back

I<ECMAScript Language Specification> (ECMA-262)

=over 4

L<http://www.ecma-international.org/publications/files/ecma-st/ECMA-262.pdf>

=back

L<JavaScript.pm|JavaScript>, L<JavaScript::SpiderMonkey> and
L<JavaScript::Lite>--all 
interfaces to
Mozilla's open-source SpiderMonkey JavaScript engine.

L<JavaScript::V8>

L<WWW::Mechanize::Plugin::JavaScript>
