#
# $Id: X509.pm,v 50c217684c90 2018/07/17 12:37:05 gomor $
#
# crypto::x509 Brik
#
package Metabrik::Crypto::X509;
use strict;
use warnings;

use base qw(Metabrik::Shell::Command);

sub brik_properties {
   return {
      revision => '$Revision: 50c217684c90 $',
      tags => [ qw(unstable openssl ssl pki certificate) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         datadir => [ qw(directory) ],
         ca_name => [ qw(name) ],
         ca_lc_name => [ qw(name) ],
         ca_key => [ qw(key_file) ],
         ca_cert => [ qw(cert_file) ],
         ca_directory => [ qw(directory) ],
         ca_conf => [ qw(conf_file) ],
         use_passphrase => [ qw(0|1) ],
         key_size => [ qw(bits) ],
      },
      attributes_default => {
         capture_stderr => 1,
         use_passphrase => 0,
         key_size => 2048,
      },
      commands => {
         ca_init => [ qw(name|OPTIONAL directory|OPTIONAL) ],
         set_ca_attributes => [ qw(ca_name|OPTIONAL) ],
         ca_show => [ qw(ca_name|OPTIONAL) ],
         ca_sign_csr => [ qw(csr_file|OPTIONAL ca_name|OPTIONAL) ],
         csr_new => [ qw(base_file use_passphrase|OPTIONAL) ],
         cert_hash => [ qw(cert_file) ],
         cert_verify => [ qw(cert_file ca_name|OPTIONAL) ],
         cert_show => [ qw(cert_file) ],
         parse_certificate_string => [ qw(string) ],
      },
      require_modules => {
         'Crypt::X509' => [ ],
         'Metabrik::File::Text' => [ ],
         'Metabrik::System::File' => [ ],
      },
      require_binaries => {
         'openssl', => [ ],
      },
   };
}

sub set_ca_attributes {
   my $self = shift;
   my ($ca_name) = @_;

   $ca_name ||= $self->ca_name;
   $self->brik_help_run_undef_arg('set_ca_attributes', $ca_name) or return;

   my $ca_lc_name = lc($ca_name);
   my $ca_directory = $self->ca_directory || $self->datadir.'/'.$ca_lc_name;

   my $ca_conf = $ca_directory.'/'.$ca_lc_name.'.conf';
   my $ca_cert = $ca_directory.'/'.$ca_lc_name.'.pem';
   my $ca_key = $ca_directory.'/'.$ca_lc_name.'.key';
   my $email = 'dummy@example.com';
   my $organization = 'Dummy Org';

   $self->ca_name($ca_name);
   $self->ca_lc_name($ca_lc_name);
   $self->ca_conf($ca_conf);
   $self->ca_directory($ca_directory);
   $self->ca_cert($ca_cert);
   $self->ca_key($ca_key);

   return 1;
}

