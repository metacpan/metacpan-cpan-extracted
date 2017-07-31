package Email::MIME::RFC2047::Mailbox;
$Email::MIME::RFC2047::Mailbox::VERSION = '0.96';
use strict;
use warnings;

# ABSTRACT: Handling of MIME encoded mailboxes

use base qw(Email::MIME::RFC2047::Address);

use Email::MIME::RFC2047::Decoder;
use Email::MIME::RFC2047::Encoder;

my $domain_part_re = qr/[A-Za-z0-9](?:[A-Za-z0-9-]*[A-Za-z0-9])?/;
my $addr_spec_re   = qr{
    [\w&'*+.\/=?^{}~-]+
    \@
    $domain_part_re (?: \. $domain_part_re)+
}x;

sub new {
    my $class = shift;

    my $self;

    if (@_ >= 2) {
        $self = { @_ };
    }
    elsif (ref($_[0])) {
        $self = $_[0];
    }
    else {
        $self = { address => $_[0] };
    }

    return bless($self, $class);
}

sub parse {
    my ($class, $string, $decoder) = @_;
    my $string_ref = ref($string) ? $string : \$string;

    my $mailbox;

    if ($$string_ref =~ /\G\s*($addr_spec_re)\s*/cg) {
        $mailbox = $class->new($1);
    }
    else {
        $decoder ||= Email::MIME::RFC2047::Decoder->new();
        my $name = $decoder->decode_phrase($string_ref);

        $$string_ref =~ /\G<\s*($addr_spec_re)\s*>\s*/cg
            or return $class->_parse_error($string_ref, 'mailbox');
        my $addr_spec = $1;

        $mailbox = $class->new(name => $name, address => $addr_spec);
    }

    if (!ref($string) && pos($string) < length($string)) {
        return $class->_parse_error($string_ref);
    }

    return $mailbox;
}

sub name {
    my $self = shift;

    my $old_name = $self->{name};
    $self->{name} = $_[0] if @_;

    return $old_name;
}

sub address {
    my $self = shift;

    my $old_address = $self->{address};
    $self->{address} = $_[0] if @_;

    return $old_address;
}

sub format {
    my ($self, $encoder) = @_;

    my $name = $self->{name};
    my $address = $self->{address};
    defined($address) && $address =~ /^$addr_spec_re\z/
        or die ("invalid email address");

    my $result;

    if (!defined($name) || $name eq '') {
        $result = $address;
    }
    else {
        $encoder ||= Email::MIME::RFC2047::Encoder->new();
        my $encoded_name = $encoder->encode_phrase($name);

        $result = "$encoded_name <$address>";
    }

    return $result;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Email::MIME::RFC2047::Mailbox - Handling of MIME encoded mailboxes

=head1 VERSION

version 0.96

=head1 SYNOPSIS

    use Email::MIME::RFC2047::Mailbox;

    my $mailbox = Email::MIME::RFC2047::Mailbox->parse($string);
    print $mailbox->name,    "\n";
    print $mailbox->address, "\n";

    my $mailbox = Email::MIME::RFC2047::Mailbox->new(
        name    => $name,
        address => $address,
    );
    $email->header_set('To', $mailbox->format());

=head1 DESCRIPTION

This module handles RFC 2822 C<mailbox>es.

=head1 CLASS METHODS

=head2 parse

    my $mailbox = Email::MIME::RFC2047::Mailbox->parse($string, [$decoder])

Parse a RFC 2822 C<mailbox>. Returns a Email::MIME::RFC2047::Mailbox object.
C<$decoder> is an optional L<Email::MIME::RFC2047::Decoder>. If it isn't
provided, a new temporary decoder is used.

=head1 CONSTRUCTOR

=head2 new

    my $mailbox = Email::MIME::RFC2047::Mailbox->new(
        name    => $name,
        address => $address,
    );

Creates a new Email::MIME::RFC2047::Mailbox object, optionally with a
display name C<$name> and an email address C<$address>.

=head1 METHODS

=head2 name

    my $name = $mailbox->name;
    $mailbox->name($new_name);

Gets or sets the display name of the mailbox.

=head2 address

    my $address = $mailbox->address;
    $mailbox->address($new_address);

Gets or sets the email address of the mailbox.

=head2 format

    my $string = $mailbox->format([$encoder]);

Returns the formatted mailbox string for use in a message header.

C<$encoder> is an optional L<Email::MIME::RFC2047::Encoder> object used for
encoding display names with non-ASCII characters. If it isn't provided, a
default UTF-8 encoder will be used.

=head1 AUTHOR

Nick Wellnhofer <wellnhofer@aevum.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Nick Wellnhofer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
