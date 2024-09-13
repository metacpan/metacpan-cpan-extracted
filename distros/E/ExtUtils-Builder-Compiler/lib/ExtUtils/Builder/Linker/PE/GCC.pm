package ExtUtils::Builder::Linker::PE::GCC;
$ExtUtils::Builder::Linker::PE::GCC::VERSION = '0.021';
use strict;
use warnings;

use parent qw/ExtUtils::Builder::Linker::Unixy ExtUtils::Builder::Linker::COFF/;

use File::Basename ();

sub _init {
	my ($self, %args) = @_;
	$args{ld} ||= ['gcc'];
	$args{export} ||= 'all';
	$self->ExtUtils::Builder::Linker::Unixy::_init(%args);
	$self->ExtUtils::Builder::Linker::COFF::_init(%args);
	return;
}

sub linker_flags {
	my ($self, $from, $to, %opts) = @_;
	my @ret = $self->SUPER::linker_flags($from, $to, %opts);

	push @ret, $self->new_argument(ranking => 85, value => ['-Wl,--enable-auto-image-base']);
	if ($self->type eq 'shared-library' or $self->type eq 'loadable-object') {
		push @ret, $self->new_argument(ranking => 10, value => ['--shared']);
	}
	if ($self->autoimport) {
		push @ret, $self->new_argument(ranking => 85, value => ['-Wl,--enable-auto-import']);
	}

	if ($self->export eq 'all') {
		push @ret, $self->new_argument(ranking => 85, value => ['-Wl,--export-all-symbols']);
	}
	elsif ($self->export eq 'some') {
		my $export_file = $opts{export_file} || ($opts{basename} || File::Basename::basename($to)) . '.def';
		push @ret, $self->new_argument(ranking => 20, value => [$export_file]);
	}
	return @ret;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

ExtUtils::Builder::Linker::PE::GCC

=head1 VERSION

version 0.021

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
