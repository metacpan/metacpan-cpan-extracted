# Base package for Register modules
package Lemonldap::NG::Portal::Register::Base;

use strict;
use Mouse;
use Text::Unidecode;

extends 'Lemonldap::NG::Portal::Main::Plugin';

our $VERSION = '2.0.0';

sub _stripaccents {
    my ( $self, $str ) = @_;

    # UTF8 really shouldn't be decoded here, but in PSGI layer instead
    utf8::decode($str);

    # This method replaces all non-ascii characters by the
    # closest ascii lookalike
    my $res = unidecode($str);
    return $res;
}

sub applyLoginRule {
    my ( $self, $req ) = @_;

    my $firstname =
      lc $self->_stripaccents( $req->data->{registerInfo}->{firstname} );
    my $lastname =
      lc $self->_stripaccents( $req->data->{registerInfo}->{lastname} );

    # For now, get first letter of firstname and lastname
    return substr( $firstname, 0, 1 ) . $lastname;
}
1;
