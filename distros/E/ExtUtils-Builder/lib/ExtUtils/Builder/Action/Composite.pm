package ExtUtils::Builder::Action::Composite;
$ExtUtils::Builder::Action::Composite::VERSION = '0.015';
use strict;
use warnings;

use parent 'ExtUtils::Builder::Action';

sub _preference_map {
	return {
		flatten => 3,
		execute => 2,
		command => 1,
		code    => 0,
	};
}

sub execute {
	my ($self, %opts) = @_;
	$_->execute(%opts) for $self->flatten(%opts);
	return;
}

sub to_code {
	my ($self, %opts) = @_;
	return map { $_->to_code(%opts) } $self->flatten(%opts);
}

sub to_command {
	my ($self, %opts) = @_;
	return map { $_->to_command(%opts) } $self->flatten(%opts);
}

1;

# ABSTRACT: A base role for composite action classes

__END__

=pod

=encoding UTF-8

=head1 NAME

ExtUtils::Builder::Action::Composite - A base role for composite action classes

=head1 VERSION

version 0.015

=head1 DESCRIPTION

This is a base-role for all composite action classes

=head1 METHODS

=head2 preference

This will prefer handling methods in the following order: flatten, execute, command, code

=head2 execute

Execute all actions in this collection.

=head2 to_command

This returns the list commands of all actions in the collection.

=head2 to_code

This returns the list of evaluatable strings of all actions in the collection.

=head2 preference

This will prefer handling methods in the following order: flatten, execute, command, code

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
