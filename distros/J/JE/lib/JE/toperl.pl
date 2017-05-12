package JE::Code;

use strict;
use warnings; no warnings qw 'utf8 parenthesis';

use constant 1.03 our $_const = do {
	my $x = 0;
	+{ map +($_ => $x++),
		'cx_stm',  # statement
		'cx_void', # statement; retval ignored

		# expression contexts
		'cx_void_expr',
		'cx_any',  # includes lvalue
	  	'cx_rv',   # rvalue
		'cx_lv',   # lvalue
		'cx_bool', # plain boolean, not necessarily a JE::Boolean
		'cx_str',  # Perl scalar in UTF-16 (with surrogates)
		'cx_num',  # Perl scalar

		'ret_void',  # no retval
		'ret_maybe', # might have a retval (which could be an lval)
		'ret_break', # break or continue
		'ret_any',   # includes lvalue
		'ret_lv',
		'ret_rv',
		'ret_str',
		'ret_num',
		'ret_bool',
	 }
};
BEGIN { no strict; delete @{__PACKAGE__."::"}{_const => keys %$_const} }

=begin notes

The cx_stm constant for statement-level context applies to a context in
which any return type (including an lvalue) is expected, but an lvalue has
to have ->get called on it before it is returned.

The to_perl methods take 1 argument, a cx_ constant, and return 2 or 3:
   0. ret_ constant indicating possible return types
   1. string of Perl code
 ( 2. alternate string of Perl code that can be used only in some
      contexts, such as "..." for JE::String->new(...) )

The reason we have all those return values is most easily demonstrated by
example:

For the + operator, we have two completely different behaviours, depending
on the types of the operands. If an operand can only be a string, we get:

  ret_str, 'JE::String->new($global, "...")', '"..."'

If we see one of those, we can stringify the other operand, returning code
like this:

  "..." . [other operand]->to_string->value16

We need to_perl’s second retval, for cases like - :

  [str operand]->to_number->value - [num operand]
 

=end notes

=cut

