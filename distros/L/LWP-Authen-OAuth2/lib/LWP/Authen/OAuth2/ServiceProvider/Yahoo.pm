package LWP::Authen::OAuth2::ServiceProvider::Yahoo;

# ABSTRACT: Access Yahoo using OAuth2
our $VERSION = '0.19'; # VERSION

our @ISA = qw(LWP::Authen::OAuth2::ServiceProvider);

sub authorization_endpoint {
  return "https://api.login.yahoo.com/oauth2/request_auth";
}

sub token_endpoint {
  return "https://api.login.yahoo.com/oauth2/get_token";
}

sub authorization_required_params {
  my $self = shift;
  return ("client_id", "redirect_uri", "response_type", $self->SUPER::authorization_required_params());
}

sub authorization_optional_params {
  my $self = shift;
  return ("state", "language", $self->SUPER::authorization_optional_params());
}

sub refresh_required_params {
  my $self = shift;
  return ("client_id", "client_secret", "redirect_uri", "grant_type", $self->SUPER::refresh_required_params());
}

sub request_required_params {
  my $self = shift;
  return ("client_id", "client_secret", "redirect_uri",  "grant_type", $self->SUPER::request_required_params());
}

sub authorization_default_params {
  my $self = shift;
  return ("response_type" => "code", $self->SUPER::authorization_default_params());
}

sub request_default_params {
  my $self = shift;
  return ("grant_type" => "authorization_code", $self->SUPER::request_default_params());
}

sub refresh_default_params {
  my $self = shift;
  return ("grant_type" => "refresh_token", $self->SUPER::refresh_default_params());
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

LWP::Authen::OAuth2::ServiceProvider::Yahoo - Access Yahoo using OAuth2

=head1 VERSION

version 0.19

=head1 SYNOPSIS

See L<https://developer.yahoo.com/oauth2/guide/"> for Yahoo's own documentation.

=head1 REGISTERING

Before you can use OAuth 2 with Yahoo you need to register yourself as an app. For that, go to L<https://developer.yahoo.com/apps/create/>.

=head1 AUTHOR

Michael Stevens, C<< <mstevens@etla.org> >>

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
