package Mail::DKIM::Verifier;
use strict;
use warnings;
our $VERSION = '1.20220520'; # VERSION
# ABSTRACT: verifies a DKIM-signed message

# Copyright 2005-2009 Messiah College. All rights reserved.
# Jason Long <jlong@messiah.edu>

# Copyright (c) 2004 Anthony D. Urso. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

use Mail::DKIM::Signature;
use Mail::DKIM::DkSignature;
use Mail::Address;



use base 'Mail::DKIM::Common';
use Carp;
our $MAX_SIGNATURES_TO_PROCESS = 50;

sub init {
    my $self = shift;
    $self->SUPER::init;
    $self->{signatures} = [];
}

# @{$dkim->{signatures}}
#   array of L<Mail::DKIM::Signature> objects, representing all
#   parseable signatures found in the header,
#   ordered from the top of the header to the bottom.
#
# $dkim->{signature_reject_reason}
#   simple string listing a reason, if any, for not using a signature.
#   This may be a helpful diagnostic if there is a signature in the header,
#   but was found not to be valid. It will be ambiguous if there are more
#   than one signatures that could not be used.
#
# $dkim->{signature}
#   the L<Mail::DKIM::Signature> selected as the "best" signature.
#
# @{$dkim->{headers}}
#   array of strings, each member is one header, in its original format.
#
# $dkim->{algorithms}
#   array of algorithms, one for each signature being verified.
#
# $dkim->{result}
#   string; the result of the verification (see the result() method)
#

