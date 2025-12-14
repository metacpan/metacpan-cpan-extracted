package ExtUtils::Builder::Compiler::MSVC;
$ExtUtils::Builder::Compiler::MSVC::VERSION = '0.033';
use strict;
use warnings;

use parent qw/ExtUtils::Builder::Compiler ExtUtils::Builder::MultiLingual/;

sub _init {
	my ($self, %args) = @_;
	$args{cc} //= ['cl'];
	$self->ExtUtils::Builder::Compiler::_init(%args);
	$self->ExtUtils::Builder::MultiLingual::_init(%args);
	return;
}

sub compile_flags {
	my ($self, $from, $to) = @_;
	my @ret;
	push @ret, $self->new_argument(ranking => 5,  value => ['/NOLOGO']);
	push @ret, $self->new_argument(ranking => 10, value => [qw{/TP /EHsc}]) if $self->language eq 'C++';
	push @ret, $self->new_argument(ranking => 75, value => [ "/Fo$to", '/c', $from ]);
	push @ret, map { $self->new_argument(ranking => $_->{ranking}, value => [ "/I$_->{value}" ]) } @{ $self->{include_dirs} };
	for my $entry (@{ $self->{defines} }) {
		my $key = $entry->{key};
		my $value = defined $entry->{value} ? $entry->{value} ne '' ? "/D$key=$entry->{value}" : "/D$key" : "/U$key";
		push @ret, $self->new_argument(ranking => $entry->{ranking}, value => [$value]);
	}
	return @ret;
}

1;

# ABSTRACT: Class for compiling with Microsoft Visual C

__END__

=pod

=encoding UTF-8

=head1 NAME

ExtUtils::Builder::Compiler::MSVC - Class for compiling with Microsoft Visual C

=head1 VERSION

version 0.033

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
