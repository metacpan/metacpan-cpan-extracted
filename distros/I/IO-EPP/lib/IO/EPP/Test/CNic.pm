package IO::EPP::Test::CNic;

=encoding utf8

=head1 NAME

IO::EPP::Test::CNic

=head1 SYNOPSIS

Call IO::EPP::CNic with parameter "test_mode=1"

=head1 DESCRIPTION

Module for testing IO::EPP::CNic,
emulates answers of CentralNic server

=head1 AUTHORS

Vadim Likhota <vadiml@cpan.org>

=cut

use IO::EPP::Test::Base;

use strict;
use warnings;

no utf8; # !!!

sub req {
    my ( $obj, $out_data, undef ) = @_;

    my $in_data;

    if ( !$out_data  or  $out_data =~ m|<hello[^<>]+/>| ) {
        $in_data = hello( $out_data );
    }
    else {
        return IO::EPP::Test::Base::req( @_ );
    }

    return $in_data;
}


sub hello {
    my $dt = IO::EPP::Test::Base::get_dates();

    return qq|<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0"><greeting><svID>CentralNic EPP server EPP.CENTRALNIC.COM</svID><svDate>$dt</svDate><svcMenu><version>1.0</version><lang>en</lang><objURI>urn:ietf:params:xml:ns:domain-1.0</objURI><objURI>urn:ietf:params:xml:ns:contact-1.0</objURI><objURI>urn:ietf:params:xml:ns:host-1.0</objURI><svcExtension><extURI>urn:ietf:params:xml:ns:rgp-1.0</extURI><extURI>urn:ietf:params:xml:ns:secDNS-1.1</extURI><extURI>urn:ietf:params:xml:ns:idn-1.0</extURI><extURI>urn:ietf:params:xml:ns:fee-0.4</extURI><extURI>urn:ietf:params:xml:ns:fee-0.5</extURI><extURI>urn:ietf:params:xml:ns:launch-1.0</extURI><extURI>urn:ietf:params:xml:ns:regtype-0.1</extURI><extURI>urn:ietf:params:xml:ns:auxcontact-0.1</extURI><extURI>urn:ietf:params:xml:ns:artRecord-0.2</extURI><extURI>http://www.nic.coop/contactCoopExt-1.0</extURI></svcExtension></svcMenu><dcp><access><all></all></access><statement><purpose><admin></admin><prov></prov></purpose><recipient><ours></ours><public></public></recipient><retention><stated></stated></retention></statement></dcp></greeting></epp>|;
}

1;
