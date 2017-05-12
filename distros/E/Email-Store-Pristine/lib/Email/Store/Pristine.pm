=head1 NAME

Email::Store::Pristine - keep a pristine copy of the mail

=head1 DESCRIPTION

Many Email::Store plugins will munge the underlying rfc2822
representation of the message, which in some cases is undesirable.

When in use Email::Store::Pristine stores a copy of the original
message in a pristine_copies relationship.  This is a one-to-many
relationship as in the case of a cross-posted mail you may recieve
many subtly different versions of the same mail, for which there will
be only one Email::Store::Mail message due to the unchanging
Message-ID.

A C<pristine_copies> accessor is added to the Email::Store::Mail
object, which returns Email::Store::Pristine copies which encapsulate
the original message.

=head1 METHODS

=head2 ->message

The pristine rfc2822 message.  A readonly accessor.

=head2 ->simple

The message represented as an Email::Simple object.

=head1 AUTHOR

Richard Clamp <richardc@unixbeard.net>

=head1 COPYRIGHT

Copyright 2005 Richard Clamp.  All Rights Reserved.

This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Email::Store>

=cut


package Email::Store::Pristine;
use strict;
use warnings;
our $VERSION = '1.21';
use base 'Email::Store::DBI';
__PACKAGE__->table("pristine");
__PACKAGE__->columns(All  => qw/id mail message/);
__PACKAGE__->columns(TEMP => qw/simple/);
__PACKAGE__->has_a(mail => 'Email::Store::Mail');
Email::Store::Mail->has_many( pristine_copies => __PACKAGE__ );

# I damn well want to be first
sub on_store_order { -20000 }
sub on_seen_duplicate_order { -20000 }

sub _store {
    my ($self, $mail, $message) = @_;
    $mail->add_to_pristine_copies({
        mail    => $mail,
        message => $message,
    });
}

sub on_store {
    my ($self, $mail) = @_;
    $self->_store( $mail, $mail->simple->as_string );
}

# don't store all duplicates, only the ones we've not got the exact
# same rfc2822 body for
sub on_seen_duplicate {
    my ($self, $mail, $simple)  = @_;
    my $message = $simple->as_string;
    for my $check ($mail->pristine_copies) {
        return if $check->message eq $message;
    }
    $self->_store( $mail, $message );
}

sub message {
    my $self = shift;
    if (@_) {
        die "which part of pristine didn't you get?"
    }
    $self->get('message');
}

# hmm, is there a way to make this Email::Simple object readonly too?
sub simple {
    my $self = shift;
    return $self->{simple} ||= Email::Simple->new( $self->message );
}

1;
__DATA__

CREATE TABLE IF NOT EXISTS pristine (
    id integer NOT NULL auto_increment primary key,
    mail varchar(255) NOT NULL,
    message text
);
