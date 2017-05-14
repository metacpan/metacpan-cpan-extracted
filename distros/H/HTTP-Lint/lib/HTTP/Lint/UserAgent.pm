package HTTP::Lint::UserAgent;

=head1 NAME

HTTP::Lint::UserAgent - HTTP User agent that warns for suspicious transactions

=head1 SYNOPSIS

  # Do not overload LWP::UserAgent::request;
  use HTTP::Lint::UserAgent qw/:noinject/;
  new HTTP::Lint::UserAgent->request ($request);

  # Do overload LWP::UserAgent::request;
  use HTTP::Lint::UserAgent;
  use LWP::UserAgent;
  new LWP::UserAgent->request ($request);

  # Overload LWP::UserAgent::request without script modification;
  perl -MHTTP::Lint::UserAgent client.pl

=head1 DESCRIPTION

L<HTTP::Lint::UserAgent> subclasses L<LWP::UserAgent>, providing
B<request> method that checks each transaction and messages involved
when it finishes with L<HTTP::Lint> and produces warning on console
(with B<warn>).

Unless loaded with B<:noinject>, it replaces the B<request> method
in L<LWP::UserAgent> package, transparently intercepting all
requests.

=cut

use strict;
use warnings;

use HTTP::Lint qw/http_lint/;
use base qw/LWP::UserAgent/;

sub request
{
	my $response = lwp_request (@_);
	if ($response) {
		warn $_ foreach http_lint ($response)
	}
	return $response;
}

sub import
{
	my $class = shift;
	return if grep { $_ eq ':noinject' } @_;

	no warnings 'redefine';
	*HTTP::Lint::UserAgent::lwp_request = \&LWP::UserAgent::request;
	*LWP::UserAgent::request = \&request;
}

=head1 BUGS

It's hackish, use it only for debugging and avoid
using it in production code!

Not much can go wrong, but it's just not nice.

=head1 SEE ALSO

=over

=item *

L<LWP::UserAgent> -- The User Agent

=item *

L<HTTP::Lint> -- Checker module

=back

=head1 COPYRIGHT

Copyright 2011, Lubomir Rintel

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 AUTHOR

Lubomir Rintel C<lkundrak@v3.sk>

=cut

1;
