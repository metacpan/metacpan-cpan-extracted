package Mail::DKIM::Algorithm::dk_rsa_sha1;
use strict;
use warnings;
our $VERSION = '1.20220520'; # VERSION
# ABSTRACT: Base algorithm class

# Copyright 2005-2006 Messiah College. All rights reserved.
# Jason Long <jlong@messiah.edu>

# Copyright (c) 2004 Anthony D. Urso. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

use Mail::DKIM::Canonicalization::dk_simple;
use Mail::DKIM::Canonicalization::dk_nofws;

use base 'Mail::DKIM::Algorithm::Base';
use Carp;
use MIME::Base64;
use Digest::SHA;

sub finish_header {
    my $self = shift;
    $self->SUPER::finish_header(@_);

    if ( ( my $s = $self->signature )
        && $self->{canon}->{interesting_header} )
    {
        my $sender = $self->{canon}->{interesting_header}->{sender};
        $sender = defined($sender) && ( Mail::Address->parse($sender) )[0];
        my $author = $self->{canon}->{interesting_header}->{from};
        $author = defined($author) && ( Mail::Address->parse($author) )[0];

        if ($sender) {
            $s->init_identity( $sender->address, 'header.sender' );
        }
        elsif ($author) {
            $s->init_identity( $author->address, 'header.from' );
        }
    }
    return;
}

sub get_canonicalization_class {
    my $self = shift;
    croak 'wrong number of arguments' unless ( @_ == 1 );
    my ($method) = @_;

    my $class =
        $method eq 'nofws'  ? 'Mail::DKIM::Canonicalization::dk_nofws'
      : $method eq 'simple' ? 'Mail::DKIM::Canonicalization::dk_simple'
      :                       die "unknown method $method\n";
    return $class;
}

sub init {
    my $self = shift;

    die 'no signature' unless $self->{Signature};

    $self->{mode} = $self->{Signature}->signature ? 'verify' : 'sign';

    # allows subclasses to set the header_digest and body_digest
    # properties
    $self->init_digests;

    my $method = $self->{Signature}->canonicalization;

    my $canon_class = $self->get_canonicalization_class($method);
    $self->{canon} = $canon_class->new(
        output_digest          => $self->{header_digest},
        Signature              => $self->{Signature},
        Debug_Canonicalization => $self->{Debug_Canonicalization}
    );
}

sub init_digests {
    my $self = shift;

    # initialize a SHA-1 Digest
    $self->{header_digest} = Digest::SHA->new(1);
    $self->{body_digest}   = $self->{header_digest};
}

sub sign {
    my $self = shift;
    croak 'wrong number of arguments' unless ( @_ == 1 );
    my ($private_key) = @_;

    my $digest = $self->{header_digest}->digest;
    my $signature = $private_key->sign_digest( 'SHA-1', $digest );

    return encode_base64( $signature, '' );
}

sub verify {
    my $self = shift;
    croak 'wrong number of arguments' unless ( @_ == 0 );

    my $base64     = $self->signature->data;
    my $public_key = $self->signature->get_public_key;

    my $digest = $self->{header_digest}->digest;
    my $sig    = decode_base64($base64);
    return $public_key->verify_digest( 'SHA-1', $digest, $sig );
}

sub finish_message {
    my $self = shift;

    # DomainKeys doesn't include the signature in the digest,
    # but we still want it to look "pretty" :).

    if ( $self->{mode} eq 'sign' ) {
        $self->{Signature}->prettify;
    }
}

sub wants_pre_signature_headers {
    return 0;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mail::DKIM::Algorithm::dk_rsa_sha1 - Base algorithm class

=head1 VERSION

version 1.20220520

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
