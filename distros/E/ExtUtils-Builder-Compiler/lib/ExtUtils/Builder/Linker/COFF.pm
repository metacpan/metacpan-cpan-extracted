package ExtUtils::Builder::Linker::COFF;
$ExtUtils::Builder::Linker::COFF::VERSION = '0.004';
use strict;
use warnings;

use base 'ExtUtils::Builder::Linker';

my %export_for = (
	executable        => 'none',
	'static-library'  => 'all',
	'shared-library'  => 'some',
	'loadable-object' => 'some',
);

sub _init {
	my ($self, %args) = @_;
	$args{export} ||= $export_for{ $args{type} };
	$self->SUPER::_init(%args);
	$self->{autoimport} = defined $args{autoimport} ? $args{autoimport} : 1;
	return;
}

sub autoimport {
	my $self = shift;
	return $self->{autoimport};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

ExtUtils::Builder::Linker::COFF

=head1 VERSION

version 0.004

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
