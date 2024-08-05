package ExtUtils::Builder::Action::Primitive;
$ExtUtils::Builder::Action::Primitive::VERSION = '0.011';
use strict;
use warnings;

use parent 'ExtUtils::Builder::Action';

sub flatten {
	my $self = shift;
	return $self;
}

1;

# ABSTRACT: A base role for primitive action classes

__END__

=pod

=encoding UTF-8

=head1 NAME

ExtUtils::Builder::Action::Primitive - A base role for primitive action classes

=head1 VERSION

version 0.011

=head1 DESCRIPTION

This is a base role for primitive action classes such as L<Code|ExtUtils::Builder::Action::Code> and L<Command|ExtUtils::Builder::Action::Command>.

=head1 METHODS

=head2 flatten

This is an identity operator (it returns C<$self>).

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
