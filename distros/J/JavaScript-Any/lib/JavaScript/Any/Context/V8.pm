use 5.010001;
use strict;
use warnings;

package JavaScript::Any::Context::V8;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.002';

use namespace::autoclean;
use Class::Tiny qw( _context );
use Role::Tiny::With;
with qw( JavaScript::Any::Context );

use Ref::Util qw(
	is_plain_arrayref is_plain_hashref is_ref
	is_blessed_ref is_plain_coderef
);
use JavaScript::V8 qw();

sub BUILD {
	my $self = shift;
	my ($args) = @_;

	$self->_context("JavaScript::V8::Context"->new(
		time_limit => $args->{timeout},
	));
	
	return;
}

# delegated methods
sub eval    { shift->_context->eval(@_) }
sub timeout { shift->_context->time_limit(@_) }

sub define {
	my $self = shift;
	my ($name, $value) = @_;
	
	$self->_throw_if_bad_name($name);
	
	# XXX
	# need to install a wrapper
	# to process params and return values
	
	if (is_plain_coderef($value)) {
		$self->_context->bind($name, $value);
		return;
	}
	
	if (is_plain_hashref($value)) {
		$self->_context->bind($name, $value);
		return;
	}
	
	if (is_plain_arrayref($value)) {
		$self->_context->bind($name, $value);
		return;
	}
	
	if (is_blessed_ref($value)) {
		$self->_context->bind($name, $value);
		return;
	}
	
	if ($self->is_true($value)) {
		$self->_context->eval("$name = true;");  # UGLY
		return;
	}
	
	if ($self->is_false($value)) {
		$self->_context->eval("$name = false;");  # UGLY
		return;
	}
	
	if ($self->is_null($value)) {
		$self->_context->eval("$name = null;");  # UGLY
		return;
	}
	
	if (not is_ref($value)) {
		$self->_context->bind($name, $value);
		return;
	}
	
	$self->_throw_because_bad_value($value);
}


1;

