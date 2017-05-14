## @file
# OpenID Issuer file

## @class
# OpenID Issuer class
package Lemonldap::NG::Portal::IssuerDBOpenID;

use strict;
use Lemonldap::NG::Portal::Simple;
use Lemonldap::NG::Common::Regexp;

# Special comments for doxygen
#inherits Lemonldap::NG::Portal::OpenID::Server
#link Lemonldap::NG::Portal::OpenID::SREG protected sreg_extension

our $VERSION = '1.9.1';
our $initDone;

BEGIN {
    eval {
        require threads::shared;
        threads::shared::share($initDone);
    };
}

## @method void issuerDBInit()
# Do nothing
# @return Lemonldap::NG::Portal error code
sub issuerDBInit {
    my $self = shift;
    $self->{openIdIssuerSecret} ||= $self->{cipher}->encrypt(0);
    my $tmp = $self->{openIdSPList};
    $tmp =~ s/^(\d);//;
    $self->{_openIdSPListIsWhite} = $1 + 0;
    $self->{_reopenIdSPList} =
      Lemonldap::NG::Common::Regexp::reDomainsToHost($tmp);

    return PE_OK if ($initDone);

    eval { require Lemonldap::NG::Portal::OpenID::Server };
    $self->abort( 'Unable to load Net::OpenID::Server', $@ ) if ($@);
    $initDone = 1;
    return PE_OK;
}

## @apmethod int issuerForUnAuthUser()
# Do nothing
# @return Lemonldap::NG::Portal error code
sub issuerForUnAuthUser {
    my $self = shift;

    # Restore datas
    $self->restoreOpenIDprm();
    my $mode = $self->param('openid.mode');

    unless ($mode) {
        $self->lmLog( 'OpenID SP test', 'debug' );
        return PE_OPENID_EMPTY;
    }

    # Fill user attribute with OpenID user identity
    $self->{user} = ( split '/', $self->param('openid.identity') )[-1];
    $self->lmLog( "Get OpenID user " . $self->{user}, 'debug' );

    if ( $mode eq 'associate' ) {
        return $self->_openIDResponse( $self->openIDServer->_mode_associate() );
    }
    elsif ( $mode eq 'check_authentication' ) {
        return $self->_openIDResponse(
            $self->openIDServer->_mode_check_authentication() );
    }
    else {
        $self->storeOpenIDprm();
        return PE_OK;
    }
}

## @apmethod int issuerForAuthUser()
# Do nothing
# @return Lemonldap::NG::Portal error code
sub issuerForAuthUser {
    my $self = shift;

    # Restore datas
    $self->restoreOpenIDprm();
    my $mode = $self->param('openid.mode');

    unless ($mode) {
        $self->lmLog( 'OpenID SP test', 'debug' );
        return PE_OPENID_EMPTY;
    }

    unless ( $mode =~ /^checkid_(?:immediate|setup)/ ) {
        $self->lmLog(
"OpenID error : $mode is not known at this step (issuerForAuthUser)",
            'error'
        );
        return PE_ERROR;
    }
    my @r = $self->openIDServer->_mode_checkid();
    return $self->_openIDResponse(@r);
}

## @apmethod int issuerLogout()
# Does nothing since OpenID does not provide any logout system
# @return Lemonldap::NG::Portal error code
sub issuerLogout {
    PE_OK;
}

## @method private void storeOpenIDprm()
# Store openid parameters in a hidden value for forms using
# setHiddenFormValue()
sub storeOpenIDprm {
    my $self = shift;

    # Store all openid.* parameters
    my $params = {};
    foreach ( keys %{ $self->{_prm} } ) {
        next if $_ !~ /^openid\./;
        $params->{$_} = $self->{_prm}->{$_};
    }

    $self->setHiddenFormValue( 'openidprm', Storable::nfreeze($params) );
}

## @method private void restoreOpenIDprm()
# Restore initial openid parameters stored with storeOpenIDprm()
sub restoreOpenIDprm {
    my $self = shift;
    return if ( $self->{openIDRestored} );
    if ( my $tmp = $self->getHiddenFormValue('openidprm') ) {
        $self->lmLog( 'Restore OpenID parameters', 'debug' );
        eval {
            $tmp = Storable::thaw($tmp);
            $self->{_prm}->{$_} = $tmp->{$_} foreach ( keys %$tmp );
        };
    }
    $self->{openIDRestored} = 1;
}

