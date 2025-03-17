package ExtUtils::Builder::ArgumentCollector;
$ExtUtils::Builder::ArgumentCollector::VERSION = '0.025';
use strict;
use warnings;

sub _init {
	my ($self, %args) = @_;
	$self->{arguments} = $args{arguments} // [];
	return;
}

sub add_argument {
	my ($self, %arguments) = @_;
	$arguments{ranking} = $self->fix_ranking(delete @arguments{qw/ranking fix/});
	push @{ $self->{arguments} }, $self->new_argument(%arguments);
	return;
}

sub new_argument {
	my ($self, %args) = @_;
	return [ $args{ranking} // 50, $args{value} ];
}

sub collect_arguments {
	my $self = shift;
	return @{ $self->{arguments} };
}

sub arguments {
	my ($self, @args) = @_;
	use sort 'stable';
	return map { @{ $_->[1] } } sort { $a->[0] <=> $b->[0] } $self->collect_arguments(@args);
}

sub fix_ranking {
	my (undef, $baseline, $override) = @_;
	return $baseline if not defined $override;
	return (ref($override) eq 'CODE') ? $override->($baseline) : $override;
}

1;

=pod

=encoding UTF-8

=head1 NAME

ExtUtils::Builder::ArgumentCollector - Helper role for argument collecting classes

=head1 VERSION

version 0.025

=head1 DESCRIPTION

This is a helper role for classes that collect arguments for their command. Classes that use this include ExtUtils::Builder::Compiler and ExtUtils::Builder::Linker

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

#ABSTRACT: Helper role for argument collecting classes

