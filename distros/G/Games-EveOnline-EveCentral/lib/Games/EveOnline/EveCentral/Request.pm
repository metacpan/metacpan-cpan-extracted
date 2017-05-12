package Games::EveOnline::EveCentral::Request;
{
  $Games::EveOnline::EveCentral::Request::VERSION = '0.001';
}


# ABSTRACT: Base class for the Request::* classes.


use Moo 1.003001;
use MooX::Types::MooseLike 0.25;
use MooX::StrictConstructor 0.006;

use 5.012;

use Games::EveOnline::EveCentral::HTTPRequest;



sub http_request {
  my ($self, $path, $content) = @_;
  my $method = (defined $content && ref $content eq 'ARRAY')? 'POST' : 'GET';

  return Games::EveOnline::EveCentral::HTTPRequest->new(
    method => $method,
    path => $path,
    content => $content
  )->http_request;
}



1; # End of Games::EveOnline::EveCentral::Request

__END__

=pod

=head1 NAME

Games::EveOnline::EveCentral::Request - Base class for the Request::* classes.

=head1 VERSION

version 0.001

=head1 SYNOPSIS

=head1 DESCRIPTION

Base class for the Request::* classes, this class exists to provide the
http_request method.

=for test_synopsis no strict 'vars'

=head1 METHODS

=head2 http_request

Creates a L<HTTP::Request> object using the object's fields as parameters and
GET as the HTTP method.

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
