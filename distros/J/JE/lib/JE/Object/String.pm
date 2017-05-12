package JE::Object::String;

our $VERSION = '0.066';


use strict;
use warnings; no warnings 'utf8';

sub surrogify($);
sub desurrogify($);

our @ISA = 'JE::Object';

use POSIX qw 'floor ceil';
use Scalar::Util 'blessed';

require JE::Code;
require JE::Number;
require JE::Object                 ;
require JE::Object::Error::TypeError;
require JE::Object::Function        ;
require JE::String                 ;

JE::String->import(qw/surrogify desurrogify/);
JE::Code->import('add_line_number');
sub add_line_number;

=encoding UTF-8

=head1 NAME

JE::Object::String - JavaScript String object class

=head1 SYNOPSIS

  use JE;
  use JE::Object::String;

  $j = new JE;

  $js_str_obj = new JE::Object::String $j, "etetfyoyfoht";

  $perl_str = $js_str_obj->value;

=head1 DESCRIPTION

This class implements JavaScript String objects for JE. The difference
between this and JE::String is that that module implements
I<primitive> string value, while this module implements the I<objects.>

=head1 METHODS

See L<JE::Types> for descriptions of most of the methods. Only what
is specific to JE::Object::String is explained here.

=over 4

=cut

sub new {
	my($class, $global, $val) = @_;
	my $self = $class->SUPER::new($global, {
		prototype => $global->prototype_for('String')
		          || $global->prop('String')->prop('prototype')
	});

	$$$self{value} = defined $val
		? defined blessed $val
		  && $val->can('to_string')
			? $val->to_string->value16
			: surrogify $val
		: '';
	$self;
}

sub prop {
	my $self = shift;
	if($_[0] eq 'length') {
		return JE::Number->new(
			$$$self{global},length $$$self{value}
		);
	}
	SUPER::prop $self @_;
}

sub delete {
	my $self = shift;
	$_[0] eq 'length' and return !1;
	SUPER::delete $self @_;
}

=item value

Returns a Perl scalar.

=cut

sub value { desurrogify ${+shift}->{value} }

=item value16

Returns a Perl scalar containing a UTF-16 string (i.e., with surrogate
pairs if the string has chars outside the BMP). This is here more for
internal usage than anything else.

=cut

sub value16 { ${+shift}->{value} }



sub is_readonly {
	my $self = shift;
	$_[0] eq 'length' and return 1;
	SUPER::is_readonly $self @_;
}

sub class { 'String' }

