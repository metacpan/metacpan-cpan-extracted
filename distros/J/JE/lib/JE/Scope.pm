package JE::Scope;

our $VERSION = '0.066';

use strict;
use warnings; no warnings 'utf8';

require JE::LValue;

our $AUTOLOAD;

# ~~~ We need a C<can> method.

sub find_var {
	my ($self,$var) = @_;
	my $lvalue;

	for(reverse @$self) {
		my $p = $_;
		defined($p=$p->prototype) or next  while !$p->exists($var);
		return new JE::LValue $_, $var;
	}
	# if we get this far, then we create an lvalue without a base obj
	new JE::LValue \$self->[0], $var;
}

sub new_var {
	my ($self,$var) = (shift,shift);
	my $var_obj;
	for(reverse @$self[1..$#$self]) { # Object  0  can't  be  a  call 
	                                 # object. Omitting it should the-
	                               # oretically make  things  margin-
	                            # ally faster.
		ref $_ eq 'JE::Object::Function::Call' and
			$var_obj = $_,
			last;
	}
	defined $var_obj or $var_obj = $$self[0];

	if (defined $var_obj->prop($var)) {
		$var_obj->prop($var, shift) if @_;
	}
	else {
		$var_obj->prop($var, @_ ? shift :
			$$self[0]->undefined);

		# This is very naughty code, but it works.	
		$JE::Code::Expression::_eval or $var_obj->prop({
			name => $var,
			dontdel => 1,
		});
	}

	return new JE::LValue $var_obj, $var
		unless not defined wantarray;
}

sub AUTOLOAD { # This delegates the method to the global object
	my($method) = $AUTOLOAD =~ /([^:]+)\z/;

	 # deal with various ALLCAPS names
	if($method =~ /^[A-Z]+\z/) {
		substr($method,0,0) = 'SUPER::';
		local *@;
		return eval { shift->$method(@_) };
	}

	shift->[0]->$method(@_); # ~~~ Maybe I should use goto
	                         #     to remove AUTOLOAD from
	                         #     the call stack.
}

sub DESTROY {}

1;

=head1 NAME

JE::Scope - JavaScript scope chain (what makes closures work)

=head1 DESCRIPTION

JavaScript code runs within an execution context which has a scope chain
associated with it. This class implements this scope chain. When a variable 
is accessed the objects in the scope chain are searched till the variable
is found.

A JE::Scope object can also be used as global (JE) object. Any methods it
does not understand will be delegated to the object at the bottom of the
stack (the far end of the chain), so that C<< $scope->null >> means the
same thing as C<< $scope->[0]->null >>.

Objects of this class consist of a reference to an array, the elements of
which are the objects in the chain (the first element
being the global object). (Think
of it as a stack.)

=head1 METHODS

=over 4

=item find_var($name, $value)

=item find_var($name)

This method searches through
the scope chain, starting at the end of the array, until it 
finds the
variable named by the first argument. If the second argument is
present, it sets the variable. It then returns an lvalue (a
JE::LValue object) that references the variable.

=item new_var($name, $value)

=item new_var($name)

This method creates (and optionally sets the value of) a new
variable in the variable object (the same thing that JavaScript's C<var>
keyword does) and returns an lvalue.

The variable object is the first object in the scope chain 
(searching from the top of the 
stack) that is a call object, or C<< $scope->[0] >> if no call object is 
found.

=back

=head1 CONSTRUCTOR

None. Just bless an array reference. You should not need to do
this because it is done for you by the C<JE> and C<JE::Object::Function> 
classes.

=head1 SEE ALSO

=over

=item L<JE>

=item L<JE::LValue>

=item L<JE::Object::Function>

=back

=cut




