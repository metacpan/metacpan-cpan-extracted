package HTTP::Exception::3XX;
$HTTP::Exception::3XX::VERSION = '0.04006';
use strict;
use base 'HTTP::Exception::Base';

sub is_info         () { '' }
sub is_success      () { '' }
sub is_redirect     () { 1  }
sub is_error        () { '' }
sub is_client_error () { '' }
sub is_server_error () { '' }

sub location {
    $_[0]->{location} = $_[1] if (@_ > 1);
    return $_[0]->{location};
}

sub Fields {
    my $self    = shift;
    my @fields  = $self->SUPER::Fields();
    # TODO: default-value or required, maybe alter new
    push @fields, qw(location); # additional Fields
    return @fields;
}

1;


=head1 NAME

HTTP::Exception::3XX - Base Class for 3XX (redirect) Exceptions

=head1 VERSION

version 0.04006

=head1 SYNOPSIS

    use HTTP::Exception;

    # all are exactly the same
    HTTP::Exception->throw(301, location => 'google.com');
    HTTP::Exception::301->throw(location => 'google.com');
    HTTP::Exception::MOVED_PERMANENTLY->throw(location => 'google.com');

    # and in your favourite Webframework
    eval { ... }
    if (my $e = HTTP::Exception::301->caught) {
        my $self->req->redirect($e->location);
    }

=head1 DESCRIPTION

This package is the base class for all 3XX (redirect) Exceptions.
This makes adding features for a range of exceptions easier.

DON'T USE THIS PACKAGE DIRECTLY. 'use HTTP::Exception' does this for you.

=head1 ADDITIONAL FIELDS

Fields, that 3XX-Exceptions provide over HTTP::Exceptions.

=head2 location

Indicates, where the browser is being redirected to.

=head1 AUTHOR

Thomas Mueller, C<< <tmueller at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-http-exception at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=HTTP-Exception>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc HTTP::Exception::Base

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=HTTP-Exception>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/HTTP-Exception>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/HTTP-Exception>

=item * Search CPAN

L<https://metacpan.org/release/HTTP-Exception>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Thomas Mueller.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut
