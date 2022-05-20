package Mail::DKIM::Signer;
use strict;
use warnings;
our $VERSION = '1.20220520'; # VERSION
# ABSTRACT: generates a DKIM signature for a message

# Copyright 2005-2007 Messiah College. All rights reserved.
# Jason Long <jlong@messiah.edu>

# Copyright (c) 2004 Anthony D. Urso. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

use Mail::DKIM::PrivateKey;
use Mail::DKIM::Signature;


use base 'Mail::DKIM::Common';
use Carp;

# PROPERTIES
#
# public:
#
# $dkim->{Algorithm}
#   identifies what algorithm to use when signing the message
#   default is "rsa-sha1"
#
# $dkim->{Domain}
#   identifies what domain the message is signed for
#
# $dkim->{KeyFile}
#   name of the file containing the private key used to sign
#
# $dkim->{Method}
#   identifies what canonicalization method to use when signing
#   the message. default is "relaxed"
#
# $dkim->{Policy}
#   a signing policy (of type Mail::DKIM::SigningPolicy)
#
# $dkim->{Selector}
#   identifies name of the selector identifying the key
#
# $dkim->{Key}
#   the loaded private key
#
# private:
#
# $dkim->{algorithms} = []
#   an array of algorithm objects... an algorithm object is created for
#   each signature being added to the message
#
# $dkim->{result}
#   result of the signing policy: "signed" or "skipped"
#
# $dkim->{signature}
#   the created signature (of type Mail::DKIM::Signature)

sub init {
    my $self = shift;
    $self->SUPER::init;

    if ( defined $self->{KeyFile} ) {
        $self->{Key} ||=
          Mail::DKIM::PrivateKey->load( File => $self->{KeyFile} );
    }

    unless ( $self->{'Algorithm'} ) {

        # use default algorithm
        $self->{'Algorithm'} = 'rsa-sha1';
    }
    unless ( $self->{'Method'} ) {

        # use default canonicalization method
        $self->{'Method'} = 'relaxed';
    }
    unless ( $self->{'Domain'} ) {

        # use default domain
        $self->{'Domain'} = 'example.org';
    }
    unless ( $self->{'Selector'} ) {

        # use default selector
        $self->{'Selector'} = 'unknown';
    }
}

sub finish_header {
    my $self = shift;

    $self->{algorithms} = [];

    my $policy = $self->{Policy};
    if ( UNIVERSAL::isa( $policy, 'CODE' ) ) {

        # policy is a subroutine ref
        my $default_sig = $policy->($self);
        unless ( @{ $self->{algorithms} } || $default_sig ) {
            $self->{'result'} = 'skipped';
            return;
        }
    }
    elsif ( $policy && $policy->can('apply') ) {

        # policy is a Perl object or class
        my $default_sig = $policy->apply($self);
        unless ( @{ $self->{algorithms} } || $default_sig ) {
            $self->{'result'} = 'skipped';
            return;
        }
    }

    unless ( @{ $self->{algorithms} } ) {

        # no algorithms were created yet, so construct a signature
        # using the current signature properties

        # check properties
        unless ( $self->{'Algorithm'} ) {
            die 'invalid algorithm property';
        }
        unless ( $self->{'Method'} ) {
            die 'invalid method property';
        }
        unless ( $self->{'Domain'} ) {
            die 'invalid header property';
        }
        unless ( $self->{'Selector'} ) {
            die 'invalid selector property';
        }

        $self->add_signature(
            Mail::DKIM::Signature->new(
                Algorithm => $self->{'Algorithm'},
                Method    => $self->{'Method'},
                Headers   => $self->headers,
                Domain    => $self->{'Domain'},
                Selector  => $self->{'Selector'},
                Key       => $self->{'Key'},
                KeyFile   => $self->{'KeyFile'},
                (
                    $self->{'Identity'} ? ( Identity => $self->{'Identity'} )
                    : ()
                ),
                (
                    $self->{'Timestamp'} ? ( Timestamp => $self->{'Timestamp'} )
                    : ()
                ),
                (
                    $self->{'Expiration'} ? ( Expiration => $self->{'Expiration'} )
                    : ()
                ),
            )
        );
    }

    foreach my $algorithm ( @{ $self->{algorithms} } ) {

        # output header as received so far into canonicalization
        foreach my $header ( @{ $self->{headers} } ) {
            $algorithm->add_header($header);
        }
        $algorithm->finish_header( Headers => $self->{headers} );
    }
}