no warnings 'qw';
our %_replace = qw/
	$	\$
	&	".substr($str,$-[0],$+[0]-$-[0])."
	`	".substr($str,0,$-[0])."
	'	".substr($str,$+[0])."
/;

sub _new_constructor {
	my $global = shift;
	my $f = JE::Object::Function->new({
		name            => 'String',
		scope            => $global,
		function         => sub {
			my $arg = shift;
			defined $arg ? $arg->to_string :
				JE::String->_new($global, '');
		},
		function_args    => ['args'],
		argnames         => ['value'],
		constructor      => sub {
			unshift @_, __PACKAGE__;
			goto &new;
		},
		constructor_args => ['scope','args'],
	});

	# E 15.5.3.2
	$f->prop({
		name  => 'fromCharCode',
		value => JE::Object::Function->new({
			scope  => $global,
			name   => 'fromCharCode',
			length => 1,
			no_proto => 1,
			function_args => ['args'],
			function => sub {
				my $str = '';
				my $num;
				for (@_) {
					# % 2**16 is buggy in perl
					$num = $_->to_number->value;
					$num = 
					  ($num < 0 ? ceil$num : floor$num)
						% 2**16 ;
					$str .= chr($num == $num && $num);
						# change nan to 0
				}
				JE::String->_new($global, $str);
			},
		}),
		dontenum => 1,
	});

	my $proto = bless $f->prop({
		name    => 'prototype',
		dontenum => 1,
		readonly => 1,
	}), __PACKAGE__;
	$$$proto{value} = '';
	$global->prototype_for('String', $proto);

	$proto->prop({
		name  => 'toString',
		value => JE::Object::Function->new({
			scope  => $global,
			name   => 'toString',
			no_proto => 1,
			function_args => ['this'],
			function => sub {
				my $self = shift;
				die JE::Object::Error::TypeError->new(
					$global, add_line_number
					"Argument to toString is not a " .
					"String object"
				) unless $self->class eq 'String';

				return $self if ref $self eq 'JE::String';
				JE::String->_new($global, $$$self{value});
			},
		}),
		dontenum => 1,
	});

	$proto->prop({
		name  => 'valueOf',
		value => JE::Object::Function->new({
			scope  => $global,
			name   => 'valueOf',
			no_proto => 1,
			function_args => ['this'],
			function => sub {
				my $self = shift;
				die JE::Object::Error::TypeError->new(
					$global, add_line_number
					"Argument to valueOf is not a " .
					"String object"
				) unless $self->class eq 'String';

				# We also deal with plain strings here.
				ref $self eq 'JE::String'
				 ? $self
				 : JE::String->_new(
				    $global, $$$self{value}
				   );
			},
		}),
		dontenum => 1,
	});

	$proto->prop({
		name  => 'charAt',
		value => JE::Object::Function->new({
			scope  => $global,
			name   => 'charAt',
			argnames => ['pos'],
			no_proto => 1,
			function_args => ['this','args'],
			function => sub {
				my ($self,$pos) = @_;
				
				my $str = $self->to_string->value16;
				if (defined $pos) {
					$pos = int $pos->to_number->[0];
					$pos = 0 unless $pos == $pos;
				}

				JE::String->_new($global,
					$pos < 0 || $pos >= length $str
						? ''
						: substr $str, $pos, 1);
			},
		}),
		dontenum => 1,
	});

	$proto->prop({
		name  => 'charCodeAt',
		value => JE::Object::Function->new({
			scope  => $global,
			name   => 'charCodeAt',
			argnames => ['pos'],
			no_proto => 1,
			function_args => ['this','args'],
			function => sub {
				my ($self,$pos) = @_;
				
				my $str = $self->to_string->value16;
				if (defined $pos) {
					$pos = int $pos->to_number->[0];
					$pos = 0 unless $pos == $pos;
				}

				JE::Number->new($global,
					$pos < 0 || $pos >= length $str
					    ? 'nan'
					    : ord substr $str, $pos, 1);
			},
		}),
		dontenum => 1,
	});

	$proto->prop({
		name  => 'concat',
		value => JE::Object::Function->new({
			scope  => $global,
			name   => 'concat',
			length => 1,
			no_proto => 1,
			function_args => ['this','args'],
			function => sub {
				my $str = '';
				for (@_) {
					$str .= $_->to_string->value16
				}
				JE::String->_new($global, $str);
			},
		}),
		dontenum => 1,
	});

	$proto->prop({
		name  => 'indexOf',
		value => JE::Object::Function->new({
			scope  => $global,
			name   => 'indexOf',
			length => 1,
			argnames => [qw/searchString position/],
			no_proto => 1,
			function_args => ['this','args'],
			function => sub {
				my $str = shift->to_string->value16;
				my $find = defined $_[0]
						? $_[0]->to_string->value16
						: 'undefined';
				my $start = defined $_[1]
							? $_[1]->to_number
								->value
							: 0;
				JE::Number->new($global,
					# In -DDEBUGGING builds of perl (as
					# of 5.13.2), a $start greater than
					# the length causes a panick, so we
					# avoid passing that to index(), as
					# of version 0.049.
					$start > length $str
					? length $find ? -1 : length $str
					: index $str, $find, $start
				);
			},
		}),
		dontenum => 1,
	});

	$proto->prop({
		name  => 'lastIndexOf',
		value => JE::Object::Function->new({
			scope  => $global,
			name   => 'lastIndexOf',
			length => 1,
			argnames => [qw/searchString position/],
			no_proto => 1,
			function_args => ['this','args'],
			function => sub {
				my $string = shift->to_string->value16;
				my $pos = length $string;
				if(defined $_[1] && $_[1]->id ne 'undef') {
					my $p = $_[1]->to_number->value;
					$p < $pos and $pos = $p
				}
				JE::Number->new($global, rindex
					$string,
					defined $_[0]
						? $_[0]->to_string->value16
						: 'undefined',
					$pos
				);
			},
		}),
		dontenum => 1,
	});

	$proto->prop({   # ~~~ I need to figure out how to deal with
	                #     locale settings
		name  => 'localeCompare',
		value => JE::Object::Function->new({
			scope  => $global,
			name   => 'localeCompare',
			argnames => [qw/that/],
			no_proto => 1,
			function_args => ['this','args'],
			function => sub {
				my($this,$that) = @_;
				JE::Number->new($global,
					$this->to_string->value	
					   cmp
					defined $that
						? $that->to_string->value
						: 'undefined'
				);
			},
		}),
		dontenum => 1,
	});

	$proto->prop({
		name  => 'match',
		value => JE::Object::Function->new({
			scope  => $global,
			name   => 'match',
			argnames => [qw/regexp/],
			no_proto => 1,
			function_args => ['this','args'],
			function => sub {
				my($str, $re_obj) = @_;

				$str = $str->to_string;

				!defined $re_obj || 
				    (eval{$re_obj->class}||'') ne 'RegExp'
				 and do {
				      require JE::Object::RegExp;
				      $re_obj =	
					JE::Object::RegExp->new($global, 
						$re_obj);
				     };
		
				my $re = $re_obj->value;

				# For non-global patterns and string, reg-
				# exps, just return the fancy array result-
				# from a call to String.prototype.exec

				if (not $re_obj->prop('global')->value) {
					return $global
						->prototype_for('RegExp')
						->prop('exec')
						->apply($re_obj, $str);
				}

				# For global patterns, I just do the
				# matching here, since it's faster.

				# ~~~ Problem: This is meant to call String
				#   .prototype.exec, according to the spec,
				#  which method can, of course, be replaced
				# with a user-defined function. So much for
				# this optimisation. (But, then, no one
				# else follows the spec!)
				
				$str = $str->value16;

				my @ary;
				while($str =~ /$re/g) {
					push @ary, JE::String->_new($global,
						substr $str, $-[0],
						$+[0] - $-[0]);
				}
				
				JE::Object::Array->new($global, \@ary);
			},
		}),
		dontenum => 1,
	});

	$proto->prop({
		name  => 'replace',
		value => JE::Object::Function->new({
			scope  => $global,
			name   => 'replace',
			argnames => [qw/searchValue replaceValue/],
			no_proto => 1,
			function_args => ['this','args'],
			function => sub {
				my($str, $foo, $bar) = @_;
					# as in s/foo/bar/

				$str = $str->to_string->value16;

				my $g; # global?
				if(defined $foo && $foo->can('class') &&
					$foo->class eq 'RegExp') 
				{
					$g = $foo->prop('global')->value;
					$foo = $$$foo{value};
				}
				else {
				    $g = !1;
				    $foo = defined $foo
				       ? quotemeta $foo->to_string->value16
				       : 'undefined';
				}

				if (defined $bar && $bar->can('class') &&
				    $bar->class eq 'Function') {
					my $replace = sub {
					    $global
					     ->prototype_for('RegExp')
					     ->prop('constructor')
					     ->capture_re_vars($str);
					
					    $_[0]->call(
					      JE::String->_new($global,
					        substr $str, $-[0],
					          $+[0] - $-[0]),
					      map(JE::String->_new(
					        $global,
					        $JE'Object'RegExp'Match[$_]
					      ), 1..$#+),
					      JE::Number->new($global,
					        $-[0]),
					      $_[1]
					    )->to_string->value16
					};

					my $je_str = JE::String->_new(
						$global, $str);

					$g
					? $str =~ s/$foo/
					    &$replace($bar, $je_str)
					/ge
					: $str =~ s/$foo/
					    &$replace($bar, $je_str)
					/e
				}
				else {
					# replacement string instead of
					# function (a little tricky)

					# We need to use /ee and surround
					# bar with double quotes, so that
					# '$1,$2' becomes eval  '"$1,$2"'.
					# And so we also have to quotemeta
					# the whole string.

					# I know the indiscriminate
					# untainting may seem a little
					# dangerous, but quotemeta takes
					# care of it.
					$bar = defined $bar
					   ? do {
					      $bar->to_string->value16
					          =~ /(.*)/s; # untaint
					      quotemeta $1
					   }
					   : 'undefined';

					# now $1, $&, etc have become \$1,
					# \$\& ...

					$bar =~ s/\\\$(?:
						\\([\$&`'])
						  |
						([1-9][0-9]?|0[0-9])
					)/
						defined $1 ? $_replace{$1}
						: "\$JE::Object::RegExp::"
						. "Match[$2]";
					/gex;

					my $orig_str = $str;
					no warnings 'uninitialized';
					$g ? $str =~ s/$foo/qq'"$bar"'/gee
					   : $str =~ s/$foo/qq'"$bar"'/ee
					and
					 $global
					  ->prototype_for('RegExp')
					  ->prop('constructor')
					  ->capture_re_vars($orig_str);
				}
					
				JE::String->_new($global, $str);
			},
		}),
		dontenum => 1,
	});

	$proto->prop({
		name  => 'search',
		value => JE::Object::Function->new({
			scope  => $global,
			name   => 'search',
			argnames => [qw/regexp/],
			no_proto => 1,
			function_args => ['this','args'],
			function =>
sub {
	my($str, $re) = @_;

	$re = defined $re ?(eval{$re->class}||'')eq 'RegExp' ? $re->value :
		do {
		  require JE::Object::RegExp;
		  JE::Object::RegExp->new($global, $re)->value
		} : qr//;

	return JE::Number->new(
	 $global,
	 ($str = $str->to_string->value16) =~ $re
	  ? scalar(
	     $global->prototype_for('RegExp')
	      ->prop('constructor')
	      ->capture_re_vars($str),
	     $-[0]
	    )
	  :-1
	);
}
		}),
		dontenum => 1,
	});

	$proto->prop({
		name  => 'slice',
		value => JE::Object::Function->new({
			scope  => $global,
			name   => 'slice',
			argnames => [qw/start end/],
			no_proto => 1,
			function_args => ['this','args'],
			function => sub {
my($str, $start, $end) = @_;

$str = $str->to_string->value16;
my $length = length $str;

if (defined $start) {
	$start = int $start->to_number->value;
	$start = $start == $start && $start; # change nan to 0

	$start >= $length and return JE::String->_new($global, '');
#	$start < 0 and $start = 0;
}
else { $start =  0; }

if (defined $end && $end->id ne 'undef') {
	$end = int $end->to_number->value;
	$end = $end == $end && $end;

	$end > 0 and $end -= $start + $length * ($start < 0);
}
else { $end = $length }

return  JE::String->_new($global, substr $str, $start, $end);

			},
		}),
		dontenum => 1,
	});


