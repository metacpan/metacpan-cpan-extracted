package Leyland::Logger;

# ABSTARCT: Logging facilities for Leyland applications

use Moo;
use namespace::clean;

=head1 NAME

Leyland::Logger - Wrapper around Plack's logging middlewares

=head1 SYNOPSIS

	# in your app.psgi file
	builder {
		enable 'SomeLoggingMiddleware';
		MyApp->to_app;
	};

	# in your controllers
	$c->log->debug("Some debug message");

=head1 DESCRIPTION

This package provides a simple wrapper around the L<Plack> logging middleware
used by your application. An object of this class is provided to the L<context|Leyland::Context>
object. Read L<Leyland::Manual::Logging> to learn more.

=head1 ATTRIBUTES

=head2 logger

An anonymous logging subroutine. This will be the C<psgix.logger> subroutine
automatically created by your selected logging middleware. If you haven't selected
one, however, this class will create a default one that simply prints messages
to standard output or standard error (as appropriate).

=cut

has 'logger' => (
	is => 'ro',
	isa => sub { die "logger must be a code reference" unless ref $_[0] && ref $_[0] eq 'CODE' },
	default => sub {
		sub {
			my $args = shift;

			if ($args->{level} eq 'emergency' || $args->{level} eq 'error') {
				binmode STDERR, ":encoding(utf8)";
				print STDERR '| [', $args->{level}, '] ', $args->{message}, "\n";
			} else {
				binmode STDOUT, ":encoding(utf8)";
				print STDOUT '| [', $args->{level}, '] ', $args->{message}, "\n";
			}
		}
	}
);

=head1 METHODS

This class provides methods for the following log levels:

=over

=item * B<trace>

=item * B<debug>

=item * B<info> (with an B<inform> alias)

=item * B<notice>

=item * B<warning> (with a B<warn> alias)

=item * B<error> (with an B<err> alias)

=item * B<critical> (with a B<crit> and B<fatal> aliases)

=item * B<alert>

=item * B<emergency>

=back

All methods take the same parameters: a required C<$message> string,
and an optional C<\%data> hash-ref. This is meant to be used by a
logger such as L<Pye>, so take a look at it to learn more.

=cut

no strict 'refs';
foreach (
	['trace'],
	['debug'],
	['info', 'inform'],
	['notice'],
	['warning', 'warn'],
	['error', 'err'],
	['critical', 'crit', 'fatal'],
	['alert'],
	['emergency']
) {
	my $level = $_->[0];

	*{$level} = sub {
		my $self = shift;

		my $message = {
			level => $level,
			message => $_[0],
		};
		if ($_[1]) {
			$message->{data} = $_[1];
		}

		$self->logger->($message);
	};
}
use strict 'refs';

=head1 AUTHOR

Ido Perlmuter, C<< <ido at ido50.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-Leyland at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Leyland>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc Leyland::Logger

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
