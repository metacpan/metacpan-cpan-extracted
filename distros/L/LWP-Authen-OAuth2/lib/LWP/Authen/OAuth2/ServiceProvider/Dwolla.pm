package LWP::Authen::OAuth2::ServiceProvider::Dwolla;

# ABSTRACT: Access Dwolla API v2
our $VERSION = '0.20'; # VERSION

use strict;
use warnings;

use base qw/LWP::Authen::OAuth2::ServiceProvider/;

use JSON qw/decode_json/;

sub authorization_endpoint {
    my $self = shift;
    my $host = $self->{use_test_urls} ? 'uat.dwolla.com' : 'www.dwolla.com';
    return 'https://'.$host.'/oauth/v2/authenticate';
}

sub token_endpoint {
    my $self = shift;
    my $host = $self->{use_test_urls} ? 'uat.dwolla.com' : 'www.dwolla.com';
    return 'https://'.$host.'/oauth/v2/token';
}

sub api_url_base {
    my $self = shift;
    my $host = $self->{use_test_urls} ? 'api-uat.dwolla.com' : 'api.dwolla.com';
    return 'https://'.$host;
}

sub authorization_required_params {
    my $self = shift;
    return ('scope', $self->SUPER::authorization_required_params());
}

sub authorization_optional_params {
    my $self = shift;
    return ($self->SUPER::authorization_optional_params(), qw/dwolla_landing verified_account/);
}

sub default_api_headers {
    return { 'Content-Type' => 'application/vnd.dwolla.v1.hal+json', 'Accept' => 'application/vnd.dwolla.v1.hal+json' };
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

LWP::Authen::OAuth2::ServiceProvider::Dwolla - Access Dwolla API v2

=head1 VERSION

version 0.20

=head1 SYNOPSIS

  my $oauth_dwolla = LWP::Authen::OAuth2->new(
    # client_id/client_secret come from your Dwolla account, under API Keys in
    # Registered Applications
    client_id        => DWOLLA_APP_KEY,
    client_secret    => DWOLLA_APP_SECRET,
    service_provider => 'Dwolla',
    # $use_test = 1 to use uat.dwolla.com in your dev sandbox, for test transactions
    use_test_urls    => $use_test ? 1 : 0,
    redirect_uri     => 'http://my.host/dwolla_redirect_handler',
    # scope for reading funding sources and sending money; see Dwolla docs for other scopes
    scope            => 'Send|Funding',
  );

  # read user's list of funding sources
  my $account = $oauth_dwolla->access_token()->{'_links'}->{'account'}->{'href'};
  my $funding_sources = eval { $oauth_dwolla->make_api_call($account.'/funding-sources') };

  # get all verified bank accounts
  my @verified_sources = grep {
    $_->{'status'} eq 'verified' && $_->{'type'} ne 'balance'
  } @{ $funding_sources->{'_embedded'}->{'funding-sources'} };

  # get user's Dwolla balance, if it has a positive balance
  my ($balance_source) = grep {
    $_->{'type'} eq 'balance'
  } @{ $funding_sources->{'_embedded'}->{'funding-sources'} };

  my $dwolla_balance = eval {
    $oauth_dwolla->make_api_call($balance_source->{'_links'}->{'with-available-balance'}->{'href'})
  };
  print 'Dwolla balance = '.$dwolla_balance->{'balance'}->{'value'}."\n";

  # send 100USD from first verified bank account to $recipient_account_id
  my $success = eval { $oauth2->make_api_call('/transfers', {
    _links => {
      destination => { href => $oauth2->api_url_base().'/accounts/'.$recipient_account_id },
      source      => { href => $verified_sources[0]->{'_links'}->{'account'}->{'href'} },
    },
    amount => { currency => 'USD', value => '100.00' },
  }) };

  # (to send via Dwolla balance, use $balance_source->{'_links'}->{'account'}->{'href'}
  # as source href instead)

=head1 REGISTERING

First get a Dwolla account, by signing up at dwolla.com.  Then create a new application
via API Keys -> Create an application.  Set up the OAuth Redirect to match the C<redirect_uri>
in your LWP::Authen::OAuth2 object, and use the application's Key and Secret values
in client_id and client_secret.

Full Dwolla API v2 docs can be found here:

L<https://docsv2.dwolla.com/>,
L<https://developers.dwolla.com/>

=head1 AUTHOR

Adi Fairbank, C<< <https://github.com/adifairbank> >>

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
