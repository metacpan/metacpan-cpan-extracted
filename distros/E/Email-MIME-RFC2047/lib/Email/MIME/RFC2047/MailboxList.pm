package Email::MIME::RFC2047::MailboxList;
$Email::MIME::RFC2047::MailboxList::VERSION = '0.96';
use strict;
use warnings;

# ABSTRACT: Handling of MIME encoded mailbox lists

use base qw(Email::MIME::RFC2047::AddressList);

use Email::MIME::RFC2047::Mailbox;

sub _parse_item {
    my ($class, $string_ref, $decoder) = @_;

    return Email::MIME::RFC2047::Mailbox->parse(
        $string_ref, $decoder
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Email::MIME::RFC2047::MailboxList - Handling of MIME encoded mailbox lists

=head1 VERSION

version 0.96

=head1 SYNOPSIS

    use Email::MIME::RFC2047::MailboxList;

    my $mailbox_list = Email::MIME::RFC2047::MailboxList->parse($string);
    my @items = $mailbox_list->items;

    my $mailbox_list = Email::MIME::RFC2047::MailboxList->new();
    $mailbox_list->push($mailbox);
    $email->header_set('To', $mailbox_list->format());

=head1 DESCRIPTION

This module handles RFC 2822 C<mailbox-list>s. It is a subclass of
L<Email::MIME::RFC2047::AddressList> and works the same but only allows
L<Email::MIME::RFC2047::Mailbox> items.

=head1 AUTHOR

Nick Wellnhofer <wellnhofer@aevum.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Nick Wellnhofer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
