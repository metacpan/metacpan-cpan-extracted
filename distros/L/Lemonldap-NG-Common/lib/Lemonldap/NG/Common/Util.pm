package Lemonldap::NG::Common::Util;
require Exporter;

use strict;
use Digest::MD5;
use MIME::Base64 qw(encode_base64);

our $VERSION = '2.17.0';
our @ISA     = qw(Exporter);
our @EXPORT_OK =
  qw(getSameSite getPSessionID genId2F display2F filterKey2F isHiddenAttr);

sub getPSessionID {
    my ($uid) = @_;
    return substr( Digest::MD5::md5_hex($uid), 0, 32 );
}

sub genId2F {
    my ($device) = @_;
    return encode_base64( "$device->{epoch}::$device->{type}::$device->{name}",
        "" );
}

sub display2F {
    my ($device) = @_;
    return sprintf( "[%s]%s", $device->{type}, $device->{epoch} );
}

# Return the 2F device without private _* keys
sub filterKey2F {
    my ( $device, @filterKeys ) = @_;
    my $filtered_2f =
      { map { $_ => $device->{$_} } grep( !/^_/, keys %$device ) };

    delete $filtered_2f->{$_} for @filterKeys;
    return $filtered_2f;
}

sub isHiddenAttr {
    my ( $conf, $attr, @extra_hidden_attributes ) = @_;
    my ( @regexps, $match );

    my %hiddenAttributes = map { $_ => 1 } grep {
        if (m#^/(.+)?/$#) {
            push @regexps, qr/$1/;
            0;
        }
        else {
            1;
        }
    } ( split( /[,\s]+/, $conf->{hiddenAttributes} ),
        @extra_hidden_attributes );

    my $regex =
      keys %hiddenAttributes
      ? '\b(?:' . join( '|', keys %hiddenAttributes ) . ')\b'
      : '';

    foreach (@regexps) {
        $match++ if $attr =~ $_;
    }

    return
         $match
      || $hiddenAttributes{$attr}
      || ( $regex && $attr =~ m#$regex# );
}

sub getSameSite {
    my ($conf) = @_;

    # Initialize cookie SameSite value
    return $conf->{sameSite} if $conf->{sameSite};

    # SAML requires SameSite=None for POST bindings
    return (
        $conf->{issuerDBSAMLActivation}
          or keys %{ $conf->{samlIDPMetaDataXML} }
    ) ? 'None' : 'Lax';

    # if CDA, OIDC, CAS: Lax
    # TODO: try to detect when we can use 'Strict'?
    # Any scenario that uses pdata to save state during login,
    # Issuers, and CDA all require at least Lax
}

1;
__END__

=head1 NAME

=encoding utf8

Lemonldap::NG::Common::Util - Utility class for LemonLDAP::NG

=head1 DESCRIPTION

This package contains various functions that need to be shared between 
modules.

=head1 METHODS

=head3 getPSessionID($uid)

This method computes the psession ID from the user login

=head3 genId2F($device)

This method computes the unique ID of each 2F device, for use with the API and CLI

=head3 display2F($device)

This method formats device name for logging purpose

=head3 isHiddenAttr( $conf, $attr, @extra_hidden_attributes )

This method tests if the attribute is hidden.
@extra_hidden_attributes is an array of additional attributes to hide.

=head3 getSameSite($conf)

Try to find a sensible value for the SameSite cookie attribute.
If the user has overridden it, return the forced value

=head1 AUTHORS

=over

=item LemonLDAP::NG team L<http://lemonldap-ng.org/team>

=back

=head1 BUG REPORT

Use OW2 system to report bug or ask for features:
L<https://gitlab.ow2.org/lemonldap-ng/lemonldap-ng/issues>

=head1 DOWNLOAD

Lemonldap::NG is available at
L<https://lemonldap-ng.org/download>

=head1 COPYRIGHT AND LICENSE

See COPYING file for details.

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
