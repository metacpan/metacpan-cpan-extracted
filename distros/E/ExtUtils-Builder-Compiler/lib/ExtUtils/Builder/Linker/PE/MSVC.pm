package ExtUtils::Builder::Linker::PE::MSVC;
$ExtUtils::Builder::Linker::PE::MSVC::VERSION = '0.027';
use strict;
use warnings;

use ExtUtils::Builder::Action::Command;

use parent qw/ExtUtils::Builder::Linker::COFF/;

sub _init {
	my ($self, %args) = @_;
	$args{ld} //= ['link'];
	$self->ExtUtils::Builder::Linker::COFF::_init(%args);
	return;
}

sub linker_flags {
	my ($self, $from, $to, %opts) = @_;
	my @ret;
	push @ret, $self->new_argument(ranking =>  5, value => ['/nologo']);
	push @ret, $self->new_argument(ranking => 10, value => ['/dll']) if $self->type eq 'shared-library' or $self->type eq 'loadable-object';
	push @ret, map { $self->new_argument(ranking => $_->{ranking}, value => [ "/libpath:$_->{value}" ]) } @{ $self->{library_dirs} };
	push @ret, map { $self->new_argument(ranking => $_->{ranking}, value => [ "$_->{value}.lib" ]) } @{ $self->{libraries} };
	push @ret, $self->new_argument(ranking => 50, value => [ @{$from} ]);
	push @ret, $self->new_argument(ranking => 60, value => [ "/def:$opts{dl_file}" ]) if $opts{exports} eq 'some' && defined $opts{dl_file};
	push @ret, $self->new_argument(ranking => 80, value => ["/OUT:$to"]);
	# map_file, implib, def_file?…
	return @ret;
}

1;

