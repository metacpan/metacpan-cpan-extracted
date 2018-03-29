#!/usr/bin/perl

package Devel::Events::Filter::Callback;
# ABSTRACT: Callback based L<Devel::Events::Filter>
our $VERSION = '0.09';
use Moose;

with qw/Devel::Events::Filter/;

has callback => (
	isa => "CodeRef",
	is  => "rw",
	required => 1,
);

sub filter_event {
	my ( $self, @event ) = @_;
	$self->callback->(@event);
}

__PACKAGE__;

__END__

=pod

=encoding UTF-8

=head1 NAME

Devel::Events::Filter::Callback - Callback based L<Devel::Events::Filter>

=head1 VERSION

version 0.09

=head1 SYNOPSIS

	use Devel::Events::Filter::Callback;

	Devel::Events::Filter::Callback->new(
		callback => sub {
			my ( @event ) = @_;

			return if bad_event(@event); # drop it

			return map { filter($_) } @event; # change it
		},
		handler => $handler,
	);

=head1 DESCRIPTION

Duh.

=head1 ATTRIBUTES

=over 4

=item handler

L<Devel::Events::Handler>

=item callback

a code ref

=back

=head1 METHODS

=over 4

=item filter_event

Delegates to C<callback>

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
