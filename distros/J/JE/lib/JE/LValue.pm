package JE::LValue;

our $VERSION = '0.066';

use strict;
use warnings; no warnings 'utf8';

use List::Util 'first';
use Scalar::Util 'blessed';

require JE::Code;
require JE::Object::Error::TypeError;
require JE::Object::Error::ReferenceError;

import JE::Code 'add_line_number';
sub add_line_number;


our $ovl_infix = join ' ', @overload::ops{qw[
	with_assign assign num_comparison 3way_comparison str_comparison	binary
]};
our $ovl_prefix = join ' ', grep !/^(?:neg|atan2)\z/,
	map split(/ /), @overload::ops{qw[ unary mutators func ]};

use overload
fallback => !1,
nomethod => sub {
	my $at = $@;
	my ($self, $other, $reversed, $symbol) = @_;
	return $self if $symbol eq '=';
	$self = $self->get;
	my $sym_regexp = qr/(?:^| )\Q$symbol\E(?:$| )/;
	my $val;
	if ($overload::ops{conversion} =~ $sym_regexp) {
		return $self;
	}
	elsif($ovl_infix =~ $sym_regexp) {
		my $bits = (caller 0)[9];
		$val = eval 'BEGIN{${^WARNING_BITS} = $bits}'
		         . ( $reversed ? "\$other $symbol \$self"
		                       : "\$self $symbol \$other" );
	}
	elsif($ovl_prefix =~ $sym_regexp) {
		my $bits = (caller 0)[9];
		$val
		 = eval "BEGIN{\${^WARNING_BITS} = \$bits}$symbol \$self";
	}
	elsif($symbol eq 'neg') {
		return -$self;
	}
	elsif($symbol eq 'atan2') {
		return atan2 $self, $other;
	}
	elsif($symbol eq '<>') {
		return <$self>;
	}
	else {
		die "Oh no! Something is terribly wrong with " .
		    "JE::LValue's overloading mechanism. It can't deal " .
		    "with < $symbol >. Please send a bug report.";
	}
	$@ and die $@;
	$@ = $at;
	return $val;
},
'@{}' => sub {
	caller eq __PACKAGE__ and return shift;	
	$_[0]->get;
},
'%{}' => 'get', '&{}' => 'get', '*{}' => 'get', '${}' => 'get';

sub new {
	my ($class, $obj, $prop) = @_; # prop is a string
	if(defined blessed $obj && can $obj 'id'){
		my $id = $obj->id;
		$id eq 'null' || $id eq 'undef' and die 
			new JE::Object::Error::TypeError $obj->global,
			add_line_number
			    $obj->to_string->value . " has no properties"
			    .", not even one named $prop";
	}
	bless [$obj, $prop], $class;
}

sub get {
	my $base = (my $self = shift)->[0];
	defined blessed $base or die new 
		JE::Object::Error::ReferenceError $$base, add_line_number 
		"The variable $$self[1] has not been declared";
		
	my $val = $base->prop($self->[1]);
	defined $val ? $val : $base->global->undefined;
		# If we have a Perl undef, then the property does not
		# not exist, and we have to return a JS undefined val.
}

sub set {
	my $obj = (my $self = shift)->[0];
	defined blessed $obj or $obj = $$self[0] = $$obj;
	$obj->prop($self->[1], shift);
}

sub call {
	my $base_obj = (my $self = shift)->[0];
	my $prop = $self->get; # dies here if $base_obj is not blessed
	defined $prop or
		die new JE::Object::Error::TypeError $base_obj->global,
		add_line_number "The object's '" . $self->[1] .
			"' property (undefined) is not a function";
	$prop->can('apply') or
		die new JE::Object::Error::TypeError $base_obj->global,
		add_line_number "The object's '" . $self->[1] .
			"' property ($prop) is not a function";
	$prop->apply($base_obj, @_);
}

sub base { 
	my $base = $_[0][0];
	defined blessed $base ? $base : ()
}

sub property { shift->[1] }

our $AUTOLOAD;

sub AUTOLOAD {
	my($method) = $AUTOLOAD =~ /([^:]+)\z/;

	return if $method eq 'DESTROY';

#my $l = $_[0]; my $ret, my @ret;;
no warnings 'uninitialized';
#eval {
# $ret =	
return shift->get->$method(@_); # ~~~ Maybe I should use goto
	                         #     to remove AUTOLOAD from
	                         #     the call stack.
#1} or die add_line_number $l->base . ' ' . $l->property . ' ' . $l->get . #' ' . ref $_->get . qq': $@';
#return $ret;
}

sub can { # I think this returns a *canned* lvalue, as opposed to a fresh
          # one. :-)
	
	!ref $_[0] || $_[1] eq 'DESTROY' and goto &UNIVERSAL::can;

	&UNIVERSAL::can || do {
	                        my $sub = (my $obj = shift->get)->can(@_)
	                         or return undef;
	                        sub { splice @'_, 0, 1, $obj; goto &$sub }
	                      };
}



=head1 NAME

JE::LValue - JavaScript lvalue class

=head1 SYNOPSIS

  use JE::LValue;

  $lv = new JE::LValue $some_obj, 'property_name';

  $lv->get;         # get property
  $lv->set($value)  # set property

  $lv->some_other_method  # same as $lv->get->some_other_method

=head1 DESCRIPTION

This class implements JavaScript lvalues (called "Reference Types" by the
ECMAScript specification).

=head1 METHODS AND OVERLOADING

If a method is called that is not listed here, it will be passed to the 
property referenced by the lvalue. (See the last item in the L<SYNOPSIS>,
above.) For this reason, you should never call C<UNIVERSAL::can> on a
JE::LValue, but, rather, call it as a method (C<< $lv->can(...) >>), unless
you really know what you are doing.

Similarly, if you try to use an overloaded operator, it will be passed on 
to
the object that the lvalue references, such that C<!$lvalue> is the same
as calling C<< !$lvalue->get >>.

=over 4

=item $lv = new JE::LValue $obj, $property

Creates an lvalue/reference with $obj as the base object and $property
as the property name. If $obj is undefined or null, a TypeError is thrown.
To create a lvalue that has no base object, and which will throw a
ReferenceError when 
C<< ->get >> is
called and create a global property upon invocation of C<< ->set >>, pass
an unblessed reference to a global object as the first argument. (This is
used by bare identifiers in JS expressions.)

=item $lv->get

Gets the value of the property.

=item $lv->set($value)

Sets the property to $value and returns $value. If the lvalue has no base
object, the global object will become its base object automatically. 
<Note:> Whether the lvalue object itself is modified in the latter case is
not set in stone yet. (Currently it is modified, but that may change.) 

=item $lv->call(@args)

If the property is a function, this calls the function with the
base object as the 'this' value.

=item $lv->base

Returns the base object. If there isn't any, it returns undef or an empty
list, depending on context.

=item $lv->property

Returns the property name.

=back

=cut




1;
