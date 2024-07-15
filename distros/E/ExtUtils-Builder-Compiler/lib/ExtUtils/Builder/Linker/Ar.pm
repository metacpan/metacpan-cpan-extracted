package ExtUtils::Builder::Linker::Ar;
$ExtUtils::Builder::Linker::Ar::VERSION = '0.011';
use strict;
use warnings;

use Carp ();

use base 'ExtUtils::Builder::Linker';

sub _init {
	my ($self, %args) = @_;
	$args{ld} ||= ['ar'];
	$args{export} ||= 'all';
	$self->SUPER::_init(%args);
	$self->{static_args} = $args{static_args} || ['cr'];
	return;
}

sub add_libraries {
	my ($self, $libs, %opts) = @_;
	Carp::croak 'Can\'t add libraries to static link yet' if @{$libs};
	return;
};

sub linker_flags {
	my ($self, $from, $to, %opts) = @_;
	my @ret;
	push @ret, $self->new_argument(ranking =>  0, value => $self->static_args);
	push @ret, $self->new_argument(ranking => 10, value => [ $to ]),
	push @ret, $self->new_argument(ranking => 75, value => [ @{$from} ]),
	return @ret;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

ExtUtils::Builder::Linker::Ar

=head1 VERSION

version 0.011

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
