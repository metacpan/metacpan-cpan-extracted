package Mail::DKIM::Algorithm::Base;
use strict;
use warnings;
our $VERSION = '1.20220520'; # VERSION
# ABSTRACT: base class for DKIM "algorithms"

# Copyright 2005-2007 Messiah College. All rights reserved.
# Jason Long <jlong@messiah.edu>

# Copyright (c) 2004 Anthony D. Urso. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

use Mail::DKIM::Canonicalization::nowsp;
use Mail::DKIM::Canonicalization::relaxed;
use Mail::DKIM::Canonicalization::simple;
use Mail::DKIM::Canonicalization::seal;

use Carp;
use MIME::Base64;

sub new {
    my $class = shift;
    my %args  = @_;
    my $self  = bless \%args, $class;
    $self->init;
    return $self;
}

sub init {
    my $self = shift;

    croak 'no signature' unless $self->{Signature};

    $self->{mode} = $self->{Signature}->signature ? 'verify' : 'sign';

    # allows subclasses to set the header_digest and body_digest
    # properties
    $self->init_digests;

    my ( $header_method, $body_method ) = $self->{Signature}->canonicalization;

    my $header_class = $self->get_canonicalization_class($header_method);
    my $body_class   = $self->get_canonicalization_class($body_method);
    $self->{canon} = $header_class->new(
        output_digest          => $self->{header_digest},
        Signature              => $self->{Signature},
        Debug_Canonicalization => $self->{Debug_Canonicalization}
    );
    $self->{body_canon} = $body_class->new(
        output_digest          => $self->{body_digest},
        Signature              => $self->{Signature},
        Debug_Canonicalization => $self->{Debug_Canonicalization}
    );
}

# override this method, please...
# this method should set the "header_digest" and "body_digest" properties
sub init_digests {
    die 'not implemented';
}

# private method - DKIM-specific
sub get_canonicalization_class {
    my $self = shift;
    croak 'wrong number of arguments' unless ( @_ == 1 );
    my ($method) = @_;

    my $class =
        $method eq 'nowsp'   ? 'Mail::DKIM::Canonicalization::nowsp'
      : $method eq 'relaxed' ? 'Mail::DKIM::Canonicalization::relaxed'
      : $method eq 'simple'  ? 'Mail::DKIM::Canonicalization::simple'
      : $method eq 'seal'    ? 'Mail::DKIM::Canonicalization::seal'
      :                        die "unknown method $method\n";
    return $class;
}


sub add_body {
    my $self = shift;
    my $canon = $self->{body_canon} || $self->{canon};
    $canon->add_body(@_);
}


sub add_header {
    my $self = shift;
    $self->{canon}->add_header(@_);
}


sub finish_body {
    my $self = shift;
    my $body_canon = $self->{body_canon} || $self->{canon};
    $body_canon->finish_body;
    $self->finish_message;
}


sub finish_header {
    my $self = shift;
    $self->{canon}->finish_header(@_);
}

# checks the bh= tag of the signature to see if it has the same body
# hash as computed by canonicalizing/digesting the actual message body.
# If it doesn't match, a false value is returned, and the
# verification_details property is set to "body has been altered"
sub check_body_hash {
    my $self = shift;

    # The body_hash value is set in finish_message(), if we're operating
    # from a version of the DKIM spec that uses the bh= tag. Otherwise,
    # the signature shouldn't have a bh= tag to check.

    my $sighash = $self->{Signature}->body_hash();
    if ( $self->{body_hash} and $sighash ) {
        my $body_hash = $self->{body_hash};
        my $expected  = decode_base64($sighash);
        if ( $body_hash ne $expected ) {
            $self->{verification_details} = 'body has been altered';

            #		print STDERR "I calculated  "
            #			. encode_base64($body_hash, "") . "\n";
            #		print STDERR "signature has "
            #			. encode_base64($expected, "") . "\n";
            return;
        }
    }
    return 1;
}

sub finish_message {
    my $self = shift;

    # DKIM requires the signature itself to be committed into the digest.
    # But first, we need to set the bh= tag on the signature, then
    # "prettify" it.

    $self->{body_hash} = $self->{body_digest}->digest;
    if ( $self->{mode} eq 'sign' ) {
        $self->{Signature}
          ->body_hash( encode_base64( $self->{body_hash}, '' ) );
    }

    if ( $self->{mode} eq 'sign' ) {
        $self->{Signature}->prettify;
    }

    my $sig_line      = $self->{Signature}->as_string_without_data;
    my $canonicalized = $self->{canon}->canonicalize_header($sig_line);

    $self->{canon}->output($canonicalized);
}


# override this method, please...
sub sign {
    die 'Not implemented';
}


sub signature {
    my $self = shift;
    @_
      and $self->{Signature} = shift;
    return $self->{Signature};
}


# override this method, please...
sub verify {
    die 'Not implemented';
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mail::DKIM::Algorithm::Base - base class for DKIM "algorithms"

=head1 VERSION

version 1.20220520

=head1 SYNOPSIS

  my $algorithm = new Mail::DKIM::Algorithm::rsa_sha1(
                      Signature => $dkim_signature
                  );

  # add headers
  $algorithm->add_header("Subject: this is the subject\015\012");
  $algorithm->finish_header;

  # add body
  $algorithm->add_body("This is the body.\015\012");
  $algorithm->add_body("Another line of the body.\015\012");
  $algorithm->finish_body;

  # now sign or verify...
  # TODO...

=head1 CONSTRUCTOR

You should not create an object of this class directly. Instead, use one
of the DKIM algorithm implementation classes, such as rsa_sha1:

  my $algorithm = new Mail::DKIM::Algorithm::rsa_sha1(
                      Signature => $dkim_signature
                  );

=head1 METHODS

=head2 add_body() - feeds part of the body into the algorithm/canonicalization

  $algorithm->add_body("This is the body.\015\012");
  $algorithm->add_body("Another line of the body.\015\012");

The body should be fed one "line" at a time.

=head2 add_header() - feeds a header field into the algorithm/canonicalization

  $algorithm->add_header("Subject: this is the subject\015\012");

The header must start with the header field name and continue through any
folded lines (including the embedded <CRLF> sequences). It terminates with
the <CRLF> at the end of the header field.

=head2 finish_body() - signals the end of the message body

  $algorithm->finish_body

Call this method when all lines from the body have been submitted.
After calling this method, use sign() or verify() to get the results
from the algorithm.

=head2 finish_header() - signals the end of the header field block

  $algorithm->finish_header;

Call this method when all the headers have been submitted.

=head2 sign() - generates a signature using a private key

  $base64 = $algorithm->sign($private_key);

=head2 signature() - get/set the signature worked on by this algorithm

  my $old_signature = $algorithm->signature;
  $algorithm->signature($new_signature);

=head2 verify() - verifies a signature

  $result = $algorithm->verify();

Must be called after finish_body().

The result is a true/false value: true indicates the signature data
is valid, false indicates it is invalid.

For an invalid signature, details may be obtained from
$algorithm->{verification_details} or $@.

=head1 SEE ALSO

L<Mail::DKIM>

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
