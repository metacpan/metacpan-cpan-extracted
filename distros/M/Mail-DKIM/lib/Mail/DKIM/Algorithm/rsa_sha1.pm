package Mail::DKIM::Algorithm::rsa_sha1;
use strict;
use warnings;
our $VERSION = '1.20220520'; # VERSION
# ABSTRACT: rsa sha1 algorithm class

# Copyright 2005-2006 Messiah College. All rights reserved.
# Jason Long <jlong@messiah.edu>

# Copyright (c) 2004 Anthony D. Urso. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

use base 'Mail::DKIM::Algorithm::Base';
use Carp;
use MIME::Base64;
use Digest::SHA;

sub init_digests {
    my $self = shift;

    # initialize a SHA-1 Digest
    $self->{header_digest} = Digest::SHA->new(1);
    $self->{body_digest}   = Digest::SHA->new(1);
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

    my $sig    = decode_base64($base64);
    my $digest = $self->{header_digest}->digest;
    return unless $public_key->verify_digest( 'SHA-1', $digest, $sig );
    return $self->check_body_hash;
}

sub wants_pre_signature_headers {
    return 1;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mail::DKIM::Algorithm::rsa_sha1 - rsa sha1 algorithm class

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
