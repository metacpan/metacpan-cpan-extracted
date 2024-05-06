package ExtUtils::Builder::Compiler::Unixy;
$ExtUtils::Builder::Compiler::Unixy::VERSION = '0.003';
use strict;
use warnings;

use base 'ExtUtils::Builder::Compiler';

sub _init {
	my ($self, %args) = @_;
	$args{cc} ||= ['cc'];
	$self->SUPER::_init(%args);
	$self->{cccdlflags} = $args{cccdlflags};
	$self->{pic} = $args{pic} || ($self->type eq 'shared-library' || $self->type eq 'loadable-object') && @{ $self->{cccdlflags} };
	return;
}

sub compile_flags {
	my ($self, $from, $to) = @_;
	my @ret;
	push @ret, $self->new_argument(ranking => 75, value => [ '-o' => $to, '-c', $from ]);
	push @ret, $self->new_argument(ranking => 45, value => $self->{cccdlflags}) if $self->{pic};
	push @ret, map { $self->new_argument(ranking => $_->{ranking}, value => [ "-I$_->{value}" ]) } @{ $self->{include_dirs} };
	for my $entry (@{ $self->{defines} }) {
		my $key = $entry->{key};
		my $value = defined $entry->{value} ? $entry->{value} ne '' ? "-D$key=$entry->{value}" : "-D$key" : "-U$key";
		push @ret, $self->new_argument(ranking => $entry->{ranking}, value => [$value]);
	}
	return @ret;
}

1;

#ABSTRACT: Class for compiling with a unix compiler

__END__

=pod

=encoding UTF-8

=head1 NAME

ExtUtils::Builder::Compiler::Unixy - Class for compiling with a unix compiler

=head1 VERSION

version 0.003

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
