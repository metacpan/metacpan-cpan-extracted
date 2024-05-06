package ExtUtils::Builder::Binary;
$ExtUtils::Builder::Binary::VERSION = '0.003';
use strict;
use warnings;

use Carp qw//;

my %allowed_types = map { ($_ => 1) } qw/shared-library static-library loadable-object executable/;

sub _init {
	my ($self, %args) = @_;
	my $type = $args{type} or Carp::croak('No type given');
	$allowed_types{$type} or Carp::croak("$type is not an allowed linkage type");
	$self->{type} = $type;
	return;
}

sub type {
	my $self = shift;
	return $self->{type};
}

1;

# ABSTRACT: Helper role for classes producing binary objects

__END__

=pod

=encoding UTF-8

=head1 NAME

ExtUtils::Builder::Binary - Helper role for classes producing binary objects

=head1 VERSION

version 0.003

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
