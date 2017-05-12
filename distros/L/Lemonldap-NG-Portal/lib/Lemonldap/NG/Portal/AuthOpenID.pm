##@file
# OpenID authentication backend file

##@class
# OpenID authentication backend class.
# The form must return a openid_identifier field
package Lemonldap::NG::Portal::AuthOpenID;

use strict;
use Lemonldap::NG::Portal::Simple;
use Lemonldap::NG::Common::Regexp;
use Lemonldap::NG::Portal::_Browser;
use Cache::FileCache;

our @ISA     = (qw(Lemonldap::NG::Portal::_Browser));
our $VERSION = '1.4.11';
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
    $self->{openIdSecret} ||= $self->{cipher}->encrypt(0);
    my $tmp = $self->{openIdIDPList};
    $tmp =~ s/^(\d);//;
    $self->{_openIdIDPListIsWhite} = $1 + 0;
    $self->{_reopenIdIDPList} =
      Lemonldap::NG::Common::Regexp::reDomainsToHost($tmp);

    return PE_OK if ($initDone);

    eval { require Net::OpenID::Consumer };
    $self->abort( 'Unable to load Net::OpenID::Consumer', $@ ) if ($@);

    $initDone = 1;
    PE_OK;
}

## @apmethod int extractFormInfo()
# Read username return by OpenID authentication system.
# @return Lemonldap::NG::Portal constant
sub extractFormInfo {
    my $self = shift;

    $self->{csr} = Net::OpenID::Consumer->new(
        ua              => $self->ua(),
        cache           => $self->{refLocalStorage} || Cache::FileCache->new,
        args            => $self,
        consumer_secret => $self->{openIdSecret},
        required_root   => $self->{portal},
    );

    my ( $url, $openid );

    # 1. If no openid element has been detected
    $openid = $self->param('openid');
    return PE_FIRSTACCESS
      unless ( $url = $self->param('openid_identifier') or $openid );

    # 2. Check OpenID responses
    if ($openid) {
        my $csr = $self->{csr};

        # Remote error
        unless ( $csr->is_server_response() ) {
            $self->{_msg} = 'No OpenID valid message found' . $csr->err();
            $self->lmLog( $self->{_msg}, 'info' );
            return PE_BADCREDENTIALS;
        }

        # If confirmation is needed
        if ( my $setup_url = $csr->user_setup_url ) {
            $self->_sub( 'userInfo', 'OpenID confirmation needed' );
            print $self->redirect($setup_url);
            $self->quit();
        }

        # Check if user has refused to share his authentication
        elsif ( $csr->user_cancel() ) {
            $self->{_msg} = "OpenID request cancelled by user";
            $self->lmLog( $self->{_msg}, 'info' );
            return PE_FIRSTACCESS;
        }

        # TODO: check verified identity
        elsif ( $self->{vident} = $csr->verified_identity ) {
            $self->{user} = $self->{vident}->url();
            $self->lmLog( "OpenID good authentication for $self->{user}",
                'debug' );
            $self->{mustRedirect} = 1;
            return PE_OK;
        }

        # Other errors
        else {
            $self->{_msg} = 'OpenID error: ' . $csr->err;
            $self->lmLog( $self->{_msg}, 'warn' );
            return PE_ERROR;
        }
    }

    # 3. Check if an OpenID url has been submitted
    else {
        my $tmp = $url;
        $tmp =~ m#^https?://(.*?)/#;
        if ( $tmp =~
            $self->{_reopenIdIDPList} xor $self->{_openIdIDPListIsWhite} )
        {
            $self->_sub( 'userNotice',
                "$url is forbidden for openID exchange" );
            $self->{_msg} =
              "OpenID error: $tmp is forbidden for OpenID echange";
            return PE_BADPARTNER;
        }
        my $claimed_identity = $self->{csr}->claimed_identity($url);

        # Check if url is valid
        unless ($claimed_identity) {
            $self->{_msg} = "OpenID error : " . $self->{csr}->err();
            $self->lmLog( $self->{_msg}, 'warn' );
            return PE_BADCREDENTIALS;
        }

        # Build the redirection
        $self->lmLog( "OpenID redirection to $url", 'debug' );
        my $check_url = $claimed_identity->check_url(
            return_to => $self->{portal}
              . '?openid=1'
              . ( $self->{_url} ? "&url=$self->{_url}" : '' )
              . (
                $self->param( $self->{authChoiceParam} )
                ? "&"
                  . $self->{authChoiceParam} . "="
                  . $self->param( $self->{authChoiceParam} )
                : ''
              ),
            trust_root     => $self->{portal},
            delayed_return => 1,
        );

        # If UserDB uses OpenID, add "OpenID Simple Registration Extension"
        # compatible fields
        if ( $self->get_module('user') eq 'OpenID' ) {
            my ( @r, @o );
            my %vars =
              ( %{ $self->{exportedVars} }, %{ $self->{openIdExportedVars} } );
            while ( my ( $v, $k ) = each %vars ) {
                if ( $k =~ Lemonldap::NG::Common::Regexp::OPENIDSREGATTR() ) {
                    if   ( $v =~ s/^!// ) { push @r, $k }
                    else                  { push @o, $k }
                }
                else {
                    $self->lmLog(
"Unknown \"OpenID Simple Registration Extension\" field name: $k",
                        'warn'
                    );
                }
            }
            my @tmp;
            push @tmp, 'openid.sreg.required' => join( ',', @r ) if (@r);
            push @tmp, 'openid.sreg.optional' => join( ',', @o ) if (@o);
            OpenID::util::push_url_arg( \$check_url, @tmp ) if (@tmp);
        }
        print $self->redirect($check_url);
        $self->quit();
    }
    PE_OK;
}

## @apmethod int setAuthSessionInfo()
# Set _user and authenticationLevel.
# @return Lemonldap::NG::Portal constant
sub setAuthSessionInfo {
    my $self = shift;

    $self->{sessionInfo}->{'_user'} = $self->{user};

    $self->{sessionInfo}->{authenticationLevel} = $self->{openIdAuthnLevel};

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
    return "openidform";
}

1;
__END__

=head1 NAME

=encoding utf8

Lemonldap::NG::Portal::AuthOpenID - Perl extension for building Lemonldap::NG
compatible portals with OpenID authentication.

=head1 SYNOPSIS

  use Lemonldap::NG::Portal::SharedConf;
  my $portal = new Lemonldap::NG::Portal::Simple(
         configStorage     => {...}, # See Lemonldap::NG::Portal
         authentication    => 'OpenID',
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
OpenID authentication mechanism.

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