## @method private Lemonldap::NG::Portal::OpenID::Server openIDServer()
# Create if not done a new Lemonldap::NG::Portal::OpenID::Server objet
# @return Lemonldap::NG::Portal::OpenID::Server object
sub openIDServer {
    my $self = shift;
    return $self->{_openidserver} if ( $self->{_openidserver} );
    my $path = $self->{issuerDBOpenIDPath};
    $path =~ s/\^//;
    $self->{_openidPortal} = $self->{portal} . $path;
    $self->{_openidPortal} =~ s#(?<!:)//#/#g;

    my $sub = sub { return $self->param(@_) };
    $self->{_openidserver} = Lemonldap::NG::Portal::OpenID::Server->new(
        server_secret => sub { return $self->{openIdIssuerSecret} },
        args          => $sub,
        endpoint_url => $self->{_openidPortal},
        setup_url    => $self->{_openidPortal},
        get_user     => sub {
            return $self->{sessionInfo}
              ->{ $self->{openIdAttr} || $self->{whatToTrace} };
        },
        get_identity => sub {
            my ( $u, $identity ) = @_;
            return $identity unless $u;
            return $self->{_openidPortal} . $u;
        },
        is_identity => sub {
            my ( $u, $identity ) = @_;
            return 0 unless ( $u and $identity );
            if ( $u eq ( split '/', $identity )[-1] ) {
                return 1;
            }
            else {
                $self->{_badOpenIdentity} = 1;
                return 0;
            }
        },
        is_trusted => sub {
            my ( $u, $trust_root, $is_identity ) = @_;
            return 0 unless ( $u and $is_identity );
            my $tmp = $trust_root;
            $tmp =~ s#^http://(.*?)/#$1#;
            if ( $tmp =~
                $self->{_reopenIdSPList} xor $self->{_openIdSPListIsWhite} )
            {
                $self->lmLog( "$trust_root is forbidden for openID exchange",
                    'warn' );
                $self->{_openIdForbidden} = 1;
                return 0;
            }
            elsif ( $self->{sessionInfo}->{"_openidTrust$trust_root"} ) {
                $self->lmLog( 'OpenID request already trusted', 'debug' );
                return 1;
            }
            elsif ( $self->param("confirm") == 1 ) {
                $self->updatePersistentSession(
                    { "_openidTrust$trust_root" => 1 } );
                return 1;
            }
            elsif ( $self->param("confirm") == -1 ) {
                $self->updatePersistentSession(
                    { "_openidTrust$trust_root" => 0 } );
                return 0;
            }
            else {
                $self->lmLog( 'OpenID request not trusted' . $sub->("confirm"),
                    'debug' );
                $self->{_openIdTrustRequired} = 1;
                return 0;
            }
        },
        extensions => {
            sreg => sub {
                return ( 1, {} ) unless (@_);
                require Lemonldap::NG::Portal::OpenID::SREG;
                return $self->Lemonldap::NG::Portal::OpenID::SREG::sregHook(@_);
            },
        },
    );
    return $self->{_openidserver};
}

## @method private int _openIDResponse()
# Manage Lemonldap::NG::Portal::OpenID::Server responses
# @return Lemonldap::NG::Portal error code
sub _openIDResponse {
    my ( $self, $type, $data ) = @_;

    # Redirect
    if ( $type eq 'redirect' ) {
        $self->lmLog( "OpenID redirection to $data", 'debug' );
        $self->{urldc} = $data;
        print $self->_sub('autoRedirect');
    }

    # Setup
    elsif ( $type eq 'setup' ) {
        if ( $self->{_openIdTrustRequired} or $self->{_openIdTrustExtMsg} ) {

            # TODO
            $self->info(
                '<h3>'
                  . sprintf(
                    $self->msg(PM_OPENID_EXCHANGE), $data->{trust_root}
                  )
                  . "</h3>"
            );
            $self->info( $self->{_openIdTrustExtMsg} )
              if ( $self->{_openIdTrustExtMsg} );
            $self->lmLog( 'OpenID confirmation', 'debug' );
            $self->storeOpenIDprm();
            return PE_CONFIRM;
        }
        elsif ( $self->{_badOpenIdentity} ) {
            $self->userNotice(
"The user $self->{sessionInfo}->{_user} tries to use the id \"$data->{identity}\" on $data->{trust_root}"
            );
            return PE_OPENID_BADID;
        }
        elsif ( $self->{_openIdForbidden} ) {
            return PE_BADPARTNER;
        }

        # User has refused sharing its datas
        else {
            $self->userNotice( $self->{sessionInfo}->{ $self->{whatToTrace} }
                  . ' refused to share its OpenIdentity' );
            return PE_OK;
        }
    }
    elsif ($type) {
        $self->lmLog( "OpenID generated page ($type)", 'debug' );
        print $self->header($type);
        print $data;
    }
    else {
        $self->abort( 'OpenID error ', $self->openIDServer->err() );
    }
    $self->quit();
}

1;

__END__

=head1 NAME

=encoding utf8

Lemonldap::NG::Portal::IssuerDBOpenID - OpenID IssuerDB for Lemonldap::NG

=head1 DESCRIPTION

OpenID Issuer implementation in LemonLDAP::NG

=head1 SEE ALSO

L<Lemonldap::NG::Portal>

=head1 AUTHOR

=over

=item Clement Oudot, E<lt>clem.oudot@gmail.comE<gt>

=item François-Xavier Deltombe, E<lt>fxdeltombe@gmail.com.E<gt>

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

=item Copyright (C) 2012 by François-Xavier Deltombe, E<lt>fxdeltombe@gmail.com.E<gt>

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
