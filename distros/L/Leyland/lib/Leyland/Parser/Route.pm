package Leyland::Parser::Route;

# ABSTRACT: Parses route definitions in Leyland controllers

use warnings;
use strict;
use base 'Devel::Declare::Parser';
use Devel::Declare::Interface;

Devel::Declare::Interface::register_parser(__PACKAGE__);

=head1 NAME

Leyland::Parser::Route - Parses route definitions in Leyland controllers

=head1 SYNOPSIS

	# see Leyland::Parser for information

=head1 DESCRIPTION

This module defines parsers for Leyland's sweet syntax for creating routes
and controller prefixes.

=head1 EXTENDS

L<Devel::Declare::Parser>

=head1 OBJECT METHODS

=head2 rewrite()

=cut

sub rewrite {
	my $self = shift;

	my @parts = @{$self->parts};
	my @new_parts = ();

	$self->bail('You must define a route regex for the route method.') if scalar @parts == 0;

	# get the route regex
	my $route = shift(@parts)->[0];
	my $re = eval { qr{$route} };
	$self->bail("Could not parse route regex $route.") unless $re;
	push(@new_parts, [$re, undef]);

	# do we have 'accepts' and/or 'returns' rules?
	while (scalar @parts > 1) {
		my ($key, $value) = (shift(@parts)->[0], shift(@parts)->[0]);
		if ($key eq 'accepts' || $key eq 'returns' || $key eq 'speaks' || $key eq 'is') {
			push(@new_parts, [$key.'='.$value, undef]);
		} else {
			$self->bail("I can't understand rule $key.");
		}
	}

	$self->new_parts(\@new_parts);
}

=head2 inject()

Provides Leyland routes with C<$self> and C<$c> automatically.

=cut

sub inject {('my ($self, $c) = (shift, shift);')}

=head1 AUTHOR

Ido Perlmuter, C<< <ido at ido50.net> >>

=head1 ACKNOWLEDGMENTS

Paul Driver, author of L<Flea>, from which I have learned how to do this.

=head1 BUGS

Please report any bugs or feature requests to C<bug-Leyland at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Leyland>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc Leyland::Parser::Route

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Leyland>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Leyland>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Leyland>

=item * Search CPAN

L<http://search.cpan.org/dist/Leyland/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2014 Ido Perlmuter.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