sub ca_init {
   my $self = shift;
   my ($ca_name, $ca_directory) = @_;

   $ca_name ||= $self->ca_name;
   $ca_directory ||= $self->ca_directory;
   $self->brik_help_run_undef_arg('ca_init', $ca_name) or return;
   $self->brik_help_run_undef_arg('ca_init', $ca_directory) or return;

   $self->set_ca_attributes($ca_name)
      or return $self->log->error("ca_init: set_ca_attributes failed");

   if (-d $ca_directory) {
      return $self->log->error("ca_init: ca with name [$ca_name] already exists");
   }
   else {
      mkdir($ca_directory)
         or return $self->log->error("ca_init: mkdir1 failed with error [$!]");
      mkdir($ca_directory.'/certs')
         or return $self->log->error("ca_init: mkdir2 failed with error [$!]");
      mkdir($ca_directory.'/csrs')
         or return $self->log->error("ca_init: mkdir3 failed with error [$!]");

      my $ft = Metabrik::File::Text->new_from_brik_init($self) or return;
      $ft->write('', $ca_directory.'/index.txt') or return;
      $ft->write('01', $ca_directory.'/serial') or return;
   }

   $self->log->verbose("ca_init: using directory [$ca_directory]");

   my $ca_conf = $self->ca_conf;
   my $ca_cert = $self->ca_cert;
   my $ca_key = $self->ca_key;
   my $ca_lc_name = $self->ca_lc_name;
   my $key_size = $self->key_size;

   my $email = 'dummy@example.com';
   my $organization = 'Dummy Org';

   my $content = [
      "[ ca ]",
      "default_ca = $ca_lc_name",
      "",
      "[ $ca_lc_name ]",
      "dir              =  $ca_directory",
      "certificate      =  $ca_cert",
      "database         =  \$dir/index.txt",
      "#certs            =  \$dir/cert-csr",
      "new_certs_dir    =  \$dir/certs",
      "private_key      =  $ca_key",
      "serial           =  \$dir/serial",
      "default_crl_days = 7",
      "default_days     = 3650",
      "#default_md       = md5",
      "default_md       = sha1",
      "policy           = ${ca_lc_name}_policy",
      "x509_extensions  = certificate_extensions",
      "",
      "[ ${ca_lc_name}_policy ]",
      "commonName              = supplied",
      "stateOrProvinceName     = supplied",
      "countryName             = supplied",
      "organizationName        = supplied",
      "organizationalUnitName  = optional",
      "emailAddress            = optional",
      "",
      "[ certificate_extensions ]",
      "basicConstraints = CA:false",
      "",
      "[ req ]",
      "default_bits       = $key_size",
      "default_keyfile    = $ca_key",
      "#default_md         = md5",
      "default_days       = 1800",
      "default_md         = sha1",
      "prompt             = no",
      "distinguished_name = root_ca_distinguished_name",
      "x509_extensions    = root_ca_extensions",
      "",
      "[ root_ca_distinguished_name ]",
      "commonName          = $ca_name",
      "stateOrProvinceName = Paris",
      "countryName         = FR",
      "emailAddress        = $email",
      "organizationName    = $organization",
      "",
      "[ root_ca_extensions ]",
      "basicConstraints = CA:true",
   ];

   my $ft = Metabrik::File::Text->new_from_brik_init($self) or return;
   $ft->overwrite(1);
   $ft->write($content, $ca_conf)
      or return $self->log->error("ca_init: write failed");

   $self->log->verbose("ca_init: using conf file [$ca_conf] and cert [$ca_cert]");

   my $cmd = "openssl req -x509 -newkey rsa:$key_size ".
             "-days 1800 -out $ca_cert -outform PEM -config $ca_conf";

   $self->system($cmd) or return;

   my $hash = $self->cert_hash($ca_cert) or return;

   my $sf = Metabrik::System::File->new_from_brik_init($self) or return;
   $sf->link($ca_cert, $ca_directory.'/'.$hash.'.0') or return;

   return $ca_cert;
}

sub ca_show {
   my $self = shift;
   my ($ca_name) = @_;

   $ca_name ||= $self->ca_name;
   $self->brik_help_run_undef_arg('ca_show', $ca_name) or return;

   $self->set_ca_attributes($ca_name) or return;

   my $ca_cert = $self->ca_cert;
   my $cmd = "openssl x509 -in $ca_cert -text -noout";
   return $self->capture($cmd);
}

sub csr_new {
   my $self = shift;
   my ($base_file, $use_passphrase) = @_;

   $use_passphrase ||= $self->use_passphrase;
   $self->brik_help_run_undef_arg('csr_new', $base_file) or return;

   my $ca_directory = $self->ca_directory;
   my $csr_cert = $ca_directory.'/csrs/'.$base_file.'.csr';
   my $csr_key = $ca_directory.'/csrs/'.$base_file.'.key';
   my $key_size = $self->key_size;

   if (-f $csr_cert) {
      return $self->log->error("csr_new: file [$csr_cert] already exists");
   }

   my $cmd = "openssl req -newkey rsa:$key_size -keyout $csr_key -keyform PEM ".
             "-out $csr_cert -outform PEM";

   if (! $use_passphrase) {
      $cmd .= " -nodes";
   }

   $self->system($cmd);
   if ($?) {
      return $self->log->error("csr_new: system failed");
   }

   return [ $csr_cert, $csr_key ];
}

