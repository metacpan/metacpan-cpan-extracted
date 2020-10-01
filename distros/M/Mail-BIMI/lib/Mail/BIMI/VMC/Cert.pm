package Mail::BIMI::VMC::Cert;
# ABSTRACT: Class to model a VMC Cert
our $VERSION = '2.20200930.1'; # VERSION
use 5.20.0;
use Moose;
use Mail::BIMI::Prelude;
use Convert::ASN1;
use Crypt::OpenSSL::X509;
use Crypt::OpenSSL::Verify 0.20;
use File::Slurp qw{ read_file write_file };
use File::Temp;

extends 'Mail::BIMI::Base';
with(
  'Mail::BIMI::Role::Data',
  'Mail::BIMI::Role::HasError',
);
has chain => ( is => 'rw', isa => 'Mail::BIMI::VMC::Chain', required => 1, weak_ref => 1,
  documentation => 'Back reference to the chain' );
has ascii_lines => ( is => 'rw', isa => 'ArrayRef', required => 1,
  documentation => 'inputs: Raw data of the Cert contents', );
has x509_object => ( is => 'rw', isa => 'Maybe[Crypt::OpenSSL::X509]', lazy => 1, builder => '_build_x509_object',
  documentation => 'Crypt::OpenSSL::X509 object for the Certificate' );
has verifier => ( is => 'rw', isa => 'Crypt::OpenSSL::Verify', lazy => 1, builder => '_build_verifier',
  documentation => 'Crypt::OpenSSL::Verify object for the Certificate' );
has is_valid_to_root => ( is => 'rw',
  documentation => 'Could we validate this certificate to the root certs, set by Mail::BIMI::VMC::Chain->is_valid' );
has filename => ( is => 'rw', lazy => 1, builder => '_build_filename',
  documentation => 'Filename of temporary file containing the cert' );
has _delete_file_on_destroy => ( is => 'rw', lazy => 1, default => sub{return 0} );
has is_valid => ( is => 'rw', lazy => 1, builder => '_build_is_valid',
  documentation => 'Is this a valid Cert?' );
has indicator_asn => ( is => 'rw', lazy => 1, builder => '_build_indicator_asn',
  documentation => 'Parsed ASN data for the embedded Indicator' );
has index => ( is => 'rw', required => 1,
  documentation => 'Index of this certificate in the chain' );
has validated_by => ( is => 'rw',
  documentation => 'Root and/or intermediate certificate in the chain used to verify this certificate' );
has validated_by_id => ( is => 'rw',
  documentation => 'Index of cert which validated this cert' );


sub DESTROY {
  my ($self) = @_;
  return unless $self->{_delete_file_on_destroy};
  if ( $self->{filename} && -f $self->{filename} ) {
    unlink $self->{filename} or warn "Unable to unlink temporary cert file: $!";
  }
}

sub _build_is_valid($self) {
  $self->x509_object; # trigger object parse
  return 0 if $self->errors->@*;
  return 1;
}

sub _build_indicator_asn($self) {
  return if !$self->x509_object;
  my $exts = eval{ $self->x509_object->extensions_by_oid() };
  return if !$exts;
  return if !exists $exts->{&LOGOTYPE_OID};
  my $indhex = $exts->{&LOGOTYPE_OID}->value;
  $indhex =~ s/^#//;
  my $indicator = pack("H*",$indhex);
  my $asn = Convert::ASN1->new;
  $asn->prepare_file($self->get_file_name('asn1.txt'));
  my $decoder = $asn->find('LogotypeExtn');
  die $asn->error if $asn->error;
  my $decoded = $decoder->decode($indicator);
  if ( $decoder->error ) {
    $self->add_error('VMC_PARSE_ERROR',$decoder->error);
    return;
  }

  #my $image_details = $decoded->{subjectLogo}->{direct}->{image}->[0]->{imageDetails};
  #my $mime_type = $image_details->{mediaType};
  #my $logo_hash = $image_details->{logotypeHash}->[0];
  return $decoded;
}

