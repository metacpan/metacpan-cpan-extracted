##@file
# BrowserID authentication backend file

##@class
# BrowserID authentication backend class
package Lemonldap::NG::Portal::AuthBrowserID;

use strict;
use Lemonldap::NG::Portal::Simple;
use Lemonldap::NG::Portal::_Browser;
use HTTP::Request;
use JSON;

our @ISA     = (qw(Lemonldap::NG::Portal::_Browser));
our $VERSION = '1.9.1';

## @apmethod int authInit()
# Enables Browser ID (required for templates)
# @return Lemonldap::NG::Portal constant
sub authInit {
    my $self = shift;

    $self->{browserIdVerificationURL} ||=
      "https://verifier.login.persona.org/verify";
    $self->{browserIdAuthnLevel} = "2"
      unless defined $self->{browserIdAuthnLevel};
    $self->{browserIdSiteName}        ||= "LemonLDAP::NG";
    $self->{browserIdBackgroundColor} ||= "#000";
    $self->{browserIdAutoLogin}       ||= "0";

    # Enable BrowserID in template
    $self->{tpl_browserIdEnabled} = 1;

    # Set BrowserID customization parameters
    $self->{tpl_browserIdSiteName} = $self->{browserIdSiteName}
      if $self->{browserIdSiteName};
    $self->{tpl_browserIdSiteLogo} = $self->{browserIdSiteLogo}
      if $self->{browserIdSiteLogo};
    $self->{tpl_browserIdBackgroundColor} = $self->{browserIdBackgroundColor}
      if $self->{browserIdBackgroundColor};
    $self->{tpl_browserIdAutoLogin} = $self->{browserIdAutoLogin}
      if $self->{browserIdAutoLogin};

    PE_OK;
}

## @apmethod int setAuthSessionInfo()
# @return Lemonldap::NG::Portal constant
sub setAuthSessionInfo {
    my $self = shift;

    $self->{sessionInfo}->{_user}               = $self->{user};
    $self->{sessionInfo}->{authenticationLevel} = $self->{browserIdAuthnLevel};
    $self->{sessionInfo}->{_browserIdAnswer}    = $self->{browserIdAnswer};
    $self->{sessionInfo}->{_browserIdAnswerRaw} = $self->{browserIdAnswerRaw};

    PE_OK;
}

## @apmethod int extractFormInfo()
# Get BrowserID assertion
# @return Lemonldap::NG::Portal constant
sub extractFormInfo {
    my $self = shift;

    # Assertion should be browserIdAssertion parameter
    if ( $self->{browserIdAssertion} = $self->param('browserIdAssertion') ) {
        $self->lmLog(
            "BrowserID Assertion found: " . $self->{browserIdAssertion},
            'debug' );

        # Resolve assertion
        my $postdata =
            "assertion="
          . $self->{browserIdAssertion}
          . "&audience="
          . $self->{portal};

        $self->lmLog( "Send $postdata to " . $self->{browserIdVerificationURL},
            'debug' );

        my $request =
          HTTP::Request->new( 'POST' => $self->{browserIdVerificationURL} );
        $request->content_type('application/x-www-form-urlencoded');
        $request->content($postdata);

        my $answer = $self->ua()->request($request);

        $self->lmLog( "Verification response: " . $answer->as_string, 'debug' );

        if ( $answer->code() == "200" ) {

            # Get JSON answser
            $self->{browserIdAnswerRaw} = $answer->content;
            $self->lmLog(
                "Received BrowserID answer: " . $self->{browserIdAnswerRaw},
                'debug' );

            my $json = JSON->new();
            $self->{browserIdAnswer} =
              $json->decode( $self->{browserIdAnswerRaw} );

            if ( $self->{browserIdAnswer}->{status} eq "okay" ) {
                $self->{user} = $self->{browserIdAnswer}->{email};

                $self->lmLog(
                    "Found user "
                      . $self->{user}
                      . " in BrowserID verification answer",
                    'debug'
                );

                return PE_OK;
            }
            else {
                if ( $self->{browserIdAnswer}->{reason} ) {
                    $self->lmLog(
                        "Assertion "
                          . $self->{browserIdAssertion}
                          . " verification error: "
                          . $self->{browserIdAnswer}->{reason},
                        'error'
                    );

                }
                else {
                    $self->lmLog(
                        "Assertion "
                          . $self->{browserIdAssertion}
                          . " not verified by BrowserID provider",
                        'error'
                    );
                }
                return PE_BADCREDENTIALS;
            }
        }
        else {
            $self->lmLog(
                "Fail to validate BrowserId assertion "
                  . $self->{browserIdAssertion},
                'error'
            );
            return PE_ERROR;
        }

        return PE_OK;
    }

    # No assertion, return to login page with BrowserID login script
    $self->{tpl_browserIdLoadLoginScript} = 1;
    return PE_FIRSTACCESS;
}

## @apmethod int authenticate()
# Verify assertion and audience
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
# Call BrowserID logout method
# @return Lemonldap::NG::Portal constant
sub authLogout {
    my $self = shift;
    $self->{tpl_browserIdLoadLogoutScript} = 1;
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

Lemonldap::NG::Portal::AuthBrowserID - Perl extension for building Lemonldap::NG
compatible portals with Mozilla BrowserID protocol

=head1 SYNOPSIS

  use Lemonldap::NG::Portal::SharedConf;
  my $portal = new Lemonldap::NG::Portal::Simple(
         configStorage     => {...}, # See Lemonldap::NG::Portal
         authentication    => 'BrowserID',
    );

  if($portal->process()) {
    # Write here the menu with CGI methods. This page is displayed ONLY IF
    # the user was not redirected here.
    print $portal->header('text/html; charset=utf-8'); # DON'T FORGET THIS (see CGI(3))
    print "...";

    # or redirect the user to the menu
    print $portal->redirect( -uri => 'https://portal/menu');
  }
  else {
    print $portal->header('text/html; charset=utf-8'); # DON'T FORGET THIS (see CGI(3))
    print "<html><body><h1>Unable to work</h1>";
    print "This server isn't well configured. Contact your administrator.";
    print "</body></html>";
  }

=head1 DESCRIPTION

This library just overload few methods of Lemonldap::NG::Portal::Simple to 
create sessions for anonymous users.

See L<Lemonldap::NG::Portal::Simple> for usage and other methods.

=head1 SEE ALSO

L<Lemonldap::NG::Portal>, L<Lemonldap::NG::Portal::Simple>,
L<http://lemonldap-ng.org/>

=head1 AUTHOR

=over

=item Clement Oudot, E<lt>clem.oudot@gmail.comE<gt>

=back

=head1 BUG REPORT

Use OW2 system to report bug or ask for features:
L<http://jira.ow2.org>

=head1 DOWNLOAD

Lemonldap::NG is available at
L<http://forge.objectweb.org/project/showfiles.php?group_id=274>

=head1 COPYRIGHT AND LICENSE

=over

=item Copyright (C) 2013 by Clement Oudot, E<lt>clem.oudot@gmail.comE<gt>

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

