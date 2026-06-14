package Dist::Zilla::Plugin::SigStore::SignRelease;
use strict;
use warnings;

our $VERSION = '0.06'; # VERSION

# ABSTRACT: Sign Release with SigStore

use Moose;
extends 'Dist::Zilla::Plugin::UploadToCPAN';
use Convert::ASN1;
use Crypt::OpenSSL::X509;
use File::Slurper qw/read_binary/;
use File::Which qw(which);
use JSON::MaybeXS;
use MIME::Base64  qw/decode_base64/;
use Try::Tiny;

use namespace::autoclean;

has upload_to_cpan      => (is => 'ro', default => 1);
has answer_yes          => (is => 'ro', default => 0);
has sigstore_extension  => (is => 'ro', default => 'sigstore.json');
has _cosign_app => (
    is      => 'ro',
    lazy    => 1,
    default => sub { which 'cosign' },
);

sub _sign_release {
  my $self      = shift;
  my $filename  = shift;

  my $bundle = $filename . '.' . $self->sigstore_extension;
  my $exit_code = 1;

  my $answer = $self->answer_yes ? '-y' : '';

  if (! defined $self->_cosign_app) {
    $self->log_fatal("Unable to find 'cosign' by SigStore? Is it installed?");
  } else {
    try {
      my $cosign = $self->_cosign_app;
      `$cosign sign-blob $answer '$filename' --bundle '$bundle'`;
      $exit_code = $? >> 8;
    } catch {
      $self->log("cosign failed for '$filename': $_");
    };
  }
  return ($exit_code == 0 && -f $bundle) ? 1 : 0;
}

sub _load_bundle {
  my $self = shift;
  my $bundle_name = shift;

  my $bundle_json = read_binary($bundle_name);
  my $bundle_decoded = try { decode_json($bundle_json) } catch {
    $self->log_fatal("Unable to decode sigstore JSON: $_");
  };

  return $bundle_decoded;
}

sub _get_der_from_bundle {
  my $self = shift;
  my $bundle = shift;
  my $cert;
  if (defined $bundle->{mediaType} && $bundle->{mediaType} eq 'application/vnd.dev.sigstore.bundle.v0.3+json')
  {
    $cert = $bundle->{verificationMaterial}->{certificate}->{rawBytes};
  } else {
    $cert = decode_base64($bundle->{cert});
    $cert =~ s/-----[^-]*-----//gm;
  }
  return decode_base64($cert);
}

sub _get_x509_from_der {
  my $self = shift;
  my $der = shift;
  return Crypt::OpenSSL::X509->new_from_string(
    $der, Crypt::OpenSSL::X509::FORMAT_ASN1
  );
}

sub _decode_oid_value {
  my $self = shift;
  my ($extensions, $oid) = @_;
  return "" unless $oid;

  my $hex_value;
  if (exists $extensions->{$oid}) {
    $hex_value = $extensions->{$oid}->value();
  } else {
    $self->log_fatal("Unable to find oid value for $oid");
  }

  # Remove leading '#' and pack to binary
  $hex_value =~ s/^#//;
  my $binary = pack("H*", $hex_value);
  my $asn = Convert::ASN1->new;

  if ($oid eq '1.3.6.1.4.1.57264.1.1') {
    return $binary;
  }
  elsif ($oid eq '2.5.29.17') {
    $asn->prepare(q(
       GeneralNames ::= SEQUENCE OF GeneralName
       GeneralName ::= CHOICE {
         rfc822Name                      [1]     IA5String
       }
    )) or $self->log_fatal("Unable to prepare ASN1 template");
    my $schema = $asn->find('GeneralNames')
      or $self->log_fatal("Cannot find GeneralNames in schema");
    my $decoded = $schema->decode($binary);

    # Return the first email found in the sequence
    return $decoded->[0]->{rfc822Name};
  }

  return "Unknown OID Format";
}

