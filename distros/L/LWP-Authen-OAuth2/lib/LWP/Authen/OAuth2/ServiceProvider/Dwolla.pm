package LWP::Authen::OAuth2::ServiceProvider::Dwolla;

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

=head1 NAME

LWP::Authen::OAuth2::ServiceProvider::Dwolla - Access Dwolla API v2

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

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc LWP::Authen::OAuth2::ServiceProvider

You can also look for information at:

=over 4

=item Github (submit patches here)

CPAN maintainer's branch: L<https://github.com/domm/perl-oauth2>

Branch where I work on Dwolla support: L<https://github.com/adifairbank/perl-oauth2>

=item RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=LWP-Authen-OAuth2>

=item AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/LWP-Authen-OAuth2>

=item CPAN Ratings

L<http://cpanratings.perl.org/d/LWP-Authen-OAuth2>

=back

=cut

1;
