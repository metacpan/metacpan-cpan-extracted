package Gears::X::HTTP;
$Gears::X::HTTP::VERSION = '0.001';
use v5.40;
use Mooish::Base -standard;

extends 'Gears::X';

has param 'code' => (
	isa => IntRange [300, 500],
);

sub _raise_exception ($self, $code, $message)
{
	$self->new(code => $code, message => $message)->raise;
}

sub raise ($self, @args)
{
	$self->_raise_exception(@args)
		if @args != 0;

	die $self;
}

sub _build_message ($self)
{
	return $self->code . ' - ' . $self->message;
}

