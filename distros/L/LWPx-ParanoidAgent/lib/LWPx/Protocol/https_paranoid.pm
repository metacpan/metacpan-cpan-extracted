#
package LWPx::Protocol::https_paranoid;

# $Id: https_paranoid.pm 2 2005-06-01 23:12:25Z bradfitz $

use strict;

use vars qw(@ISA);
require LWPx::Protocol::http_paranoid;
@ISA = qw(LWPx::Protocol::http_paranoid);

sub _check_sock
{
    my($self, $req, $sock) = @_;
    my $check = $req->header("If-SSL-Cert-Subject");
    if (defined $check) {
	my $cert = $sock->get_peer_certificate ||
	    die "Missing SSL certificate";
	my $subject = $cert->subject_name;
	die "Bad SSL certificate subject: '$subject' !~ /$check/"
	    unless $subject =~ /$check/;
	$req->remove_header("If-SSL-Cert-Subject");  # don't pass it on
    }
}

sub _get_sock_info
{
    my $self = shift;
    $self->SUPER::_get_sock_info(@_);
    my($res, $sock) = @_;
    $res->header("Client-SSL-Cipher" => $sock->get_cipher);
    my $cert = $sock->get_peer_certificate;
    if ($cert) {
	$res->header("Client-SSL-Cert-Subject" => $cert->subject_name);
	$res->header("Client-SSL-Cert-Issuer" => $cert->issuer_name);
    }
    if(! eval { $sock->get_peer_verify }) {
       $res->header("Client-SSL-Warning" => "Peer certificate not verified");
    }
}

sub _extra_sock_opts
{
    my $self = shift;
    my %ssl_opts = %{$self->{ua}{ssl_opts} || {}};
    if (delete $ssl_opts{verify_hostname}) {
    $ssl_opts{SSL_verify_mode} ||= 1;
    $ssl_opts{SSL_verifycn_scheme} = 'www';
    }
    else {
    $ssl_opts{SSL_verify_mode} = 0;
    }
    if ($ssl_opts{SSL_verify_mode}) {
    unless (exists $ssl_opts{SSL_ca_file} || exists $ssl_opts{SSL_ca_path}) {
        eval {
        require Mozilla::CA;
        };
        if ($@) {
        if ($@ =! /^Can't locate Mozilla\/CA\.pm/) {
            $@ = <<'EOT';
Can't verify SSL peers without knowing which Certificate Authorities to trust

This problem can be fixed by either setting the PERL_LWP_SSL_CA_FILE
environment variable or by installing the Mozilla::CA module.

To disable verification of SSL peers set the PERL_LWP_SSL_VERIFY_HOSTNAME
environment variable to 0.  If you do this you can't be sure that you
communicate with the expected peer.
EOT
        }
        die $@;
        }
        $ssl_opts{SSL_ca_file} = Mozilla::CA::SSL_ca_file();
    }
    }
    $self->{ssl_opts} = \%ssl_opts;
    return (%ssl_opts, $self->SUPER::_extra_sock_opts);
}

#-----------------------------------------------------------
package LWPx::Protocol::https_paranoid::Socket;

use vars qw(@ISA);
require Net::HTTPS;
@ISA = qw(Net::HTTPS LWPx::Protocol::http_paranoid::SocketMethods);

1;
