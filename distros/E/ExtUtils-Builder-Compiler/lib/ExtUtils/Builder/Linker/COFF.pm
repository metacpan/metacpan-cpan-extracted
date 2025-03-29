package ExtUtils::Builder::Linker::COFF;
$ExtUtils::Builder::Linker::COFF::VERSION = '0.026';
use strict;
use warnings;

use parent 'ExtUtils::Builder::Linker';

my %export_for = (
	executable        => 'none',
	'static-library'  => 'all',
	'shared-library'  => 'some',
	'loadable-object' => 'some',
);

sub _init {
	my ($self, %args) = @_;
	$args{export} //= $export_for{ $args{type} };
	$self->{autoimport} = defined $args{autoimport} ? $args{autoimport} : 1;
	$self->SUPER::_init(%args);
	return;
}

sub autoimport {
	my $self = shift;
	return $self->{autoimport};
}

1;
