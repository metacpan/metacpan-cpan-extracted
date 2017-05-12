package Lufs::Rot13;

use base 'Lufs::Local';

sub init {
	my $self = shift;
	$self->{config} = shift;
}

sub read {
	my $self = shift;
	my $ret = $self->SUPER::read(@_);
	$_[-1] =~ y/A-Za-z/N-ZA-Mn-za-m/;
	return $ret;
}

sub write {
	my $self = shift;
	$_[-1] =~ y/A-Za-z/N-ZA-Mn-za-m/;
	$self->SUPER::write(@_);
}

1;

