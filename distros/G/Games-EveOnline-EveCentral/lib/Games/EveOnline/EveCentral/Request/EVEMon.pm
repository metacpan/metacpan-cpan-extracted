package Games::EveOnline::EveCentral::Request::EVEMon;
{
  $Games::EveOnline::EveCentral::Request::EVEMon::VERSION = '0.001';
}


# ABSTRACT: Create a request for the evemon endpoint.


use Moo 1.003001;
use MooX::Types::MooseLike 0.25;
use MooX::StrictConstructor 0.006;
use MooX::Types::MooseLike::Base qw(AnyOf ArrayRef Int Str);

use 5.012;

extends 'Games::EveOnline::EveCentral::Request';

use Readonly 1.03;


Readonly::Scalar my $ENDPOINT => 'evemon';



sub request {
  my $self = shift;

  return $self->http_request($ENDPOINT);
}



1; # End of Games::EveOnline::EveCentral::Request::EVEMon

__END__

=pod

=head1 NAME

Games::EveOnline::EveCentral::Request::EVEMon - Create a request for the evemon endpoint.

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  my $req = Games::EveOnline::EveCentral::Request::EVEMon->new->request;

=head1 DESCRIPTION

This class is used to create HTTP::Request objects suitable to call the
`evemon` method on EVE Central.

Examples:

=over 4

=item * L<http://api.eve-central.com/api/evemon>

=back

=for test_synopsis no strict 'vars'

=head1 METHODS

=head2 request

Returns an HTTP::Request object which can be used to call the 'evemon'
endpoint.

=begin private =end private

=head1 AUTHOR

Pedro Figueiredo, C<< <me at pedrofigueiredo.org> >>


=head1 BUGS

Please report any bugs or feature requests through the web interface at
L<https://github.com/pfig/games-eveonline-evecentral/issues>.  I will be
notified, and then you'll automatically be notified of progress on your bug as
I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Games::EveOnline::EveCentral


You can also look for information at:
=over 4

=item * GitHub Issues (report bugs here)

L<https://github.com/pfig/games-eveonline-evecentral/issues>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Games-EveOnline-EveCentral>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Games-EveOnline-EveCentral>

=item * CPAN

L<http://metacpan.org/module/Games::EveOnline::EveCentral>

=back

=head1 ACKNOWLEDGEMENTS

=over 4

=item * The people behind EVE Central.

L<http://eve-central.com/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2013 Pedro Figueiredo.

This program is free software; you can redistribute it and/or modify it
under the terms of the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=end private

=head1 AUTHOR

Pedro Figueiredo <me@pedrofigueiredo.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Pedro Figueiredo.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
