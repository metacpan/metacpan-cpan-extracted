package HTTP::Router::Match;

use strict;
use warnings;
use base 'Class::Accessor::Fast';

__PACKAGE__->mk_accessors(qw'params captures route');

sub new {
    my ($class, %args) = @_;
    return bless {
        params   => {},
        captures => {},
        %args,
    }, $class;
}

sub uri_for {
    my ($self, @args) = @_;
    $self->route->uri_for(@args);
}

1;

=head1 NAME

HTTP::Router::Match - Matched Object Representation for HTTP::Router

=head1 METHODS

=head2 uri_for($args?)

Returns a route path which is processed with parameters.

=head1 PROPERTIES

=head2 params

Route parameters which was matched.

=head2 captures

Captured variable parameters which was matched.

=head2 route

L<HTTP::Router::Route> object which was matched.

=head1 AUTHOR

NAKAGAWA Masaki E<lt>masaki@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<HTTP::Router>, L<HTTP::Router::Route>

=cut
