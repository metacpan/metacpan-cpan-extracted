package JE::Object::Array;

our $VERSION = '0.066';

use strict;
use warnings; no warnings 'utf8';

use overload fallback => 1,
	'@{}'=> \&_get_tie;


use List::Util qw/min max/;
use Scalar::Util 'blessed';

our @ISA = 'JE::Object';

require JE::Code;
require JE::Object     ;
require JE::Object::Error::TypeError              ;
require JE::Object::Function                            ;
require JE::String                                            ;
require JE::Number                                                       ;

import JE::Code 'add_line_number';
sub add_line_number;

=head1 NAME

JE::Object - JavaScript Array object class

=head1 SYNOPSIS

  use JE;
  use JE::Object::Array;

  $j = new JE;

  $js_array = new JE::Object::Array $j, 1, 2, 3;

  $perl_arrayref = $js_array->value; # returns [1, 2, 3]

  $js_array->[1]; # same as $js_array->value->[1]

  "$js_array"; # returns "1,2,3"

=head1 DESCRIPTION

This module implements JavaScript Array objects.

The C<@{}> (array ref) operator is overloaded and returns a tied array that
you can use to modify the array object itself. The limitations and caveats 
mentioned in
C<JE::Object/"USING AN OBJECT AS A HASH"> apply here, too.

=head1 METHODS

See L<JE::Types> for descriptions of most of the methods. Only what
is specific to JE::Object::Array is explained here.

=over 4

=item $a = JE::Object::Array->new($global_obj, \@elements)

=item $a = JE::Object::Array->new($global_obj, $length)

=item $a = JE::Object::Array->new($global_obj, @elements)

This creates a new Array object.

If the second argument is an unblessed array ref, the elements of that
array become the elements of the new array object.

If there are two arguments and the second
is a JE::Number, a new array is created with that number as the length.

Otherwise, all arguments starting from the second one become elements of
the new array object.

=cut

sub new {
	my($class,$global) = (shift,shift);

	my @array;
	if (ref $_[0] eq 'ARRAY') {
		@array = $global->upgrade(@{+shift});
	} elsif (@_ == 1 && UNIVERSAL::isa $_[0], 'JE::Number') {
		my $num = 0+shift;
		$num == int($num) % 2**32
		    or require JE::Object::Error::RangeError,
		       die JE::Object::Error::RangeError->new($global,
		        add_line_number "$num is not a valid array index");
		$#array = $num - 1;
	}
	else {
		@array = $global->upgrade(@_);
	}
	my $self = SUPER::new $class $global, {
		prototype => $global->prototype_for('Array') ||
		             $global->prop('Array')->prop('prototype')
	};

	my $guts = $$self;

	$$guts{array} = \@array;
	bless $self, $class;
}




sub prop {
	my ($self, $name, $val) =  (shift, @_);
	my $guts = $$self;

	if ($name eq 'length') {
		if (@_ > 1) { # assignment
			$val == int($val) % 2**32 or
				require JE::Object::Error::RangeError,
				die new JE::Object::Error::RangeError
				$$guts{global},
				add_line_number
				 "$val is not a valid value for length";
			$#{$$guts{array}} = $val - 1;
			return JE::Number->new($$guts{global}, $val);
		}
		else {
			return JE::Number->new($$guts{global},
				$#{$$guts{array}} + 1);
		}
	}
	elsif ($name =~ /^(?:0|[1-9]\d*)\z/ and $name < 4294967295) {
		if (@_ > 1) { # assignment
			return $$guts{array}[$name] =
				$$guts{global}->upgrade($val);
		}
		else {
			return exists $$guts{array}[$name]
				? $$guts{array}[$name] : undef;
		}
	}
	$self->SUPER::prop(@_);
}




sub is_enum {
	my ($self,$name) = @_;
	$name eq 'length' and return !1;
	if ($name =~ /^(?:0|[1-9]\d*)\z/ and $name < 4294967295) {
		my $array = $$$self{array};
		return $name < @$array && defined $$array[$name];
	}
	SUPER::is_enum $self $name;
}




sub keys { # length is not enumerable
	my $self = shift;
	my $array = $$$self{array};
	grep(defined $$array[$_], 0..$#$array),
		SUPER::keys $self;
}




sub delete {  # array indices are deletable; length is not
	my($self,$name) = @_;
	$name eq 'length' and return !1;
	if($name =~ /^(?:0|[1-9]\d*)\z/ and $name < 4294967295) {
		my $array = $$$self{array};
		$name < @$array and $$array[$name] = undef;
		return 1;
	}
	SUPER::delete $self $name;
}




=item $a->value

This returns a reference to an array. This is a copy of the Array object's
internal array. If you want an array through which you can modify the
object, use C<@$a>.

=cut

sub value { [@{$${+shift}{array}}] };
*TO_JSON=*value;


sub exists {
	my ($self, $name) =  (shift, @_);
	my $guts = $$self;

	if ($name eq 'length') {
		return 1
	}
	elsif ($name =~ /^(?:0|[1-9]\d*)\z/ and $name < 4294967295) {
		return exists $$guts{array}[$name]
		    && defined $$guts{array}[$name];
	}
	$self->SUPER::exists(@_);
}

sub class { 'Array' }



sub _new_constructor {
	my $global = shift;
	my $construct_cref = sub {
		__PACKAGE__->new(@_);
	};
	my $f = JE::Object::Function->new({
		name            => 'Array',
		scope            => $global,
		function         => $construct_cref,
		function_args    => ['global','args'],
		length           => 1,
		constructor      => $construct_cref,
		constructor_args => ['global','args'],
	});

	my $proto = $f->prop({
		name    => 'prototype',
		dontenum => 1,
		readonly => 1,
	});
	bless $proto, __PACKAGE__;
	$$$proto{array} = [];
	$global->prototype_for('Array',$proto);

	$proto->prop({
		name  => 'toString',
		value => JE::Object::Function->new({
			scope  => $global,
			name   => 'toString',
			length => 0,
			no_proto => 1,
			function_args => ['this'],
			function => \&_toString,
		}),
		dontenum => 1,
	});

	$proto->prop({
		name  => 'toLocaleString',
		value => JE::Object::Function->new({
			scope  => $global,
			name   => 'toLocaleString',
			length => 0,
			no_proto => 1,
			function_args => ['this'],
			function => \&_toLocaleString,
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
			function => \&_concat,
		}),
		dontenum => 1,
	});

	$proto->prop({
		name  => 'join',
		value => JE::Object::Function->new({
			scope  => $global,
			name   => 'join',
			argnames => ['separator'],
			no_proto => 1,
			function_args => ['this','args'],
			function => \&_join,
		}),
		dontenum => 1,
	});

	$proto->prop({
		name  => 'pop',
		value => JE::Object::Function->new({
			scope  => $global,
			name   => 'pop',
			length => 0,
			no_proto => 1,
			function_args => ['this'],
			function => \&_pop,
		}),
		dontenum => 1,
	});

	$proto->prop({
		name  => 'push',
		value => JE::Object::Function->new({
			scope  => $global,
			name   => 'push',
			length => 1,
			no_proto => 1,
			function_args => ['this','args'],
			function => \&_push,
		}),
		dontenum => 1,
	});

	$proto->prop({
		name  => 'reverse',
		value => JE::Object::Function->new({
			scope  => $global,
			name   => 'reverse',
			length => 0,
			no_proto => 1,
			function_args => ['this'],
			function => \&_reverse,
		}),
		dontenum => 1,
	});

	$proto->prop({
		name  => 'shift',
		value => JE::Object::Function->new({
			scope  => $global,
			name   => 'shift',
			length => 0,
			no_proto => 1,
			function_args => ['this'],
			function => \&_shift,
		}),
		dontenum => 1,
	});

	$proto->prop({
		name  => 'slice',
		value => JE::Object::Function->new({
			scope  => $global,
			name   => 'shift',
			argnames => [qw/start end/],
			no_proto => 1,
			function_args => ['this','args'],
			function => \&_slice,
		}),
		dontenum => 1,
	});

	$proto->prop({
		name  => 'sort',
		value => JE::Object::Function->new({
			scope  => $global,
			name   => 'sort',
			argnames => [qw/comparefn/],
			no_proto => 1,
			function_args => ['this','args'],
			function => \&_sort,
		}),
		dontenum => 1,
	});

	$proto->prop({
		name  => 'splice',
		value => JE::Object::Function->new({
			scope  => $global,
			name   => 'splice',
			argnames => [qw/start
			               deleteCount/],
			no_proto => 1,
			function_args => ['this','args'],
			function => \&_splice,
		}),
		dontenum => 1,
	});

	$proto->prop({
		name  => 'unshift',
		value => JE::Object::Function->new({
			scope  => $global,
			name   => 'unshift',
			length => 1,
			no_proto => 1,
			function_args => ['this','args'],
			function => \&_unshift,
		}),
		dontenum => 1,
	});

	$f
}

# ~~~ I should be able to optimise those methods that are designed to work
#    with any JS object by checking first to see whether ref eq __PACKAGE__ 
#  and then doing a fast Perl-style algorithm (reverse would be a good
# candidate for this) 

sub _toString {
	my $self = shift;

	eval{$self->class} eq 'Array'
	or die JE::Object::Error::TypeError->new($self->global,
		add_line_number 'Object is not an Array');

	my $guts = $$self;
	JE::String->_new(
		$$guts{global},
		join ',', map
			defined $_ && ref !~ /^JE::(?:Undefined|Null)\z/
			? $_->to_string->value : '',
			@{ $$guts{array} }
	);
}

sub _toLocaleString {
	my $self = shift;

	eval{$self->class} eq 'Array'
	or die JE::Object::Error::TypeError->new($self->global,
		'Object is not an Array');

	my $guts = $$self;
	JE::String->_new(
		$$guts{global},
		join ',', map
			defined $_ && defined $_->value
				? $_->method('toLocaleString')->value : '',
			@{ $$guts{array} }
	);
}

sub _concat {
	unshift @_, shift->to_object;
	my $thing;
	my $new = __PACKAGE__->new(my $global = $_[0]->global);
	my @new;
	while(@_) {
		$thing = shift;
		if(eval{$thing->class} eq 'Array') {
			push @new, @{ $$$thing{array} };
		}
		else {
			push @new, $thing;
		}
	}

	$$$new{array} = \@new;

	$new;
}

sub _join {
	my( $self,$sep) = @_;
	!defined $sep || $sep->id eq 'undef' and $sep = ',';

	my $length = $self->prop('length');
	if(defined $length) {
		$length = $length->to_number->value % 2**32;
		$length == $length or $length = 0;
	} else { $length = 0 }
	

	my $val;
	JE::String->_new(
		$self->global,
		join $sep,
			map {
				my $val = $self->prop($_);
				defined $val && defined $val->value
				? $val->to_string->value : ''
			} 0..$length-1
	);
}

sub _pop {
	my( $self) = @_;

	my $length = $self->prop('length');
	if(defined $length) {
		$length = (int $length->to_number->value) % 2**32;
		$length == $length or $length = 0;
	} else { $length = 0 }
	
	my $global = $self->global;
	$length or
		$self->prop('length', JE::Number->new($global,0)),
		return $global->undefined;

	
	$length--;
	my $val = $self->prop($length);
	$self->delete($length);
	$self->prop(length => JE::Number->new($global,$length));
	$val;
}

sub _push {
	my( $self) = shift;

	my $length = $self->prop('length');
	if(defined $length) {
		$length = (int $length->to_number->value) % 2**32;
		$length == $length or $length = 0;
	} else { $length = 0 }
	
	while(@_) {
		$self->prop($length++, shift);
	}

	$self->prop(length => JE::Number->new($self->global,$length));
}

sub _reverse {
	my $self = shift;
	
	my $length = $self->prop('length');
	if(defined $length) {
		$length = (int $length->to_number->value) % 2**32;
		$length == $length or $length = 0;
	} else { $length = 0 }
	
	my($elem1,$elem2,$indx2);

	for (0..int $length/2-1) {
		$elem1 = $self->prop($_);
		$elem2 = $self->prop($indx2 = $length - $_ - 1);

		defined $elem2
			? $self->prop($_ => $elem2)
			: $self->delete($_);

		defined $elem1
			? $self->prop($indx2 => $elem1)
			: $self->delete($indx2);
	}

	$self;
}

sub _shift {
	my( $self) = @_;

	my $length = $self->prop('length');
	if(defined $length) {
		$length = (int $length->to_number->value) % 2**32;
		$length == $length or $length = 0;
	} else { $length = 0 }
	
	$length or
		$self->prop('length', 0),
		return $self->global->undefined;

	my $ret = $self->prop(0);
	my $val;

	for (0..$length-2) {
		$val = $self->prop($_+1);
		defined $val
			? $self-> prop($_ => $val)
			: $self->delete($_);
	}
	$self->delete(--$length);
	$self->prop(length => $length);

	$ret;
}

sub _slice {
	my( $self,$start,$end) = @_;

	my $length = $self->prop('length');
	if(defined $length) {
		$length = (int $length->to_number->value) % 2**32;
		$length == $length or $length = 0;
	} else { $length = 0 }
	
	my $new = __PACKAGE__->new(my $global = $self->global);
	my @new;

	if (defined $start) {
		$start = int $start->to_number->value;
		$start  = $start == $start
			? $start < 0
				? max($start + $length,0)
				: min($start, $length)
			: 0;
	}
	else {
		$start = 0
	}

	if (defined $end and $end->id ne 'undef') {
		$end = $end->to_number->value;
		$end  = $end == $end
			? $end < 0
				? max($end + $length,0)
				: min($end, $length)
			: 0;
	}
	else {
		$end = $length
	}
	

	for ($start..$end-1) {
		push @new, $self->prop($_);
	}

	$$$new{array} = \@new;

	$new;
}

sub _sort {
	my($self, $comp) = @_;
	
	my $length = $self->prop('length');
	if(defined $length) {
		$length = (int $length->to_number->value) % 2**32;
		$length == $length or $length = 0;
	} else { $length = 0 }
	
	my(@sortable, @undef, $nonexistent, $val);
	for(0..$length-1) {
		defined($val = $self->prop($_))
			? $val->id eq 'undef'
				? (push @undef, $val)
				: (push @sortable, $val)
			: ++$nonexistent;
	}

	my $comp_sub = defined $comp && $comp->can('call') 
		? sub { 0+$comp->call($a,$b) }
		: sub { $a->to_string->value16 cmp $b->to_string->value16};

	my @sorted = ((sort $comp_sub @sortable),@undef);

	for (0..$#sorted) {
		$self->prop($_ => $sorted[$_]);
	}

	no warnings 'uninitialized';
	for (@sorted .. $#sorted + $nonexistent) {
		$self->delete($_);
	}

	$self;
}

sub _splice {
	my ($self, $start, $del_count) = (shift, shift, shift);
	my $global = $self->global;

	my $length = $self->prop('length');
	if(defined $length) {
		$length = ($length->to_number->value) % 2**32;
		$length == $length or $length = 0;
	} else { $length = 0 };
	
	if (defined $start) {
		$start = int $start->to_number->value;
		$start  = $start == $start
			? $start < 0
				? max($start + $length,0)
				: min($start, $length)
			: 0;
	}
	else {
		$start = 0
	}

	if(defined $del_count) {
		$del_count = int $del_count->to_number->value;
		$del_count = $del_count >= 0
			? min($del_count, $length-$start)
			: 0;
	}
	else {
		$del_count = 0
	}

	my @new = map $self->prop($_),
		$start..(my $end = $start+$del_count-1);

	my $val;
	if (@_ < $del_count) {
		my $diff = $del_count - @_;
		for ($end+1..$length-1) {
			defined ($val = $self->prop($_))
			?	$self->prop ($_ - $diff => $val)
			:	$self->delete($_ - $diff);
		}
		$self->prop(length =>
			JE::Number->new($global, $length - $diff)
		);
	}
	elsif (@_ > $del_count) {
		my $diff = @_ - $del_count;
		for (reverse $end+1..$length-1) {
			defined ($val = $self->prop($_))
			?	$self->prop ($_ + $diff => $val)
			:	$self->delete($_ + $diff);
		}
		$self->prop(length =>
			JE::Number->new($global, $length + $diff)
		);
	}
	else {
		$self->prop(length => JE::Number->new($global,$length));
	}

	for (0..$#_) {
		$self->prop($_+$start => $_[$_]);
	}

	my $new = __PACKAGE__->new($self->global);
	$$new->{array} = \@new;
	
	$new;
}

sub _unshift {
	my ($self) = (shift,);

	my $length = $self->prop('length');
	if(defined $length) {
		$length = (int $length->to_number->value) % 2**32;
		$length == $length or $length = 0;
	} else { $length = 0 }

	my $val;
	for (reverse 0..$length-1) {
		defined ($val = $self->prop($_))
		?	$self->prop ($_ + @_ => $val)
		:	$self->delete($_ + @_);
	}

	for (0..$#_) {
		$self->prop($_ => $_[$_]);
	}
	$self->prop(length => $length += @_);

	return JE::Number->new($self->global, $length);
}


#----------- TYING MAGIC ---------------#

sub _get_tie {
	my $self = shift;
	my $guts = $$self;
	$$guts{array_tie} or tie @{ $$guts{array_tie} }, __PACKAGE__,
		$self;	
	$$guts{array_tie};
}

# The qw/FETCH EXISTS DELETE/ methods are inherited from JE::Object.

sub TIEARRAY  { $_[1] }
sub FETCHSIZE { $_[0]->prop('length') }
sub STORESIZE { $_[0]->prop('length' => $_[1]) }
sub PUSH      { shift->method(push => @_) }
sub POP       { $_[0]->method('pop') }
sub SHIFT     { $_[0]->method('shift') }
sub UNSHIFT   { shift->method(unshift => @_) }
sub SPLICE    { @{ shift->method(splice  => @_)->value } }
sub DDS_freeze {
	my $self = shift;
	delete $$$self{array_tie};
	SUPER::DDS_freeze $self;
}

=back

=head1 SEE ALSO

L<JE>

L<JE::Types>

L<JE::Object>

=cut

1;