=begin split-notes

If the separator is a non-empty string, we need to quotemeta it.

If we have an empty string, we mustn’t allow a match at the end of the
string, so we use qr/(?!\z)/.

If we have a regexp, then there are several issues:

A successful zero-width match that occurs at the same position as
the end of the previous match needs to be turned into a failure
(no backtracking after the initial successful match), so as to
produce the aardvark result below. We could accomplish this by
wrapping it in an atomic group: /(?> ... )/. But then we come
to the second issue:

To ensure correct (ECMAScript-compliant) capture erasure in cases
like 'cbazyx'.split(/(a|(b))+/) (see 15.10-regexps-objects.t), we need to
use @JE::Object::RegExp::Match, rather than $1, $2, etc.

This precludes the use of perl’s split operator (at least for regexp sepa-
rators), so we have to implement it ourselves.

We also need to make sure that a null match does not occur at the end of
a string. Since a successful match that begins at the end of a string can-
not but be a zero-length match,  we could conceptually put (?!\z)  at the
beginning of the match,  but qr/...$a_qr_with_embedded_code/ causes weird
scoping issues (the embedded code, although it was compiled in a separate
package,  somehow makes its way into the package that combined it  in  a
larger regexp); hence the somewhat complex logic below.


join ',', split /a*?/, 'aardvark'       gives ',,r,d,v,,r,k'
'aardvark'.split(/a*?/).toString()      gives 'a,a,r,d,v,a,r,k'

