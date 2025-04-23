package ExtUtils::Builder::Linker::ELF::Any;
$ExtUtils::Builder::Linker::ELF::Any::VERSION = '0.029';
use strict;
use warnings;

use parent 'ExtUtils::Builder::Linker::Unixy';

sub _init {
	my ($self, %args) = @_;
	$args{ld} //= ['cc'];
	$args{export} //= $args{type} eq 'executable' ? 'none' : 'all';
	$self->SUPER::_init(%args);
	$self->{ccdlflags} = defined $args{ccdlflags} ? $args{ccdlflags} : Carp::croak('');
	$self->{lddlflags} = defined $args{lddlflags} ? $args{lddlflags} : Carp::croak('');
	return;
}

sub linker_flags {
	my ($self, $from, $to, %args) = @_;
	my @ret = $self->SUPER::linker_flags($from, $to, %args);

	my $type = $self->type;
	if ($type eq 'shared-library' or $type eq 'loadable-object') {
		push @ret, $self->new_argument(ranking => 10, value => $self->{lddlflags});
	}
	elsif ($type eq 'executable') {
		push @ret, $self->new_argument(ranking => 10, value => $self->{ccdlflags}) if $self->export eq 'all';
	}
	else {
		croak("Unknown linkage type $type");
	}
	return @ret;
}

1;