sub finish_body {
    my $self = shift;

    foreach my $algorithm ( @{ $self->{algorithms} } ) {

        # finished canonicalizing
        $algorithm->finish_body;

        # load the private key file if necessary
        my $signature = $algorithm->signature;
        my $key =
             $signature->{Key}
          || $signature->{KeyFile}
          || $self->{Key}
          || $self->{KeyFile};
        if ( defined($key) && !ref($key) ) {
            $key = Mail::DKIM::PrivateKey->load( File => $key );
        }
        $key
          or die "no key available to sign with\n";

        # compute signature value
        my $signb64 = $algorithm->sign($key);
        $signature->data($signb64);

        # insert linebreaks in signature data, if desired
        $signature->prettify_safe();

        $self->{signature} = $signature;
        $self->{result}    = 'signed';
    }
}


sub add_signature {
    my $self      = shift;
    my $signature = shift;

    # create a canonicalization filter and algorithm
    my $algorithm_class =
      $signature->get_algorithm_class( $signature->algorithm )
      or die 'unsupported algorithm ' . ( $signature->algorithm || '' ) . "\n";
    my $algorithm = $algorithm_class->new(
        Signature              => $signature,
        Debug_Canonicalization => $self->{Debug_Canonicalization},
    );
    push @{ $self->{algorithms} }, $algorithm;
    return;
}


sub algorithm {
    my $self = shift;
    if ( @_ == 1 ) {
        $self->{Algorithm} = shift;
    }
    return $self->{Algorithm};
}


sub domain {
    my $self = shift;
    if ( @_ == 1 ) {
        $self->{Domain} = shift;
    }
    return $self->{Domain};
}



# these are headers that "should" be included in the signature,
# according to the DKIM spec.
my @DEFAULT_HEADERS = qw(From Sender Reply-To Subject Date
  Message-ID To Cc MIME-Version
  Content-Type Content-Transfer-Encoding Content-ID Content-Description
  Resent-Date Resent-From Resent-Sender Resent-To Resent-cc
  Resent-Message-ID
  In-Reply-To References
  List-Id List-Help List-Unsubscribe List-Subscribe
  List-Post List-Owner List-Archive);

