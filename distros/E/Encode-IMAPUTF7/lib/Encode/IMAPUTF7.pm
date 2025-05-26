package Encode::IMAPUTF7 1.07;
use strict;
use warnings;

use parent qw(Encode::Encoding);

# ABSTRACT: modification of UTF-7 encoding for IMAP

__PACKAGE__->Define('IMAP-UTF-7', 'imap-utf-7');

use Encode ();
use MIME::Base64;

#pod =head1 SYNOPSIS
#pod
#pod     use Encode qw/encode decode/;
#pod     use Encode::IMAPUTF7;
#pod
#pod     print encode('IMAP-UTF-7', 'Répertoire');
#pod     print decode('IMAP-UTF-7', 'R&AOk-pertoire');
#pod
#pod =head1 ABSTRACT
#pod
#pod IMAP mailbox names are encoded in a modified UTF-7 when names contains
#pod international characters outside of the printable ASCII range. The modified
#pod UTF-7 encoding is defined in RFC2060 (section 5.1.3).
#pod
#pod =head2 RFC2060 - section 5.1.3 - Mailbox International Naming Convention
#pod
#pod By convention, international mailbox names are specified using a modified
#pod version of the UTF-7 encoding described in [UTF-7].  The purpose of these
#pod modifications is to correct the following problems with UTF-7:
#pod
#pod =for :list
#pod 1.  UTF-7 uses the "+" character for shifting; this conflicts with the common
#pod     use of "+" in mailbox names, in particular USENET newsgroup names.
#pod 2.  UTF-7's encoding is BASE64 which uses the "/" character; this conflicts
#pod     with the use of "/" as a popular hierarchy delimiter.
#pod 3.  UTF-7 prohibits the unencoded usage of "\"; this conflicts with the use of
#pod     "\" as a popular hierarchy delimiter.
#pod 4.  UTF-7 prohibits the unencoded usage of "~"; this conflicts with the use of
#pod     "~" in some servers as a home directory indicator.
#pod 5.  UTF-7 permits multiple alternate forms to represent the same string; in
#pod     particular, printable US-ASCII chararacters can be represented in encoded
#pod     form.
#pod
#pod In modified UTF-7, printable US-ASCII characters except for "&" represent
#pod themselves; that is, characters with octet values 0x20-0x25 and 0x27-0x7e.  The
#pod character "&" (0x26) is represented by the two-octet sequence "&-".
#pod
#pod All other characters (octet values 0x00-0x1f, 0x7f-0xff, and all Unicode 16-bit
#pod octets) are represented in modified BASE64, with a further modification from
#pod [UTF-7] that "," is used instead of "/".  Modified BASE64 MUST NOT be used to
#pod represent any printing US-ASCII character which can represent itself.
#pod
#pod "&" is used to shift to modified BASE64 and "-" to shift back to US- ASCII.
#pod All names start in US-ASCII, and MUST end in US-ASCII (that is, a name that
#pod ends with a Unicode 16-bit octet MUST end with a "- ").
#pod
#pod For example, here is a mailbox name which mixes English, Japanese,
#pod and Chinese text: C<~peter/mail/&ZeVnLIqe-/&U,BTFw->
#pod
#pod =cut

# Algorithms taken from Unicode::String by Gisle Aas
# Code directly borrowed from Encode::Unicode::UTF7 by Dan Kogai

# Directly from the definition in RFC2060:
# Ampersand (\x26) is represented as a special case
my $re_asis =     qr/(?:[\x20-\x25\x27-\x7e])/; # printable US-ASCII except "&" represents itself
my $re_encoded = qr/(?:[^\x20-\x7e])/; # Everything else are represented by modified base64

my $e_utf16 = Encode::find_encoding("UTF-16BE");

sub needs_lines { 1 };

sub encode($$;$) {
    my ( $obj, $str, $chk ) = @_;
    my $len = length($str);
    pos($str) = 0;
    my $bytes = '';
    while ( pos($str) < $len ) {
        if ( $str =~ /\G($re_asis+)/ogc ) {
            $bytes .= $1;
        } elsif ( $str =~ /\G&/ogc ) {
            $bytes .= "&-";
        } elsif ( $str =~ /\G($re_encoded+)/ogsc ) {
            my $s = $1;
            my $base64 = encode_base64( $e_utf16->encode($s), '' );
            $base64 =~ s/=+$//;
            $base64 =~ s/\//,/g;
            $bytes .= "&$base64-";
        } else {
            die "This should not happen! (pos=" . pos($str) . ")";
        }
    }
    $_[1] = '' if $chk;
    return $bytes;
}

