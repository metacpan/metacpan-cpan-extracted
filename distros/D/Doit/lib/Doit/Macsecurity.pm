# -*- perl -*-

#
# Author: Slaven Rezic
#
# Copyright (C) 2017,2018 Slaven Rezic. All rights reserved.
# This package is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Mail: slaven@rezic.de
# WWW:  http://www.rezic.de/eserte/
#

package Doit::Macsecurity;

use strict;
use warnings;
our $VERSION = '0.011';

use Doit::Log;

sub new { bless {}, shift }
sub functions { qw(macsecurity_install_trusted_certificate) }

sub macsecurity_install_trusted_certificate {
    my($self, %args) = @_;
    my $cert_file = delete $args{cert_file} || error "Please specify cert_file";
    error "Unhandled options: " . join(" ", %args) if %args;

    chomp(my $fingerprint = $self->info_qx({quiet=>1}, qw(openssl x509 -noout -fingerprint -in), $cert_file));
    $fingerprint =~ s{^SHA1 Fingerprint=}{};
    $fingerprint =~ s{:}{}g;

    my $found = sub {
	open my $fh, '-|', qw(security find-certificate -a -Z)
	    or error "while running security find-certificate: $!";
	while(<$fh>) {
	    chomp;
	    if (/^SHA-1 hash:\s*(\S+)/) {
		if ($1 eq $fingerprint) {
		    return 1;
		}
	    }
	}
	close $fh
	    or error "while running security find-certificate: $!";
	0;
    }->();

    if (!$found) {
	$self->system(qw(security import), $cert_file);
	$self->system(qw(security add-trusted-cert), $cert_file); # XXX actually there should be a way to find out if an installed certificate is already trusted
	return 1;
    } else {
	return 0;
    }
}

1;

__END__
