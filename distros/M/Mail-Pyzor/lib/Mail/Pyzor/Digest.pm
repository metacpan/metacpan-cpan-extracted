package Mail::Pyzor::Digest;

# Copyright 2018 cPanel, LLC.
# All rights reserved.
# http://cpanel.net
#
# This is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself. See L<perlartistic>.

use strict;
use warnings;

=encoding utf-8

=head1 NAME

Mail::Pyzor::Digest

=head1 SYNOPSIS

    my $digest = Mail::Pyzor::Digest::get( $mime_text );

=head1 DESCRIPTION

A reimplementation of L<https://github.com/SpamExperts/pyzor/blob/master/pyzor/digest.py>.

=cut

#----------------------------------------------------------------------

use Email::MIME ();

use Mail::Pyzor::Digest::Pieces ();
use Mail::Pyzor::SHA            ();

#----------------------------------------------------------------------

=head1 FUNCTIONS

=head2 $hex = get( $MSG )

This takes an email message in raw MIME text format (i.e., as saved in the
standard mbox format) and returns the message’s Pyzor digest in lower-case
hexadecimal.

The output from this function should normally be identical to that of
the C<pyzor> script’s C<digest> command. It is suitable for use in
L<Mail::Pyzor::Client>’s request methods.

=cut

sub get {
    return Mail::Pyzor::SHA::sha1_hex( ${ _get_predigest( $_[0] ) } );
}

# NB: This is called from the test.
sub _get_predigest {    ## no critic qw(RequireArgUnpacking)
    my ($msg_text_sr) = \$_[0];

    my $parsed = Email::MIME->new($$msg_text_sr);

    my @lines;

    my $payloads_ar = Mail::Pyzor::Digest::Pieces::digest_payloads($parsed);

    for my $payload (@$payloads_ar) {
        my @p_lines = Mail::Pyzor::Digest::Pieces::splitlines($payload);
        for my $line (@p_lines) {
            Mail::Pyzor::Digest::Pieces::normalize($line);

            next if !Mail::Pyzor::Digest::Pieces::should_handle_line($line);

            # Make sure we have an octet string.
            utf8::encode($line) if utf8::is_utf8($line);

            push @lines, $line;
        }
    }

    my $digest_sr = Mail::Pyzor::Digest::Pieces::assemble_lines( \@lines );

    return $digest_sr;
}

1;
