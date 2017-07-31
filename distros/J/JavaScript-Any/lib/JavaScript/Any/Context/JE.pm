use 5.008003;
use strict;
use warnings;

package JavaScript::Any::Context::JE;

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
use JE qw();

sub BUILD {
	my $self = shift;
	my ($args) = @_;

	$self->_engine("JE"->new(
		max_ops => $args->{max_ops},
	));
	
	return;
}

# delegated methods
sub eval    { shift->_engine->eval(@_) }
sub max_ops { shift->_engine->max_ops(@_) }

sub define {
	my $self = shift;
	my ($name, $value) = @_;
	
	$self->_throw_if_bad_name($name);
	
	# XXX
	# need to install a wrapper
	# to process params and return values
	
	if (is_plain_coderef($value)) {
		$self->_engine->new_function($name, $value);
		return;
	}
	
	if (is_plain_hashref($value)) {
		...;
	}
	
	if (is_plain_arrayref($value)) {
		...;
	}
	
	if (is_blessed_ref($value)) {
		...;
	}
	
	if ($self->is_true($value)) {
		$self->_engine->prop({ name => $name, value => $self->_engine->true });
		return;
	}
	
	if ($self->is_false($value)) {
		$self->_engine->prop({ name => $name, value => $self->_engine->false });
		return;
	}
	
	if ($self->is_null($value)) {
		$self->_engine->prop({ name => $name, value => $self->_engine->null });
		return;
	}
	
	if (not is_ref($value)) {
		$self->_engine->prop({ name => $name, value => $self->_engine->upgrade($value) });
		return;
	}
	
	$self->_throw_because_bad_value($value);
}

1;

