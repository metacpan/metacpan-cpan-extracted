package Drogo::Response;

use Drogo::Guts;
use strict;

sub new 
{
    my $class = shift;
    my $self = {};
    bless($self);
    return $self;
}

=head3 $self->print(...)

Output via http.

=cut

sub print { Drogo::Guts::print(@_) }

=head3 $self->header_set('header_type', 'value')

Set output header.

=cut

sub header_set { Drogo::Guts::header_set(@_) }

=head3 $self->header('content-type')

Set content type.

=cut

sub header { Drogo::Guts::header(@_) }


=head3 $self->headers

Returns hashref of response headers

=cut

sub headers { Drogo::Guts::headers(@_) }

=head3 $self->location('url')

Redirect to a url (sets the Location header out).

=cut

sub location { Drogo::Guts::location(@_) }

=head3 $self->status(...)

Set output status... (200, 404, etc...)
If no argument given, returns status.

=cut

sub status { Drogo::Guts::status(@_) }

=head1 AUTHORS

Bizowie <http://bizowie.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 Bizowie

This library is free software. You can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
