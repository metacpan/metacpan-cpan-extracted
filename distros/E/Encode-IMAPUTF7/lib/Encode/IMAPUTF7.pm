#
# $Id: IMAPUTF7.pm 3398 2009-04-21 13:18:16Z makholm $
#
package Encode::IMAPUTF7;
use strict;
no warnings 'redefine';
use base qw(Encode::Encoding);
__PACKAGE__->Define('IMAP-UTF-7', 'imap-utf-7');
our $VERSION = '1.05';
use MIME::Base64;
use Encode;

#
# Algorithms taken from Unicode::String by Gisle Aas
# Code directly borrowed from Encode::Unicode::UTF7 by Dan Kogai
#

# Directly from the definition in RFC2060:
# Ampersand (\x26) is represented as a special case
my $re_asis =     qr/(?:[\x20-\x25\x27-\x7e])/; # printable US-ASCII except "&" represents itself
my $re_encoded = qr/(?:[^\x20-\x7e])/; # Everything else are represented by modified base64

my $e_utf16 = find_encoding("UTF-16BE");

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

=head1 NAME

Encode::IMAPUTF7 - modification of UTF-7 encoding for IMAP

=head1 SYNOPSIS

  use Encode qw/encode decode/;

  print encode('IMAP-UTF-7', 'Répertoire');
  print decode('IMAP-UTF-7', R&AOk-pertoire');

=head1 ABSTRACT

IMAP mailbox names are encoded in a modified UTF7 when names contains 
international characters outside of the printable ASCII range. The
modified UTF-7 encoding is defined in RFC2060 (section 5.1.3).

There is another CPAN module with same purpose, Unicode::IMAPUtf7. However, it
works correctly only with strings, which encoded form does not
contain plus sign. For example, the Cyrillic string
\x{043f}\x{0440}\x{0435}\x{0434}\x{043b}\x{043e}\x{0433} is represented in UTF-7 as
+BD8EQAQ1BDQEOwQ+BDM- Note the second plus sign 4 characters before the end. 
Unicode::IMAPUtf7 encodes the above string as +BD8EQAQ1BDQEOwQ&BDM- 
which is not valid modified UTF-7 (the ampersand and
the plus are swapped). The problem is solved by the current module,
which is slightly modified Encode::Unicode::UTF7 and has nothing common with
Unicode::IMAPUtf7.

=head1 RFC2060 - section 5.1.3 - Mailbox International Naming Convention

By convention, international mailbox names are specified using a
modified version of the UTF-7 encoding described in [UTF-7].  The
purpose of these modifications is to correct the following problems
with UTF-7:

1) UTF-7 uses the "+" character for shifting; this conflicts with
   the common use of "+" in mailbox names, in particular USENET
   newsgroup names.

2) UTF-7's encoding is BASE64 which uses the "/" character; this
   conflicts with the use of "/" as a popular hierarchy delimiter.

3) UTF-7 prohibits the unencoded usage of "\"; this conflicts with
   the use of "\" as a popular hierarchy delimiter.

4) UTF-7 prohibits the unencoded usage of "~"; this conflicts with
   the use of "~" in some servers as a home directory indicator.

5) UTF-7 permits multiple alternate forms to represent the same
   string; in particular, printable US-ASCII chararacters can be
   represented in encoded form.

In modified UTF-7, printable US-ASCII characters except for "&"
represent themselves; that is, characters with octet values 0x20-0x25
and 0x27-0x7e.  The character "&" (0x26) is represented by the two-
octet sequence "&-".

All other characters (octet values 0x00-0x1f, 0x7f-0xff, and all
Unicode 16-bit octets) are represented in modified BASE64, with a
further modification from [UTF-7] that "," is used instead of "/".
Modified BASE64 MUST NOT be used to represent any printing US-ASCII
character which can represent itself.

"&" is used to shift to modified BASE64 and "-" to shift back to US-
ASCII.  All names start in US-ASCII, and MUST end in US-ASCII (that
is, a name that ends with a Unicode 16-bit octet MUST end with a "-
").

For example, here is a mailbox name which mixes English, Japanese,
and Chinese text: ~peter/mail/&ZeVnLIqe-/&U,BTFw-

=head1 REQUESTS & BUGS

Please report any requests, suggestions or bugs via the RT bug-tracking system 
at http://rt.cpan.org/ or email to bug-Encode-IMAPUTF7@rt.cpan.org. 

http://rt.cpan.org/NoAuth/Bugs.html?Dist=Encode-IMAPUTF7 is the RT queue for Encode::IMAPUTF7.
Please check to see if your bug has already been reported. 

=head1 COPYRIGHT

Copyright 2005 Sava Chankov

Sava Chankov, sava@cpan.org

This software may be freely copied and distributed under the same
terms and conditions as Perl.

=head1 AUTHORS

Peter Makholm E<lt>peter@makholm.netE<gt>, current maintainer

Sava Chankov E<lt>sava@cpan.orgE<gt>, original author

=head1 SEE ALSO

perl(1), Encode.

=cut