sub _build_x509_object($self) {
  my $cert;
  eval{
    $cert = Crypt::OpenSSL::X509->new_from_string(join("\n",$self->ascii_lines->@*));
    1;
  } || do {
    my $error = $@;
    chomp $error;
    $error =~ s/\. at .*$//;
    $self->add_error('VMC_PARSE_ERROR',$error);
    return;
  };
  return $cert;
}

sub _build_verifier($self) {
  return Crypt::OpenSSL::Verify->new($self->filename,{noCApath=>1});
}


sub is_expired($self) {
  return 0 if !$self->x509_object;
  my $seconds = 0;
  if ($self->x509_object->checkend($seconds)) {
    return 1;
  }
  return 0;
}


sub has_valid_usage($self) {
  return if !$self->x509_object;
  my $exts = eval{ $self->x509_object->extensions_by_oid() };
  return if !$exts;
  my $extended_usage = $exts->{'2.5.29.37'};
  return if !$extended_usage;
  my $extended_usage_string = $extended_usage->to_string;
  return 1 if $extended_usage_string eq USAGE_OID;
  return 0;
}


sub full_chain($self) {
  return join("\n",$self->ascii_lines->@*,$self->validated_by);
}

sub _build_filename($self) {
  my $temp_fh = File::Temp->new(UNLINK=>0);
  my $temp_name = $temp_fh->filename;
  close $temp_fh;
  write_file($temp_name,$self->full_chain);
  $self->_delete_file_on_destroy(1);
  return $temp_name;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mail::BIMI::VMC::Cert - Class to model a VMC Cert

=head1 VERSION

version 2.20200930.1

=head1 DESCRIPTION

Class for representing, retrieving, validating, and processing a VMC Certificate

=head1 INPUTS

These values are used as inputs for lookups and verifications, they are typically set by the caller based on values found in the message being processed

=head2 ascii_lines

is=rw required

Raw data of the Cert contents

=head1 ATTRIBUTES

These values are derived from lookups and verifications made based upon the input values, it is however possible to override these with other values should you wish to, for example, validate a record before it is published in DNS, or validate an Indicator which is only available locally

=head2 chain

is=rw required

Back reference to the chain

=head2 errors

is=rw

=head2 filename

is=rw

Filename of temporary file containing the cert

=head2 index

is=rw required

Index of this certificate in the chain

=head2 indicator_asn

is=rw

Parsed ASN data for the embedded Indicator

=head2 is_valid

is=rw

Is this a valid Cert?

=head2 is_valid_to_root

is=rw

Could we validate this certificate to the root certs, set by Mail::BIMI::VMC::Chain->is_valid

=head2 validated_by

is=rw

Root and/or intermediate certificate in the chain used to verify this certificate

=head2 validated_by_id

is=rw

Index of cert which validated this cert

=head2 verifier

is=rw

Crypt::OpenSSL::Verify object for the Certificate

=head2 x509_object

is=rw

Crypt::OpenSSL::X509 object for the Certificate

=head1 CONSUMES

=over 4

=item * L<Mail::BIMI::Role::Data>

=item * L<Mail::BIMI::Role::Data|Mail::BIMI::Role::HasError>

=item * L<Mail::BIMI::Role::HasError>

=back

=head1 EXTENDS

=over 4

=item * L<Mail::BIMI::Base>

=back

=head1 METHODS

=head2 I<is_expired()>

Return true if this cert has expired

=head2 I<has_valid_usage()>

Return true if this VMC has a valid usage extension for BIMI

=head2 I<full_chain()>

The full chain of this certificate as verified to root

=head1 REQUIRES

=over 4

=item * L<Convert::ASN1|Convert::ASN1>

=item * L<Crypt::OpenSSL::Verify|Crypt::OpenSSL::Verify>

=item * L<Crypt::OpenSSL::X509|Crypt::OpenSSL::X509>

=item * L<File::Slurp|File::Slurp>

=item * L<File::Temp|File::Temp>

=item * L<Mail::BIMI::Prelude|Mail::BIMI::Prelude>

=item * L<Moose|Moose>

=back

=head1 AUTHOR

Marc Bradshaw <marc@marcbradshaw.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Marc Bradshaw.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
