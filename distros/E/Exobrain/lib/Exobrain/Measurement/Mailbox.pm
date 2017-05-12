package Exobrain::Measurement::Mailbox;

use 5.010;
use autodie;
use Moose;
use Method::Signatures;

# ABSTRACT: Mailbox measurement packet
our $VERSION = '1.08'; # VERSION

# Declare that we will have a summary attribute. This is to make
# our roles happy.
sub summary;

# This needs to happen at begin time so it can add the 'payload'
# keyword.
BEGIN { with 'Exobrain::Message'; }


payload server  => ( isa => 'Str' );
payload user    => ( isa => 'Str' );
payload mailbox => ( isa => 'Str' );
payload count   => ( isa => 'Int' );

has summary => (
    isa => 'Str', builder => '_build_summary', lazy => 1, is => 'ro'
);

method _build_summary() {
    return join(" ",
        $self->user, '@', $self->server, "/", $self->mailbox,
        "has", $self->count, "messages"
    );
}

1;

__END__

=pod

=head1 NAME

Exobrain::Measurement::Mailbox - Mailbox measurement packet

=head1 VERSION

version 1.08

=head1 DESCRIPTION

A standard form of measuring a mailbox, whether that's via IMAP,
POP, Facebook API, or otherwise.

Eg:

    $exobrain->measure('Mailbox',
        server  => 'imap.example.com',
        user    => 'pjf',
        mailbox => 'INBOX',
        raw     => $raw_data,
        count   => $cnt,
    );

=head1 AUTHOR

Paul Fenwick <pjf@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Paul Fenwick.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
