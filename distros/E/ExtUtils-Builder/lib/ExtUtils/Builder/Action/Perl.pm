package ExtUtils::Builder::Action::Perl;
$ExtUtils::Builder::Action::Perl::VERSION = '0.005';
use strict;
use warnings;

use parent 'ExtUtils::Builder::Action::Primitive';

sub _preference_map {
	return {
		execute => 3,
		code    => 2,
		command => 1,
		flatten => 0,
	};
}

sub message {
	my $self = shift;
	return $self->{message};
}

sub to_code_hash {
	my ($self, %opts) = @_;
	my %result = (
		modules => [ $self->modules ],
		code    => $self->to_code(skip_loading => 1, %opts),
	);
	$result{message} = $self->{message} if defined $self->{message};
	return \%result;
}

1;

# ABSTRACT: A base-role for Code actions

__END__

=pod

=encoding UTF-8

=head1 NAME

ExtUtils::Builder::Action::Perl - A base-role for Code actions

=head1 VERSION

version 0.005

=head1 DESCRIPTION

This class provides most functionality of Code Actions.

=head1 ATTRIBUTES

=head2 message

This is a message that will be logged during execution. This attribute is optional.

=head1 METHODS

=head2 modules

This will return the modules needed for this action.

=for Pod::Coverage execute
to_command
preference

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
