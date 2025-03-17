package ExtUtils::Builder::Linker::ELF::GCC;
$ExtUtils::Builder::Linker::ELF::GCC::VERSION = '0.025';
use strict;
use warnings;

use parent 'ExtUtils::Builder::Linker::ELF::Any';

sub _init {
	my ($self, %args) = @_;
	$args{ld} //= 'gcc';
	$args{ccdlflags} //= ['-Wl,-E'];
	$args{lddlflags} //= ['-shared'];
	$self->SUPER::_init(%args);
	return;
}

sub add_runtime_path {
	my ($self, $dirs, %opts) = @_;
	$self->add_argument(ranking => $self->fix_ranking(30, $opts{ranking}), value => [ map { "-Wl,-rpath,$_" } @{$dirs} ]);
	return;
}

1;


