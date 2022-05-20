package Mail::DKIM::ARC::Verifier;
use strict;
use warnings;
our $VERSION = '1.20220520'; # VERSION
# ABSTRACT: verifies an ARC-Sealed message

# Copyright 2017 FastMail Pty Ltd.  All Rights Reserved.
# Bron Gondwana <brong@fastmailteam.com>

# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.



use base 'Mail::DKIM::Common';
use Mail::DKIM::ARC::MessageSignature;
use Mail::DKIM::ARC::Seal;
use Mail::Address;
use Carp;
our $MAX_SIGNATURES_TO_PROCESS = 50;

sub init {
    my $self = shift;
    $self->SUPER::init;
    $self->{signatures} = [];
    $self->{result}     = undef;    # we're done once this is set
}

# @{$arc->{signatures}}
#   array of L<Mail::DKIM::ARC::{Signature|Seal}> objects, representing all
#   parseable message signatures and seals found in the header,
#   ordered from the top of the header to the bottom.
#
# $arc->{signature_reject_reason}
#   simple string listing a reason, if any, for not using a signature.
#   This may be a helpful diagnostic if there is a signature in the header,
#   but was found not to be valid. It will be ambiguous if there are more
#   than one signatures that could not be used.
#
# @{$arc->{headers}}
#   array of strings, each member is one header, in its original format.
#
# $arc->{algorithms}
#   array of algorithms, one for each signature being verified.
#
# $arc->{result}
#   string; the result of the verification (see the result() method)
#

sub handle_header {
    my $self = shift;
    my ( $field_name, $contents, $line ) = @_;

    $self->SUPER::handle_header( $field_name, $contents );

    if ( lc($field_name) eq 'arc-message-signature' ) {
        eval {
            local $SIG{__DIE__};
            my $signature = Mail::DKIM::ARC::MessageSignature->parse($line);
            $self->add_signature($signature);
	    1
        } || do {

            # the only reason an error should be thrown is if the
            # signature really is unparse-able

            # otherwise, invalid signatures are caught in finish_header()

            chomp( my $E = $@ );
            $self->{signature_reject_reason} = $E;
        };
    }

    if ( lc($field_name) eq 'arc-seal' ) {
        eval {
            local $SIG{__DIE__};
            my $signature = Mail::DKIM::ARC::Seal->parse($line);
            $self->add_signature($signature);
	    1
        } || do {

            # the only reason an error should be thrown is if the
            # signature really is unparse-able

            # otherwise, invalid signatures are caught in finish_header()

            chomp( my $E = $@ );
            $self->{signature_reject_reason} = $E;
        };
    }

}