sub process_headers_hash {
    my $self = shift;

    my @headers;

    # these are the header fields we found in the message we're signing
    my @found_headers = @{ $self->{header_field_names} };

    # Convert all keys to lower case
    foreach my $header ( keys %{ $self->{'ExtendedHeaders'} } ) {
        next if $header eq lc $header;
        if ( exists $self->{'ExtendedHeaders'}->{ lc $header } ) {

            # Merge
            my $first  = $self->{'ExtendedHeaders'}->{ lc $header };
            my $second = $self->{'ExtendedHeaders'}->{$header};
            if ( $first eq '+' || $second eq '+' ) {
                $self->{'ExtendedHeaders'}->{ lc $header } = '+';
            }
            elsif ( $first eq '*' || $second eq '*' ) {
                $self->{'ExtendedHeaders'}->{ lc $header } = '*';
            }
            else {
                $self->{'ExtendedHeaders'}->{ lc $header } = $first + $second;
            }
        }
        else {
            # Rename
            $self->{'ExtendedHeaders'}->{ lc $header } =
              $self->{'ExtendedHeaders'}->{$header};
        }
        delete $self->{'ExtendedHeaders'}->{$header};
    }

    # Add the default headers
    foreach my $default (@DEFAULT_HEADERS) {
        if ( !exists $self->{'ExtendedHeaders'}->{ lc $default } ) {
            $self->{'ExtendedHeaders'}->{ lc $default } = '*';
        }
    }

    # Build a count of found headers
    my $header_counts = {};
    foreach my $header (@found_headers) {
        if ( !exists $header_counts->{ lc $header } ) {
            $header_counts->{ lc $header } = 1;
        }
        else {
            $header_counts->{ lc $header } = $header_counts->{ lc $header } + 1;
        }
    }

    foreach my $header ( sort keys %{ $self->{'ExtendedHeaders'} } ) {
        my $want_count = $self->{'ExtendedHeaders'}->{$header};
        my $have_count = $header_counts->{ lc $header } || 0;
        my $add_count  = 0;
        if ( $want_count eq '+' ) {
            $add_count = $have_count + 1;
        }
        elsif ( $want_count eq '*' ) {
            $add_count = $have_count;
        }
        else {
            if ( $want_count > $have_count ) {
                $add_count = $have_count;
            }
            else {
                $add_count = $want_count;
            }
        }
        for ( 1 .. $add_count ) {
            push @headers, $header;
        }
    }
    return join( ':', @headers );
}

sub extended_headers {
    my $self = shift;
    $self->{'ExtendedHeaders'} = shift;
    return;
}

sub headers {
    my $self = shift;
    croak 'unexpected argument' if @_;

    if ( exists $self->{'ExtendedHeaders'} ) {
        return $self->process_headers_hash();
    }

    # these are the header fields we found in the message we're signing
    my @found_headers = @{ $self->{header_field_names} };

    # these are the headers we actually want to sign
    my @wanted_headers = @DEFAULT_HEADERS;
    if ( $self->{Headers} ) {
        push @wanted_headers, split /:/, $self->{Headers};
    }

    my @headers =
      grep {
        my $a = $_;
        scalar grep { lc($a) eq lc($_) } @wanted_headers
      } @found_headers;
    return join( ':', @headers );
}

# return nonzero if this is header we should sign
sub want_header {
    my $self = shift;
    my ($header_name) = @_;

    #TODO- provide a way for user to specify which headers to sign
    return scalar grep { lc($_) eq lc($header_name) } @DEFAULT_HEADERS;
}


sub key {
    my $self = shift;
    if (@_) {
        $self->{Key}     = shift;
        $self->{KeyFile} = undef;
    }
    return $self->{Key};
}


sub key_file {
    my $self = shift;
    if (@_) {
        $self->{Key}     = undef;
        $self->{KeyFile} = shift;
    }
    return $self->{KeyFile};
}


sub method {
    my $self = shift;
    if ( @_ == 1 ) {
        $self->{Method} = shift;
    }
    return $self->{Method};
}



sub selector {
    my $self = shift;
    if ( @_ == 1 ) {
        $self->{Selector} = shift;
    }
    return $self->{Selector};
}


