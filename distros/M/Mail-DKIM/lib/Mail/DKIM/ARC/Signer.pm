package Mail::DKIM::ARC::Signer;
use strict;
use warnings;
our $VERSION = '1.20220520'; # VERSION
# ABSTRACT: generates a DKIM signature for a message

# Copyright 2017 FastMail Pty Ltd.  All Rights Reserved.
# Bron Gondwana <brong@fastmailteam.com>

# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

use Mail::DKIM::PrivateKey;
use Mail::DKIM::ARC::MessageSignature;
use Mail::DKIM::ARC::Seal;
use Mail::AuthenticationResults::Parser;
use Mail::AuthenticationResults::Header::AuthServID;


use base 'Mail::DKIM::Common';
use Carp;

# PROPERTIES
#
# public:
#
# $signer->{Algorithm}
#   identifies what algorithm to use when signing the message
#   default is "rsa-sha256"
#
# $signer->{Domain}
#   identifies what domain the message is signed for
#
# $signer->{SrvId}
#   identifies what authserv-id is in the A-R headers
#
# $signer->{KeyFile}
#   name of the file containing the private key used to sign
#
# $signer->{Policy}
#   a signing policy (of type Mail::DKIM::SigningPolicy)
#
# $signer->{Selector}
#   identifies name of the selector identifying the key
#
# $signer->{Key}
#   the loaded private key
#
# private:
#
# $signer->{algorithms} = []
#   an array of algorithm objects... an algorithm object is created for
#   each signature being added to the message
#
# $signer->{result}
#   result of the signing policy: "signed" or "skipped"
#
# $signer->{details}
#   why we skipped this signature
#
# $signer->{signature}
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
        $self->{'Algorithm'} = 'rsa-sha256';
    }
    unless ( $self->{'Domain'} ) {

        # use default domain
        $self->{'Domain'} = 'example.org';
    }
    unless ( $self->{'SrvId'} ) {

        # use default domain
        $self->{'SrvId'} = $self->{'Domain'};
    }
    unless ( $self->{'Selector'} ) {

        # use default selector
        $self->{'Selector'} = 'unknown';
    }
    $self->{result} = '?';    # better update this before we finish
    die 'Invalid signing algorithm'
      unless $self->{Algorithm} eq 'rsa-sha256';    # add ed25519 sometime
    die 'Need a valid chain value'
      unless $self->{Chain} and $self->{Chain} =~ m{^(pass|fail|none|ar)$};
}

