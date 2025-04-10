package ExtUtils::Builder::AutoDetect::Cpp;
$ExtUtils::Builder::AutoDetect::Cpp::VERSION = '0.028';
use strict;
use warnings;

use parent 'ExtUtils::Builder::AutoDetect::C';

sub _get_compiler {
	my ($self, $opts) = @_;
	my $os = $opts->{osname} // $^O;
	my $cc = $self->_get_opt($opts, 'cc');
	return $self->_is_gcc($cc, $opts) ? $self->SUPER::_get_compiler({ cc => 'g++', %{$opts} }) : is_os_type('Windows', $os) ? $self->SUPER::_get_compiler({ language => 'C++', %{$opts} }) : Carp::croak('Your platform is not supported yet');
}

sub _get_linker {
	my ($self, $opts) = @_;
	my $os = $opts->{osname} // $^O;
	my $cc = $self->_get_opt($opts, 'cc');
	return $self->_is_gcc($cc, $opts) ? $self->SUPER::_get_linker({ cc => 'g++', %{$opts} }) : is_os_type('Windows', $os) ? $self->SUPER::_get_linker({ language => 'C++', %{$opts} }) : Carp::croak('Your platform is not supported yet');
	return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

ExtUtils::Builder::AutoDetect::Cpp

=head1 VERSION

version 0.028

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