sub add_signature {
    my ( $self, $signature ) = @_;
    croak 'wrong number of arguments' unless ( @_ == 2 );

    return if $self->{result};    # already failed

    push @{ $self->{signatures} }, $signature;

    unless ( $self->check_signature($signature) ) {
        $signature->result( 'invalid', $self->{signature_reject_reason} );
        return;
    }

    # signature looks ok, go ahead and query for the public key
    $signature->fetch_public_key;

    # create a canonicalization filter and algorithm
    my $algorithm_class =
      $signature->get_algorithm_class( $signature->algorithm );
    my $algorithm = $algorithm_class->new(
        Signature              => $signature,
        Debug_Canonicalization => $signature->isa('Mail::DKIM::ARC::Seal')
        ? $self->{AS_Canonicalization}
        : $self->{AMS_Canonicalization},
    );

    # push through the headers parsed prior to the signature header
    if ( $algorithm->wants_pre_signature_headers ) {

        # Note: this will include the signature header that led to this
        # "algorithm"...
        foreach my $head ( @{ $self->{headers} } ) {
            $algorithm->add_header($head);
        }
    }

    # save the algorithm
    $self->{algorithms} ||= [];
    push @{ $self->{algorithms} }, $algorithm;

 # check for bogus tags (should be done much earlier but better late than never)
 # tagkeys is uniq'd via a hash, rawtaglen counts all the tags
    my @tagkeys   = keys %{ $signature->{tags_by_name} };
    my $rawtaglen = $#{ $signature->{tags} };

    # crock: ignore empty clause after trailing semicolon
    $rawtaglen--
      if $signature->{tags}->[ $#{ $signature->{tags} } ]->{raw} =~ /^\s*$/;

    # duplicate tags
    if ( $rawtaglen != $#tagkeys ) {
        $self->{result}  = 'fail';                         # bogus
        $self->{details} = 'Duplicate tag in signature';
        return;
    }

    # invalid tag name
    if ( grep { !m{[a-z][a-z0-9_]*}i } @tagkeys ) {
        $self->{result}  = 'fail';                         # bogus
        $self->{details} = 'Invalid tag in signature';
        return;
    }

    if ( $signature->isa('Mail::DKIM::ARC::Seal') ) {
        my ($instance);
        $instance = $signature->instance() || '';

        if ( $instance !~ m{^\d+$} or $instance < 1 or $instance > 1024 ) {
            $self->{result}  = 'fail';                                   # bogus
            $self->{details} = sprintf "Invalid ARC-Seal instance '%s'",
              $instance;
            return;
        }

        if ( $self->{seals}[$instance] ) {
            $self->{result} = 'fail';                                    # dup
            if ( $signature eq $self->{seals}[$instance] ) {
                $self->{details} = sprintf 'Duplicate ARC-Seal %d', $instance;
            }
            else {
                $self->{details} = sprintf 'Redundant ARC-Seal %d', $instance;
            }
            return;
        }

        $self->{seals}[$instance] = $signature;
    }
    elsif ( $signature->isa('Mail::DKIM::ARC::MessageSignature') ) {
        my $instance = $signature->instance() || '';

        if ( $instance !~ m{^\d+$} or $instance < 1 or $instance > 1024 ) {
            $self->{result} = 'fail';    # bogus
            $self->{details} =
              sprintf "Invalid ARC-Message-Signature instance '%s'", $instance;
            return;
        }

        if ( $self->{messages}[$instance] ) {
            $self->{result} = 'fail';    # dup
            if ( $signature->as_string() eq
                $self->{messages}[$instance]->as_string() )
            {
                $self->{details} = sprintf 'Duplicate ARC-Message-Signature %d',
                  $instance;
            }
            else {
                $self->{details} = sprintf 'Redundant ARC-Message-Signature %d',
                  $instance;
            }
            return;
        }
        $self->{messages}[$instance] = $signature;
    }
}

sub check_signature {
    my $self = shift;
    croak 'wrong number of arguments' unless ( @_ == 1 );
    my ($signature) = @_;

    unless ( $signature->check_version ) {

        # unsupported version
        if ( defined $signature->version ) {
            $self->{signature_reject_reason} =
              'unsupported version ' . $signature->version;
        }
        else {
            $self->{signature_reject_reason} = 'missing v tag';
        }
        return 0;
    }

    unless ( $signature->algorithm
        && $signature->get_algorithm_class( $signature->algorithm )
        && ( !$self->{Strict} || $signature->algorithm ne 'rsa-sha1' )
      )    # no more SHA1 for us in strict mode
    {
        # unsupported algorithm
        $self->{signature_reject_reason} = 'unsupported algorithm';
        if ( defined $signature->algorithm ) {
            $self->{signature_reject_reason} .= ' ' . $signature->algorithm;
        }
        return 0;
    }

    unless ( $signature->check_canonicalization ) {

        # unsupported canonicalization method
        $self->{signature_reject_reason} = 'unsupported canonicalization';
        if ( defined $signature->canonicalization ) {
            $self->{signature_reject_reason} .=
              ' ' . $signature->canonicalization;
        }
        return 0;
    }

    unless ( $signature->check_protocol ) {

        # unsupported query protocol
        $self->{signature_reject_reason} =
          !defined( $signature->protocol )
          ? 'missing q tag'
          : 'unsupported query protocol, q=' . $signature->protocol;
        return 0;
    }

    unless ( $signature->check_expiration ) {

        # signature has expired
        $self->{signature_reject_reason} = 'signature is expired';
        return 0;
    }

    unless ( defined $signature->domain ) {

        # no domain specified
        $self->{signature_reject_reason} = 'missing d tag';
        return 0;
    }

    if ( $signature->domain eq '' ) {

        # blank domain
        $self->{signature_reject_reason} = 'invalid domain in d tag';
        return 0;
    }

    unless ( defined $signature->selector ) {

        # no selector specified
        $self->{signature_reject_reason} = 'missing s tag';
        return 0;
    }

    return 1;
}

sub check_public_key {
    my $self = shift;
    croak 'wrong number of arguments' unless ( @_ == 2 );
    my ( $signature, $public_key ) = @_;

    my $result = 0;
    eval {
        local $SIG{__DIE__};
        $@ = undef;

        # HACK- I'm indecisive here about whether I want the
        # check_foo functions to return false or to "die"
        # on failure

        # check public key's allowed hash algorithms
        $result =
          $public_key->check_hash_algorithm( $signature->hash_algorithm );

# HACK- DomainKeys signatures are allowed to have an empty g=
# tag in the public key
#        my $empty_g_means_wildcard = $signature->isa('Mail::DKIM::DkSignature');

        # check public key's granularity
        $result &&= $public_key->check_granularity( $signature->domain, 0 );

        #                $signature->instance, $empty_g_means_wildcard);

        die $@ if $@;
	1
    } || do {
        my $E = $@;
        chomp $E;
        $self->{signature_reject_reason} = "public key: $E";
    };
    return $result;
}

#
# called when the verifier has received the last of the message headers
# (body is still to come)
#
sub finish_header {
    my $self = shift;

    # Signatures we found and were successfully parsed are stored in
    # $self->{signatures}. If none were found, our result is "none".

    if ( @{ $self->{signatures} } == 0
        && !defined( $self->{signature_reject_reason} ) )
    {
        $self->{result} = 'none';
        return;
    }

    # check for duplicate AAR headers (dup AS and AMS checked in add_signature)
    my @aars = [];
    foreach my $hdr ( @{ $self->{headers} } ) {
        if ( my ($i) = $hdr =~ m{ARC-Authentication-Results:\s*i=(\d+)\s*;}i ) {
            if ( defined $aars[$i] ) {
                $self->{result} = 'fail';
                $self->{details} =
                  "Duplicate ARC-Authentication-Results header $1";
                return;
            }
            $aars[$i] = $hdr;
        }
    }

    foreach my $algorithm ( @{ $self->{algorithms} } ) {
        $algorithm->finish_header(
            Headers => $self->{headers},
            Chain   => 'pass'
        );
    }

    # stop processing signatures that are already known to be invalid
    @{ $self->{algorithms} } = grep {
        my $sig = $_->signature;
        !( $sig->result && $sig->result eq 'invalid' );
    } @{ $self->{algorithms} };

    if (   @{ $self->{algorithms} } == 0
        && @{ $self->{signatures} } > 0 )
    {
        $self->{result} = $self->{signatures}->[0]->result || 'invalid';
        $self->{details} = $self->{signatures}->[0]->{verify_details}
          || $self->{signature_reject_reason};
        return;
    }
}

sub _check_and_verify_signature {
    my $self = shift;
    my ($algorithm) = @_;

    # check signature
    my $signature = $algorithm->signature;

    if ( not $signature->get_tag('d') ) {    # All sigs must have a D tag
        $self->{signature_reject_reason} = 'missing D tag';
        return ( 'fail', $self->{signature_reject_reason} );
    }

    if ( not $signature->get_tag('b') ) {    # All sigs must have a B tag
        $self->{signature_reject_reason} = 'missing B tag';
        return ( 'fail', $self->{signature_reject_reason} );
    }

    if ( not $signature->isa('Mail::DKIM::ARC::Seal') ) {    # AMS tests
        unless ( $signature->get_tag('bh') ) {    # AMS must have a BH tag
            $self->{signature_reject_reason} = 'missing BH tag';
            return ( 'fail', $self->{signature_reject_reason} );
        }
        if ( ( $signature->get_tag('h') || '' ) =~ /arc-seal/i )
        {                                         # cannot cover AS
            $self->{signature_reject_reason} =
              'Arc-Message-Signature covers Arc-Seal';
            return ( 'fail', $self->{signature_reject_reason} );
        }
    }

    # AMS signature must not

    # get public key
    my $pkey;
    eval {
        local $SIG{__DIE__};
        $pkey = $signature->get_public_key;
	1
    } || do  {
        my $E = $@;
        chomp $E;
        $self->{signature_reject_reason} = "public key: $E";
        return ( 'invalid', $self->{signature_reject_reason} );
    };

    unless ( $self->check_public_key( $signature, $pkey ) ) {
        return ( 'invalid', $self->{signature_reject_reason} );
    }

    # make sure key is big enough
    my $keysize = $pkey->cork->size * 8;    # in bits
    if ( $keysize < 1024 && $self->{Strict} ) {
        $self->{signature_reject_reason} = "Key length $keysize too short";
        return ( 'fail', $self->{signature_reject_reason} );
    }

    # verify signature
    my $result;
    my $details;
    local $@ = undef;
    eval {
        local $SIG{__DIE__};
        $result = $algorithm->verify() ? 'pass' : 'fail';
        $details = $algorithm->{verification_details} || $@;
	1
    } || do {

        # see also add_signature
        chomp( my $E = $@ );
        if ( $E =~ /(OpenSSL error: .*?) at / ) {
            $E = $1;
        }
        elsif ( $E =~ /^(panic:.*?) at / ) {
            $E = "OpenSSL $1";
        }
        $result  = 'fail';
        $details = $E;
    };
    return ( $result, $details );
}

sub finish_body {
    my $self = shift;

    return if $self->{result};    # already failed

    foreach my $algorithm ( @{ $self->{algorithms} } ) {

        # finish canonicalizing
        $algorithm->finish_body;

        my ( $result, $details ) =
          $self->_check_and_verify_signature($algorithm);

        # save the results of this signature verification
        $algorithm->{result}  = $result;
        $algorithm->{details} = $details;
        $self->{signature} ||= $algorithm->signature;    # something if we fail
        $algorithm->signature->result( $result, $details );
    }

    my $seals    = $self->{seals}    || [];
    my $messages = $self->{messages} || [];
    unless ( @$seals or @$messages ) {
        $self->{result}  = 'none';
        $self->{details} = 'no ARC headers found';
        return;
    }

    # determine if it's valid:
    # 5.1.1.5.  Determining the 'cv' Tag Value for ARC-Seal

    #    In order for a series of ARC sets to be considered valid, the
    #    following statements MUST be satisfied:

    #    1.  The chain of ARC sets must have structural integrity (no sets or
    #        set component header fields missing, no duplicates, excessive
    #        hops (cf.  Section 5.1.1.1.1), etc.);

    if ( $#$seals == 0 ) {
        $self->{result}  = 'fail';
        $self->{details} = 'missing ARC-Seal 1';
        return;
    }
    if ( $#$messages == 0 ) {
        $self->{result}  = 'fail';
        $self->{details} = 'missing ARC-Message-Signature 1';
        return;
    }

    if ( $#$messages > $#$seals ) {
        $self->{result}  = 'fail';
        $self->{details} = 'missing Arc-Seal ' . $#$messages;
        return;
    }

    foreach my $i ( 1 .. $#$seals ) {

# XXX - we should error if it's already present, but that's done above if at all
        if ( !$seals->[$i] ) {
            $self->{result}  = 'fail';
            $self->{details} = "missing ARC-Seal $i";
            return;
        }
        if ( !$messages->[$i] ) {
            $self->{result}  = 'fail';
            $self->{details} = "missing ARC-Message-Signature $i";
            return;
        }
    }

    # 2. All ARC-Seal header fields MUST validate;
    foreach my $i ( 1 .. $#$seals ) {
        my $result = $seals->[$i]->result();
        if ( $result ne 'pass' ) {
            $self->{signature} = $seals->[$i]->signature;
            $self->{result}    = $result;
            $self->{details}   = $seals->[$i]->result_detail();
            return;
        }
    }

    #    3.  All ARC-Seal header fields MUST have a chain value (cv=) status
    #        of "pass" (except the first which MUST be "none"); and
    my $cv = $seals->[1]->get_tag('cv');
    if ( !defined $cv or $cv ne 'none' ) {
        $self->{signature} = $seals->[1]->signature;
        $self->{result}    = 'fail';
        $self->{details}   = 'first ARC-Seal must be cv=none';
        return;
    }
    foreach my $i ( 2 .. $#$seals ) {
        my $cv = $seals->[$i]->get_tag('cv');
        if ( $cv ne 'pass' ) {
            $self->{signature} = $seals->[$i]->signature;
            $self->{result}    = 'fail';
            $self->{details}   = "wrong cv for ARC-Seal i=$i";
            return;
        }
    }

    #    4.  The newest (highest instance number (i=)) AMS header field MUST
    #        validate.
    my $result = $messages->[$#$seals]->result();
    if ( $result ne 'pass' ) {
        $self->{signature} = $messages->[$#$seals]->signature;
        $self->{result}    = $result;
        $self->{details}   = $messages->[$#$seals]->result_detail();
        return;
    }

    # Success!
    $self->{signature} = $seals->[$#$seals]->signature();
    $self->{result}    = 'pass';
    $self->{details}   = $seals->[$#$seals]->result_detail();
}

sub result_detail {
    my $self = shift;

    return 'none' if $self->{result} eq 'none';

    my @items;
    foreach my $signature ( @{ $self->{signatures} } ) {
        my $type =
            ref($signature) eq 'Mail::DKIM::ARC::Seal'             ? 'as'
          : ref($signature) eq 'Mail::DKIM::ARC::MessageSignature' ? 'ams'
          :   ref($signature);
        push @items,
            "$type."
          . ( $signature->instance()      || '' ) . '.'
          . ( $signature->domain()        || '(none)' ) . '='
          . ( $signature->result_detail() || '?' );
    }

    return $self->{result} . ' (' . join( ', ', @items ) . ')';
}



sub signatures {
    my $self = shift;
    croak 'unexpected argument' if @_;

    return @{ $self->{signatures} };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mail::DKIM::ARC::Verifier - verifies an ARC-Sealed message

=head1 VERSION

version 1.20220520

=head1 SYNOPSIS

  use Mail::DKIM::ARC::Verifier;

  # create a verifier object
  my $arc = Mail::DKIM::ARC::Verifier->new();

  # read an email from a file handle
  $arc->load(*STDIN);

  # or read an email and pass it into the verifier, incrementally
  while (<STDIN>)
  {
      # remove local line terminators
      chomp;
      s/\015$//;

      # use SMTP line terminators
      $arc->PRINT("$_\015\012");
  }
  $arc->CLOSE;

  # what is the result of the verify?
  my $result = $arc->result;

  # print the results for all the message-signatures and seals on the message
  foreach my $signature ($arc->signatures)
  {
      print $signature->prefix() . ' v=' . $signature->instance .
                                     ' ' . $signature->result_detail . "\n";
  }

  # example output.  Note that to pass, only the MOST RECENT ARC-Message-Signature
  # must match, because other steps may have modified the signature.  What matters
  # is that all ARC-Seals pass, and the most recent ARC-Message-Signature passes.

=head1 DESCRIPTION

The verifier object allows an email message to be scanned for ARC
seals and their associated signatures to be verified. The verifier
tracks the state of the message as it is read into memory. When the
message has been completely read, the signatures are verified and the
results of the verification can be accessed.

To use the verifier, first create the verifier object. Then start
"feeding" it the email message to be verified. When all the _headers_
have been read, the verifier:

 1. checks whether any ARC signatures were found
 2. queries for the public keys needed to verify the signatures
 3. sets up the appropriate algorithms and canonicalization objects
 4. canonicalizes the headers and computes the header hash

Then, when the _body_ of the message has been completely fed into the
verifier, the body hash is computed and the signatures are verified.

The results of the verification can be checked with L</"result()">
or L</"signatures()">.

The final result is calculated by the algorithm layed out in
https://tools.ietf.org/html/draft-ietf-dmarc-arc-protocol-06 -
if ALL ARC-Seal headers pass and the highest index (i=)
ARC-Message-Signature passes, then the seal is intact.

=head1 CONSTRUCTOR

=head2 new()

Constructs an object-oriented verifier.

  my $arc = Mail::DKIM::ARC::Verifier->new();

  my $arc = Mail::DKIM::ARC::Verifier->new(%options);

The only options supported at this time are:

=over

=item AS_Canonicalization

if specified, the canonicalized message for the ARC-Seal
is written to the referenced string or file handle.

=item AMA_Canonicalization

if specified, the canonicalized message for the ARC-Message-Signature
is written to the referenced string or file handle.

=item Strict

If true, rejects sha1 hashes and signing keys shorter than 1024 bits.

=back

=head1 METHODS

=head2 PRINT()

Feeds part of the message to the verifier.

  $arc->PRINT("a line of the message\015\012");
  $arc->PRINT('more of');
  $arc->PRINT(" the message\015\012bye\015\012");

Feeds content of the message being verified into the verifier.
The API is designed this way so that the entire message does NOT need
to be read into memory at once.

Please note that although the PRINT() method expects you to use
SMTP-style line termination characters, you should NOT use the
SMTP-style dot-stuffing technique described in RFC 2821 section 4.5.2.
Nor should you use a <CR><LF>.<CR><LF> sequence to terminate the
message.

=head2 CLOSE()

Call this when finished feeding in the message.

  $arc->CLOSE;

This method finishes the canonicalization process, computes a hash,
and verifies the signature.

=head2 load()

Load the entire message from a file handle.

  $arc->load($file_handle);

Reads a complete message from the designated file handle,
feeding it into the verifier. The message must use <CRLF> line
terminators (same as the SMTP protocol).

=head2 message_originator()

Access the "From" header.

  my $address = $arc->message_originator;

Returns the "originator address" found in the message, as a
L<Mail::Address> object.
This is typically the (first) name and email address found in the
From: header. If there is no From: header,
then an empty L<Mail::Address> object is returned.

To get just the email address part, do:

  my $email = $arc->message_originator->address;

See also L</"message_sender()">.

=head2 message_sender()

Access the "From" or "Sender" header.

  my $address = $arc->message_sender;

Returns the "sender" found in the message, as a L<Mail::Address> object.
This is typically the (first) name and email address found in the
Sender: header. If there is no Sender: header, it is the first name and
email address in the From: header. If neither header is present,
then an empty L<Mail::Address> object is returned.

To get just the email address part, do:

  my $email = $arc->message_sender->address;

The "sender" is the mailbox of the agent responsible for the actual
transmission of the message. For example, if a secretary were to send a
message for another person, the "sender" would be the secretary and
the "originator" would be the actual author.

=head2 result()

Access the result of the verification.

  my $result = $arc->result;

Gives the result of the verification. The following values are possible:

=over

=item pass

Returned if a valid ARC chain was found, with all the ARC-Seals passing,
and the most recent (highest index) ARC-Message-Signature passing.

=item fail

Returned if any ARC-Seal failed, or if the ARC-Message-Signature failed.
Will also be a fail if there is a DNS temporary failure, which is a
known flaw in this version of the ARC::Verifier.  Future versions may
reject this message outright (4xx) and ask the sender to attempt
delivery later to avoid creating a broken chain.  There is no temperror
for ARC, as it doesn't make sense to sign a chain with temperror in it
or every spammer would just use one of those.

=item invalid

Returned if a ARC-Seal could not be checked because of a problem
in the signature itself or the public key record. I.e. the signature
could not be processed.

=item none

Returned if no ARC-* headers were found.

=back

=head2 result_detail()

Access the result, plus details if available.

  my $detail = $dkim->result_detail;

The detail is constructed by taking the result (e.g. "pass", "fail",
"invalid" or "none") and appending any details provided by the verification
process for the topmost ARC-Seal in parenthesis.

The following are possible results from the result_detail() method:

  pass
  fail (bad RSA signature)
  fail (OpenSSL error: ...)
  fail (message has been altered)
  fail (body has been altered)
  invalid (bad instance)
  invalid (invalid domain in d tag)
  invalid (missing q tag)
  invalid (missing d tag)
  invalid (missing s tag)
  invalid (unsupported version 0.1)
  invalid (unsupported algorithm ...)
  invalid (unsupported canonicalization ...)
  invalid (unsupported query protocol ...)
  invalid (signature is expired)
  invalid (public key: not available)
  invalid (public key: unknown query type ...)
  invalid (public key: syntax error)
  invalid (public key: unsupported version)
  invalid (public key: unsupported key type)
  invalid (public key: missing p= tag)
  invalid (public key: invalid data)
  invalid (public key: does not support email)
  invalid (public key: does not support hash algorithm 'sha1')
  invalid (public key: does not support signing subdomains)
  invalid (public key: revoked)
  invalid (public key: granularity mismatch)
  invalid (public key: granularity is empty)
  invalid (public key: OpenSSL error: ...)
  none

=head2 signatures()

Access all of this message's signatures.

  my @all_signatures = $arc->signatures;

Use $signature->result or $signature->result_detail to access
the verification results of each signature.

Use $signature->instance and $signature->prefix to find the
instance and header-name for each signature.

=head1 AUTHORS

=over 4

=item *

Jason Long <jason@long.name>

=item *

Marc Bradshaw <marc@marcbradshaw.net>

=item *

Bron Gondwana <brong@fastmailteam.com> (ARC)

=back

=head1 THANKS

Work on ensuring that this module passes the ARC test suite was
generously sponsored by Valimail (https://www.valimail.com/)

=head1 COPYRIGHT AND LICENSE

=over 4

=item *

Copyright (C) 2013 by Messiah College

=item *

Copyright (C) 2010 by Jason Long

=item *

Copyright (C) 2017 by Standcore LLC

=item *

Copyright (C) 2020 by FastMail Pty Ltd

=back

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
