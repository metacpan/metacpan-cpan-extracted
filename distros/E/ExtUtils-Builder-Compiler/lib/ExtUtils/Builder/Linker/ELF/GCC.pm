package ExtUtils::Builder::Linker::ELF::GCC;
$ExtUtils::Builder::Linker::ELF::GCC::VERSION = '0.023';
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

__END__

=pod

=encoding UTF-8

=head1 NAME

ExtUtils::Builder::Linker::ELF::GCC

=head1 VERSION

version 0.023

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
