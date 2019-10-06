use strict;
package DigitalOcean::Error;
use Object::Tiny::XS qw /id message status_code status_message status_line DigitalOcean/;

#ABSTRACT: Represents an HTTP error returned by the DigitalOcean API







1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DigitalOcean::Error - Represents an HTTP error returned by the DigitalOcean API

=head1 VERSION

version 0.17

=head1 SYNOPSIS

  my $do_error = DigitalOcean::Error->new(id => "forbidden", message => "You do not have access for the attempted action.", status_code => 403, status_message => "403 Forbidden", DigitalOcean => $do);

=head1 DESCRIPTION

Represents an HTTP error returned by the DigitalOcean API. 

=head1 METHODS

=head2 id
    The id of the error returned by the Digital Ocean API. This method is just a getter.

=head2 message
    The message of the error returned by the Digital Ocean API. This method is just a getter.

=head2 status_code
    A 3 digit number that encode the overall outcome of an HTTP response. This is the C<code> returned by the L<HTTP::Response> object. This method is just a getter.

=head2 status_message
    This returns a message that is a short human readable single line string that explains the response code. This is the C<message> returned by the L<HTTP::Response> object. This method is just a getter.

=head2 status_line
    Returns the string "<code> <message>". This is the C<status_line> returned by the L<HTTP::Response> object. This method is just a getter.

=head2 status_line
    Returns the associated L<DigitalOcean> object that created the L<DigitalOcean::Error> object. This method is just a getter.

=head1 AUTHOR

Adam Hopkins <srchulo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Adam Hopkins.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