sub _verify_sigstore_signature {
  my $self      = shift;
  my ($filename, $bundle_name) = @_;

  my $bundle      = $self->_load_bundle($bundle_name);
  my $der         = $self->_get_der_from_bundle ($bundle);
  my $x509        = $self->_get_x509_from_der($der);
  my $extensions  = $x509->extensions_by_oid();
  my $identity    = $self->_decode_oid_value($extensions, '2.5.29.17');
  my $issuer      = $self->_decode_oid_value($extensions, '1.3.6.1.4.1.57264.1.1');

  my $exit_code = 1;
  my $verified;
  if (! defined $self->_cosign_app) {
    $self->log_fatal("Unable to find 'cosign' by SigStore? Is it installed?");
  } else {
    try {
      my $cosign = $self->_cosign_app;
      $verified = `$cosign verify-blob '$filename' --bundle '$bundle_name' --certificate-identity '$identity' --certificate-oidc-issuer '$issuer' 2>&1`;
      $exit_code = $? >> 8;
    } catch {
      $self->log("cosign failed for '$filename': $_");
    };
  }
  if ($exit_code == 0) {
    my $log = "Verified that $filename was signed by $identity via $issuer\n";
    $self->log($log);
  } else {
    $self->log($verified // "cosign verify failed with no output");
  }
  return $exit_code == 0 ? 1 : 0;
}

sub release {
  my ($self, $archive) = @_;

  my $signed = $self->_sign_release("$archive");
  my $bundle = $archive . '.' . $self->sigstore_extension;

  if ($signed && $self->upload_to_cpan && -f "$bundle") {
    my $verified = $self->_verify_sigstore_signature("$archive", "$bundle");
    if ($verified == 1) {
      $self->SUPER::release("$archive");
      $self->SUPER::release("$bundle");
    } else {
        $self->log("CRITICAL: verification of signature prior to upload failed");
        $self->log_fatal("CRITICAL: This should not happen!!!!");
    }
  } else {
      $self->log("cosign bundle was not created") if (! -f $bundle);
  }
}

sub BUILDARGS {
  my ($class, @args) = @_;
  my $args = @args == 1 ? $args[0] : {@args};

  $args->{sigstore_extension} =~ s/^\.// if defined $args->{sigstore_extension};
  return $class->SUPER::BUILDARGS(%$args);
}

no Moose;

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::SigStore::SignRelease - Sign Release with SigStore

=head1 VERSION

version 0.06

=head1 SYNOPSIS

In your F<dist.ini>:

    [@Filter]
    -bundle = @Basic
    -remove = UploadToCPAN

    [SigStore::SignRelease]
    upload_to_cpan     = 1             ; Upload the sigstore bundle to CPAN (optional)
    sigstore_extension = sigstore.json ; Extension of the sigstore bundle (optional)
    answer_yes         = 1             ; Answer yes to any cosign messages (Default = 0)

B<Note>: that I<upload_to_cpan> defaults to true (1).

=head1 DESCRIPTION

This plugin will sign a CPAN Release with SigStore

=head1 Required Plugins

This plugin requires that your Dist::Zilla configuration do the following:

 1. Create a release

There are numerous combinations of Dist::Zilla plugins that can perform those
functions.

 2. This Plugin replaces 'Dist::Zilla::Plugin::UploadToCPAN'

You will need to remove it from your dist.ini process as documented in the SYNOPSIS.

=head1 SIGSTORE INFORMATION

The current version requires the installation of the B<cosign> application. That
application can be accessed via the SigStore web site:

L<https://docs.sigstore.dev/cosign/system_config/installation/>

=head1 CPAN SUPPORT

As of version 0.01 there is no support in PAUSE or any CPAN client for sigstore
signature verification.

=head1 MANUAL SIGNATURE VERIFICATION

    cosign verify-blob Dist-Zilla-Plugin-SigStore-SignRelease-0.01.tar.gz \
        --bundle Dist-Zilla-Plugin-SigStore-SignRelease-0.01.tar.gz.sigstore.json \
        --certificate-identity timlegge@gmail.com \
        --certificate-oidc-issuer https://accounts.google.com

The GitHub repository also includes a script in the examples directory that
can be used to manually verify signatures.

L<https://github.com/timlegge/perl-Dist-Zilla-Plugin-SigStore/blob/main/example/verify_sigstore.pl>

=head1 ATTRIBUTES

=over

=item upload_to_cpan (Optional)

    true (1) or false (0) - Default = 1

=item sigstore_extension (Optional)

    Defaults to 'sigstore.json'

    The extension is appended to the end of the distribution's filename.

    example: Distribution-0.99.tar.gz.sigstore.json

=item answer_yes (Optional)

    true (1) or false (0) - Default = 0

    This answers yes to any cosign messages that require an answer.

=back

=head1 METHODS

=over

=item release

The main release and upload function.  It signs the archive with 'cosign'
and then uploads the archive and signature bundle if the signing was
successful and the signature matches.

=back

=head1 AUTHOR

Timothy Legge <timlegge@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Timothy Legge <timlegge@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
