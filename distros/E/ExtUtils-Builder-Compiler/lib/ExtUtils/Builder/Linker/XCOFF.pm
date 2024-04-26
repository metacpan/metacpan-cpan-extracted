package ExtUtils::Builder::Linker::XCOFF;
$ExtUtils::Builder::Linker::XCOFF::VERSION = '0.001';
use strict;
use warnings;

use base qw/ExtUtils::Builder::Linker::Unixy ExtUtils::Builder::Linker::COFF/;

use File::Basename ();

sub _init {
	my ($self, %args) = @_;
	$args{ld} ||= ['ld'];
	$self->ExtUtils::Builder::Linker::Unixy::_init(%args);
	$self->ExtUtils::Builder::Linker::COFF::_init(%args);
	return;
}

sub linker_flags {
	my ($self, $from, $to, %opts) = @_;
	my @ret = $self->SUPER::linker_flags($from, $to, %opts);
	push @ret, $self->new_argument(ranking => 20, value => ['-bnoautoimp']) if !$self->autoimport;

	my $type = $self->type;
	if ($type eq 'shared-library' or $type eq 'loadable-object') {
		if ($self->export eq 'some') {
			my $basename = $opts{basename} || File::Basename::basename($to);
			push @ret, $self->new_arguments(ranking => 20, value => ["-bE:$basename.exp"]);
		}
		elsif ($self->export eq 'all') {
			push @ret, $self->new_argument(ranking => 20, value => ['-bexpfull']);
		}
	}
	return @ret;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

ExtUtils::Builder::Linker::XCOFF

=head1 VERSION

version 0.001

=head1 AUTHOR

Leon Timmermans <leont@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
