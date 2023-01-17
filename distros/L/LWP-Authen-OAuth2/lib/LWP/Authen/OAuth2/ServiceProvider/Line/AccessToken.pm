package LWP::Authen::OAuth2::ServiceProvider::Line::AccessToken;

# ABSTRACT: Line AccessToken
our $VERSION = '0.20'; # VERSION

use strict;
use warnings;
use parent 'LWP::Authen::OAuth2::AccessToken::Bearer';

our $REFRESH_PERIOD = 864000; # 10 days. https://devdocs.line.me/en/#refreshing-access-tokens

# Line tokens can be refreshed until the refresh period is over.
sub should_refresh {
    my ($self, @args) = @_;

    return 0 unless $self->SUPER::should_refresh(@args);

    my $refresh_expires_time = $self->expires_time + $REFRESH_PERIOD;
    my $refresh_token_valid = time < $refresh_expires_time;

    return $refresh_token_valid;
}

# These are exposed for use with /oauth/verify and /oauth/revoke API requests
sub access_token  { shift->{access_token}  }
sub refresh_token { shift->{refresh_token} }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

LWP::Authen::OAuth2::ServiceProvider::Line::AccessToken - Line AccessToken

=head1 VERSION

version 0.20

=head1 AUTHORS

=over 4

=item *

Ben Tilly, <btilly at gmail.com>

=item *

Thomas Klausner <domm@plix.at>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 - 2022 by Ben Tilly, Rent.com, Thomas Klausner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