sub signatures {
    my $self = shift;
    croak 'no arguments allowed' if @_;
    return map { $_->signature } @{ $self->{algorithms} };
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mail::DKIM::Signer - generates a DKIM signature for a message

=head1 VERSION

version 1.20220520

=head1 SYNOPSIS

  use Mail::DKIM::Signer;
  use Mail::DKIM::TextWrap;  #recommended

  # create a signer object
  my $dkim = Mail::DKIM::Signer->new(
                  Algorithm => 'rsa-sha1',
                  Method => 'relaxed',
                  Domain => 'example.org',
                  Selector => 'selector1',
                  KeyFile => 'private.key',
                  Headers => 'x-header:x-header2',
             );

  # read an email from a file handle
  $dkim->load(*STDIN);

  # or read an email and pass it into the signer, one line at a time
  while (<STDIN>)
  {
      # remove local line terminators
      chomp;
      s/\015$//;

      # use SMTP line terminators
      $dkim->PRINT("$_\015\012");
  }
  $dkim->CLOSE;

  # what is the signature result?
  my $signature = $dkim->signature;
  print $signature->as_string;

=head1 DESCRIPTION

This class is the part of L<Mail::DKIM> responsible for generating
signatures for a given message. You create an object of this class,
specifying the parameters of the signature you wish to create, or
specifying a callback function so that the signature parameters can
be determined later. Next, you feed it the entire message using
L</"PRINT()">, completing with L</"CLOSE()">. Finally, use the
L</"signatures()"> method to access the generated signatures.

=head2 Pretty Signatures

L<Mail::DKIM> includes a signature-wrapping module (which inserts
linebreaks into the generated signature so that it looks nicer in the
resulting message. To enable this module, simply call

  use Mail::DKIM::TextWrap;

in your program before generating the signature.

=head1 CONSTRUCTOR

=head2 new()

Construct an object-oriented signer.

  # create a signer using the default policy
  my $dkim = Mail::DKIM::Signer->new(
                  Algorithm => 'rsa-sha1',
                  Method => 'relaxed',
                  Domain => 'example.org',
                  Selector => 'selector1',
                  KeyFile => 'private.key',
                  Headers => 'x-header:x-header2',
             );

  # create a signer using a custom policy
  my $dkim = Mail::DKIM::Signer->new(
                  Policy => $policyfn,
             );

The "default policy" is to create a DKIM signature using the specified
parameters, but only if the message's sender matches the domain.
The following parameters can be passed to this new() method to
influence the resulting signature:
Algorithm, Method, Domain, Selector, KeyFile, Identity, Timestamp, Expiration.

If you want different behavior, you can provide a "signer policy"
instead. A signer policy is a subroutine or class that determines
signature parameters after the message's headers have been parsed.
See the section L</"SIGNER POLICIES"> below for more information.

See L<Mail::DKIM::SignerPolicy> for more information about policy objects.

In addition to the parameters demonstrated above, the following
are recognized:

=over

=item Key

rather than using C<KeyFile>, use C<Key> to use an already-loaded
L<Mail::DKIM::PrivateKey> object.

=item Headers

A colon separated list of headers to sign, this is added to the list
of default headers as shown in in the DKIM specification.

For each specified header all headers of that type which are
present in the message will be signed, but we will not oversign
or sign headers which are not present.

If you require greater control over signed headers please use
the extended_headers() method instead.

The list of headers signed by default is as follows

    From Sender Reply-To Subject Date
    Message-ID To Cc MIME-Version
    Content-Type Content-Transfer-Encoding Content-ID Content-Description
    Resent-Date Resent-From Resent-Sender Resent-To Resent-cc
    Resent-Message-ID
    In-Reply-To References
    List-Id List-Help List-Unsubscribe List-Subscribe
    List-Post List-Owner List-Archive

=back

=head1 METHODS

=head2 PRINT()

Feed part of the message to the signer.

  $dkim->PRINT("a line of the message\015\012");

Feeds content of the message being signed into the signer.
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
and generates a signature.

=head2 extended_headers()

This method overrides the headers to be signed and allows more
control than is possible with the Headers property in the constructor.

The method expects a HashRef to be passed in.

The Keys are the headers to sign, and the values are either the
number of headers of that type to sign, or the special values
'*' and '+'.

* will sign ALL headers of that type present in the message.

+ will sign ALL + 1 headers of that type present in the message
to prevent additional headers being added.

You may override any of the default headers by including them
in the hashref, and disable them by giving them a 0 value.

Keys are case insensitive with the values being added upto the
highest value.

    Headers => {
        'X-test'  => '*',
        'x-test'  => '1',
        'Subject' => '+',
        'Sender'  => 0,
    },

=head2 add_signature()

Used by signer policy to create a new signature.

  $dkim->add_signature(new Mail::DKIM::Signature(...));

Signer policies can use this method to specify complete parameters for
the signature to add, including what type of signature. For more information,
see L<Mail::DKIM::SignerPolicy>.

=head2 algorithm()

Get or set the selected algorithm.

  $alg = $dkim->algorithm;

  $dkim->algorithm('rsa-sha1');

=head2 domain()

Get or set the selected domain.

  $alg = $dkim->domain;

  $dkim->domain('example.org');

=head2 load()

Load the entire message from a file handle.

  $dkim->load($file_handle);

Reads a complete message from the designated file handle,
feeding it into the signer.  The message must use <CRLF> line
terminators (same as the SMTP protocol).

=head2 headers()

Determine which headers to put in signature.

  my $headers = $dkim->headers;

This is a string containing the names of the header fields that
will be signed, separated by colons.

=head2 key()

Get or set the private key object.

  my $key = $dkim->key;

  $dkim->key(Mail::DKIM::PrivateKey->load(File => 'private.key'));

The key object can be any object that implements the
L<sign_digest() method|Mail::DKIM::PrivateKey/"sign_digest()">.
(Providing your own object can be useful if your actual keys
are stored out-of-process.)

If you use this method to specify a private key,
do not use L</"key_file()">.

=head2 key_file()

Get or set the filename containing the private key.

  my $filename = $dkim->key_file;

  $dkim->key_file('private.key');

If you use this method to specify a private key file,
do not use L</"key()">.

=head2 method()

Get or set the selected canonicalization method.

  $alg = $dkim->method;

  $dkim->method('relaxed');

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

=head2 selector()

Get or set the current key selector.

  $alg = $dkim->selector;

  $dkim->selector('alpha');

=head2 signature()

Access the generated signature object.

  my $signature = $dkim->signature;

Returns the generated signature. The signature is an object of type
L<Mail::DKIM::Signature>. If multiple signatures were generated, this method
returns the last one.

The signature (as text) should be B<prepended> to the message to make the
resulting message. At the very least, it should precede any headers
that were signed.

=head2 signatures()

Access list of generated signature objects.

  my @signatures = $dkim->signatures;

Returns all generated signatures, as a list.

=head1 SIGNER POLICIES

The new() constructor takes an optional Policy argument. This
can be a Perl object or class with an apply() method, or just a simple
subroutine reference. The method/subroutine will be called with the
signer object as an argument. The policy is responsible for checking the
message and specifying signature parameters. The policy must return a
nonzero value to create the signature, otherwise no signature will be
created. E.g.,

  my $policyfn = sub {
      my $dkim = shift;

      # specify signature parameters
      $dkim->algorithm('rsa-sha1');
      $dkim->method('relaxed');
      $dkim->domain('example.org');
      $dkim->selector('mx1');

      # return true value to create the signature
      return 1;
  };

Or the policy object can actually create the signature, using the
add_signature method within the policy object.
If you add a signature, you do not need to return a nonzero value.
This mechanism can be utilized to create multiple signatures,
or to create the older DomainKey-style signatures.

  my $policyfn = sub {
      my $dkim = shift;
      $dkim->add_signature(
              new Mail::DKIM::Signature(
                      Algorithm => 'rsa-sha1',
                      Method => 'relaxed',
                      Headers => $dkim->headers,
                      Domain => 'example.org',
                      Selector => 'mx1',
              ));
      $dkim->add_signature(
              new Mail::DKIM::DkSignature(
                      Algorithm => 'rsa-sha1',
                      Method => 'nofws',
                      Headers => $dkim->headers,
                      Domain => 'example.org',
                      Selector => 'mx1',
              ));
      return;
  };

If no policy is specified, the default policy is used. The default policy
signs every message using the domain, algorithm, method, and selector
specified in the new() constructor.

=head1 SEE ALSO

L<Mail::DKIM::SignerPolicy>

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
