## @file
# Common CAS functions

## @class
# Common CAS functions
package Lemonldap::NG::Portal::_CAS;

use strict;
use Lemonldap::NG::Portal::_Browser;
use Lemonldap::NG::Common::Session;

our @ISA     = (qw(Lemonldap::NG::Portal::_Browser));
our $VERSION = '1.9.1';

## @method hashref getCasSession(string id)
# Try to recover the CAS session corresponding to id and return session datas
# If id is set to undef, return a new session
# @param id session reference
# @return CAS session object
sub getCasSession {
    my ( $self, $id ) = @_;

    my $casSession = Lemonldap::NG::Common::Session->new(
        {
            storageModule        => $self->{casStorage},
            storageModuleOptions => $self->{casStorageOptions},
            cacheModule          => $self->{localSessionStorage},
            cacheModuleOptions   => $self->{localSessionStorageOptions},
            id                   => $id,
            kind                 => "CAS",
        }
    );

    if ( $casSession->error ) {
        if ($id) {
            $self->_sub( 'userInfo', "CAS session $id isn't yet available" );
        }
        else {
            $self->lmLog( "Unable to create new CAS session", 'error' );
            $self->lmLog( $casSession->error,                 'error' );
        }
        return undef;
    }

    return $casSession;
}

## @method void returnCasValidateError()
# Return an error for CAS VALIDATE request
# @return nothing
sub returnCasValidateError {
    my ($self) = @_;

    $self->lmLog( "Return CAS validate error", 'debug' );

    print $self->header();
    print "no\n\n";

    $self->quit();
}

## @method void returnCasValidateSuccess(string username)
# Return success for CAS VALIDATE request
# @param username User name
# @return nothing
sub returnCasValidateSuccess {
    my ( $self, $username ) = @_;

    $self->lmLog( "Return CAS validate success with username $username",
        'debug' );

    print $self->header();
    print "yes\n$username\n";

    $self->quit();
}

## @method void returnCasServiceValidateError(string code, string text)
# Return an error for CAS SERVICE VALIDATE request
# @param code CAS error code
# @param text Error text
# @return nothing
sub returnCasServiceValidateError {
    my ( $self, $code, $text ) = @_;

    $code ||= 'INTERNAL_ERROR';
    $text ||= 'No description provided';

    $self->lmLog( "Return CAS service validate error $code ($text)", 'debug' );

    print $self->header( -type => 'application/xml' );
    print "<cas:serviceResponse xmlns:cas='http://www.yale.edu/tp/cas'>\n";
    print "\t<cas:authenticationFailure code=\"$code\">\n";
    print "\t\t$text\n";
    print "\t</cas:authenticationFailure>\n";
    print "</cas:serviceResponse>\n";

    $self->quit();
}

## @method void returnCasServiceValidateSuccess(string username, string pgtIou, string proxies, hashref attributes)
# Return success for CAS SERVICE VALIDATE request
# @param username User name
# @param pgtIou Proxy granting ticket IOU
# @param proxies List of used CAS proxies
# @param attributes Attributes to return
# @return nothing
sub returnCasServiceValidateSuccess {
    my ( $self, $username, $pgtIou, $proxies, $attributes ) = @_;

    $self->lmLog( "Return CAS service validate success with username $username",
        'debug' );

    print $self->header( -type => 'application/xml' );
    print "<cas:serviceResponse xmlns:cas='http://www.yale.edu/tp/cas'>\n";
    print "\t<cas:authenticationSuccess>\n";
    print "\t\t<cas:user>$username</cas:user>\n";
    if ( defined $attributes ) {
        print "\t\t<cas:attributes>\n";
        foreach my $attribute ( keys %$attributes ) {
            foreach my $value (
                split(
                    $self->{multiValuesSeparator},
                    $attributes->{$attribute}
                )
              )
            {
                print "\t\t\t<cas:$attribute>$value</cas:$attribute>\n";
            }
        }
        print "\t\t</cas:attributes>\n";
    }
    if ( defined $pgtIou ) {
        $self->lmLog( "Add proxy granting ticket $pgtIou in response",
            'debug' );
        print
          "\t\t<cas:proxyGrantingTicket>$pgtIou</cas:proxyGrantingTicket>\n";
    }
    if ($proxies) {
        $self->lmLog( "Add proxies $proxies in response", 'debug' );
        print "\t\t<cas:proxies>\n";
        print "\t\t\t<cas:proxy>$_</cas:proxy>\n"
          foreach ( split( /$self->{multiValuesSeparator}/, $proxies ) );
        print "\t\t</cas:proxies>\n";
    }
    print "\t</cas:authenticationSuccess>\n";
    print "</cas:serviceResponse>\n";

    $self->quit();
}

