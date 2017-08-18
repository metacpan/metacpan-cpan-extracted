package LWP::Authen::OAuth2::ServiceProvider::Line::AccessToken;

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