-----
JS's 'aardvark'.split('', 3) means (split //, 'aardvark', 4)[0..2]

=end split-notes

=cut


	$proto->prop({
		name  => 'split',
		value => JE::Object::Function->new({
			scope  => $global,
			name   => 'split',
			argnames => [qw/separator limit/],
			no_proto => 1,
			function_args => ['this','args'],
			function => sub {
				my($str, $sep, $limit) = @_;

				$str = (my $je_str = $str->to_string)
					->value16;

				if(!defined $limit ||
				   $limit->id eq 'undef') {
					$limit = -2;
				}
				elsif(defined $limit) {
				  $limit = int($limit->to_number->value)
				    % 2 ** 32;
				  $limit = $limit == $limit && $limit;
				    # Nan --> 0
				}
				
				if (defined $sep) {
				  if ($sep->can('class')
				      && $sep->class eq 'RegExp') {
				    $sep = $sep->value;
				  }
				  elsif($sep->id eq 'undef') {
				    return JE::Object::Array->new(
				      $global, $je_str
				    );
				  }
				  else {
				    $sep = $sep->to_string->value16;
				  }
				}
				else {
				    return JE::Object::Array->new(
				      $global, $je_str
				    );
				}
				
				my @split;

				if (!ref $sep) {
				  $sep = length $sep ? quotemeta $sep :
				    qr/(?!\z)/;
				  @split = split $sep, $str, $limit+1;
				  goto returne;
				}

				!length $str and
				  ''=~ $sep || (@split = ''),
				  goto returne;
				
				my$pos = 0;
				while($str =~ /$sep/gc) {
				  $pos == pos $str and ++pos $str, next;
				    # That ++pos won’t go past the end of
				    # the string, so it may end up being a
				    # no-op;  but the  ‘next’  bypasses the
				    # pos assignment below, so perl refuses
				    # to match again at the same  position.
				  $-[0] == length $str and last;
				  push @split,substr($str,$pos,$-[0]-$pos),
				    @JE::Object::RegExp::Match[
				      1..$#JE::Object::RegExp::Match
				    ];
				  $pos = pos $str = pos $str;
				    # Assigning pos to itself has the same
				    # effect as using an atomic group
				    # with split
				}
				push @split, substr($str, $pos);

				returne:
				JE::Object::Array->new($global,
				  $limit == -2 ? @split : @split ? @split[
				    0..(@split>$limit?$limit-1:$#split)
				  ] : @split);

			},
		}),
		dontenum => 1,
	});

	$proto->prop({
		name  => 'substring',
		value => JE::Object::Function->new({
			scope  => $global,
			name   => 'substring',
			argnames => [qw/start end/],
			no_proto => 1,
			function_args => ['this','args'],
			function => sub {
my($str, $start, $end) = @_;

$str = $str->to_string->value16;
my $length = length $str;


if (defined $start) {
	$start = int $start->to_number->value;
	$start >= 0 or $start = 0;
}
else { $start =  0; }


if (!defined $end || $end->id eq 'undef') {
	$end = $length;
}
else {
	$end = int $end->to_number->value;
	$end >= 0 or $end = 0;
}

$start > $end and ($start,$end) = ($end,$start);

no warnings 'substr'; # in case start > length
my $x= substr $str, $start, $end-$start;
return  JE::String->_new($global, defined $x ? $x : '');

			},
		}),
		dontenum => 1,
	});

	$proto->prop({
		name  => 'toLowerCase',
		value => JE::Object::Function->new({
			scope  => $global,
			name   => 'toLowerCase',
			no_proto => 1,
			function_args => ['this'],
			function => sub {
				my $str = shift;

				JE::String->_new($global,
					lc $str->to_string->value16);
			},
		}),
		dontenum => 1,
	});

	$proto->prop({
		name  => 'toLocaleLowerCase',
		value => JE::Object::Function->new({
			scope  => $global,
			name   => 'toLocaleLowerCase',
			no_proto => 1,
			function_args => ['this'],
			function => sub { # ~~~ locale settings?
				my $str = shift;

				JE::String->_new($global,
					lc $str->to_string->value);
			},
		}),
		dontenum => 1,
	});

	$proto->prop({
		name  => 'toUpperCase',
		value => JE::Object::Function->new({
			scope  => $global,
			name   => 'toUpperCase',
			no_proto => 1,
			function_args => ['this'],
			function => sub {
				my $str = shift;

				JE::String->_new($global,
					uc $str->to_string->value16);
			},
		}),
		dontenum => 1,
	});

	$proto->prop({
		name  => 'toLocaleUpperCase',
		value => JE::Object::Function->new({
			scope  => $global,
			name   => 'toLocaleUpperCase',
			no_proto => 1,
			function_args => ['this'],
			function => sub { # ~~~ locale settings?
				my $str = shift;

				JE::String->_new($global,
					uc $str->to_string->value);
			},
		}),
		dontenum => 1,
	});

	$proto->prop({
		name  => 'substr',
		value => JE::Object::Function->new({
			scope  => $global,
			name   => 'substr',
			argnames => [qw/start length/],
			no_proto => 1,
			function_args => ['this','args'],
			function => sub {
my($str, $start, $len) = @_;

$str = $str->to_string->value16;

if (defined $start) {
	$start = int $start->to_number->value;
}
else { $start =  0; }


if (!defined $len || $len->id eq 'undef') {
	$len = undef;
}
else {
	$len = int $len->to_number->value;
}

return  JE::String->_new($global, defined $len ?
	(substr $str, $start, $len) :
	(substr $str, $start)
);

			},
		}),
		dontenum => 1,
	});

	$f;
}



return "a true value";

=back

=head1 SEE ALSO

=over 4

=item JE

=item JE::Types

=item JE::String

=item JE::Object

=back

=cut




