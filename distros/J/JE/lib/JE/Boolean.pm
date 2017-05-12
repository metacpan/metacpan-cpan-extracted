package JE::Boolean;

our $VERSION = '0.066';


use strict;
use warnings;

use overload fallback => 1,
	'""' =>  sub { qw< false true >[shift->[0]] },
#	 cmp =>  sub { "$_[0]" cmp $_[1] },
	bool =>  sub { shift->[0] },
	'0+' =>  sub { shift->[0] };

# ~~~ to do: make sure it numifies properly (as 0 or 1)

require JE::Object::Boolean;
require JE::Number;
require JE::String;


sub new {
	my($class, $global, $val) = @_;
	bless [!!$val, $global], $class;
}


sub prop {
	if(@_ > 2) { return $_[2] } # If there is a value, just return it

	my ($self, $name) = @_;
	
	$$self[1]->prototype_for('Boolean')->prop($name);
}

sub keys {
	my $self = shift;
	$$self[1]->prototype_for('Boolean')->keys;
}

sub delete {1}

sub method {
	my $self = shift;
	$$self[1]->prototype_for('Boolean')->prop(shift)->apply(
		$self,$$self[1]->upgrade(@_)
	);
}


sub value { warn caller if !ref $_[0];shift->[0] }
sub TO_JSON { \(0+shift->[0]) }

sub exists { !1 }

sub typeof    { 'boolean' }
sub class     { 'Boolean' }
sub id        { 'bool:' . shift->value }
sub primitive { 1 }

sub to_primitive { $_[0] }
sub to_boolean   { $_[0] }


# $_[0][1] is the global object
sub to_string { JE::String->_new($_[0][1], qw< false true >[shift->[0]]) }
sub to_number { JE::Number->new($_[0][1], shift->[0]) }
sub to_object { JE::Object::Boolean->new($_[0][1], shift) }

sub global { $_[0][1] }



1;
__END__

=head1 NAME

JE::Boolean - JavaScript boolean value

=head1 SYNOPSIS

  use JE;
  use JE::Boolean;

  $j = JE->new;

  $js_true  = new JE::Boolean $j, 1;
  $js_false = new JE::Boolean $j, 0;

  $js_true ->value; # returns 1
  $js_false->value; # returns ""

  "$js_true"; # returns "true"
 
  $js_true->to_object; # returns a new JE::Object::Boolean

=head1 DESCRIPTION

This class implements JavaScript boolean values for JE. The difference
between this and JE::Object::Boolean is that that module implements
boolean
I<objects,> while this module implements the I<primitive> values.

The stringification and boolean operators are overloaded.

=head1 SEE ALSO

=over 4

=item L<JE>

=item L<JE::Types>

=item L<JE::Object::Boolean>

=back