sub finish_header {
    my $self = shift;

    # add the AAR header
    my @aar;
    my @ams;
    my @as;

    my $ar;
    HEADER:
    foreach my $header ( @{ $self->{headers} } ) {
        $header =~ s/[\r\n]+$//;
        if ( $header =~ m/^Authentication-Results:/ ) {
            my ( $arval ) = $header =~ m/^Authentication-Results:[^;]*;[\t ]*(.*)/is;
            my $parsed;
	    eval {
		$parsed= Mail::AuthenticationResults::Parser->new
		    ->parse( $header );
		1
	    } || do {
		my $error = $@;
		warn "Authentication-Results Header parse error: $error\n$header";
		next HEADER;
            };
            my $ardom = $parsed->value->value;

            next
              unless "\L$ardom" eq $self->{SrvId};   # make sure it's our domain

            $arval =~ s/;?\s*$//;    # ignore trailing semicolon and whitespace
            # preserve leading fold if there is one, otherwise set one leading space
            $arval =~ s/^\s*/ / unless ($arval =~ m/^\015\012/);
            if ($ar) {
                $ar .= ";$arval";
            }
            else {
                $ar = "$ardom;$arval";
            }

            # get chain value from A-R header
            $self->{Chain} = $1
              if $self->{Chain} eq 'ar' and $arval =~ m{\barc=(none|pass|fail)};

        }
        else {
            # parse ARC headers to make sure we have completeness

            if ( $header =~ m/^ARC-/ ) {
                if ( !$ar ) {
                    $self->{result} = 'skipped';
                    $self->{details} =
                      'ARC header seen before Authentication-Results';
                    return;
                }
                if ( $self->{Chain} eq 'ar' ) {
                    $self->{result} = 'skipped';
                    $self->{details} =
                      'No ARC result found in Authentication-Results';
                    return;
                }

            }

            if ( $header =~ m/^ARC-Seal:/ ) {
                my $seal = Mail::DKIM::ARC::Seal->parse($header);
                my $i    = $seal->instance;
                if ( $as[$i] ) {
                    $self->{result}        = 'skipped';
                    $self->{details} = "Duplicate ARC-Seal $i";
                    return;
                }
                $as[$i] = $seal;
            }
            elsif ( $header =~ m/^ARC-Message-Signature:/ ) {
                my $sig = Mail::DKIM::ARC::MessageSignature->parse($header);
                my $i   = $sig->instance;
                if ( $ams[$i] ) {
                    $self->{result} = 'skipped';
                    $self->{details} =
                      "Duplicate ARC-Message-Signature $i";
                    return;
                }
                $ams[$i] = $sig;
            }
            elsif ( $header =~ m/^ARC-Authentication-Results:\s*i=(\d+)/ ) {
                my $i = $1;
                if ( $aar[$i] ) {
                    $self->{result} = 'skipped';
                    $self->{details} =
                      "Duplicate ARC-Authentication-Results $i";
                    return;
                }

                $aar[$i] = $header;
            }
        }
    }

    unless ($ar) {
        $self->{result}        = 'skipped';
        $self->{details} = 'No authentication results seen';
        return;
    }

    $self->{Chain} = 'none' if ($self->{Chain} eq 'ar');

    if ( $#ams > $#as ) {
        $self->{result}        = 'skipped';
        $self->{details} = 'More message signatures than seals';
        return;
    }
    if ( $#aar > $#as ) {
        $self->{result}        = 'skipped';
        $self->{details} = 'More authentication results than seals';
        return;
    }

    foreach my $i ( 1 .. $#as ) {
        unless ( $as[$i] ) {
            $self->{result}        = 'skipped';
            $self->{details} = "Missing ARC-Seal $i";
            return;
        }
        unless ( $ams[$i] ) {
            $self->{result}        = 'skipped';
            $self->{details} = "Missing Arc-Message-Signature $i";
            return;
        }

        # don't care about authentication results, they are compulsary
    }

    $self->{_Instance} = @as || 1;    # next instance value

    # first add the AAR header
    $self->{_AAR} = "ARC-Authentication-Results: i=$self->{_Instance}; $ar";
    unshift @{ $self->{headers} }, $self->{_AAR};

    # set up the signer for AMS
    $self->add_signature(
        Mail::DKIM::ARC::MessageSignature->new(
            Algorithm => $self->{Algorithm},
            Headers   => $self->headers,
            Instance  => $self->{_Instance},
            Method    => 'relaxed/relaxed',
            Domain    => $self->{Domain},
            Selector  => $self->{Selector},
            Key       => $self->{Key},
            KeyFile   => $self->{KeyFile},
            ( $self->{Timestamp} ? ( Timestamp => $self->{Timestamp} ) : () ),
            ( $self->{Expiration} ? ( Expiration => $self->{Expiration} ) : () ),
        )
    );

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

    if ( $self->{result} eq 'skipped' ) {    # already failed
        $self->{_AS} = undef;
        return;
    }

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

        $self->{_AMS} = $signature->as_string();
        unshift @{ $self->{headers} }, $self->{_AMS};
    }

    # reset the internal state
    $self->{signatures} = [];
    $self->{algorithms} = [];

    $self->add_signature(
        Mail::DKIM::ARC::Seal->new(
            Algorithm => $self->{Algorithm},
            Chain     => $self->{Chain},
            Headers   => $self->headers,
            Instance  => $self->{_Instance},
            Domain    => $self->{Domain},
            Selector  => $self->{Selector},
            Key       => $self->{Key},
            KeyFile   => $self->{KeyFile},
            ( $self->{Timestamp} ? ( Timestamp => $self->{Timestamp} ) : () ),
            ( $self->{Expiration} ? ( Expiration => $self->{Expiration} ) : () ),
        )
    );

    foreach my $algorithm ( @{ $self->{algorithms} } ) {

        # output header as received so far into canonicalization
        foreach my $header ( @{ $self->{headers} } ) {
            $algorithm->add_header($header);
        }

        # chain needed for seal canonicalization
        $algorithm->finish_header(
            Headers => $self->{headers},
            Chain   => $self->{Chain}
        );

        # no body is required for ARC-Seal
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
          or die "no key available to sign ARC-Seal\n";

        # compute signature value
        my $signb64 = $algorithm->sign($key);
        $signature->data($signb64);

        # insert linebreaks in signature data, if desired
        $signature->prettify_safe();

        $self->{_AS} = $signature->as_string();
    }

    $self->{result} = 'sealed';
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
    if ( !$self->{'NoDefaultHeaders'} ) {
        foreach my $default (@DEFAULT_HEADERS) {
            if ( !exists $self->{'ExtendedHeaders'}->{ lc $default } ) {
                $self->{'ExtendedHeaders'}->{ lc $default } = '*';
            }
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
    my @wanted_headers;
    if ( !$self->{'NoDefaultHeaders'} ) {
        @wanted_headers = @DEFAULT_HEADERS;
    }
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


sub as_string {
    my $self = shift;
    return '' unless $self->{_AS};    # skipped, no signature

    return join( "\015\012", $self->{_AS}, $self->{_AMS}, $self->{_AAR}, '' );
}


sub as_strings {
    my $self = shift;
    return ( $self->{_AS}, $self->{_AMS}, $self->{_AAR} );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mail::DKIM::ARC::Signer - generates a DKIM signature for a message

=head1 VERSION

version 1.20220520

=head1 SYNOPSIS

  use Mail::DKIM::ARC::Signer;
  use Mail::DKIM::TextWrap;  #recommended

  # create a signer object
  my $signer = Mail::DKIM::ARC::Signer->new(
                  Algorithm => 'rsa-sha256',
                  Chain => 'none',    # or pass|fail|ar
                  Domain => 'example.org',
                  SrvId => 'example.org',
                  Selector => 'selector1',
                  KeyFile => 'private.key',
                  Headers => 'x-header:x-header2',
             );

  # read an email from a file handle
  $signer->load(*STDIN);

  # NOTE: any email being ARC signed must have an Authentication-Results
  # header so that the ARC seal can cover those results copied into
  # an ARC-Authentication-Results header.

  # or read an email and pass it into the signer, one line at a time
  while (<STDIN>)
  {
      # remove local line terminators
      chomp;
      s/\015$//;

      # use SMTP line terminators
      $signer->PRINT("$_\015\012");
  }
  $signer->CLOSE;

  die 'Failed' $signer->result_details() unless $signer->result() eq 'sealed';

  # Get all the signature headers to prepend to the message
  # ARC-Seal, ARC-Message-Signature and ARC-Authentication-Results
  # in that order.
  print $signer->as_string;

=head1 DESCRIPTION

This class is the part of L<Mail::DKIM> responsible for generating
ARC Seals for a given message. You create an object of this class,
specifying the parameters for the ARC-Message-Signature you wish to
create.

You also need to pass the 'Chain' value (pass or fail) from validation
of the previous ARC-Seals on the message.

Next, you feed it the entire message using L</"PRINT()">, completing
with L</"CLOSE()">.

Finally, use the L</"as_string()"> method to get the new ARC headers.

Note: you can only seal a message which has already had an
Authentication-Results header added, either by using L</"PRINT()">
to pre-feed it into this module, or by adding a message which has
already been authenticated by your inbound scanning mechanisms.

It is not necessary to ARC-Seal a message which already has DKIM
signatures if you are not modifying the message and hence breaking
the existing DKIM-Signature or top ARC-Message-Signature on the email.

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
  my $signer = Mail::DKIM::ARC::Signer->new(
                  Algorithm => 'rsa-sha256',
                  Chain => 'none',    # or pass|fail|ar
                  Domain => 'example.org',
                  SrvId => 'example.org',
                  Selector => 'selector1',
                  KeyFile => 'private.key',
                  Headers => 'x-header:x-header2',
             );

=over

=item Key

rather than using C<KeyFile>, use C<Key> to use an already-loaded
L<Mail::DKIM::PrivateKey> object.

=item Chain

The cv= value for the Arc-Seal header.  "ar" means to copy it from
an Authentication-Results header, or use none if there isn't one.

=item SrvId

The authserv-id in the Authentication-Results headers, defaults to
Domain.

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

  $signer->PRINT("a line of the message\015\012");

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

  $signer->CLOSE;

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

  $signer->add_signature(new Mail::DKIM::Signature(...));

Signer policies can use this method to specify complete parameters for
the signature to add, including what type of signature. For more information,
see L<Mail::DKIM::SignerPolicy>.

=head2 algorithm()

Get or set the selected algorithm.

  $alg = $signer->algorithm;

  $signer->algorithm('rsa-sha256');

=head2 domain()

Get or set the selected domain.

  $alg = $signer->domain;

  $signer->domain('example.org');

=head2 load()

Load the entire message from a file handle.

  $signer->load($file_handle);

Reads a complete message from the designated file handle,
feeding it into the signer.  The message must use <CRLF> line
terminators (same as the SMTP protocol).

=head2 headers()

Determine which headers to put in signature.

  my $headers = $signer->headers;

This is a string containing the names of the header fields that
will be signed, separated by colons.

=head2 key()

Get or set the private key object.

  my $key = $signer->key;

  $signer->key(Mail::DKIM::PrivateKey->load(File => 'private.key'));

The key object can be any object that implements the
L<sign_digest() method|Mail::DKIM::PrivateKey/"sign_digest()">.
(Providing your own object can be useful if your actual keys
are stored out-of-process.)

If you use this method to specify a private key,
do not use L</"key_file()">.

=head2 key_file()

Get or set the filename containing the private key.

  my $filename = $signer->key_file;

  $signer->key_file('private.key');

If you use this method to specify a private key file,
do not use L</"key()">.

=head2 message_originator()

Access the "From" header.

  my $address = $signer->message_originator;

Returns the "originator address" found in the message, as a
L<Mail::Address> object.
This is typically the (first) name and email address found in the
From: header. If there is no From: header,
then an empty L<Mail::Address> object is returned.

To get just the email address part, do:

  my $email = $signer->message_originator->address;

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

=head2 signatures()

Access list of generated signature objects.

  my @signatures = $dkim->signatures;

Returns all generated signatures, as a list.

=head2 as_string()

Returns the new ARC headers

  my $pre_headers = $signer->as_string();

The headers are separated by \015\012 (SMTP line separator) including
a trailing separator, so can be directly injected in front of the raw
message.

=head2 as_strings()

Returns the new ARC headers

  my @pre_headers = $signer->as_string();

The headers are returned as a list so you can add whatever line ending
your local MTA prefers.

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