sub handle_header {
    my $self = shift;
    my ( $field_name, $contents, $line ) = @_;

    $self->SUPER::handle_header( $field_name, $contents );

    if ( lc($field_name) eq 'dkim-signature' ) {
        eval {
            local $SIG{__DIE__};
            my $signature = Mail::DKIM::Signature->parse($line);
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

    if ( lc($field_name) eq 'domainkey-signature' ) {
        eval {
            local $SIG{__DIE__};
            my $signature = Mail::DKIM::DkSignature->parse($line);
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
    my $self = shift;
    croak 'wrong number of arguments' unless ( @_ == 1 );
    my ($signature) = @_;

    # ignore signature headers once we've seen 50 or so
    # this protects against abuse.
    return if ( @{ $self->{signatures} } > $MAX_SIGNATURES_TO_PROCESS );

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
        Debug_Canonicalization => $self->{Debug_Canonicalization},
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
        && $signature->get_algorithm_class( $signature->algorithm ) )
    {
        # unsupported algorithm
        $self->{signature_reject_reason} = 'unsupported algorithm';
        if ( defined $signature->algorithm ) {
            $self->{signature_reject_reason} .= ' ' . $signature->algorithm;
        }
        return 0;
    }

    if ( $self->{Strict} ) {
        if ( $signature->algorithm eq 'rsa-sha1' ) {
            $self->{signature_reject_reason} = 'unsupported algorithm';
            if ( defined $signature->algorithm ) {
                $self->{signature_reject_reason} .= ' ' . $signature->algorithm;
            }
            return 0;
        }
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
        my $empty_g_means_wildcard = $signature->isa('Mail::DKIM::DkSignature');

        # check public key's granularity
        $result &&=
          $public_key->check_granularity( $signature->identity,
            $empty_g_means_wildcard );

        die $@ if $@;
	1
    } || do {
        my $E = $@;
        chomp $E;
        $self->{signature_reject_reason} = "public key: $E";
    };
    return $result;
}

# returns true if the i= tag is an address with a domain matching or
# a subdomain of the d= tag
#
sub check_signature_identity {
    my ($signature) = @_;

    my $d = $signature->domain;
    my $i = $signature->identity;
    if ( defined($i) && $i =~ /\@([^@]*)$/ ) {
        return match_subdomain( $1, $d );
    }
    return 0;
}

sub match_subdomain {
    croak 'wrong number of arguments' unless ( @_ == 2 );
    my ( $subdomain, $superdomain ) = @_;

    my $tmp = substr( ".$subdomain", -1 - length($superdomain) );
    return ( lc ".$superdomain" eq lc $tmp );
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

    foreach my $algorithm ( @{ $self->{algorithms} } ) {
        $algorithm->finish_header( Headers => $self->{headers} );
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
    unless ( check_signature_identity($signature) ) {
        $self->{signature_reject_reason} = 'bad identity';
        return ( 'invalid', $self->{signature_reject_reason} );
    }

    # get public key
    my $pkey;
    eval { $pkey = $signature->get_public_key; 1 }
    || do {
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

    foreach my $algorithm ( @{ $self->{algorithms} } ) {

        # finish canonicalizing
        $algorithm->finish_body;

        my ( $result, $details ) =
          $self->_check_and_verify_signature($algorithm);

        # save the results of this signature verification
        $algorithm->{result}  = $result;
        $algorithm->{details} = $details;
        $algorithm->signature->result( $result, $details );

        # collate results ... ignore failed signatures if we already got
        # one to pass
        if ( !$self->{result} || $result eq 'pass' ) {
            $self->{signature} = $algorithm->signature;
            $self->{result}    = $result;
            $self->{details}   = $details;
        }
    }
}


sub fetch_author_domain_policies {
    my $self = shift;
    use Mail::DKIM::AuthorDomainPolicy;

    return () unless $self->{headers_by_name}->{from};
    my @list = Mail::Address->parse( $self->{headers_by_name}->{from} );
    my @authors = map { $_->address } @list;

    # fetch the policies
    return map {
        Mail::DKIM::AuthorDomainPolicy->fetch(
            Protocol => 'dns',
            Author   => $_,
          )
    } @authors;
}


sub fetch_author_policy {
    my $self = shift;
    my ($author) = @_;
    use Mail::DKIM::DkimPolicy;

    # determine address found in the "From"
    $author ||= $self->message_originator->address;

    # fetch the policy
    return Mail::DKIM::DkimPolicy->fetch(
        Protocol => 'dns',
        Author   => $author,
    );
}


sub fetch_sender_policy {
    my $self = shift;
    use Mail::DKIM::DkPolicy;

    # determine addresses found in the "From" and "Sender" headers
    my $author = $self->message_originator->address;
    my $sender = $self->message_sender->address;

    # fetch the policy
    return Mail::DKIM::DkPolicy->fetch(
        Protocol => 'dns',
        Author   => $author,
        Sender   => $sender,
    );
}


sub policies {
    my $self = shift;

    my $sender_policy = eval { $self->fetch_sender_policy() };
    my $author_policy = eval { $self->fetch_author_policy() };
    return (
        $sender_policy ? $sender_policy : (),
        $author_policy ? $author_policy : (),
        $self->fetch_author_domain_policies(),
    );
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

Mail::DKIM::Verifier - verifies a DKIM-signed message

=head1 VERSION

version 1.20220520

=head1 SYNOPSIS

  use Mail::DKIM::Verifier;

  # create a verifier object
  my $dkim = Mail::DKIM::Verifier->new();

  # read an email from a file handle
  $dkim->load(*STDIN);

  # or read an email and pass it into the verifier, incrementally
  while (<STDIN>)
  {
      # remove local line terminators
      chomp;
      s/\015$//;

      # use SMTP line terminators
      $dkim->PRINT("$_\015\012");
  }
  $dkim->CLOSE;

  # what is the result of the verify?
  my $result = $dkim->result;

  # there might be multiple signatures, what is the result per signature?
  foreach my $signature ($dkim->signatures)
  {
      print 'signature identity: ' . $signature->identity . "\n";
      print 'verify result: ' . $signature->result_detail . "\n";
  }

  # the alleged author of the email may specify how to handle email
  foreach my $policy ($dkim->policies)
  {
      die 'fraudulent message' if ($policy->apply($dkim) eq 'reject');
  }

=head1 DESCRIPTION

The verifier object allows an email message to be scanned for DKIM and
DomainKeys signatures and those signatures to be verified. The verifier
tracks the state of the message as it is read into memory. When the
message has been completely read, the signatures are verified and the
results of the verification can be accessed.

To use the verifier, first create the verifier object. Then start
"feeding" it the email message to be verified. When all the _headers_
have been read, the verifier:

 1. checks whether any DomainKeys/DKIM signatures were found
 2. queries for the public keys needed to verify the signatures
 3. sets up the appropriate algorithms and canonicalization objects
 4. canonicalizes the headers and computes the header hash

Then, when the _body_ of the message has been completely fed into the
verifier, the body hash is computed and the signatures are verified.

The results of the verification can be checked with L</"result()">
or L</"signatures()">.

Messages that do not verify may be checked against the alleged sender's
published signing policy with L</"policies()"> and
L<Mail::DKIM::Policy/"apply()">.

=head1 CONSTRUCTOR

=head2 new()

Constructs an object-oriented verifier.

  my $dkim = Mail::DKIM::Verifier->new();

  my $dkim = Mail::DKIM::Verifier->new(%options);

The only options supported at this time are:

=over

=item Debug_Canonicalization

if specified, the canonicalized message for the first signature
is written to the referenced string or file handle.

=item Strict

If true, rejects sha1 hashes and signing keys shorter than 1024 bits.

=back

=head1 METHODS

=head2 PRINT()

Feeds part of the message to the verifier.

  $dkim->PRINT("a line of the message\015\012");
  $dkim->PRINT('more of');
  $dkim->PRINT(" the message\015\012bye\015\012");

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

  $dkim->CLOSE;

This method finishes the canonicalization process, computes a hash,
and verifies the signature.

=head2 fetch_author_domain_policies()

Retrieves ADSP records from DNS.

  my @policies = $dkim->fetch_author_domain_policies;
  foreach my $policy (@policies)
  {
      my $policy_result = $policy->apply($dkim);
  }

This method will retrieve all applicable
"author-domain-signing-practices" published in DNS for this message.
Author policies are keyed to the email address(es) in the From: header,
i.e. the claimed author of the message.

This method returns a *list* of policy records, since there is allowed
to be zero or multiple email addresses in the From: header.

The result of the apply() method is one of: "accept", "reject", "neutral".

See also: L</"policies()">.

=head2 fetch_author_policy()

Retrieves a signing policy from DNS.

  my $policy = $dkim->fetch_author_policy;
  my $policy_result = $policy->apply($dkim);

This method retrieves the DKIM Sender Signing Practices
record as described in Internet Draft draft-ietf-dkim-ssp-00-01dc.
This Internet Draft is now obsolete; this method is only kept for
backward-compatibility purposes.

Please use the L</"policies()"> method instead.

=head2 fetch_sender_policy()

Retrieves a signing policy from DNS.

  my $policy = $dkim->fetch_sender_policy;
  my $policy_result = $policy->apply($dkim);

The "sender" policy is the sender signing policy as described by the
DomainKeys specification, now available in RFC4870(historical).
I call it the "sender" policy because it is keyed to the email address
in the Sender: header, or the From: header if there is no Sender header.
This is the person whom the message claims as the "transmitter" of the
message (not necessarily the author).

If the email being verified has no From or Sender header from which to
get an email address (which violates email standards),
then this method will C<die>.

The result of the apply() method is one of: "accept", "reject", "neutral".

See also: L</"policies()">.

=head2 load()

Load the entire message from a file handle.

  $dkim->load($file_handle);

Reads a complete message from the designated file handle,
feeding it into the verifier. The message must use <CRLF> line
terminators (same as the SMTP protocol).

=head2 message_originator()

Access the "From" header.

  my $address = $dkim->message_originator;

Returns the "originator address" found in the message, as a
L<Mail::Address> object.
This is typically the (first) name and email address found in the
From: header. If there is no From: header,
then an empty L<Mail::Address> object is returned.

To get just the email address part, do:

  my $email = $dkim->message_originator->address;

See also L</"message_sender()">.

=head2 message_sender()

Access the "From" or "Sender" header.

  my $address = $dkim->message_sender;

Returns the "sender" found in the message, as a L<Mail::Address> object.
This is typically the (first) name and email address found in the
Sender: header. If there is no Sender: header, it is the first name and
email address in the From: header. If neither header is present,
then an empty L<Mail::Address> object is returned.

To get just the email address part, do:

  my $email = $dkim->message_sender->address;

The "sender" is the mailbox of the agent responsible for the actual
transmission of the message. For example, if a secretary were to send a
message for another person, the "sender" would be the secretary and
the "originator" would be the actual author.

=head2 policies()

Retrieves applicable signing policies from DNS.

  my @policies = $dkim->policies;
  foreach my $policy (@policies)
  {
      $policy_result = $policy->apply($dkim);
      # $policy_result is one of "accept", "reject", "neutral"
  }

This method searches for and returns any signing policies that would
apply to this message. Signing policies are selected based on the
domain that the message *claims* to be from. So, for example, if
a message claims to be from security@bank, and forwarded by
trusted@listserv, when in reality the message came from foe@evilcorp,
this method would check for signing policies for security@bank and
trusted@listserv. The signing policies might tell whether
foe@evilcorp (the real sender) is allowed to send mail claiming
to be from your bank or your listserv.

I say "might tell", because in reality this is still really hard to
specify with any accuracy. In addition, most senders do not publish
useful policies.

=head2 result()

Access the result of the verification.

  my $result = $dkim->result;

Gives the result of the verification. The following values are possible:

=over

=item pass

Returned if a valid DKIM-Signature header was found, and the signature
contains a correct value for the message.

=item fail

Returned if a valid DKIM-Signature header was found, but the signature
does not contain a correct value for the message.

=item invalid

Returned if a DKIM-Signature could not be checked because of a problem
in the signature itself or the public key record. I.e. the signature
could not be processed.

=item temperror

Returned if a DKIM-Signature could not be checked due to some error
which is likely transient in nature, such as a temporary inability
to retrieve a public key. A later attempt may produce a better
result.

=item none

Returned if no DKIM-Signature headers (valid or invalid) were found.

=back

In case of multiple signatures, the "best" result will be returned.
Best is defined as "pass", followed by "fail", "invalid", and "none".
To examine the results of individual signatures, use the L</"signatures()">
method to retrieve the signature objects. See
L<Mail::DKIM::Signature/"result()">.

=head2 result_detail()

Access the result, plus details if available.

  my $detail = $dkim->result_detail;

The detail is constructed by taking the result (e.g. "pass", "fail",
"invalid" or "none") and appending any details provided by the verification
process in parenthesis.

The following are possible results from the result_detail() method:

  pass
  fail (bad RSA signature)
  fail (OpenSSL error: ...)
  fail (message has been altered)
  fail (body has been altered)
  invalid (bad identity)
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

=head2 signature()

Access the message's DKIM signature.

  my $sig = $dkim->signature;

Accesses the signature found and verified in this message. The returned
object is of type L<Mail::DKIM::Signature>.

In case of multiple signatures, the signature with the "best" result will
be returned.
Best is defined as "pass", followed by "fail", "invalid", and "none".

=head2 signatures()

Access all of this message's signatures.

  my @all_signatures = $dkim->signatures;

Use $signature->result or $signature->result_detail to access
the verification results of each signature.

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
