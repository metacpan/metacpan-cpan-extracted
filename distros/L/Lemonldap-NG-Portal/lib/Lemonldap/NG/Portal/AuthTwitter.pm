##@file
# Twitter authentication backend file

##@class
# Twitter authentication backend class.
package Lemonldap::NG::Portal::AuthTwitter;

use strict;
use Lemonldap::NG::Portal::Simple;
use Lemonldap::NG::Portal::_Browser;
use URI::Escape;

our @ISA     = (qw(Lemonldap::NG::Portal::_Browser));
our $VERSION = '1.9.3';
our $initDone;

BEGIN {
    eval {
        require threads::shared;
        threads::shared::share($initDone);
    };
}

## @apmethod int authInit()
# @return Lemonldap::NG::Portal constant
sub authInit {
    my $self = shift;
    return PE_OK if ($initDone);

    unless ( $self->{twitterKey} and $self->{twitterSecret} ) {
        $self->abort( 'Bad configuration',
            'twitterKey and twitterSecret parameters are required' );
    }
    eval {
        require Net::OAuth;
        $Net::OAuth::PROTOCOL_VERSION = &Net::OAuth::PROTOCOL_VERSION_1_0A();
    };
    $self->abort("Unable to load Net::OAuth: $@") if ($@);

    $initDone = 1;
    PE_OK;
}

## @apmethod int extractFormInfo()
# Authenticate users by Twitter and set user
# @return Lemonldap::NG::Portal constant
sub extractFormInfo {
    my $self  = shift;
    my $nonce = time;

    # Default values for Twitter API
    $self->{twitterRequestTokenURL} ||=
      "https://api.twitter.com/oauth/request_token";
    $self->{twitterAuthorizeURL} ||= "https://api.twitter.com/oauth/authorize";
    $self->{twitterAccessTokenURL} ||=
      "https://api.twitter.com/oauth/access_token";

    # 1. Request to authenticate
    unless ( $self->param('twitterback') ) {
        $self->lmLog( 'Redirection to Twitter', 'debug' );

        # 1.1 Try to get token to dialog with Twitter
        my $callback_url = $self->url();

        # Twitter callback parameter
        $callback_url .=
          ( $callback_url =~ /\?/ ? '&' : '?' ) . "twitterback=1";

        # Add request state parameters
        if ( $self->{_url} ) {
            my $url_param = 'url=' . uri_escape( $self->{_url} );
            $callback_url .= ( $callback_url =~ /\?/ ? '&' : '?' ) . $url_param;
        }
        if ( $self->param( $self->{authChoiceParam} ) ) {
            my $url_param =
              $self->{authChoiceParam} . '='
              . uri_escape( $self->param( $self->{authChoiceParam} ) );
            $callback_url .= ( $callback_url =~ /\?/ ? '&' : '?' ) . $url_param;
        }

        # Forward hidden fields
        if ( exists $self->{portalHiddenFormValues} ) {

            $self->lmLog( "Add hidden values to Twitter redirect URL", 'debug' );

            foreach ( keys %{ $self->{portalHiddenFormValues} } ) {
                $callback_url .=
                    ( $callback_url =~ /\?/ ? '&' : '?' )
                  . $_ . '='
                  . uri_escape( $self->{portalHiddenFormValues}->{$_} );
            }
        }

        my $request = Net::OAuth->request("request token")->new(
            consumer_key     => $self->{twitterKey},
            consumer_secret  => $self->{twitterSecret},
            request_url      => $self->{twitterRequestTokenURL},
            request_method   => 'POST',
            signature_method => 'HMAC-SHA1',
            timestamp        => time,
            nonce            => $nonce,
            callback         => $callback_url,
        );

        $request->sign;

        my $request_url = $request->to_url;

        $self->lmLog( "POST $request_url to Twitter", 'debug' );

        my $res = $self->ua()->post($request_url);
        $self->lmLog( "Twitter response: " . $res->as_string, 'debug' );

        if ( $res->is_success ) {
            my $response = Net::OAuth->response('request token')
              ->from_post_body( $res->content );

            # 1.2 Store token key and secret in cookies
            push @{ $self->{cookie} },
              $self->cookie(
                -name    => '_twitSec',
                -value   => $response->token_secret,
                -expires => '+3m'
              );

            # 1.3 Redirect user to Twitter
            my $authorize_url =
              $self->{twitterAuthorizeURL} . "?oauth_token=" . $response->token;
            $self->redirect( -uri => $authorize_url );
            $self->quit();
        }
        else {
            $self->lmLog( 'Twitter OAuth protocol error: ' . $res->content,
                'error' );
            return PE_ERROR;
        }
    }

    # 2. User is back from Twitter
    my $request_token = $self->param('oauth_token');
    my $verifier      = $self->param('oauth_verifier');
    unless ( $request_token and $verifier ) {
        $self->lmLog( 'Twitter OAuth protocol error', 'error' );
        return PE_ERROR;
    }

    $self->lmLog(
        "Get token $request_token and verifier $verifier from Twitter",
        'debug' );

    # 2.1 Reconnect to Twitter
    my $access = Net::OAuth->request("access token")->new(
        consumer_key     => $self->{twitterKey},
        consumer_secret  => $self->{twitterSecret},
        request_url      => $self->{twitterAccessTokenURL},
        request_method   => 'POST',
        signature_method => 'HMAC-SHA1',
        verifier         => $verifier,
        token            => $request_token,
        token_secret     => $self->cookie('_twitSec'),
        timestamp        => time,
        nonce            => $nonce,
    );
    $access->sign;

    my $access_url = $access->to_url;

    $self->lmLog( "POST $access_url to Twitter", 'debug' );

    my $res_access = $self->ua()->post($access_url);
    $self->lmLog( "Twitter response: " . $res_access->as_string, 'debug' );

    if ( $res_access->is_success ) {
        my $response = Net::OAuth->response('access token')
          ->from_post_body( $res_access->content );

        # Get user_id and screename
        $self->{_twitterUserId}     = $response->{extra_params}->{user_id};
        $self->{_twitterScreenName} = $response->{extra_params}->{screen_name};

        $self->lmLog(
            "Get user id "
              . $self->{_twitterUserId}
              . " and screen name "
              . $self->{_twitterScreenName},
            'debug'
        );
    }
    else {
        $self->lmLog( 'Twitter OAuth protocol error: ' . $res_access->content,
            'error' );
        return PE_ERROR;
    }

    # 2.4 Set $self->{user} to screen name
    $self->{user} = $self->{_twitterScreenName};
    $self->lmLog( "Good Twitter authentication for $self->{user}", 'debug' );

    # Force redirection to avoid displaying OAuth datas
    $self->{mustRedirect} = 1;

    # Clean temporaries cookies
    push @{ $self->{cookie} },
      $self->cookie( -name => '_twitSec', -value => 0, -expires => '-3m' );
    PE_OK;
}