sub decode($$;$) {
    my ( $obj, $bytes, $chk ) = @_;
    my $len = length($bytes);
    my $str = "";
    pos($bytes) = 0;
    while ( pos($bytes) < $len ) {
        if ( $bytes =~ /\G([^&]+)/ogc ) {
            $str .= $1;
        } elsif ( $bytes =~ /\G\&-/ogc ) {
            $str .= "&";
        } elsif ( $bytes =~ /\G\&([A-Za-z0-9+,]+)-?/ogsc ) {
            my $base64 = $1;
            $base64 =~ s/,/\//g;
            my $pad = length($base64) % 4;
            $base64 .= "=" x ( 4 - $pad ) if $pad;
            $str .= $e_utf16->decode( decode_base64($base64) );
        } elsif ( $bytes =~ /\G\&/ogc ) {
            $^W and warn "Bad IMAP-UTF7 data escape";
            $str .= "&";
        } else {
            die "This should not happen " . pos($bytes);
        }
    }
    $_[1] = '' if $chk;
    return $str;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Encode::IMAPUTF7 - modification of UTF-7 encoding for IMAP

=head1 VERSION

version 1.07

=head1 SYNOPSIS

    use Encode qw/encode decode/;
    use Encode::IMAPUTF7;

    print encode('IMAP-UTF-7', 'Répertoire');
    print decode('IMAP-UTF-7', 'R&AOk-pertoire');

=head1 PERL VERSION

This library should run on perls released even a long time ago.  It should
work on any version of perl released in the last five years.

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to
lower the minimum required perl.

=head1 ABSTRACT

IMAP mailbox names are encoded in a modified UTF-7 when names contains
international characters outside of the printable ASCII range. The modified
UTF-7 encoding is defined in RFC2060 (section 5.1.3).

=head2 RFC2060 - section 5.1.3 - Mailbox International Naming Convention

By convention, international mailbox names are specified using a modified
version of the UTF-7 encoding described in [UTF-7].  The purpose of these
modifications is to correct the following problems with UTF-7:

=over 4

=item 1

UTF-7 uses the "+" character for shifting; this conflicts with the common use of "+" in mailbox names, in particular USENET newsgroup names.

=item 2

UTF-7's encoding is BASE64 which uses the "/" character; this conflicts with the use of "/" as a popular hierarchy delimiter.

=item 3

UTF-7 prohibits the unencoded usage of "\"; this conflicts with the use of "\" as a popular hierarchy delimiter.

=item 4

UTF-7 prohibits the unencoded usage of "~"; this conflicts with the use of "~" in some servers as a home directory indicator.

=item 5

UTF-7 permits multiple alternate forms to represent the same string; in particular, printable US-ASCII chararacters can be represented in encoded form.

=back

In modified UTF-7, printable US-ASCII characters except for "&" represent
themselves; that is, characters with octet values 0x20-0x25 and 0x27-0x7e.  The
character "&" (0x26) is represented by the two-octet sequence "&-".

All other characters (octet values 0x00-0x1f, 0x7f-0xff, and all Unicode 16-bit
octets) are represented in modified BASE64, with a further modification from
[UTF-7] that "," is used instead of "/".  Modified BASE64 MUST NOT be used to
represent any printing US-ASCII character which can represent itself.

"&" is used to shift to modified BASE64 and "-" to shift back to US- ASCII.
All names start in US-ASCII, and MUST end in US-ASCII (that is, a name that
ends with a Unicode 16-bit octet MUST end with a "- ").

For example, here is a mailbox name which mixes English, Japanese,
and Chinese text: C<~peter/mail/&ZeVnLIqe-/&U,BTFw->

=head1 AUTHOR

Sava Chankov <sava@cpan.org>

=head1 CONTRIBUTOR

=for stopwords Ricardo Signes

Ricardo Signes <rjbs@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2005 by Sava Chankov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
