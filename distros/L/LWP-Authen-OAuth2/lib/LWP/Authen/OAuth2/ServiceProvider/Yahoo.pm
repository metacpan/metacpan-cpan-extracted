package LWP::Authen::OAuth2::ServiceProvider::Yahoo;

our @ISA = qw(LWP::Authen::OAuth2::ServiceProvider);
our $VERSION = "0.01";

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

=head1 NAME

LWP::Authen::OAuth2::ServiceProvider::Yahoo - Access Yahoo API OAuth2 APIs

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

See L<https://developer.yahoo.com/oauth2/guide/"> for Yahoo's own documentation.

=head1 REGISTERING

Before you can use OAuth 2 with Yahoo you need to register yourself as an app. For that, go to L<https://developer.yahoo.com/apps/create/>.

=head1 AUTHOR

Michael Stevens, C<< <mstevens@etla.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-lwp-authen-oauth2 at rt.cpan.org>, or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=LWP-Authen-OAuth2>.

=head1 SUPPORT


You can find documentation for this module with the perldoc command.

    perldoc LWP::Authen::OAuth2::ServiceProvider

You can also look for information at:

=over 4

=item Github (submit patches here)

L<https://github.com/domm/perl-oauth2>
=
item RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=LWP-Authen-OAuth2>

=item AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/LWP-Authen-OAuth2>

=item CPAN Ratings

L<http://cpanratings.perl.org/d/LWP-Authen-OAuth2>

=back

http://rt.cpan.org/NoAuth/ReportBug.html?Queue=LWP-Authen-OAuth2

=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2018 by Michael Stevens.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

=cut
