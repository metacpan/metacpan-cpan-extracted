package ExtUtils::Builder::Linker::Unixy;
$ExtUtils::Builder::Linker::Unixy::VERSION = '0.004';
use strict;
use warnings;

use base 'ExtUtils::Builder::Linker';

sub linker_flags {
	my ($self, $from, $to, %opts) = @_;
	my @ret;
	push @ret, map { $self->new_argument(ranking => $_->{ranking}, value => [ "-L$_->{value}" ]) } @{ $self->{library_dirs} };
	push @ret, map { $self->new_argument(ranking => $_->{ranking}, value => [ "-l$_->{value}" ]) } @{ $self->{libraries} };
	push @ret, $self->new_argument(ranking => 50, value => [ '-o' => $to, @{$from} ]);
	return @ret;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

ExtUtils::Builder::Linker::Unixy

=head1 VERSION

version 0.004

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
