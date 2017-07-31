use 5.008003;
use strict;
use warnings;

package JavaScript::Any::Context::Duktape;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.002';

use namespace::autoclean;
use Class::Tiny qw( _engine );
use Role::Tiny::With;
with qw( JavaScript::Any::Context );

use Ref::Util qw(
	is_plain_arrayref is_plain_hashref is_ref
	is_blessed_ref is_plain_coderef
);
use JavaScript::Duktape qw();

sub BUILD {
	my $self = shift;
	my ($args) = @_;

	$self->_engine("JavaScript::Duktape"->new(
		timeout    => $args->{timeout},
		max_memory => $args->{max_memory},
	));
	
	return;
}

# delegated methods
sub timeout    { shift->_engine->timeout(@_) }
sub max_memory { shift->_engine->max_memory(@_) }
sub eval       { shift->_engine->eval(@_) }

sub define {
	my $self = shift;
	my ($name, $value) = @_;
	
	$self->_throw_if_bad_name($name);
	
	# XXX
	# need to install a wrapper
	# to process params and return values
	
	if (is_plain_coderef($value)) {
		$self->_engine->set($name, $value);
		return;
	}
	
	if (is_plain_hashref($value)) {
		$self->_engine->set($name, $value);
		return;
	}
	
	if (is_plain_arrayref($value)) {
		$self->_engine->set($name, $value);
		return;
	}
	
	if (is_blessed_ref($value)) {
		$self->_engine->set($name, $value);
		return;
	}
	
	if ($self->is_true($value)) {
		$self->_engine->eval("$name = true;");  # UGLY
		return;
	}
	
	if ($self->is_false($value)) {
		$self->_engine->eval("$name = false;");  # UGLY
		return;
	}
	
	if ($self->is_null($value)) {
		$self->_engine->eval("$name = null;");  # UGLY
		return;
	}
	
	if (not is_ref($value)) {
		$self->_engine->set($name, $value);
		return;
	}
	
	$self->_throw_because_bad_value($value);
}


1;

