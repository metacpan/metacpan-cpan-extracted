##@file
# Twitter authentication backend file

##@class
# Twitter authentication backend class.
package Lemonldap::NG::Portal::AuthTwitter;

use strict;
use Lemonldap::NG::Portal::Simple;

our $VERSION = '1.2.0';
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
    eval { require Net::Twitter };
    $self->abort("Unable to load Net::Twitter: $@") if ($@);

    $initDone = 1;
    PE_OK;
}

## @apmethod int extractFormInfo()
# Authenticate users by Twitter and set user
# @return Lemonldap::NG::Portal constant
sub extractFormInfo {
    my $self = shift;

    # Build Net::Twitter object
    $self->{_twitter} = Net::Twitter->new(
        traits          => [qw/API::REST OAuth/],
        consumer_key    => $self->{twitterKey},
        consumer_secret => $self->{twitterSecret},
        clientname      => $self->{twitterAppName} || 'Lemonldap::NG'
    );

    # 1. Request to authenticate
    unless ( $self->param('twitterback') ) {
        $self->lmLog( 'Redirection to Twitter', 'debug' );
        my $url;

        # 1.1 Try to get token to dialog with Twitter
        eval {
            $url =
              $self->{_twitter}->get_authorization_url(
                callback => "$self->{portal}?twitterback=1&url="
                  . $self->get_url() );
        };

        #   If 401 is returned => application not declared on Twitter
        if ($@) {
            if ( $@ =~ /\b401\b/ ) {
                $self->abort('Twitter application undeclared');
            }
            $self->lmLog( "Net::Twitter error: $@", 'error' );
            return PE_ERROR;
        }

        # 1.2 Store token key and secret in cookies
        push @{ $self->{cookie} },
          $self->cookie(
            -name    => '_twitTok',
            -value   => $self->{_twitter}->request_token,
            -expires => '+3m'
          ),
          $self->cookie(
            -name    => '_twitSec',
            -value   => $self->{_twitter}->request_token_secret,
            -expires => '+3m'
          );

        # 1.3 Redirect user to Twitter
        $self->redirect( -uri => $url );
        $self->quit();
    }

    # 2. User is back from Twitter
    my $request_token = $self->param('oauth_token');
    my $verifier      = $self->param('oauth_verifier');
    unless ( $request_token and $verifier ) {
        $self->lmLog( 'Twitter OAuth protocol error', 'error' );
        return PE_ERROR;
    }

    # 2.1 Reconnect to Twitter
    (
        $self->{sessionInfo}->{_access_token},
        $self->{sessionInfo}->{_access_token_secret}
      )
      = $self->{_twitter}->request_access_token(
        token        => $self->cookie('_twitTok'),
        token_secret => $self->cookie('_twitSec'),
        verifier     => $verifier
      );

    # 2.2 Ask for user_timeline : I've not found an other way to access to user
    #     datas !
    my $status = eval { $self->{_twitter}->user_timeline( { count => 1 } ) };

    # 2.3 Check if user has accepted authentication
    if ($@) {
        if ( $@ =~ /\b401\b/ ) {
            $self->userError('Twitter authentication refused');
            return PE_BADCREDENTIALS;
        }
        $self->lmLog( "Net::Twitter error: $@", 'error' );
    }

    # 2.4 Set $self->{user} to twitter.com/<username>
    $self->{_twitterUser} = $status->[0]->{user};
    $self->{user} = 'twitter.com/' . $status->{_twitterUser}->{screen_name};
    $self->lmLog( "Good Twitter authentication for $self->{user}", 'debug' );

    # Force redirection to avoid displaying OAuth datas
    $self->{mustRedirect} = 1;

    # Clean temporaries cookies
    push @{ $self->{cookie} },
      $self->cookie( -name => '_twitTok', -value => 0, -expires => '-3m' ),
      $self->cookie( -name => '_twitSec', -value => 0, -expires => '-3m' );
    PE_OK;
}

## @apmethod int setAuthSessionInfo()
# Set authenticationLevel and Twitter attributes.
# @return Lemonldap::NG::Portal constant
sub setAuthSessionInfo {
    my $self = shift;

    # TODO: set a parameter to choose this
    foreach (qw(screen_name location lang name url)) {
        $self->{sessionInfo}->{$_} = $self->{_twitterUser}->{$_};
    }

    $self->{sessionInfo}->{authenticationLevel} = $self->{twitterAuthnLevel};

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

=item Copyright (C) 2010, 2012 by Clement Oudot, E<lt>clem.oudot@gmail.comE<gt>

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