sub ca_sign_csr {
   my $self = shift;
   my ($csr_cert, $ca_name) = @_;

   $ca_name ||= $self->ca_name;
   $self->brik_help_run_undef_arg('ca_sign_csr', $csr_cert) or return;
   $self->brik_help_run_file_not_found('ca_sign_csr', $csr_cert) or return;
   $self->brik_help_run_undef_arg('ca_sign_csr', $ca_name) or return;

   $self->set_ca_attributes($ca_name) or return;

   my $ca_directory = $self->ca_directory;
   my $ca_conf = $self->ca_conf;

   my $sf = Metabrik::System::File->new_from_brik_init($self) or return;
   my $base_file = $sf->basefile($csr_cert) or return;
   $base_file =~ s/.[^\.]+$//;  # Remove extension

   my $signed_cert = $ca_directory.'/certs/'.$base_file.'.signed.pem';
   my $cmd = "openssl ca -in $csr_cert -out $signed_cert -config $ca_conf";
   $self->log->verbose("ca_sign_csr: cmd[$cmd]");
   $self->system($cmd);
   if ($?) {
      return $self->log->error("ca_sign_csr: system failed");
   }

   return $signed_cert;
}

#
# Returns hash ID of a certificate.
#
sub cert_hash {
   my $self = shift;
   my ($cert_file) = @_;

   $self->brik_help_run_undef_arg('cert_hash', $cert_file) or return;
   $self->brik_help_run_file_not_found('cert_hash', $cert_file) or return;

   my $cmd = "openssl x509 -noout -hash -in \"$cert_file\"";
   my $lines = $self->capture($cmd) or return;

   if (@$lines == 0) {
      return $self->log->error('cert_hash: unable to get hash');
   }

   return $lines->[0];
}

sub cert_verify {
   my $self = shift;
   my ($cert_file, $ca_name) = @_;

   $ca_name ||= $self->ca_name;
   $self->brik_help_run_undef_arg('cert_verify', $cert_file) or return;
   $self->brik_help_run_file_not_found('cert_verify', $cert_file) or return;
   $self->brik_help_run_undef_arg('cert_verify', $ca_name) or return;

   $self->set_ca_attributes($ca_name) or return;

   my $ca_directory = $self->ca_directory;

   my $cmd = "openssl verify -CApath $ca_directory $cert_file";

   return $self->capture($cmd);
}

sub cert_show {
   my $self = shift;
   my ($cert_file) = @_;

   $cert_file ||= $self->cert_file;
   $self->brik_help_run_undef_arg('cert_show', $cert_file) or return;
   $self->brik_help_run_file_not_found('cert_show', $cert_file) or return;

   my $cmd = "openssl x509 -in $cert_file -text -noout";
   return $self->capture($cmd);
}

sub parse_certificate_string {
   my $self = shift;
   my ($string) = @_;

   $self->brik_help_run_undef_arg('parse_certificate_string', $string) or return;
   if (! length($string)) {
      return $self->log->error("parse_certificate_string: empty string found");
   }

   # Patch fonction to add a defined() check.
   {
      no warnings 'redefine';

      *Crypt::X509::pubkey_components = sub {
         my $self = shift;
         my $pubkeyalg = $self->PubKeyAlg();
         if (defined($pubkeyalg) && $pubkeyalg eq 'RSA') {
            my $parser = Crypt::X509::_init('RSAPubKeyInfo');
            my $values = $parser->decode(
               $self->{tbsCertificate}{subjectPublicKeyInfo}{subjectPublicKey}[0]
            );
            return $values;
         }
         else {
            return undef;
         }
      };
   };

   my $decoded = Crypt::X509->new(cert => $string);
   if ($decoded->error) {
      return $self->log->error("parse_certificate_string: failed: ".$decoded->error);;
   }

   return $decoded;
}

1;

__END__

=head1 NAME

Metabrik::Crypto::X509 - crypto::x509 Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2018, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