## @apmethod int setAuthSessionInfo()
# Set authenticationLevel and Twitter attributes.
# @return Lemonldap::NG::Portal constant
sub setAuthSessionInfo {
    my $self = shift;

    $self->{sessionInfo}->{authenticationLevel} = $self->{twitterAuthnLevel};
    $self->{sessionInfo}->{'_user'}             = $self->{user};
    $self->{sessionInfo}->{_twitterUserId}      = $self->{_twitterUserId};
    $self->{sessionInfo}->{_twitterScreenName}  = $self->{_twitterScreenName};

    PE_OK;
}

## @apmethod int authenticate()
# Does nothing.
# @return Lemonldap::NG::Portal constant
sub authenticate {
    PE_OK;
}

## @apmethod int authFinish()
# Does nothing.
# @return Lemonldap::NG::Portal constant
sub authFinish {
    PE_OK;
}

## @apmethod int authLogout()
# Does nothing
# @return Lemonldap::NG::Portal constant
sub authLogout {
    PE_OK;
}

## @apmethod boolean authForce()
# Does nothing
# @return result
sub authForce {
    return 0;
}

## @method string getDisplayType
# @return display type
sub getDisplayType {
    return "logo";
}

1;
__END__

=head1 NAME

=encoding utf8

Lemonldap::NG::Portal::AuthTwitter - Perl extension for building Lemonldap::NG
compatible portals with Twitter authentication.

=head1 SYNOPSIS

  use Lemonldap::NG::Portal::SharedConf;
  my $portal = new Lemonldap::NG::Portal::Simple(
         configStorage     => {...}, # See Lemonldap::NG::Portal
         authentication    => 'Twitter',
    );

  if($portal->process()) {
    # Write here the menu with CGI methods. This page is displayed ONLY IF
    # the user was not redirected here.
    print $portal->header('text/html; charset=utf-8'); # DON'T FORGET THIS (see CGI(3))
    print "...";
  }
  else {
    # If the user enters here, IT MEANS THAT CAS REDIRECTION DOES NOT WORK
    print $portal->header('text/html; charset=utf-8'); # DON'T FORGET THIS (see CGI(3))
    print "<html><body><h1>Unable to work</h1>";
    print "This server isn't well configured. Contact your administrator.";
    print "</body></html>";
  }

=head1 DESCRIPTION

This library just overload few methods of Lemonldap::NG::Portal::Simple to use
Twitter authentication mechanism.

See L<Lemonldap::NG::Portal::Simple> for usage and other methods.

=head1 SEE ALSO

L<Lemonldap::NG::Portal>, L<Lemonldap::NG::Portal::Simple>,
L<http://lemonldap-ng.org/>

=head1 AUTHOR

=over

=item Clement Oudot, E<lt>clem.oudot@gmail.comE<gt>

=item Xavier Guimard, E<lt>x.guimard@free.frE<gt>

=back

=head1 BUG REPORT

Use OW2 system to report bug or ask for features:
L<http://jira.ow2.org>

=head1 DOWNLOAD

Lemonldap::NG is available at
L<http://forge.objectweb.org/project/showfiles.php?group_id=274>

=head1 COPYRIGHT AND LICENSE

=over

=item Copyright (C) 2010 by Xavier Guimard, E<lt>x.guimard@free.frE<gt>

=item Copyright (C) 2010-2012 by Clement Oudot, E<lt>clem.oudot@gmail.comE<gt>

=back

This library is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2, or (at your option)
any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see L<http://www.gnu.org/licenses/>.

=cut