## @method void returnCasProxyError(string code, string text)
# Return an error for CAS PROXY request
# @param code CAS error code
# @param text Error text
# @return nothing
sub returnCasProxyError {
    my ( $self, $code, $text ) = @_;

    $code ||= 'INTERNAL_ERROR';
    $text ||= 'No description provided';

    $self->lmLog( "Return CAS proxy error $code ($text)", 'debug' );

    print $self->header( -type => 'application/xml' );
    print "<cas:serviceResponse xmlns:cas='http://www.yale.edu/tp/cas'>\n";
    print "\t<cas:proxyFailure code=\"$code\">\n";
    print "\t\t$text\n";
    print "\t</cas:proxyFailure>\n";
    print "</cas:serviceResponse>\n";

    $self->quit();
}

## @method void returnCasProxySuccess(string ticket)
# Return success for CAS PROXY request
# @param ticket Proxy ticket
# @return nothing
sub returnCasProxySuccess {
    my ( $self, $ticket ) = @_;

    $self->lmLog( "Return CAS proxy success with ticket $ticket", 'debug' );

    print $self->header( -type => 'application/xml' );
    print "<cas:serviceResponse xmlns:cas='http://www.yale.edu/tp/cas'>\n";
    print "\t<cas:proxySuccess>\n";
    print "\t\t<cas:proxyTicket>$ticket</cas:proxyTicket>\n";
    print "\t</cas:proxySuccess>\n";
    print "</cas:serviceResponse>\n";

    $self->quit();
}
## @method boolean deleteCasSecondarySessions(string session_id)
# Find and delete CAS sessions bounded to a primary session
# @param session_id Primary session ID
# @return result
sub deleteCasSecondarySessions {
    my ( $self, $session_id ) = @_;
    my $result = 1;

    # Find CAS sessions
    my $moduleOptions = $self->{casStorageOptions} || {};
    $moduleOptions->{backend} = $self->{casStorage};
    my $module = "Lemonldap::NG::Common::Apache::Session";

    my $cas_sessions =
      $module->searchOn( $moduleOptions, "_cas_id", $session_id );

    if ( my @cas_sessions_keys = keys %$cas_sessions ) {

        foreach my $cas_session (@cas_sessions_keys) {

            # Get session
            $self->lmLog( "Retrieve CAS session $cas_session", 'debug' );

            my $casSession = $self->getCasSession($cas_session);

            # Delete session
            $result = $self->deleteCasSession($casSession);
        }
    }
    else {
        $self->lmLog( "No CAS session found for session $session_id ",
            'debug' );
    }

    return $result;

}

## @method boolean deleteCasSession(Lemonldap::NG::Common::Session session)
# Delete an opened CAS session
# @param session object
# @return result
sub deleteCasSession {
    my ( $self, $session ) = @_;

    # Check session object
    unless ( $session && $session->data ) {
        $self->lmLog( "No session to delete", 'error' );
        return 0;
    }

    # Get session_id
    my $session_id = $session->id;

    # Delete session
    unless ( $session->remove ) {
        $self->lmLog( $session->error, 'error' );
        return 0;
    }

    $self->lmLog( "CAS session $session_id deleted", 'debug' );

    return 1;
}

## @method boolean callPgtUrl(string pgtUrl, string pgtIou, string pgtId)
# Call proxy granting URL on CAS client
# @param pgtUrl Proxy granting URL
# @param pgtIou Proxy granting ticket IOU
# @param pgtId Proxy granting ticket
# @return result
sub callPgtUrl {
    my ( $self, $pgtUrl, $pgtIou, $pgtId ) = @_;

    # Build URL
    my $url = $pgtUrl;
    $url .= ( $pgtUrl =~ /\?/ ? '&' : '?' );
    $url .= "pgtIou=$pgtIou&pgtId=$pgtId";

    $self->lmLog( "Call URL $url", 'debug' );

    # GET URL
    my $response = $self->ua()->get($url);

    # Return result
    return $response->is_success();
}

1;

__END__

=head1 NAME

=encoding utf8

Lemonldap::NG::Portal::_CAS - Common CAS functions

=head1 SYNOPSIS

use Lemonldap::NG::Portal::_CAS;

=head1 DESCRIPTION

This module contains common methods for CAS

=head1 METHODS

=head2 getCasSession

Try to recover the CAS session corresponding to id and return session datas
If id is set to undef, return a new session

=head2 returnCasValidateError

Return an error for CAS VALIDATE request

=head2 returnCasValidateSuccess

Return success for CAS VALIDATE request

=head2 deleteCasSecondarySessions

Find and delete CAS sessions bounded to a primary session

=head2 returnCasServiceValidateError

Return an error for CAS SERVICE VALIDATE request

=head2 returnCasServiceValidateSuccess

Return success for CAS SERVICE VALIDATE request

=head2 returnCasProxyError

Return an error for CAS PROXY request

=head2 returnCasProxySuccess

Return success for CAS PROXY request

=head2 deleteCasSession

Delete an opened CAS session

=head2 callPgtUrl

Call proxy granting URL on CAS client

=head1 SEE ALSO

L<Lemonldap::NG::Portal::IssuerDBCAS>

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

