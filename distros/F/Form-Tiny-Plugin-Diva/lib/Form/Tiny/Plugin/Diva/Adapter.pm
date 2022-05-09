package Form::Tiny::Plugin::Diva::Adapter;

use v5.10;
use strict;
use warnings;

our $VERSION = '1.02';

use parent 'Form::Diva';

sub _ftpd_generate_errors
{
	my ($self, $errors_arr) = @_;
	my $error_class = $self->{error_class};

	return join '', map {
		qq|<div class="$error_class">$_</div>|
	} @{$errors_arr};
}

sub _ftpd_tweak
{
	my ($self, $generated) = @_;

	my $errors = $self->{form_instance}->errors_hash;
	for my $field (@{$generated}) {
		my $extra_data = $field->{comment};

		$field->{errors} = $self->_ftpd_generate_errors($errors->{$extra_data->{name}});

		# TODO: https://github.com/brainbuz/form-diva/issues/6
		$field->{label} = ''
			if (exists $extra_data->{l} && !defined $extra_data->{l})
			|| (exists $extra_data->{label} && !defined $extra_data->{label});
	}

	return $generated;
}

sub generate
{
	my $self = shift;
	my $generated = $self->SUPER::generate(@_ || $self->{form_instance}->input);

	return $self->_ftpd_tweak($generated);
}

sub prefill
{
	my $self = shift;
	my $generated = $self->SUPER::prefill(@_ || $self->{form_instance}->input);

	return $self->_ftpd_tweak($generated);
}

sub hidden
{
	my $self = shift;
	return $self->SUPER::hidden(@_ || $self->{form_instance}->input);
}

sub datavalues
{
	my $self = shift;

	# check if input has references or undefs
	if (@_ == grep { defined $_ && !ref $_ } @_) {
		return $self->SUPER::datavalues($self->{form_instance}->input, @_);
	}
	else {
		return $self->SUPER::datavalues(@_);
	}
}

sub form_errors
{
	my ($self) = @_;

	$self->_ftpd_generate_errors($self->{form_instance}->errors_hash->{''});
}

1;

__END__
