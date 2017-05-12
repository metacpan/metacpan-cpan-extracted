##@file
# WebID authentication backend file

##@class
# WebID authentication backend class
package Lemonldap::NG::Portal::AuthWebID;

use strict;
use Lemonldap::NG::Portal::Simple;
use Lemonldap::NG::Portal::AuthSSL;
use Lemonldap::NG::Common::Regexp;
use Regexp::Assemble;

our $VERSION = '1.4.1';
our @ISA     = qw(Lemonldap::NG::Portal::AuthSSL);
our $initDone;
our $reWebIDWhitelist;

BEGIN {
    eval {
        require threads::shared;
        threads::shared::share($initDone);
        threads::shared::share($reWebIDWhitelist);
    };
}

*getDisplayType = *Lemonldap::NG::Portal::AuthSSL::getDisplayType;

## @apmethod int authInit()
# @return Lemonldap::NG::Portal constant
sub authInit {
    my $self = shift;
    my $tmp  = $self->SUPER::authInit(@_);
    return $tmp unless ( $tmp eq PE_OK );
    unless ($initDone) {
        eval "use Web::ID";
        $self->abort( 'Unable to load Web::ID', $@ ) if ($@);
        $initDone++;

        # Now examine white list and compile it
        my @hosts = split /\s+/, $self->{webIDWhitelist};
        $self->abort( 'WebID white list is empty',
            'Set it in manager, use * to accept all FOAF providers' )
          unless (@hosts);
        my $re = Regexp::Assemble->new();
        foreach my $h (@hosts) {
            $self->lmLog( "Add $h in WebID whitelist", 'debug' );
            $h = quotemeta($h);
            $h =~ s/\\\*/\.\*\?/g;
            $re->add($h);
        }
        $reWebIDWhitelist = '^https?://' . $re->as_string . '(?:/.*|)$';

    }
    PE_OK;
}

sub extractFormInfo {
    my $self = shift;

    # 1. Verify SSL exchange
    unless ( $ENV{SSL_CLIENT_S_DN} ) {
        $self->_sub( 'userError', "No certificate found for " . $self->ipAddr );
        $self->lmLog(
'No certificate found, be sure to have "SSLOptions +StdEnvVars +ExportCertData" for .pl files',
            'debug'
        );
        return PE_CERTIFICATEREQUIRED;
    }

    # 2. Return an error if SSL_CLIENT_CERT is not set
    $self->abort(
        'SSL configuration error',
        'Unable to get client certificate, SSL_CLIENT_CERT is not set<br/>'
          . 'Be sure to have "SSLOptions +StdEnvVars +ExportCertData" for .pl files'
    ) unless ( $ENV{SSL_CLIENT_CERT} );

    # 3. Verify that certificate is WebID compliant
    #    NB: WebID URI is used as user field
    eval {
        $self->{_webid} = Web::ID->new( certificate => $ENV{SSL_CLIENT_CERT} )
          and $self->{user} = $self->{_webid}->uri->as_string;
    };
    return PE_BADCERTIFICATE if ( $@ or not( $self->{user} ) );

    # 4. Verify that FOAF host is in white list
    return PE_BADPARTNER unless ( $self->{user} =~ $reWebIDWhitelist );

    # 5. Verify FOAF document
    return PE_BADCREDENTIALS unless ( $self->{_webid}->valid() );
    $self->{_webIdAuthDone}++;

    # 6. OK, access granted
    return PE_OK;
}

## @apmethod int authenticate()
# Just test that authentication has been done: job is done in
# extractFormInfo() else launch extractFormInfo()
# @return Lemonldap::NG::Portal constant
sub authenticate {
    my $self = shift;
    return $self->{_webIdAuthDone} ? PE_OK : PE_ERROR;
}

1;
__END__

=head1 NAME

=encoding utf8

Lemonldap::NG::Portal::AuthWebID - Perl extension for building Lemonldap::NG
compatible portals with WebID authentication.

=head1 SYNOPSIS

  use Lemonldap::NG::Portal::SharedConf;
  my $portal = new Lemonldap::NG::Portal::Simple(
         configStorage     => {...}, # See Lemonldap::NG::Portal
         authentication    => 'WebID',
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
WebID authentication mechanism.

See L<Lemonldap::NG::Portal::Simple> for usage and other methods.

=head1 SEE ALSO

L<Lemonldap::NG::Portal>, L<Lemonldap::NG::Portal::Simple>,
L<http://lemonldap-ng.org/>, L<Web::ID>
L<http://www.w3.org/wiki/WebID>

=head1 AUTHOR

=over

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

=item Copyright (C) 2013 by Xavier Guimard, E<lt>x.guimard@free.frE<gt>

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

