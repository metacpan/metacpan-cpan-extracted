package Mail::BIMI::VMC::Chain;
# ABSTRACT: Class to model a VMC Chain
our $VERSION = '2.20200930.1'; # VERSION
use 5.20.0;
use Moose;
use Mail::BIMI::Prelude;
use Mail::BIMI::VMC::Cert;
use Crypt::OpenSSL::X509;
use Crypt::OpenSSL::Verify 0.20;
use File::Slurp qw{ read_file write_file };
use File::Temp;
use Mozilla::CA;
use Term::ANSIColor qw{ :constants };

extends 'Mail::BIMI::Base';
with(
  'Mail::BIMI::Role::Data',
  'Mail::BIMI::Role::HasError',
);
has cert_list => ( is => 'rw', isa => 'ArrayRef',
  documentation => 'ArrayRef of individual Certificates in the chain' );
has cert_object_list => ( is => 'rw', isa => 'ArrayRef', lazy => 1, builder => '_build_cert_object_list',
  documentation => 'ArrayRef of Crypt::OpenSSL::X509 objects for the Certificates in the chain' );
has is_valid => ( is => 'rw', lazy => 1, builder => '_build_is_valid',
  documentation => 'Does the VMC of this chain validate back to root?' );


sub _build_is_valid($self) {
  # Start with root cert validations
  return 0 if !$self->vmc;

  my $ssl_root_cert = $self->bimi_object->options->ssl_root_cert;
  my $unlink_root_cert_file = 0;
  if ( !$ssl_root_cert ) {
    my $mozilla_root = scalar read_file Mozilla::CA::SSL_ca_file;
    my $bimi_root = $self->get_data_from_file('CA.pem');
    my $temp_fh = File::Temp->new(UNLINK=>0);
    $ssl_root_cert = $temp_fh->filename;
    $unlink_root_cert_file = 1;
    print $temp_fh join("\n",$mozilla_root,$bimi_root);
    close $temp_fh;
  }

  my $root_ca = Crypt::OpenSSL::Verify->new($ssl_root_cert,{noCApath=>0});
  my $root_ca_ascii = scalar read_file $ssl_root_cert;
  foreach my $cert ( $self->cert_object_list->@* ) {
    my $i = $cert->index;
    if ($cert->is_expired) {
      $self->log_verbose("Certificate $i is expired");
      next;
    }
    if ( !$cert->is_valid ) {
      $self->log_verbose("Certificate $i is not valid");
      next;
    }
    my $is_valid = 0;
    eval {
      $root_ca->verify($cert->x509_object);
      $is_valid = 1;
    };
    if ( !$is_valid ) {
      $self->log_verbose("Certificate $i not directly validated to root");
      # NOP
    }
    else {
      $self->log_verbose("Certificate $i directly validated to root");
      $cert->validated_by($root_ca_ascii);
      $cert->validated_by_id(0);
      $cert->is_valid_to_root(1);
    }
  }

  my $iteration_did_no_work;
  do {
    $iteration_did_no_work = 1;
    VALIDATED_CERT:
    foreach my $validated_cert ( $self->cert_object_list->@* ) {
      next VALIDATED_CERT if ! $validated_cert->is_valid_to_root;
      my $validated_i = $validated_cert->index;
      VALIDATING_CERT:
      foreach my $validating_cert ( $self->cert_object_list->@* ) {
        next VALIDATING_CERT if $validating_cert->is_valid_to_root;
        my $validating_i = $validating_cert->index;
        if ($validating_cert->is_expired) {
          $self->log_verbose("Certificate $validating_i is expired");
          next;
        }
        if ( !$validating_cert->is_valid ) {
          $self->log_verbose("Certificate $validating_i is not valid");
          next VALIDATING_CERT;
        }
        eval{
          $validated_cert->verifier->verify($validating_cert->x509_object);
          $self->log_verbose("Certificate $validating_i validated to root via certificate $validated_i");
          $validating_cert->validated_by($validated_cert->full_chain);
          $validating_cert->validated_by_id($validated_i);
          $validating_cert->is_valid_to_root(1);
          $iteration_did_no_work = 0;
        };
      }
    }
  } until $iteration_did_no_work;
  if ( !$self->vmc->is_valid_to_root ) {
    $self->add_error('VMC_PARSE_ERROR','Could not verify VMC');
  }

  if ( $unlink_root_cert_file && -f $ssl_root_cert ) {
    unlink $ssl_root_cert or warn "Unable to unlink temporary chain file: $!";
  }

  return 0 if $self->errors->@*;
  return 1;
}


