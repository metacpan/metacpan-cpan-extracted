package Drogo::Cookie;

use strict;

use CGI::Cookie;

=head1 MODULE

Drogo::Cookie

=head1 METHODS

=over 4

=cut

=item $self->new

Return cookie dispatcher.

=cut

sub new
{
    my ($class, $ns) = @_;
    my $self = { server => $ns };
    bless($self);
    return $self;
}

=item Cookie->set

Set cookie.

=cut

sub set 
{
    my ($self, %params) = @_;

    $self->{server}->header_set(
        'Set-Cookie',
        new CGI::Cookie(%params)->as_string,
    );
}

=item my %params = Cookie->read

Read all cookies.

=cut

sub read
{
    my ($self, %params) = @_;

    my $cookies = $self->{server}->header_in('cookie');
    
    return parse CGI::Cookie($cookies);
}

=head1 AUTHORS

Bizowie <http://bizowie.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 Bizowie

This library is free software. You can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
