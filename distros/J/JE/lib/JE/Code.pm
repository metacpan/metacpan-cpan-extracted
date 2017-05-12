package JE::Code;

our $VERSION = '0.066';

use strict;
use warnings; no warnings 'utf8', 'recursion';

#use Data::Dumper;
use Carp 1.01 'shortmess';
use Exporter 5.57 'import';
use Scalar::Util 'tainted';

our @CARP_NOT = 'JE';
our @EXPORT_OK = 'add_line_number';

use constant T => ${^TAINT}; # perl doesn’t optimise if(${AINT}) away

require JE::Object::Error;
require JE::Object::Error::ReferenceError;
require JE::Object::Error::SyntaxError;
require JE::Object::Error::TypeError;
require JE::Object::Function;
require JE::Object::Array;
require JE::Boolean;
require JE::Object;
require JE::Parser;
require JE::Number;
require JE::LValue;
require JE::String;
require JE::Scope;

sub add_line_number; # so I can call it without parentheses in sub execute


# This is documented in a POD comment at the bottom of the file.
sub parse {
	my($global, $src, $file, $line) = @_;

	($src, my ($tree, $vars)) = JE::Parser::_parse(
		program => $src, $global, $file, $line
	);

	$@ and return;

#print Dumper $tree;

	my $r= bless { global     => $global,
	               ( $JE::Parser::_parser
	                 ? (parser => $JE::Parser::_parser)
	                 : () ),
	               source     => \$src,
	               file       => $file,
	               line       => $line,
	               vars       => $vars,
	               tree       => $tree };
	# $self->{source} is a reference, so that we can share the same
	# source between code objects without the extra memory overhead
	# that copying it  would  have.  (Some  JS  script  files  are
	# rather large.)

	$r->optimise
	 if   $ENV{'YES_I_WANT_JE_TO_OPTIMISE'}
	  and $ENV{'YES_I_WANT_JE_TO_OPTIMISE'} ne 2;

	$r;
}




sub execute_till { # ~~~ Should this be made public?
	(my $code, local our $counting) = (shift,shift);
	local our $ops = 0;
	JE_Code_OP: {
		return $code->execute(@_);
	}
	# If we get here, then we reached the max number of ops.
	$@ = shortmess "max_ops ($counting) exceeded";
	return undef;
}

