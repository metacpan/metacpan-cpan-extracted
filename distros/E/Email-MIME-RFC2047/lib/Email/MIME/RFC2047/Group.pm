package Email::MIME::RFC2047::Group;
$Email::MIME::RFC2047::Group::VERSION = '0.95';
use strict;
use warnings;

# ABSTRACT: Handling of MIME encoded mailbox groups

use base qw(Email::MIME::RFC2047::Address);

use Email::MIME::RFC2047::Decoder;
use Email::MIME::RFC2047::MailboxList;

sub new {
    my $class = shift;

    my $self;

    if (@_ >= 2) {
        $self = { @_ };
    }
    else {
        $self = $_[0];
    }

    return bless($self, $class);
}

#sub _parse {
#    my ($class, $string, $decoder) = @_;
#    my $string_ref = ref($string) ? $string : \$string;
#
#    $decoder ||= Email::MIME::RFC2047::Decoder->new();
#
#    my $name = $decoder->decode_phrase($string_ref);
#    return $class->_parse_error($string_ref, 'group name')
#        if $name eq '';
#
#    $$string_ref =~ /\G:/cg
#        or return $class->_parse_error($string_ref, 'group');
#
#    my $mailbox_list;
#
#    if ($$string_ref =~ /\G\s*;\s*/cg) {
#        $mailbox_list = Email::MIME::RFC2047::MailboxList->new();
#    }
#    else {
#        $mailbox_list = Email::MIME::RFC2047::MailboxList->parse(
#            $string_ref, $decoder
#        );
#
#        $$string_ref =~ /\G;\s*/cg
#            or return $class->_parse_error($string_ref, 'group');
#    }
#
#    my $group = $class->new(
#        name         => $name,
#        mailbox_list => $mailbox_list,
#    );
#
#    if (!ref($string) && pos($string) < length($string)) {
#        return $class->_parse_error($string_ref);
#    }
#
#    return $group;
#}

sub name {
    my $self = shift;

    my $old_name = $self->{name};
    $self->{name} = $_[0] if @_;

    return $old_name;
}

sub mailbox_list {
    my $self = shift;

    my $old_mailbox_list = $self->{mailbox_list};
    $self->{mailbox_list} = $_[0] if @_;

    return $old_mailbox_list;
}

sub format {
    my ($self, $encoder) = @_;
    $encoder ||= Email::MIME::RFC2047::Encoder->new();

    my $name = $self->{name};
    die("empty group name") if !defined($name) || $name eq '';

    my $result = $encoder->encode_phrase($name) . ': ';

    my $mailbox_list = $self->{mailbox_list};
    $result .= $mailbox_list->format($encoder) if $mailbox_list;

    $result .= ';';

    return $result;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Email::MIME::RFC2047::Group - Handling of MIME encoded mailbox groups

=head1 VERSION

version 0.95

=head1 SYNOPSIS

    use Email::MIME::RFC2047::Group;

    my $group = Email::MIME::RFC2047::Group->parse($string);
    print $group->name, "\n";
    my @mailboxes = $group->mailbox_list->items;

    my $group = Email::MIME::RFC2047::Group->new(
        name         => $name,
        mailbox_list => $mailbox_list,
    );
    $email->header_set('To', $group->format());

=head1 DESCRIPTION

This module handles RFC 2822 C<group>s.

=head1 CONSTRUCTOR

=head2 new

    my $group = Email::MIME::RFC2047::Group->new(
        name         => $name,
        mailbox_list => $mailbox_list,
    );

Creates a new Email::MIME::RFC2047::Group object, optionally with a
display name C<$name> and an mailbox list C<$mailbox_list>.

=head1 METHODS

=head2 name

    my $name = $group->name;
    $group->name($new_name);

Gets or sets the display name of the group.

=head2 mailbox_list

    my $mailbox_list = $group->mailbox_list;
    $group->mailbox_list($new_mailbox_list);

Gets or sets the mailbox list of the group.

=head2 format

    my $string = $group->format([$encoder]);

Returns the formatted string for use in a message header.

C<$encoder> is an optional L<Email::MIME::RFC2047::Encoder> object used for
encoding display names with non-ASCII characters. If it isn't provided, a
default UTF-8 encoder is used.

=head1 AUTHOR

Nick Wellnhofer <wellnhofer@aevum.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Nick Wellnhofer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
