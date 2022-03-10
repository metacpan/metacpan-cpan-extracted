package LWP::Authen::OAuth2::ServiceProvider::Withings;

# ABSTRACT: Withings OAuth2
our $VERSION = '0.18';    our $VERSION = '0.19'; # VERSION

use strict;
use warnings;
use JSON;

our @ISA = qw(LWP::Authen::OAuth2::ServiceProvider);

sub authorization_endpoint {
    return ' https://account.withings.com/oauth2_user/authorize2';
}

sub token_endpoint {
    return 'https://wbsapi.withings.net/v2/oauth2';
}

sub authorization_required_params {
    return ( 'client_id', 'state', 'scope', 'redirect_uri', 'response_type' );
}

sub authorization_default_params {
    return ( response_type => 'code', state => 'auth', scope => 'user.metrics' );
}

sub request_required_params {
    return ( 'action', 'grant_type', 'client_id', 'client_secret', 'code', 'redirect_uri' );
}

sub request_default_params {
    return ( grant_type => 'authorization_code', action => 'requesttoken' );
}

sub refresh_required_params {
    return ( 'action', 'grant_type', 'client_id', 'client_secret', 'refresh_token' );
}

sub refresh_default_params {
    return ( grant_type => 'refresh_token', action => 'requesttoken' );
}

sub construct_tokens {
    my ( $self, $oauth2, $response ) = @_;

    my $content = eval { decode_json( $response->content ) };
    $content = $content->{ 'body' };
    $response->content( encode_json( $content ) );

    $self->SUPER::construct_tokens( $oauth2, $response );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

LWP::Authen::OAuth2::ServiceProvider::Withings - Withings OAuth2

=head1 VERSION

version 0.19

=head1 SYNOPSIS

See L<https://developer.withings.com/> for Withings's own documentation. Withings's
documentation is very detailed, so that is the best place to find detailed
and up to date info about.

=head1 NAME

LWP::Authen::OAuth2::ServiceProvider::Withings - Access Withings using OAuth2

=head1 VERSION

version 0.18

=head1 NAME

LWP::Authen::OAuth2::ServiceProvider::Withings - Access Withings OAuth2 APIs

=head1 VERSION

Version 0.01

=head1 REGISTERING

Before you can use OAuth 2 with Withings you need to register a developer account at
L<https://account.withings.com/connectionuser/account_create>

You also need to create an application at L<https://account.withings.com/partner/>
which will provide you with a C<clientId> and C<client_secret>.

=head1 AUTHOR

Brian Foley, C<< <brianf@sindar.net> >>

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