sub set_global {
	my $code = shift;
	my $old = $code->{global};
	$code->{global} = $_[0];
	{for(@{$code->{cache}||last}) {
		ref eq 'JE::Code' and $_->set_global($_[0]);
	}}
	{for(@{$code->{vars}||last}){
		ref && ref $$_[4] eq 'JE::Code'
		    && $$_[4]->set_global($_[0])
	}}
	defined $old or return;
	my @stack = $code->{tree};
	local *@;
	while(@stack) {
	  for(shift @stack) {
	    for(@$_[1..$#$_]) {
	      my $r = ref || next;
	      $r =~ /^(?:ARRAY\z|JE::Code::)/
	        and push @stack, $_, =~ next;
	      $r eq 'JE::Boolean'
	        and $_ = qw(f t)[$_->value], next;
	      $r eq 'JE::Number'
	        and $_ = $_->value, next;
	      $r eq 'JE::String'
	        and $_ = "s".$_->value16, next;
	      $r eq 'JE::Null' and $_ = 'n', next;
	      $r eq 'JE::Object::RegExp'
	          and $_ = [$_->{source}->value, $$$_{regexp_flags}],
	              next;
	    }
	  }
	}
	return;
}

sub optimise {
	require 'JE/toperl.pl';
	goto &{'optimise'};
}

# Variables pertaining to the current execution context
our $code; # JE::Code object, not source code
our $this;
our $scope;
our $parser;
our $pos; # position within the source code; used to calculate a line no.
our $taint;
our $ops;
our $counting;
our $global;
our $return;
our $cache;

sub execute {
	local $code = shift;
	local $global = $$code{global};

	# We check $ops’ definedness to avoid resetting the op count when
	# called recursively.
	if(!defined our $ops and my $max_ops = $global->max_ops) {
		unshift @_, $code, $max_ops;
		goto &execute_till;
	}

	local $this = defined $_[0] ? $_[0] : $global;
	shift;

	local $scope = shift || bless [$global], 'JE::Scope';

	my $code_type = shift || 0;

	local our $taint = substr(${$$code{source}},0,0) if T;

	my $rv;
	eval {
		# passing these values around is too
		# cumbersome
		local $JE::Code::parser = $code->{parser}; # might be
		local our $pos;                            # undef
		local our $code = $code;
		local $JE::Code::Expression::_eval   = $code_type == 1;

		package JE::Code::Statement;
		local our $_label;
		package JE::Code;
		# This $return variable has two uses. It holds the return
		# value when the JS 'return' statement calls 'last RETURN'.
		# It also is used by statements that return values. It is
		# necessary to use this var, rather than simply returning
		# the value (as in v0.016 and earlier), in order to make
		# 'while(true) { 3; break }'  return  3,  rather  than
		#  undefined.
		local $return;
		local $cache = $$code{cache}||=[];

		RETURN: {
		BREAK: {
		CONT: {
			JE'Code'Statement'_create_vars();
			$$code{sub} ? &{$$code{sub}} :
			$$code{psrc}? (
			# ~~~ temporary hack:
				($$code{psrc}) = $$code{psrc} =~/(.*)/s,
				&{$$code{sub} =
				eval{ eval("sub{$$code{psrc}}")||die }
				|| die "Internal error that should never"
				   . " happen (please report this): $@: "
				   . $$code{psrc}
			}):
			$$code{tree}->eval;
			$code_type == 2 # function
				or defined $return && ($rv = $return);
			goto FINISH;
		} 

		if($JE::Code::Statement::_label) {
			 die new JE::Object::Error::SyntaxError $global,
		  	 add_line_number
			"continue $JE::Code::Statement::_label: label " .
		  	"'$JE::Code::Statement::_label' not found";
		} else { goto FINISH; }

		} # end of BREAK

		if($JE::Code::Statement::_label) {
			 die new JE::Object::Error::SyntaxError $global,
			 add_line_number
		  	"break $JE::Code::Statement::_label: label " .
		  	"'$JE::Code::Statement::_label' not found";
		} else { goto FINISH; }

		} # end of RETURN

		$rv = $return;


		FINISH:  # I have to  put  this  here  inside  the  eval,
		         # because 'eval { goto label }; label:' causes a
		         # a bus error in p5.8.8 if a tie handler  is  in
		         # the call stack (fixed in 5.9.5).
	};

	T and defined $rv and tainted $taint and $rv->can('taint')
		and $rv = taint $rv $taint;

	if(ref $@ eq '' and $@ eq '') {
		!defined $rv and $rv = $scope->undefined;
	}
	else {
		# Catch-all for any errors not dealt with elsewhere
		$@ = _objectify_error($@);
	}

	$rv;
}

sub add_line_number {
	my $msg = shift;
	my $code = @_ ? shift : $code;
	my $pos  = @_ ? shift : $pos ;
	$msg =~  /\n\z/ and return $msg;
	defined(my $file = ($code || return $msg)->{file})
		or defined $pos or return $msg;
	my $first_line = $code->{line};
	defined $first_line or $first_line = 1;
	if(defined $pos) {
	    no warnings 'uninitialized';
	    "$msg at $file" . ', ' x defined($file) . 'line ' .
	        ($first_line + (() = substr(${$code->{source}},0,$pos) =~
	            /\cm\cj?|[\cj\x{2028}\x{2029}]/g))
	        . ".\n";
	} else {
	    "$msg in $file.\n"
	}
}

sub _objectify_error {
	my $msg = shift;

	ref $msg and return $global->upgrade($msg);

	my $class = 'JE::Object::Error';

	if($msg =~ /^Can't\ locate\ object\ method\ 
	    "(?:c(?:all|onstruct)|apply|invoke_with)"/x) {
	     # ~~~ the ‘apply’ in there is legacy and can be removed b4 v1
		$class = 'JE::Object::Error::TypeError';
		$msg = "Argument to new is not a constructor";
	}

	new $class $global, add_line_number $msg;
}

sub DDS_freeze {
	my $self = shift;
	my $copy = bless {%$self}, ref $self;
	delete $copy->{sub};
	$copy;
}



package JE::Code::Statement; # This does not cover expression statements.

our $VERSION = '0.066';

use subs qw'_eval_term';
use List::Util 'first';

our( $_label);

*_eval_term = *JE::Code::Expression::_eval_term;
import JE::Code 'add_line_number';
sub add_line_number;


# Note: each statement object is an array ref. The elems are:
# [0] - an array ref containing
#       [0] - the starting position in the source code and
#       [1] - the ending position
# [1] - the type of statement
# [2..$#] - the various expressions/statements that make up the statement

sub eval {  # evaluate statement
	my $stm = shift;

	my $type = $$stm[1];
	$type eq 'empty' || $type eq 'function' and return;

	my @labels;
	$pos = $$stm[0][0];

	if ($type eq 'labelled') {
		@labels = @$stm[2..$#$stm-1];
		if ($$stm[-1][1] =~ /^(?:do|while|for|switch)\z/) {
			$stm = $$stm[-1];
			$type = $$stm[1];
			no warnings 'deprecated';
			goto LOOPS; # skip unnecessary if statements
		}

		BREAK: {
			my $returned = $$stm[-1]->eval;
			defined $returned and $return = $returned
		}

		# Note that this has 'defined' in it, whereas the similar
		# 'if' statement further down where the loop constructs are
		# doesn't. This is because 'break' without a label sets
		# $_label to '' and exits loops and switches.
		if(! defined $_label || first {$_ eq $_label} @labels) {
			undef $_label;
			return;
		} else {
			no warnings 'exiting';
			last BREAK;
		}
	}

	if ($type eq 'statements') {

		# Execute the statements, one by one, and return the return
		# value of the last statement that actually returned one.
		my $returned;
		for (@$stm[2..$#$stm]) {
			next if $_ eq 'empty';
			defined($returned = $_->eval) and
				$return = $returned,
				ref $return eq 'JE::LValue'
					&& get $return;
		}
		return;
	}
	if ($type eq 'var') {
		for (@$stm[2..$#$stm]) { if (@$_ == 2) {
			my $ret = _eval_term $$_[1];
			ref $ret eq'JE::LValue' and $ret = get $ret;
			$scope->find_var($$_[0])->set($ret);
		}}
		return;
	}
	if ($type eq 'if') {
		#            2       3          4
		# we have:  expr statement statement?
		my $returned;
		if ($$stm[2]->eval->to_boolean->value) {
			$$stm[3] eq 'empty' or $returned = $$stm[3]->eval;
		}
		else {
			exists $$stm[4]
				&& $$stm[4] ne 'empty'
				and $returned = $$stm[4]->eval;
		}
		defined $returned and $return = $returned;
		return
	}
	if ($type =~ /^(?:do|while|for|switch)\z/) {
		# We have one of the following:
		#
		#  1      2          3          4          5
		# 'do'    statement  expression
		# 'while' expression statement
		# 'for'   expression 'in'       expression statement
		# 'for'   var_decl   'in'       expression statement 
		# 'for'   expression expression expression statement
		# 'for'   var_decl   expression expression statement
 		#
		# In those last two cases, expression may be 'empty'.
		# (See further down for 'switch').

		no warnings 'exiting';

		LOOPS:
		my $returned;
		
		BREAK: {
		if ($type eq 'do') {
			do {
			  CONT: {
			    defined ($returned = ref $$stm[2]
			      ? $$stm[2]->eval : undef)
			    and $return = $returned;
			  }

			  if($_label and
			     !first {$_ eq $_label} @labels) {
			       goto NEXT;
			  }
			  undef $_label;
			} while $$stm[3]->eval->to_boolean->value;
		}
		elsif ($type eq 'while') {
			CONT: while ($$stm[2]->eval->to_boolean->value) {
				defined ($returned = ref $$stm[3]
					? $$stm[3]->eval : undef)
				and $return = $returned;
			}
			continue {
				if($_label and
				   !first {$_ eq $_label} @labels) {
					goto NEXT;
				}
			}
			undef $_label;
		}
		elsif ($type eq 'for' and $$stm[3] eq 'in') {
			my $left_side = $$stm[2];
			if ($left_side->[1] eq 'var') {
				$left_side->eval;
				$left_side = $left_side->[2][0];
				# now contains the identifier
			}
			my $obj = $$stm[4]->eval;
			$obj = $obj->get if ref $obj eq 'JE::LValue';
			ref($obj) =~ /^JE::(?:Undefined|Null)\z/
			 # ~~~ Do we need undef $_label here?
			 and undef $_label, return;
			my @keys = $obj->keys;
			CONT: for(@keys) {
				if($_label and
				   !first {$_ eq $_label} @labels) {
					goto NEXT;
				}
				undef $_label;

				next if not defined $obj->prop($_);	
				# in which case it's been deleted
				
				(ref $left_side ? $left_side->eval :
					$scope->find_var($left_side))
				  ->set(_new JE::String $global, $_);

				defined ($returned = ref $$stm[5]
					? $$stm[5]->eval : undef)
				and $return = $returned;
			}

			# In case 'continue LABEL' is called during the
			# last iteration of the loop
			if($_label and
			   !first {$_ eq $_label} @labels) {
				next CONT;
			}
			undef $_label;

		}
		elsif ($type eq 'for') { # for(;;)
			my $tmp;
			CONT: for (
				$tmp = ref $$stm[2] && $$stm[2]->eval,
				ref $tmp eq 'JE::LValue' && get $tmp;

				ref $$stm[3]
					? $$stm[3]->eval->to_boolean->value
					: 1;

				do{if($_label and
				     !first {$_ eq $_label} @labels) {
				       goto NEXT;
				  }
				  undef $_label;
				},
				$tmp = ref $$stm[4] && $$stm[4]->eval,
				ref $tmp eq 'JE::LValue' && get $tmp
			) {
				defined ($returned = ref $$stm[5]
					? $$stm[5]->eval : undef)
				and $return = $returned;
			}			
		}
		else { # switch
			# $stm->[2] is the parenthesized
			# expression.
			# Each pair of elements thereafter
			# represents one case clause, an expr
			# followed by statements, except for
			# the default clause, which has the
			# string 'default' for its first elem

			
			# Evaluate the expression in the header
			my $given = $$stm[2]->eval;
			$given = get $given if ref $given eq 'JE::LValue';
			
			# Look through the case clauses to see
			# which it matches. At the same time,
			# look for the default clause.

			no strict 'refs';

			my($n, $default) = 1;
			while (($n+=2) < @$stm) {
				if($$stm[$n] eq 'default') {
					$default = $n; next;
				}

				# Execute the statements if we have a match
				if("JE::Code::Expression::in==="->(
					$given, $$stm[$n]->eval
				  )) {
					$n++;
					do {
						$$stm[$n]->eval;
					} while ($n+=2) < @$stm;
					undef $default;
					last;
				}
			} ;

			# If we can't find a case that matches, but we
			# did find a default (and $default was not erased
			# when a case matched)
			if(defined $default) {
				$n = $default +1;
				do { $$stm[$n]->eval }
					while ($n+=2) < @$stm;
			}
		} # switch

		} # end of BREAK


		if(!$_label || first {$_ eq $_label} @labels) {
			undef $_label;
			return;
		} else {
			last BREAK;
		}
		
		NEXT: next CONT;
	}
	if ($type eq 'continue') {
		no warnings 'exiting';
		$_label = exists $$stm[2] ? $$stm[2] : '';
		next CONT;
	}
	if ($type eq 'break') {
		no warnings 'exiting';
		$_label = exists $$stm[2] ? $$stm[2] : '';
		last BREAK;
	}
	if ($type eq 'return') {
		no warnings 'exiting';
		if (exists $$stm[2]) {
			ref ($return = $$stm[2]->eval) eq 'JE::LValue'
			and $return = get $return;
		} else { $return = undef }
		last RETURN;
	}
	if ($type eq 'with') {
		local $scope = bless [
			@$scope, $$stm[2]->eval->to_object
		], 'JE::Scope';
		my $returned = $$stm[3]->eval;
		defined $returned and $return = $returned;
		return;
	}
	if ($type eq 'throw') {
		my $excep;
		if (exists $$stm[2]) {
			ref ($excep = $$stm[2]->eval) eq 'JE::LValue'
			and $excep = get $excep;
		}
		die defined $excep? $excep : $global->undefined;
	}
	if ($type eq 'try') {
		# We have one of the following:
		#   1     2     3     4     5
		# 'try' block ident block       (catch)
		# 'try' block block             (finally)
		# 'try' block ident block block (catch & finally)

		my $result;
		my $propagate;

		eval { # try
			local $return;
			no warnings 'exiting';
			RETURN: {
			BREAK: {
			CONT: {
				$result = $$stm[2]->eval;
				goto SAVERESULT;
			} $propagate = sub{ next CONT }; goto SAVERESULT;
			} $propagate = sub{ last BREAK }; goto SAVERESULT;
			} $propagate = sub{ last RETURN }; goto SAVERESULT;

			SAVERESULT:
			defined $result or $result = $return;
			goto FINALLY;
		};
		# check ref first to avoid the overhead of overloading
		if (ref $@ || $@ ne '' and !ref $$stm[3]) { # catch
			undef $result; # prevent { 3; throw ... } from
			                # returning 3

			# Turn miscellaneous errors into Error objects
			$@ = JE'Code'_objectify_error($@);

			(my $new_obj = new JE::Object $global)
			 ->prop({
				name => $$stm[3],
				value => $@,
				dontdel => 1,
			});
			local $scope = bless [
				@$scope, $new_obj
			], 'JE::Scope';
	
			eval { # in case the catch block ends abruptly
			  local $return;
			  no warnings 'exiting';
			  RETURN: {
			  BREAK: {
			  CONT: {
			    $result = $$stm[4]->eval;
			    goto SAVE;
			  } $propagate = sub{ next CONT }; goto SAVE;
			  } $propagate = sub{ last BREAK }; goto SAVE;
			  } $propagate = sub{ last RETURN }; goto SAVE;

			  SAVE:
			  defined $result or $result = $return;
			  $@ = '';
			}
		}
		# In case the 'finally' block resets $@:
		my $exception = $@;
		FINALLY:
		if ($#$stm == 3 or $#$stm == 5) {
			$$stm[-1]->eval;
		}
		defined $exception and ref $exception || $exception ne ''
			and die $exception;
		$return = $result if defined $result;
		$propagate and &$propagate();
	}
}

sub _create_vars {  # Process var and function declarations
	my $vars = $code->{vars};
	for(@$vars) {
		if(ref) { # function
			# format: [[...], function=> 'name',
			#          [ (params) ], $statements_obj, \@vars ]
			# With optimisation on, the $statements_obj will
			# actually be a code object. 
			$scope->[-1]->delete($$_[2], 1);
			my $new_code_obj;
			if(ref $$_[4] eq 'JE::Code') {
				$new_code_obj = $$_[4]
			}
			else {
			  ($new_code_obj = bless {
			    map+($_=>$code->{$_}),
			      qw/global source file line/
			  }, 'JE::Code')
			  ->{tree} = $$_[4];
			  $new_code_obj->{vars} = $$_[5];
			}
			$scope->new_var($$_[2], new JE::Object::Function {
				scope    => $scope,
				name     => $$_[2],
				argnames => $$_[3],
				function => $new_code_obj
			});
		}
		else {
			$scope->new_var($_);
		}
	}
}




package JE::Code::Expression;

our $VERSION = '0.066';

# B::Deparse showed me how to get these values.
use constant nan => sin 9**9**9;
use constant inf => 9**9**9;

use subs qw'_eval_term';
use POSIX 'fmod';
use Scalar::Util 'tainted';

import JE::Code 'add_line_number';
sub add_line_number;

BEGIN{*T = *JE::Code::T;}


#----------for reference------------#
#sub _to_int {
	# call to_number first
	# then...
	# NaN becomes 0
	# 0 and Infinity remain as they are
	# other nums are rounded towards zero ($_ <=> 0) * floor(abs)
#}

# Note that abs in ECMA-262
#sub _to_uint32 {
	# call to_number, then ...

	# return 0 for Nan, -?inf and 0
	# (round toward zero) % 2 ** 32
#}

#sub _to_int32 {
	# calculate _to_uint32 but subtract 2**32 if the result >= 2**31
#}

#sub _to_uint16 { 
	# just like _to_uint32, except that 2**16 is used instead.
#}


#---------------------------------#

{ # JavaScript operators
  # Note: some operators are not dealt with here, but inside
  #       sub eval.
	no strict 'refs';
	*{'predelete'} = sub {
		ref(my $term = shift) eq 'JE::LValue' or return
			new JE::Boolean $global, 1;
		my $base = $term->base;
		new JE::Boolean $global,
			defined $base ? $base->delete($term->property) : 1;
	};
	*{'prevoid'} = sub {
		my $term = shift;
		$term = get $term while ref $term eq 'JE::LValue';
		return $global->undefined;
	};
	*{'pretypeof'} = sub {
		my $term = shift;
		ref  $term eq 'JE::LValue' and
			ref base $term eq '' and
			return _new JE::String $global, 'undefined';
		_new JE::String $global, typeof $term;
	};
	*{'pre++'} = sub {
		# ~~~ These is supposed to use the same rules
		#     as the + infix op for the actual
		#     addition part. Verify that it does this.
		my $term = shift;
		$term->set(new JE::Number $global,
			get $term->to_number + 1);
	};
	*{'pre--'} = sub {
		# ~~~ These is supposed to use the same rules
		#     as the - infix op for the actual
		#     subtraction part. Verify that it does this.
		my $term = shift;
		$term->set(new JE::Number $global,
			get $term->to_number->value - 1);
	};
	*{'pre+'} = sub {
		shift->to_number;
	};
	*{'pre-'} = sub {
		new JE::Number $global, -shift->to_number->value;
	};
	*{'pre~'} = sub {
		my $num = shift->to_number->value;
		$num = 
			$num != $num || abs($num) == inf  # nan/+-inf
			? 0
			: int($num) % 2**32;

		$num -= 2**32 if $num >= 2**31;

		{ use integer; # for signed bitwise negation
		  $num = ~$num; }
		
		new JE::Number $global, $num;	
	};
	*{'pre!'} = sub {
		new JE::Boolean $global, !shift->to_boolean->value
	};
	*{'in*'} = sub {
		new JE::Number $global,
			shift->to_number->value *
			shift->to_number->value;
	};
	*{'in/'} = sub {
		my($num,$denom) = map to_number $_->value, @_[0,1];
		new JE::Number $global,
			$denom ?
				$num/$denom :
			# Divide by zero:
			$num && $num == $num # not zero or nan
				? $num * inf
				: nan;
	};
	*{'in%'} = sub {
		my($num,$denom) = map to_number $_->value,
			@_[0,1];
		new JE::Number $global,
			$num+1 == $num ? nan :
			$num == $num && abs($denom) == inf ?
				$num :
			fmod $num, $denom;
	};
	*{'in+'} = sub {
		my($x, $y) = @_;
		$x = $x->to_primitive;
		$y = $y->to_primitive;
		if($x->typeof eq 'string' or
		   $y->typeof eq 'string') {
			return _new JE::String $global,
				$x->to_string->value16 .
				$y->to_string->value16;
		}
		return new JE::Number $global,
		                      $x->to_number->value +
		                      $y->to_number->value;
	};
	*{'in-'} = sub {
		new JE::Number $global,
			shift->to_number->value -
			shift->to_number->value;
	};
	*{'in<<'} = sub {
		my $num = shift->to_number->value;
		$num = 
			$num != $num || abs($num) == inf  # nan/+-inf
			? $num = 0
			: int($num) % 2**32;
		$num -= 2**32 if $num >= 2**31;

		my $shift_by = shift->to_number->value;
		$shift_by = 
			$shift_by != $shift_by || abs($shift_by) == inf
			? 0
			: int($shift_by) % 32;

		my $ret = ($num << $shift_by) % 2**32;
		$ret -= 2**32 if $ret >= 2**31;

		new JE::Number $global, $ret;

		# Fails on 64-bit:
		#use integer;
		#new JE::Number $global,
		#	$num << $shift_by;
	};
	*{'in>>'} = sub {
		my $num = shift->to_number->value;
		$num = 
			$num != $num || abs($num) == inf  # nan/+-inf
			? $num = 0
			: int($num) % 2**32;
		$num -= 2**32 if $num >= 2**31;

		my $shift_by = shift->to_number->value;
		$shift_by = 
			$shift_by != $shift_by || abs($shift_by) == inf
			? 0
			: int($shift_by) % 32;

		use integer;
		new JE::Number $global,
			$num >> $shift_by;
	};
	*{'in>>>'} = sub {
		my $num = shift->to_number->value;
		$num = 
			$num != $num || abs($num) == inf  # nan/+-inf
			? $num = 0
			: int($num) % 2**32;

		my $shift_by = shift->to_number->value;
		$shift_by = 
			$shift_by != $shift_by || abs($shift_by) == inf
			? 0
			: int($shift_by) % 32;

		new JE::Number $global,
			$num >> $shift_by;
	};
	*{'in<'} = sub {
		my($x,$y) = map to_primitive $_, @_[0,1];
		new JE::Boolean $global,
			$x->typeof eq 'string' &&
			$y->typeof eq 'string'
			? $x->to_string->value16 lt $y->to_string->value16
			: $x->to_number->[0] <  $y->to_number->[0];
	};
	*{'in>'} = sub {
		my($x,$y) = map to_primitive $_, @_[0,1];
		new JE::Boolean $global,
			$x->typeof eq 'string' &&
			$y->typeof eq 'string'
			? $x->to_string->value16 gt $y->to_string->value16
			: $x->to_number->[0] >  $y->to_number->[0];
	};
	*{'in<='} = sub {
		my($x,$y) = map to_primitive $_, @_[0,1];
		new JE::Boolean $global,
			$x->typeof eq 'string' &&
			$y->typeof eq 'string'
			? $x->to_string->value16 le $y->to_string->value16
			: $x->to_number->[0] <= $y->to_number->[0];
	};
	*{'in>='} = sub {
		my($x,$y) = map to_primitive $_, @_[0,1];
		new JE::Boolean $global,
			$x->typeof eq 'string' &&
			$y->typeof eq 'string'
			? $x->to_string->value16 ge $y->to_string->value16
			: $x->to_number->[0] >= $y->to_number->[0];
	};
	*{'ininstanceof'} = sub {
		my($obj,$func) = @_;
		die new JE::Object::Error::TypeError $global,
			add_line_number "$func is not an object"
			if $func->primitive;

		die new JE::Object::Error::TypeError $global,
			add_line_number "$func is not a function"
			if $func->typeof ne 'function';
		
		return new JE::Boolean $global, 0 if $obj->primitive;

		my $proto_id = $func->prop('prototype');
		!defined $proto_id || $proto_id->primitive and die new
		   JE::Object::Error::TypeError $global,
		   add_line_number "Function $$$func{func_name} has no prototype property";
		$proto_id = $proto_id->id;

		0 while (defined($obj = $obj->prototype)
		         or return new JE::Boolean $global, 0),
			$obj->id ne $proto_id;
		
		new JE::Boolean $global, 1;
	};
	*{'inin'} = sub {
		my($prop,$obj) = @_;
		die new JE::Object::Error::TypeError $global,
		    add_line_number "$obj is not an object"
			if $obj->primitive;
		new JE::Boolean $global, defined $obj->prop($prop);
	};
	*{'in=='} = sub {
		my($x,$y) = @_;
		my($xt,$yt) = (typeof $x, typeof $y);
		my($xi,$yi) = (    id $x,     id $y);
		$xt eq $yt and return new JE::Boolean $global,
			$xi eq $yi && $xi ne 'num:nan';

		$xi eq 'null' and
			return new JE::Boolean $global,
				$yi eq 'undef';
		$xi eq 'undef' and
			return new JE::Boolean $global,
				$yi eq 'null';
		$yi eq 'null' and
			return new JE::Boolean $global,
				$xi eq 'undef';
		$yi eq 'undef' and
			return new JE::Boolean $global,
				$xi eq 'null';

		if($xt eq 'boolean') {
			$x = to_number $x;
			$xt = 'number';
		}
		elsif($yt eq 'boolean') {
			$y = to_number $y;
			$yt = 'number';
		}

		if($xt eq 'string' || $xt eq 'number' and !primitive $y)
			{ $y = to_primitive $y; $yt = typeof $y }
		elsif
		  ($yt eq 'string' || $yt eq 'number' and !primitive $x)
			{ $x = to_primitive $x; $xt = typeof $x }

		($xt eq 'number' and $yt eq 'string' || $yt eq 'number')
		  ||
		($yt eq 'number' and $xt eq 'string' || $xt eq 'number')
		  and
			return new JE::Boolean $global,
			to_number $x->[0] == to_number $y->[0];

		$xt eq 'string' && $yt eq 'string' and 
			return new JE::Boolean $global,
			$x->value16 eq $y->value16;
		
		new JE::Boolean $global, 0;
	};
	*{'in!='} = sub {
		new JE::Boolean $global, !&{'in=='}->[0];
	};
	*{'in==='} = sub {
		my($x,$y) = @_;
		my($xi,$yi) = (    id $x,     id $y);
		return new JE::Boolean $global,
			$xi eq $yi && $xi ne 'num:nan';
	};
	*{'in!=='} = sub {
		new JE::Boolean $global, !&{'in==='}->[0];
	};

	# ~~~ These three bitwise operators are slower than molasses. There
	# must be some way to speed them up, but I'm not sure the research
	# is worth it. Does anyone actually use these in JS?
	*{'in&'} = sub {
		my $num = shift->to_number->[0];
		$num = 
			$num != $num || abs($num) == inf
			? 0
			: int($num) % 2**32;
		$num -= 2**32 if $num >= 2**31;

		my $num2 = shift->to_number->[0];
		$num2 = 
			$num2 != $num2 || abs($num2) == inf
			? 0
			: int($num2) % 2**32;
		$num2 -= 2**32 if $num2 >= 2**31;

		use integer;
		new JE::Number $global,
			$num & $num2;
	};
	*{'in^'} = sub {
		my $num = shift->to_number->[0];
		$num = 
			$num != $num || abs($num) == inf
			? 0
			: int($num) % 2**32;
		$num -= 2**32 if $num >= 2**31;

		my $num2 = shift->to_number->[0];
		$num2 = 
			$num2 != $num2 || abs($num2) == inf
			? 0
			: int($num2) % 2**32;
		$num2 -= 2**32 if $num2 >= 2**31;

		use integer;
		new JE::Number $global,
			$num ^ $num2;
	};
	*{'in|'} = sub {
		my $num = shift->to_number->[0];
		$num = 
			$num != $num || abs($num) == inf
			? 0
			: int($num) % 2**32;
		$num -= 2**32 if $num >= 2**31;

		my $num2 = shift->to_number->[0];
		$num2 = 
			$num2 != $num2 || abs($num2) == inf
			? 0
			: int($num2) % 2**32;
		$num2 -= 2**32 if $num2 >= 2**31;

		use integer;
		new JE::Number $global,
			$num | $num2;
	};
}

=begin for-me

Types of expressions:

'new' term args?

'member/call' term ( subscript | args) *  

'postfix' term op

'hash' term*

'array' term? (comma term?)*

'prefix' op+ term

'lassoc' term (op term)*

'assign' term (op term)* (term term)?
	(the last two terms are the 2nd and 3rd terms of ? :

'expr' term*
	(commas are omitted from the array)

'function' ident? params statements

=end for-me

=cut


# Note: each expression object is an array ref. The elems are:
# [0] - an array ref containing
#       [0] - the starting position in the source code and
#       [1] - the ending position
# [1] - the type of expression
# [2..$#] - the various terms/tokens that make up the expr

sub eval {  # evalate (sub)expression
	no warnings 'exiting';
	++ $ops>$counting and last JE_Code_OP  if $counting;
	
	my $expr = shift;

	my $type = $$expr[1];
	my @labels;

	$pos = $$expr[0][0];

	if ($type eq 'expr') {
		my $result;
		if(@$expr == 3) { # no comma
			return _eval_term $$expr[-1];
		}
		else { # comma op
			for (@$expr[2..$#$expr-1]) {
				$result = _eval_term $_ ;
				get $result if ref $result eq 'JE::LValue';
			}
			$result = _eval_term $$expr[-1] ;
			return ref $result eq 'JE::LValue' ? get $result
				: $result;
		}
	}
	if ($type eq 'assign') {
		my @copy = \(@$expr[2..$#$expr]);
		# Evaluation is done left-first in JS, unlike in
		# Perl, so a = b = c is evaluated in this order:
		#  - evaluate a
		#  - evaluate b
		#  - evaluate c
		#  - assign c to b
		#  - assign b to a

		# Check first to see whether we have the terms
		# of a ? : at the end:
		my @qc_terms = @copy >= 3 && (
				ref ${$copy[-2]} # avoid stringification
				|| ${$copy[-2]} =~ /^(?:[tfu]|[si0-9])/
		)
			? (pop @copy, pop @copy) : ();
			# @qc_terms is now in reverse order

		# Make a list of operands, evalling each
		my @terms = _eval_term ${shift @copy};
		my @ops;
		while(@copy) {
			push @ops, ${shift @copy};
			push @terms, _eval_term ${shift @copy};
		}

		my $val = pop @terms;		

		# Now apply ? : if it's there
		@qc_terms and $val = _eval_term
			${$qc_terms[$val->to_boolean->[0]]};

		for (reverse @ops) {
			no strict 'refs';
			length > 1 and $val =
				&{'in'.substr $_,0,-1}(
					$terms[-1], $val
				);
			$val = $val->get if ref $val eq 'JE::LValue'; 
			T and tainted $taint and $val->can('taint')
				and $val = taint $val $taint;
			eval { (pop @terms)->set($val) };
			if (my $err = $@) {
				die $err if UNIVERSAL::isa($err, 'JE::Object::Error');
				die new JE::Object::Error::ReferenceError
					$global, add_line_number "Cannot assign to a non-lvalue";
			}
			# ~~~ This needs to check whether it was an error
			#     other than 'Can't locate object method "set"
			#     since store handlers can thrown other errors.
			
		}
		if(!@ops) { # If we only have ? : and no assignment
			$val = $val->get if ref $val eq 'JE::LValue'; 
		}
		return $val;
	}
	if($type eq 'lassoc') { # left-associative
		my @copy = \(@$expr[2..$#$expr]);
		my $result = _eval_term ${shift @copy};
		while(@copy) {
			no strict 'refs';
			# We have to deal with || && here for the sake of
			# short-circuiting
			my $op = ${$copy[0]};
			if ($op eq '&&') {
				$result = _eval_term(${$copy[1]}) if
					$result->to_boolean->[0];
				$result = $result->get
					if ref $result eq 'JE::LValue'; 
			}
			elsif($op eq '||') {
				$result = _eval_term(${$copy[1]}) unless
					$result->to_boolean->[0];
				$result = $result->get
					if ref $result eq 'JE::LValue'; 
			}
			else {
				$result = $result->get
					if ref $result eq 'JE::LValue'; 
				$result = &{"in$op"}(
					$result, _eval_term ${$copy[1]}
				);
			}
			splice @copy, 0, 2; # double shift
		}
		return $result;
	}
	if ($type eq 'prefix') {
		# $$expr[1]     -- 'prefix'
		# @$expr[2..-2] -- prefix ops
		# $$expr[-1]    -- operand
		my $term = _eval_term $$expr[-1];

		no strict 'refs';
		$term = &{"pre$_"}($term) for reverse @$expr[2..@$expr-2];
		return $term;
	}
	if ($type eq 'postfix') {
		# ~~~ These are supposed to use the same rules
		#     as the + and - infix ops for the actual
		#     addition part. Verify that they do this.

		my $ret = (my $term = _eval_term $$expr[2])
			->to_number;
		$term->set(new JE::Number $global,
			$ret->value + (-1,1)[$$expr[3] eq '++']);
		return $ret;
	}
	if ($type eq 'new') {
		return _eval_term($$expr[2])->construct(
			@$expr == 4
			? T && tainted $taint
				? map $_->can('taint') ?taint $_ $taint:$_,
					$$expr[-1]->list
				: $$expr[-1]->list
			: ()
		);
	}
	if($type eq 'member/call') {
		my $obj = _eval_term $$expr[2];
		for (@$expr[3..$#$expr]) {
			if(ref eq 'JE::Code::Subscript') {
				$obj = get $obj
					if ref $obj eq 'JE::LValue';
				$obj = new JE::LValue $obj, $_->str_val;
			}
			else {
				$obj = $obj->call(
					T && tainted $taint
					? map $_->can('taint')
						? taint $_ $taint
						: $_,
					  $_->list
					: $_->list
				);
				# If $obj is an lvalue,
				# JE::LValue::call will make
				# the lvalue's base object the 'this'
				# value. Otherwise,
				# JE::Object::Function::call 
				# will make the
				# global object the 'this' value.
			}
			# ~~~ need some error-checking
		}
		return $obj; # which may be an lvalue
	}
	if($type eq 'array') {
		my @ary;
		for (2..$#$expr) {
			if(ref $$expr[$_] eq 'comma') {
				ref $$expr[$_-1] eq 'comma' || $_ == 2
				and ++$#ary
			}
			else {
				push @ary, _eval_term $$expr[$_];
				$ary[-1] = $ary[-1]->get
				 if ref $ary[-1] eq 'JE::LValue';
			}
		}

		my $ary = new JE::Object::Array $global;
		$$$ary{array} = \@ary; # sticking it in like this
		                       # makes 'undef' elements non-
		                       # existent, rather
		                       # than undefined
		return $ary;
	}
	if($type eq 'hash') {
		my $obj = new JE::Object $global;
		local @_ = \(@$expr[2..$#$expr]);
		my (@keys, $key, $value);
		while(@_) { # I have to loop through them to keep
		            # the order.
			$key = ${+shift};
			$value = _eval_term ${shift;};
			$value = get $value if ref $value eq 'JE::LValue';
			$obj->prop($key, $value);
		}
		return $obj;
	}
	if ($type eq 'func') {
		# format: [[...], function=> 'name',
		#          [ params ], $statements_obj, \@vars] 
		#     or: [[...], function =>
		#          [ params ], $statements_obj, \@vars] 
		my($name,$params,$statements) = ref $$expr[2] ?
			(undef, @$expr[2,3]) : @$expr[2..4];
		my $func_scope = $name
			? bless([@$scope, my $obj=new JE::Object $global], 
				'JE::Scope')
			: $scope;
		(my $new_code_obj = bless {
			map+($_=>$code->{$_}),qw/global source file line/
		}, 'JE::Code')
		 ->{tree} = $statements;
		$new_code_obj->{vars} = $$expr[-1];
		my $f = new JE::Object::Function {
			scope    => $func_scope,
			defined $name ? (name => $name) : (),
			argnames => $params,
			function => $new_code_obj,
		};
		if($name) {
			$obj->prop({
				name    => $name,
				value   => $f,
				readonly => 1,
				dontdel  => 1,
			});
		}
		return $f;
	}
}
sub _eval_term {
	my $term = $_[0];

	return $term->eval if ref $term eq 'JE::Code::Expression';

	ref $term     ? ref $term eq 'ARRAY'
	                ? ( require JE::Object::RegExp,
	                    return JE::Object::RegExp->new(
	                      $global, @$term
	                    ) )
	                : $term :
	$term eq'this'? $this :
	$term =~ /^s/ ? $_[0] = JE::String->_new($global,substr $term,1) :
	$term =~ /^i/ ? $scope->find_var(substr $term,1) :
	$term eq 't'  ? $global->true :
	$term eq 'f'  ? $global->false :
	$term eq 'n'  ? $global->null :
	               ($_[0] = JE::Number->new($global,$term));
}




package JE::Code::Subscript;

our $VERSION = '0.066';

sub str_val {
	my $val = (my $self = shift)->[1];
	ref $val ? ''.$val->eval : $val; 
}




package JE::Code::Arguments;

our $VERSION = '0.066';

sub list {
	my $self = shift;

	#  I can't use map here, because this method is called from within
	#  a foreach loop,  and an exception might be thrown from  within
	# _eval_term, which has strange effects in perl 5.8.x (see perl
	#  bug #24254).

if(1) {
	my @result;
	for(@$self[1..$#$self]) {
		my $val = JE::Code::Expression::_eval_term($_);
		push @result, ref $val eq 'JE::LValue' ? $val->get : $val
	}
	@result;

}else{ # original code
	map { my $val = JE::Code::Expression::_eval_term($_);
	      ref $val eq 'JE::LValue' ? $val->get : $val }
	    @$self[1..$#$self];
}
}




1;
__END__


=head1 NAME

JE::Code - ECMAScript parser and code executor for JE

=head1 SYNOPSIS

  use JE;

  $j = new JE;

  $code = $j->compile('1+1'); # returns a JE::Code object

  $code->execute;

=head1 METHODS

=over 4

=item $code->execute($this, $scope, $code_type);

The C<execute> method of a parse tree executes it. All the arguments are
optional.

The first argument
will be the 'this' value of the execution context. The global object will
be used if it is omitted or undef.

The second argument is the scope chain.
A scope chain containing just the global object will be used if it is
omitted or undef.

The third arg indicates the type of code. B<0> or B<undef> indicates global 
code.
B<1> means eval code (code called by I<JavaScript's> C<eval> function, 
which
has nothing to do with JE's C<eval> method, which runs global code).
Variables created with C<var> and function declarations 
inside
eval code can be deleted, whereas such variables in global or function
code cannot. A value of B<2> means function code, which requires an 
explicit C<return>
statement for a value to be returned.

If an error occurs, C<undef> will be returned and C<$@> will contain the
error message. If no error occurs, C<$@> will be a null string.

=item $code->set_global( $thing )

You can transfer a JE::Code object to another JavaScript environment by
setting the global object this way. You can also set it to C<undef>, if,
for instance, you want to serialise the compiled code without serialising
the entire JS environment. If you do that, you'll need to set the global
object again before you can use the code object.

=back

=head1 FUNCTIONS

=over 4

=item JE::Code::add_line_number($message, $code_object, $position)

B<WARNING:> The parameter list is still subject to change.

This routine append a string such as 'at file, line 76.' to the error 
message passed to it,  
unless it ends with a line break already.

C<$code_object> is a code object as returned by JE's or JE::Parser's
C<parse> method. If it is omitted, the current value of C<$JE::Code::code>
will be used (this is set while JS code is running). If C<$JE::Code::code>
turns out to be undefined, then C<$message> will be returned unchanged
(B<this is subject to change>; later I might make it use Carp to add a Perl 
file and line number).

C<$position> is the position within the source code, which will be used to
determine the line number. If this is omitted, $JE::Code::pos will be used.

=begin private

=item JE::Code::parse($global, $src, $file, $line)

Please don't use this. It is for internal use. It might get renamed,
or change its behaviour without notice (which has happened several times).
Use JE's C<compile> and C<eval> methods instead.

This function returns a JE::Code object.

C<$global> is a global object. C<$src> is the source code. C<$file> is a
filename, or any name you want to give the code. C<$line> is a line number.

=end private

=back

=head1 EXPORTS

C<add_line_number> can optionally be exported.

=head1 SEE ALSO

=over 4

=item L<JE>

=back

=cut