sub vmc($self) {
  my $vmc;
  foreach my $cert ( $self->cert_object_list->@* ) {
    my $x509_object = $cert->x509_object;
    next if !$x509_object;
    my $exts = eval{ $x509_object->extensions_by_oid() };
    next if !$exts;
    if ( $cert->has_valid_usage && exists $exts->{&LOGOTYPE_OID}) {
      # Has both extended usage and embedded Indicator
      $self->add_error('VMC_VALIDATION_ERROR','Multiple VMCs found in chain') if $vmc;
      $vmc = $cert;
    }
  }
  if ( !$vmc ) {
    $self->add_error('VMC_VALIDATION_ERROR','No valid VMC found in chain');
  }
  return $vmc;
}

sub _build_cert_object_list($self) {
  my @objects;
  my $i = 1;
  foreach my $cert ( $self->cert_list->@* ) {
    push @objects, Mail::BIMI::VMC::Cert->new(
      bimi_object => $self->bimi_object,
      chain => $self,
      ascii_lines => $cert,
      index => $i++,
    );
  }
  return \@objects;
}


sub app_validate($self) {
  say 'Certificate Chain Returned: '.($self->is_valid ? GREEN."\x{2713}" : BRIGHT_RED."\x{26A0}").RESET;
  foreach my $cert ( $self->cert_object_list->@* ) {
    my $i = $cert->index;
    my $obj = $cert->x509_object;
    say '';
    say YELLOW.'  Certificate '.$i.WHITE.': '.($cert->is_valid ? GREEN."\x{2713}" : BRIGHT_RED."\x{26A0}").RESET;
    if ( $obj ) {
      say YELLOW.'  Subject          '.WHITE.': '.CYAN.($obj->subject//'-none-').RESET;
      say YELLOW.'  Not Before       '.WHITE.': '.CYAN.($obj->notBefore//'-none-').RESET;
      say YELLOW.'  Not After        '.WHITE.': '.CYAN.($obj->notAfter//'-none-').RESET;
      say YELLOW.'  Issuer           '.WHITE.': '.CYAN.($obj->issuer//'-none-').RESET;
      say YELLOW.'  Expired          '.WHITE.': '.($obj->checkend(0)?BRIGHT_RED.'Yes':GREEN.'No').RESET;
      my $exts = eval{ $obj->extensions_by_oid() };
      if ( $exts ) {
        my $alt_name = exists $exts->{'2.5.29.17'} ? $exts->{'2.5.29.17'}->to_string : '-none-';
        say YELLOW.'  Alt Name         '.WHITE.': '.CYAN.($alt_name//'-none-').RESET;
        say YELLOW.'  Has LogotypeExtn '.WHITE.': '.CYAN.(exists($exts->{&LOGOTYPE_OID})?GREEN.'Yes':BRIGHT_RED.'No').RESET;
      }
      else {
        say YELLOW.'  Extensions       '.WHITE.': '.BRIGHT_RED.'NOT FOUND'.RESET;
      }
      say YELLOW.'  Has Valid Usage  '.WHITE.': '.CYAN.($cert->has_valid_usage?GREEN.'Yes':BRIGHT_RED.'No').RESET;
    }
    say YELLOW.'  Valid to Root    '.WHITE.': '.CYAN.($cert->is_valid_to_root?GREEN.($cert->validated_by_id == 0?'Direct':'Via cert '.$cert->validated_by_id):BRIGHT_RED.'No').RESET;
    say YELLOW.'  Is Valid         '.WHITE.': '.CYAN.($cert->is_valid?GREEN.'Yes':BRIGHT_RED.'No').RESET;
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mail::BIMI::VMC::Chain - Class to model a VMC Chain

=head1 VERSION

version 2.20200930.1

=head1 DESCRIPTION

Class for representing, retrieving, validating, and processing a VMC Certificate Chain

=head1 ATTRIBUTES

These values are derived from lookups and verifications made based upon the input values, it is however possible to override these with other values should you wish to, for example, validate a record before it is published in DNS, or validate an Indicator which is only available locally

=head2 cert_list

is=rw

ArrayRef of individual Certificates in the chain

=head2 cert_object_list

is=rw

ArrayRef of Crypt::OpenSSL::X509 objects for the Certificates in the chain

=head2 errors

is=rw

=head2 is_valid

is=rw

Does the VMC of this chain validate back to root?

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

=head2 I<vmc()>

Locate and return the VMC object from this chain.

=head2 I<app_validate()>

Output human readable validation status of this object

=head1 REQUIRES

=over 4

=item * L<Crypt::OpenSSL::Verify|Crypt::OpenSSL::Verify>

=item * L<Crypt::OpenSSL::X509|Crypt::OpenSSL::X509>

=item * L<File::Slurp|File::Slurp>

=item * L<File::Temp|File::Temp>

=item * L<Mail::BIMI::Prelude|Mail::BIMI::Prelude>

=item * L<Mail::BIMI::VMC::Cert|Mail::BIMI::VMC::Cert>

=item * L<Moose|Moose>

=item * L<Mozilla::CA|Mozilla::CA>

=item * L<Term::ANSIColor|Term::ANSIColor>

=back

=head1 AUTHOR

Marc Bradshaw <marc@marcbradshaw.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Marc Bradshaw.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
