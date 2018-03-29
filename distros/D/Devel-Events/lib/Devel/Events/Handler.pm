#!/usr/bin/perl

package Devel::Events::Handler;
# ABSTRACT: An optional base role for event handlers.
our $VERSION = '0.09';
use Moose::Role;

requires "new_event";

__PACKAGE__;

__END__

=pod

=encoding UTF-8

=head1 NAME

Devel::Events::Handler - An optional base role for event handlers.

=head1 VERSION

version 0.09

=head1 SYNOPSIS

	package MyGen;
	use Moose;

	with qw/Devel::Events::Handler/;

	sub new_event {
		my ( $self, $type, %data ) = @_;

		# ...
	}

=head1 DESCRIPTION

This convenience role reminds you to add a C<new_event> method.

=head1 REQUIRED METHODS

=over 4

=item new_event @event

Handle a fired event.

=back

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Devel-Events>
(or L<bug-Devel-Events@rt.cpan.org|mailto:bug-Devel-Events@rt.cpan.org>).

=head1 AUTHOR

יובל קוג'מן (Yuval Kogman) <nothingmuch@woobling.org>

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2007 by יובל קוג'מן (Yuval Kogman).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
