# -*- perl -*-

#
# Author: Slaven Rezic
#
# Copyright (C) 2017,2018,2022 Slaven Rezic. All rights reserved.
# This package is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Mail: slaven@rezic.de
# WWW:  http://www.rezic.de/eserte/
#

package Doit::Ssl; # Convention: all commands here should be prefixed with 'ssl_'

use strict;
use warnings;
our $VERSION = '0.012';

use File::Basename 'basename';

use Doit::Log;

sub new { bless {}, shift }
sub functions { qw(ssl_install_ca_certificate can_openssl) }

sub can_openssl {
    my($self) = @_;
    $self->which('openssl') ? 1 : 0;
}

sub ssl_install_ca_certificate {
    my($self, %args) = @_;
    my $ca_file = delete $args{ca_file} || error "Please specify ca_file";
    error "Unhandled options: " . join(" ", %args) if %args;

    if (!$self->can_openssl) {
	error "openssl is not available";
    }

    my $fingerprint = $self->info_qx({quiet=>1}, qw(openssl x509 -noout -fingerprint -in), $ca_file);

    my $cert_file = '/etc/ssl/certs/ca-certificates.crt'; # XXX what about non-Debians?
    if (open my $fh, '<', $cert_file) {
	my $buf;
	while(<$fh>) {
	    if (/BEGIN CERTIFICATE/) {
		$buf = $_;
	    } else {
		$buf .= $_;
		if (/END CERTIFICATE/) {
		    my $check_fingerprint = $self->info_open2({quiet=>1, instr=>$buf}, qw(openssl x509 -noout -fingerprint));
		    if ($fingerprint eq $check_fingerprint) {
			# Found certificate, nothing to do
			return 0;
		    }
		}
	    }
	}
    } else {
	warning "No file '$cert_file' found --- is this the first certificate on this system?";
    }

    my $dest_file = basename $ca_file;
    if ($dest_file !~ m{\.crt$}) {
	$dest_file .= '.crt';
    }
    my $sudo = $< == 0 ? $self: $self->do_sudo; # unprivileged? -> upgrade to sudo
    $sudo->copy($ca_file, "/usr/local/share/ca-certificates/$dest_file");
    if (!$sudo->is_dry_run) {
	$sudo->system('update-ca-certificates');
    } else {
	info "Would need to run update-ca-certificates";
    }

    return 1;
}

1;

__END__