sub _esc_str($) {
	my $str = shift;
	$str =~ s/(['\\])/\\$1/g;
	"'$str'";
}

our %labels;
our %loop_labels;
our $cache_indx;
our $code;

no warnings 'redefine';
sub optimise {
	my $self = shift;
	local %labels; local %loop_labels; local $cache_indx;
	local $code = $self;
	my $global = $self->{global};
	$self->set_global(undef);
	$self->{psrc} = 'no warnings"utf8","exiting";'
		. $self->{tree}->to_perl(cx_stm);
	$self->{tree}=[$self->{tree}[0]];
	$self->set_global($global);
}

use Scalar::Util 'refaddr';

sub JE::Code::Statement::to_perl {
	my $stm = shift;
	my $cx = shift;

	my $type = $$stm[1];
	$type eq 'empty' and return ret_void, '';

	if($type eq 'function' ) {
		(my $new_code_obj = bless {
		  map+($_=>$code->{$_}),qw/global source file line/
		}, 'JE::Code')
		 ->{tree} = $$_[4];
		$new_code_obj->{vars} = $$_[5];
		$new_code_obj->optimise;
		$$stm[4] = $new_code_obj;
		return ret_void, '';
	}

	my $pos = $$stm[0][0];

	if ($type eq 'labelled') {
		my @labels = @$stm[2..$#$stm-1];

		my $is_loop =
			$$stm[-1][1] =~ /^(?:do|while|for|switch)\z/;

 		# We have to alias the labels to a single label, because
		# Perl does  not  support  multiple  labels  on  a  sin-
		# gle  statement.  Nor  can  we  stack  them  up  with
		# blocks, ( foo:{bar:{...}} ) because that won’t work
		# for loop-control  constructs  (next  foo).  We have
		# to rename them, since JS idents can have $ in them.
		my $alias_to = refaddr $stm->[-1];
		local @labels{@labels} = ($alias_to)x@labels;

		# ‘continue’ statements only look in this hash:
		local @loop_labels{@labels} = ($alias_to)x@labels
			if $is_loop;

		my($rettype,$code) = $$stm[-1]->to_perl($cx);
		return
			$rettype,
			# loops add their own label, since some have to put
			# something before it
			$is_loop ? $code :
				"JE_Code_$alias_to:" . (
					$$stm[-1][1] =~ /^{/
					? $code
					: length $code ? "{$code}" : '{;}'
				);             # Without the ; it’s a hash.
	}

	if ($type eq 'statements') {

		# At run time, the statements are executed one by one, and
		# the return value of the  last  statement  that  actually
		# returned one is returned. To avoid passing cx_stm context
		# when cx_void will do, we work backwards.
		# ~~~ This logic is currently flawed. It needs to account
		#     for a ‘break’ or similar in between two ret_any stms.
		#    And also ‘return’ satetments.

		my @code; my $last_rettype;
		for (@$stm[reverse 2..$#$stm]) {
			my($rettype,$code) = $_->to_perl($cx);
			$last_rettype = $rettype;
			push @code, $code;
			if($rettype != ret_void && $rettype != ret_maybe) {
				$cx = cx_void
			}
		}
		my $code = join '', reverse @code;
		# $rettype will be undefined if this is an empty block
		return defined $last_rettype?$last_rettype:ret_void, $code;
	}
	if ($type eq 'var') {
		# The Perl code looks like this:
		# $scope->find_var("foo")->set( ...expr... );

		my $stm_code = '';
		for (@$stm[2..$#$stm]) { if (@$_ == 2) {

			my($rettype,$code) = _term_to_perl($$_[1],cx_rv);
			$stm_code .=
			  '$scope->find_var(' . _esc_str($$_[0]) .')->set('
			  . $code . ");";
		}}
		return ret_void, $stm_code;
	}
	if ($type eq 'if') {
		#            2       3          4
		# we have:  expr statement statement?

		my($rettype,$code) = $$stm[2]->to_perl(cx_bool);
		my $stm_code = "if($code){";

		($rettype,$code) = $$stm[3]->to_perl($cx);
		$stm_code .= "$code}";

		my $rettype2;
		if(exists $$stm[4]) {
			($rettype2,$code) = $$stm[4]->to_perl($cx);
			$stm_code .= "else{$code}"
		}
		return $cx == cx_void ? ret_void
		  : (defined $rettype2 ? $rettype2 == ret_void : 1)
		    && $rettype == ret_void
		      ? ret_void
		      : ret_maybe,
		  $stm_code
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

		my $label = refaddr $stm;
		my $stm_code = "JE_Code_$label:";

		# Alias for simple break/continue statements with-
		# out a label:
		local $labels{''} = local $loop_labels{''} = $label;

		if ($type eq 'do') {
			# For a do statement we need two loop labels:
			#   outer: {
			#     do { inner: {
			#
			#     }} while foo
			#   }
			# continue statements use the inner label.

			# In case there are aliases to the existing label:
			my @js_labels = grep $labels{$_} == $label  =>=>
				keys %loop_labels;
			local @loop_labels{'',@js_labels} =
				($label.'c')x(@js_labels+1);

			my($rettype,$code) = $$stm[2]->to_perl($cx);
			my(undef,$boolcode)
				= $$stm[3]->to_perl(cx_bool);
			return $rettype,
			  "$stm_code\{do{JE_Code_${label}c:{" .
			    (length $code ? $code : ';') # foo:{} is a hash
			  ."}}while " 
			  . "$boolcode}";
		}
		elsif ($type eq 'while') {
			my(undef,$boolcode)
				= $$stm[2]->to_perl(cx_bool);
			my($rettype,$code) = $$stm[3]->to_perl($cx);
			return $rettype,
				"${stm_code}while($boolcode){$code}";
		}
		elsif ($type eq 'for' and $$stm[3] eq 'in') {
			#   for(var i = 3 in ...) {
			#       break;
			#   }
			# translates into
			#   $scope->find_var('i')->set(3);
			#   JE_Code_loop: for((my $o = ...)->keys) {
			#       next if not defined $o->prop($_);
			#           # in which case it's been deleted
			#       $scope->find_var('i')->set($_);
			#       last JE_Code_loop;
			#   }
			# (except that the arguments to ->set() have to be
			# expressions returning JE::(Number|String)).  For
			# statements without the ‘var’,  we don’t evaluate
			# the lhs before the loop, but only in the loop. It
			# takes the place of $scope->find_var.

			my $left_side = $$stm[2];
			if ($left_side->[1] eq 'var') {
				substr $stm_code,0,0 =>=
					($left_side->to_perl(cx_void))[1];
				$left_side = _esc_str($left_side->[2][0]);
				# now contains the identifier within a 
				# Perl string
			}

			(undef,my $obj_code) = $$stm[4]->to_perl(cx_rv);
			$stm_code .= 
				"for((my\$o=$obj_code)->keys){" .
				'next if!defined prop$o $_;' .
			
				( ref $left_side
				  ? ( $left_side->to_perl(cx_lv) )[1]
				  : "\$scope->find_var($left_side)" ) .
				'->set(_new JE\'String $global,$_);';

			my($rettype, $code) = $$stm[5]->to_perl($cx);

			return $rettype, "$stm_code$code}";
		}
		elsif ($type eq 'for') { # for(;;)
			$stm_code .= 'for(';
			if(ref $$stm[2]) {
				my $code = ($$stm[2]->to_perl(cx_void))[1];
				length $code and $stm_code .=
					"do{$code}" # We need the  do
			}                           # because to_perl
			$stm_code .= ';';           # returns  whole
			if(ref $$stm[3]) {          # statements
				my(undef,$code) =
					$$stm[3]->to_perl(cx_bool);
				$stm_code .= $code;
			}
			$stm_code .= ';';

			ref $$stm[4] and $stm_code .=
				( $$stm[4]->to_perl(cx_void_expr) )[1];
			
			my($rettype, $code) = $$stm[5]->to_perl($cx);
			return $rettype, "$stm_code){$code}";
		}
		else { # switch
			# $stm->[2] is the parenthesized
			# expression.
			# Each pair of elements thereafter
			# represents one case clause, an expr
			# followed by statements, except for
			# the default clause, which has the
			# string 'default' for its first elem

			# We need to turn something like
			#   switch(3) {
			#       case 5:    a();
			#       default:   f();
			#       case 3636:
			#       case 838:  break;
			#       case 3:    h();
			#   }
			# into
			#   JE_Code_loop: for(3) {
			#     $_->id eq    5->id and goto JE_Code_case1;
			#     $_->id eq 3636->id and goto JE_Code_case2;
			#     $_->id eq  838->id and goto JE_Code_case3;
			#     $_->id eq    3->id and goto JE_Code_case4;
			#     goto JE_Code_default;
			#     JE_Code_case1:   $scope->find_var('a')->call;
			#     JE_Code_default: $scope->find_var('f')->call;
			#     JE_Code_case2:   ;
			#     JE_Code_case3:   last JE_Code_loop;
			#     JE_Code_case4:   $scope->find_var('f')->call;
			#   }
			# (except that the expressions are more complex).
			
			# header
			$stm_code .= 'for(' .
				( $$stm[2]->to_perl(cx_rv) )[1] . '){';
			
			# Go through the case clauses and add goto state-
			# ments to $stm_code while also creating the state-
			# ments that go further down.

			my $more_statements = '';
			my($n, $there_is_a_default) = 1;
			while (($n+=2) < @$stm) {
				if($$stm[$n] eq 'default') {
					$more_statements .=
						'JE_Code_default:';
					++ $there_is_a_default
				}
				else {
					$stm_code .= 'id$_ eq ' .
					  ($$stm[$n]->to_perl(cx_rv))[1] .
					  "->id&&goto JE_Code_case$n;";
					$more_statements.="JE_Code_case$n:"
				}
				my $stm = ( $$stm[$n+1]->to_perl($cx) )[1];
				$more_statements .= length $stm?$stm:';' ;
			} ;

			return $cx==ret_void ? ret_void : ret_maybe, # ~~~ need to do some detecting
				              # for the rettype
				$stm_code . (
					$there_is_a_default
					? 'goto JE_Code_default' : 'last'
				) . ";$more_statements}"
		} # switch
	}
	if ($type eq 'continue') {
		my $label = exists $$stm[2] ? $$stm[2] : '';
		return ret_break, exists $loop_labels{$label}
		  ? "next JE_Code_$loop_labels{$label};"
		  : "die q[continue $label: label '$label' not found];"
	}
	if ($type eq 'break') {
		my $label = exists $$stm[2] ? $$stm[2] : '';
		return ret_break, exists $labels{$label}
		  ? "last JE_Code_$labels{$label};"
		  : "die q[break $label: label '$label' not found];"
	}
	if ($type eq 'return') {
		return ret_any, '$return=' . ( exists $$stm[2]
			? ($$stm[2]->to_perl(cx_rv))[1]
			: 'undef'
		) . ';last RETURN;' ;
	}
	if ($type eq 'with') {
		my($rettype, $code) = $$stm[3]->to_perl($cx);
		return $rettype,
			'{local$scope=bless[@$scope,'
			. ($$stm[2]->to_perl(cx_rv))[1]
			. "->to_object],'JE::Scope';$code}";
	}
	if ($type eq 'throw') {
		return ret_void,'die '.($$stm[2]->to_perl(cx_rv))[1]. ';' ;
	}
	if ($type eq 'try') {
		# We have one of the following:
		#   1     2     3     4     5
		# 'try' block ident block       (catch)
		# 'try' block block             (finally)
		# 'try' block ident block block (catch & finally)

		# For a try-catch, we can simply use eval{...;1}||do{...}.
		# With finally, it’s a lot more complicated.  We can’t use
		# Scope::Guard, because a destructor can’t affect execution
		# flow.  So we have to set up a complicated  net  to  catch
		# every  return/break/continue  in addition to  exceptions.
		# For every unique value in %labels,  we need a separate
		# block.  What we end up with is something like this:

		# ~~~(The inner do{} is actually redundant. Maybe I should
		# refactor it a bit.)

		#   { # lexical scope for all these variables:
		#     my $l; #label
		#     my $e; #exception
		#     my $c; #continue 
		#     eval {
		#       JE_Code_labels: {
		#         RETURN: {
		#         JE_Code_1: for(0,1){ $_ and ++$c, last;
		#         JE_Code_2: for(0,1){ $_ and ++$c, last;
		#         JE_Code_3: for(0,1){ $_ and ++$c, last;
		#           my $r = $return;
		#           eval { ... try ...; last JE_Code_labels };
		#           ... catch ...;
		#           last JE_Code_labels;
		#         } $l = 3, last JE_Code_labels
		#         } $l = 2, last JE_Code_labels
		#         } $l = 1, last JE_Code_labels
		#         } $l = 'r'
		#       }
		#       1
		#     } or $e=$@;
		#     my $r = $return;
		#     ... finally ...
		#     defined $e && die $e;
		#     $return = $r;
		#     $l and $l == 'r' ? last RETURN :
		#            $c ? next "JE_Code_$l" : last "JE_Code_$l"
		#  }

		# A catch’s do-block (this is not in a do when there is a
		# finally) is as follows:
		#   do {
		#     $return = $r;
		#     ref $@ or $@ = _objectify_error($@);
		#     (my $o = new JE::Object $global)
		#      ->prop({
		#             name => 'e',
		#             value => $@,
		#             dontdel => 1,
		#     });
		#     local $scope = bless [
		#             @$scope, $o
		#     ], 'JE::Scope';
		#     ...code...
		#   };

		# Got that?


		my $finally = $#$stm == 3 || $#$stm == 5;

		# try and catch

		my $inner_code = '';
		
		# We don’t want try{3; throw...} to return 3, so we save
		# the previous value of $return before entering the eval.

		my $we_can_catch = !ref $$stm[3];
		$inner_code .= 'my$r=$return;eval{' if $we_can_catch;
		my($rettype,$code) = $$stm[2]->to_perl($cx); # try
		$inner_code .= $code;
		$inner_code .= 'last JE_Code_labels;' if $finally;
		if($we_can_catch) {
			$inner_code .= ($finally ? '};' : '1}||do{')

				. '$return=$r;' # prevent { 3; throw ... }
				                 # from returning 3
				# Turn miscellaneous errors into
				# Error objects
				.q"ref$@or$@=_objectify_error($@);"

				.q"(my$o=new JE'Object $global)->prop({"
				.  'name=>' . _esc_str($$stm[3]) . ','
				.  'value=>$@,'
				.  'dontdel=>1'
				.'});'
				.'local$scope='
				.  'bless[@$scope,$o],"JE::Scope";';

			my($rettype, $code) = $$stm[4]->to_perl($cx);
			$inner_code .= $code
			  . ($finally ? ';last JE_Code_labels' : '}');
		}

		if ($finally) {
			# get a list of labels
			my @labels; my %seen;

			for(values %labels, values %loop_labels) {
				push @labels, $_ unless $seen{$_}++
			}

			my $stm_code =
			  '{'
			  .  'my($l,$e,$c);'
			  .  'eval{'
			  .    'JE_Code_labels:{'
			  .      'RETURN:{';

			$stm_code .=
			         "JE_Code_$_:for(0,1){\$_ and++\$c,last;",
			  for @labels;

			$stm_code .= $inner_code;

			$stm_code .=
			         '}$l='._esc_str($_).",last JE_Code_labels"
			  for reverse @labels;

			$stm_code .=
			         '}$l="r"'
			  .    '}'
			  .    '1'
			  .  '}or$e=$@;'
			  .  'my$r=$return;'
			  .  ( $$stm[-1]->to_perl(cx_void) )[1]
			  .  'defined$e&&die$e;'
			  .  '$return=$r;'
			  .  '$l and$l eq"r"?last RETURN:'
			  .        '$c?eval"next JE_Code_$l"'
			  .          ':eval"last JE_Code_$l"'
			  .'}';

			return $cx==ret_void ? ret_void : ret_maybe,
				$stm_code;
		}
		else {
			return $cx==ret_void ? ret_void : ret_maybe,
				$we_can_catch ? "{$inner_code}" :
					$inner_code;
		}
		# ~~~ need to do some detecting for the rettype

	}
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

sub JE::Code::Expression::to_perl {
	
	#ret_rv, "hooha()" . ';' x ($_[1] == cx_stm || $_[1] == cx_void)

# ~~~	++ $ops>$counting and last JE_Code_OP  if $counting;
	
	my $expr = shift;
	my $cx = shift;

	my $type = $$expr[1];

# ~~~	$pos = $$expr[0][0];

	if ($type eq 'expr') {
		my $sc = '';
		$cx == cx_stm
			? ($sc = ';', $cx = cx_any) :
		$cx == cx_void && ($sc = ';', $cx = cx_void_expr);

		if(@$expr == 3) { # no comma
			my($rettype,$code) =
				_term_to_perl($$expr[-1], $cx);
			if($rettype == ret_lv && $sc) {
				$code =
				  "{my\$v=$code;\$v->get;\$return=\$v}";
			}elsif($rettype==ret_any && $sc){
				$code = "{my\$v=$code;"
					.  'ref$v eq"JE::LValue"&&$v->get'
					.  ';$return=$v'
					.'}';
			}
			elsif($sc) {
				$code = "\$return=$code;"
			}
			return $rettype, $code;
		}
		else { # comma op
			my $result = join ',', map+
				(_term_to_perl($_, cx_void_expr))[1],
				@$expr[2..$#$expr-1];
			$result .= ',';

			my($rettype,$code) =
				_term_to_perl($$expr[-1], ret_rv);
			$result .= $code;
			if($sc) {
				$result = "\$return=($result);";
			}
			else {
				$result = "scalar($result)";
			}

			return $cx == cx_void_expr ? ret_void : $rettype,
				$result;
		}
	}
	if ($type eq 'assign') {
		my @copy = @$expr[2..$#$expr];
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
				ref $copy[-2] # avoid stringification
				|| $copy[-2] =~ /^(?:[tfu]\z|[si0-9])/
		)
			? (pop @copy, pop @copy) : ();
			# @qc_terms is now in reverse order

		# Rough sketch of what we want to accomplish:

		# a += b += c += d
		#
		# do {
		#   my $l = a;
		#   $l->set($l->get + do{
		#     my $l = b;
		#     $l->set($l->get + do {
		#       my $l = c;
		#       $l->set($l->get + d)
		#     })
		#   })
		# }

		# a = b
		#
		# a->set(b->get)

		# a += b = c
		#
		# do {
		#   my $l = a;
		#   $l->set($l->get + b->set(my $v = c))
		# }

		# Get the first rhs ready:

		my $perl_expr = pop @copy;		

		# Now apply ? : if it's there
		if(@qc_terms) {
			$perl_expr = (_term_to_perl($perl_expr,cx_bool))[1]
			  . '?' . (_term_to_perl($qc_terms[1],cx_rv))[1]
			  . ':' . (_term_to_perl($qc_terms[0],cx_rv))[1]
		}
		else {
			$perl_expr = (_term_to_perl($perl_expr,cx_rv))[1];
		}

		# short-circuit if we only have ? : and no assignment
		# ~~~ check return types from both legs
		return ret_rv, $perl_expr unless @copy;

		# Iterate through the ops, wrapping each previous expr with
		# the current one.
		while(@copy) {
			my ($op, $term) = (pop @copy, pop @copy);
			if(length $op > 1) {
			  $perl_expr = 'do{my$l='
			    . (_term_to_perl($term,cx_lv))[1] . ';'
			    . '$l->set('
			    . "'JE::Code::Expression::in".substr $op,0,-1,
			    . "'->(\$l->get,$perl_expr))}"
			}
			else {
			  $perl_expr =
			    (_term_to_perl($term,cx_lv))[1]
			    . "->set($perl_expr)"
			}
		}

# ~~~			T and tainted $taint and $val->can('taint')
#				and $val = taint $val $taint;

		return ret_rv, $perl_expr;
	}
	if($type eq 'lassoc') { # left-associative
		my @copy = @$expr[2..$#$expr];
		my $result = (_term_to_perl(shift @copy, cx_rv))[1];
		while(@copy) {
			# We have to deal with || && specially for the sake
			# of short-circuiting
			my $op = $copy[0];
			if ($op =~ m&^(?:\&\&|\|\|)\z&) {
				$result =
					"$result$op "
					.(_term_to_perl($copy[1],cx_rv))[1]
			}
			else {
				$result = "'JE::Code::Expression::in$op'->"
					. "($result," 
					.(_term_to_perl($copy[1],cx_rv))[1]
					.')'
			}
			splice @copy, 0, 2; # double shift
		}
		return ret_rv,$result;
	}
	if ($type eq 'prefix') {
# ~~~ taintedness
		# $$expr[1]     -- 'prefix'
		# @$expr[2..-2] -- prefix ops
		# $$expr[-1]    -- operand
		my $term = (
		  _term_to_perl( $$expr[-1],
		    $$expr[-2] =~ m-^(?:\+\+|\-\-)\z-          ? cx_lv :
		    $$expr[-2] =~ m e^(?:typ\eof|d\el\et\e)\ze ? cx_any :
		                                                 cx_rv
		  )
		)[1];

		$term = "'JE::Code::Expression::pre$_'->($term)"
		  for reverse @$expr[2..@$expr-2];
		return ret_rv, $term;
	}
	if ($type eq 'postfix') {
# ~~~ taintedness
		# ~~~ These are supposed to use the same rules
		#     as the + and - infix ops for the actual
		#     addition part. Verify that they do this.

		# This will need to be made more efficient:
		# do{
		#   my $l = ...; $l->set(
		#     "JE::Code::Expression::in+"->(
		#       $l->get,
		#       JE::Number->new($global, 1)
		#     )
		#   );
		#   $v
		# }

		return ret_rv, 'do{'
		.  'my$l=' . (_term_to_perl($$expr[2], cx_lv))[1] . ';'
		.  '$l->set('
		.    '"JE::Code::Expression::in+"->('
		.      'my$v=$l->get->to_number,'
		.      _cached('JE\'Number->new($global,'
		               . (-1,1)[$$expr[3] eq '++']. ')')
		.    ')'
		.  ')'
		.  ';$v' x ($cx != cx_void_expr)
		.'}'
	}
	if ($type eq 'new') {
# ~~~			? T && tainted $taint
#~~~				? map $_->can('taint') ?taint $_ $taint:$_,
		return ret_rv, (_term_to_perl($$expr[2],cx_rv))[1]
			.'->construct'
			. ( @$expr == 4
				? '(' . $$expr[-1]->to_perl . ')'
				: '' )
	}
	if($type eq 'member/call') {
		my($type, $obj) = _term_to_perl( $$expr[2],
		  exists $$expr[3]
		  ? ref $$expr[3]eq 'JE::Code::Subscript'
		    ? cx_rv
		    : cx_any
		  : $cx
		);
# ~~~ We can probably optimise this not to create LValue objects for calls,
#     but use the ‘apply’ method directly.
		for (3..$#$expr) {
			my $cx = exists $$expr[$_+1]
				? ref $$expr[$_+1]eq 'JE::Code::Subscript'
				  ? cx_rv
				  : cx_any
				: $cx;
			if(ref $$expr[$_] eq 'JE::Code::Subscript') {
				if($cx != cx_lv && $cx != cx_any) {
				  $obj .= '->prop('
				    . $$expr[$_]->to_perl
				  .')';
				  if($cx == cx_void_expr) {
				    $type = ret_void
				  } else {
				    $obj = "do{my\$v=$obj;"
				    .  'defined$v?$v:$global->undefined}';
				    $type = ret_rv;
				  }
				}
				else {
				  $obj = "JE'LValue->new($obj,"
				    . $$expr[$_]->to_perl . ')';
				  $type = ret_lv
				}
			}
			else {
# ~~~ taintedness for calls
				if($cx != cx_lv && $cx != cx_any) {
				  $obj = 'do{'
				  .  "my\$v=$obj->call("
				  .    $$expr[$_]->to_perl
				  .  ');'
				  .  'ref$v eq"JE::LValue"' . (
				       $cx==cx_void_expr
				       ?'&&$v->get'
				       :'?$v->get:$v'
				      )
				  .'}';
				  $type = ret_rv;
				}
				else {
				  $obj = "$obj->call("
				  .  $$expr[$_]->to_perl
				  .')';
				  $type = ret_any
				}
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
		return $type, $obj; # which may be an lvalue
	}
	if($type eq 'array') {
		if($#$expr < 2) {
			return ret_rv, "JE'Object'Array->new(\$global)"
		}
		my @ary;
		for (2..$#$expr) {
			if(ref $$expr[$_] eq 'comma') {
				ref $$expr[$_-1] eq 'comma' || $_ == 2
				and push @ary, 'undef';
			}
			else {
				push @ary,
				  (_term_to_perl( $$expr[$_], cx_rv ))[1];
			}
		}

		return ret_rv, 'do{my$a=new JE\'Object\'Array $global;'
			. '$$$a{array}=[' . join(',',@ary) . '];$a}'
		                       # sticking it in like that
		                       # makes 'undef' elements non-
		                       # existent, rather
		                       # than undefined
	}
	if($type eq 'hash') {
		local @_ = @$expr[2..$#$expr];
		if(!@_) { return ret_rv, "JE'Object->new(\$global)"; }
		my $obj = 'do{my$o=new JE\'Object $global;';
		my ($key, $value);
		while(@_) { # I have to loop through them to keep
		            # the order.
			$key = _esc_str(shift);
			$value = (_term_to_perl( shift, cx_rv ))[1];
			$obj .= "\$o->prop($key,$value);";
		}
		return ret_rv, $obj . '$o}';
	}
	if ($type eq 'func') {
		# format: [[...], function=> 'name',
		#          [ params ], $statements_obj, \@vars] 
		#     or: [[...], function =>
		#          [ params ], $statements_obj, \@vars]

		# The code we need to produce will be like this:
		# e.g.: function(foo){ bar }
		#   JE'Object'Function->new({
		#     scope=>$scope,
		#     argnames=>['foo'],
		#     function=>$$cache[0],
		#   })
		# If there is a name (function x (){}), it’s a little
		# more complex:
		#   do{
		#     my $f = JE'Object'Function->new({
		#       name => 'x',
		#       scope =>[@$scope, my $o = new JE::Object $global],
		#       ... argnames and function ...
		#     });
		#     $o->prop({ name => 'x', value => $f,
		#                readonly => 1, dontdel => 1 });
		#     $f
		#  }
		# The code object has to be created beforehand and placed
		# in the cache.
		# ~~~ When we merge this with JE::Parser, the entire code
		#     for the code object can be placed in a
		#     $$cache[0]||=....

		my($name,$params,$statements) = ref $$expr[2] ?
			(undef, @$expr[2,3]) : @$expr[2..4];
		my $ret; my $scope;
		if($name) {
			$name = _esc_str($name);
			$ret = 'do{my$f=';
			# ~~~ I should be able to remove this ‘bless’. See
			#     the comment in jE::Object::Function::New
			$scope = 'bless('
			  . '[@$scope,my$o=new JE\'Object $global]'
			  . ',"JE::Scope")'
		}
		
		my $c = $code->{cache}->[my $indx = $cache_indx++] = bless{
			map+($_,$code->{$_}),qw/global source file line/
		}, "JE::Code";
		$c->{tree} = $statements;
		$c->{vars} = $$expr[-1];
		$c->optimise;

		$ret .=
		 "JE'Object'Function->new({"
		.  'scope=>' . ($scope||'$scope') . ','
		.   (defined $name ? ("name=>$name,") : '')
		.  'argnames=>[' . join(',',map _esc_str($_),@$params).'],'
		.  "function=>\$\$cache[$indx]"
		.'})';
		if($name) {
			$ret .=
			 ';$o->prop({'
			.  "name=>$name,"
			.  'value=>$f,'
			.  'readonly=>1,'
			.  'dontdel=>1'
			.'})}'
		}
		return ret_rv,$ret;
	}
}

sub _cached($) {
	my $code_str = shift;
	my $indx = $cache_indx++;
	return "(\$\$cache[$indx]||=$code_str)";
}

use constant nan => sin 9**9**9;
use constant inf => 9**9**9;

sub _term_to_perl {
	my $term = $_[0];
	my $cx = $_[1];

	# For booleans, we just use the expression itself, since the over-
	# loaded booleanness is much faster than ->to_boolean, which has to
	# create an object.

	# For strings and numbers, ->to_string->value16 is only slightly
	# faster than "" for objects,  but the latter is 4x the speed for
	# strings and about 5%  faster for strings  (fewer  method  calls).
	# The converse holds true  (exact  speed  differences  aside)  for
	# ->to_number->value vs 0+ (actually,  in 5.8.8 the  0+  overload-
	# ing for JE::Number is slower than two method calls,  but it’s
	# faster in 5.10).  If we might  have  an  object,  we  must
	# string-/numbify it  immediately  so  that  toString  and
	# valueOf  are called at  the right time.

	# ~~~ Having said all that, we can’t use "..." because it will Uni-
	#     codify the string (un-UTF-16-ify it). We probably need some
	#     new method added to JE::Types and all the classes.

	if(ref $term eq 'JE::Code::Expression') {
		my($rettype,$code,$alt) = $term->to_perl($cx);
		return $rettype,
		$cx == cx_str ?
			defined $alt ? $alt : "$code->to_string->value16" :
		$cx == cx_num ?
			defined $alt ? $alt : "(0+$code)" :
		$cx == cx_bool ?
			defined $alt ? $alt : $code :
			$code
	}
	elsif(ref $term) { # ’better be’n array
		my $code = _cached("scalar(require JE'Object'RegExp,"
			. "JE'Object'RegExp->new(\$global,"
			.  _esc_str($$term[0])
			.  (defined $$term[1]?',' . _esc_str($$term[1]):'')
			. '))');
		return ret_rv,
		$cx == cx_str ?
			"$code->to_string->value16" :
		$cx == cx_num ?
			"(0+$code)" :
			$code
	}

	if($term =~ /^i/) {
		my $find = "\$scope->find_var("
			. _esc_str(substr $term,1)
		. ")";
		return
		$cx == cx_lv || $cx == cx_any ? ( ret_lv,  $find ) :
		$cx==cx_str ?( ret_str, "$find->get->to_string->value16") :
		$cx==cx_bool?( ret_bool,"$find->get" ) :
		$cx==cx_num ?( ret_num, "(0+$find->get)"  ) :
		             ( ret_rv,  "$find->get" )
	}

	return (ret_void,'0') if $cx == cx_void;
	return ret_rv,'die(new JE\'Object\'Error\'ReferenceError $global,'
		.'add_line_number"Cannot assign to a non-lvalue")'
	  if $cx == cx_lv;

	$term eq'this'?
		$cx == cx_str ? (ret_str, "\$this->to_string->value16") :
		$cx == cx_bool ? (ret_bool, '$this') :
		$cx == cx_num ? (ret_num, '(0+$this)') :
		( ret_rv, '$this', 0)
	:
	$term =~ /^s/ ? do {
		my $esc = _esc_str(my $str = substr $term,1);
		$cx == cx_str ? (ret_str, $esc) :
		$cx == cx_bool ? (ret_bool, 0+(length $term > 1)) :
		$cx == cx_num  ? (ret_num,
			# ~~~ JE::Number probably needs a function for
			#     this, as it is a repeat of code found else-			#     where (in JE::String)
		$str =~ /^[\p{Zs}\s\ck]*
		  (
		    [+-]?
		    (?:
		      (?=[0-9]|\.[0-9]) [0-9]* (?:\.[0-9]*)?
		      (?:[Ee][+-]?[0-9]+)?
		        |
		      Infinity
		    )
		    [\p{Zs}\s\ck]*
		  )?
		  \z
		/ox ? defined $1 ? $1 eq 'Infinity' ? 9**9**9 : $1 : 0 :
		$str =~ /^ [\p{Zs}\s\ck]* 0[Xx] ([A-Fa-f0-9]+)
			[\p{Zs}\s\ck]*\z/ox
		? hex $1 : nan
		) : (
			ret_str, _cached "_new JE'String \$global,$esc",
			$esc
		)	
	} :
	$term eq 't' ?
		$cx == cx_str ? (ret_str, '"true"') :
		$cx == cx_bool ? (ret_bool, 1) :
		$cx == cx_num ? (ret_num, 1) :
		( ret_bool, '$global->true', 1)
	:
	$term eq 'f' ?
		$cx == cx_str ? (ret_str, '"false"') :
		$cx == cx_bool ? (ret_bool, 0) :
		$cx == cx_num ? (ret_num, 0) :
		( ret_bool, '$global->false', 0)
	:
	$term eq 'n' ?
		$cx == cx_str ? (ret_str, '"null"') :
		$cx == cx_bool ? (ret_bool, 0) :
		$cx == cx_num ? (ret_num, 0) :
		( ret_rv, '$global->null')
	:
		$cx == cx_str ? (ret_str,
			$term ==  inf ? '"Infinity"' :
			$term ==-+inf ? '"-Infinity"':
			$term == $term?  $term :
			                '"NaN"'
		) :
		$cx == cx_bool ? (ret_bool, 0+($term && $term == $term)) :
		$cx == cx_num  ? (ret_num, $term ) :
		( ret_rv, _cached "JE'Number->new(\$global," . (
			$term == inf ? '"inf"' : $term == -+inf ? '"-inf"':
			$term == $term ? $term : '"nan"'
		 ) . ')', $term )
}




sub JE::Code::Subscript::to_perl {
	my $val = (my $self = shift)->[1];
	ref $val ? $val->to_perl(cx_str) : _esc_str($val); 
}




sub JE::Code::Arguments::to_perl {
	my $self = shift;

	join ',', map +(_term_to_perl($_,cx_rv))[1],   @$self[1..$#$self];
}

1
