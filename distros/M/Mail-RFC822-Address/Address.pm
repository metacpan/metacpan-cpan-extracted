package Mail::RFC822::Address;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;

@ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

@EXPORT_OK = qw( valid validlist );

@EXPORT = qw(
	
);
$VERSION = '0.3';


my $rfc822re;

# Preloaded methods go here.
my $lwsp = "(?:(?:\\r\\n)?[ \\t])";

sub make_rfc822re {
#   Basic lexical tokens are specials, domain_literal, quoted_string, atom, and
#   comment.  We must allow for lwsp (or comments) after each of these.
#   This regexp will only work on addresses which have had comments stripped 
#   and replaced with lwsp.

    my $specials = '()<>@,;:\\\\".\\[\\]';
    my $controls = '\\000-\\031';

    my $dtext = "[^\\[\\]\\r\\\\]";
    my $domain_literal = "\\[(?:$dtext|\\\\.)*\\]$lwsp*";

    my $quoted_string = "\"(?:[^\\\"\\r\\\\]|\\\\.|$lwsp)*\"$lwsp*";

#   Use zero-width assertion to spot the limit of an atom.  A simple 
#   $lwsp* causes the regexp engine to hang occasionally.
    my $atom = "[^$specials $controls]+(?:$lwsp+|\\Z|(?=[\\[\"$specials]))";
    my $word = "(?:$atom|$quoted_string)";
    my $localpart = "$word(?:\\.$lwsp*$word)*";

    my $sub_domain = "(?:$atom|$domain_literal)";
    my $domain = "$sub_domain(?:\\.$lwsp*$sub_domain)*";

    my $addr_spec = "$localpart\@$lwsp*$domain";

    my $phrase = "$word*";
    my $route = "(?:\@$domain(?:,\@$lwsp*$domain)*:$lwsp*)";
    my $route_addr = "\\<$lwsp*$route?$addr_spec\\>$lwsp*";
    my $mailbox = "(?:$addr_spec|$phrase$route_addr)";

    my $group = "$phrase:$lwsp*(?:$mailbox(?:,\\s*$mailbox)*)?;\\s*";
    my $address = "(?:$mailbox|$group)";

    return "$lwsp*$address";
}

sub strip_comments {
    my $s = shift;
#   Recursively remove comments, and replace with a single space.  The simpler
#   regexps in the Email Addressing FAQ are imperfect - they will miss escaped
#   chars in atoms, for example.

    while ($s =~ s/^((?:[^"\\]|\\.)*
                    (?:"(?:[^"\\]|\\.)*"(?:[^"\\]|\\.)*)*)
                    \((?:[^()\\]|\\.)*\)/$1 /osx) {}
    return $s;
}

#   valid: returns true if the parameter is an RFC822 valid address
#
sub valid ($) {
    my $s = strip_comments(shift);

    if (!$rfc822re) {
        $rfc822re = make_rfc822re();
    }

    return $s =~ m/^$rfc822re$/so;
}

#   validlist: In scalar context, returns true if the parameter is an RFC822 
#              valid list of addresses.
#
#              In list context, returns an empty list on failure (an invalid
#              address was found); otherwise a list whose first element is the
#              number of addresses found and whose remaining elements are the
#              addresses.  This is needed to disambiguate failure (invalid)
#              from success with no addresses found, because an empty string is
#              a valid list.

sub validlist ($) {
    my $s = strip_comments(shift);

    if (!$rfc822re) {
        $rfc822re = make_rfc822re();
    }
    # * null list items are valid according to the RFC
    # * the '1' business is to aid in distinguishing failure from no results

    my @r;
    if($s =~ m/^(?:$rfc822re)?(?:,(?:$rfc822re)?)*$/so) {
        while($s =~ m/(?:^|,$lwsp*)($rfc822re)/gos) {
            push @r, $1;
        }
        return wantarray ? (scalar(@r), @r) : 1;
    }
    else {
        return wantarray ? () : 0;
    }
}

1;
__END__

=head1 NAME

Mail::RFC822::Address - Perl extension for validating email addresses 
according to RFC822

=head1 SYNOPSIS

  use Mail::RFC822::Address qw(valid validlist);

  if (valid("pdw@ex-parrot.com")) {
      print "That's a valid address\n";
  }

  if (validlist("pdw@ex-parrot.com, other@elsewhere.com")) {
      print "That's a valid list of addresses\n";
  }

=head1 DESCRIPTION

Mail::RFC822::Address validates email addresses against the grammar described
in RFC 822 using regular expressions.  How to validate a user supplied email
address is a FAQ (see perlfaq9): the only sure way to see if a supplied email
address is genuine is to send an email to it and see if the user recieves it.
The one useful check that can be performed on an address is to check that the
email address is syntactically valid.  That is what this module does.

This module is functionally equivalent to RFC::RFC822::Address, but uses
regular expressions rather than the Parse::RecDescent parser.  This means that
startup time is greatly reduced making it suitable for use in transient scripts
such as CGI scripts.

=head2 valid ( address )

Returns true or false to indicate if address is an RFC822 valid address.

=head2 validlist ( addresslist )

In scalar context, returns true if the parameter is an RFC822 valid list of
addresses.

In list context, returns an empty list on failure (an invalid address was
found); otherwise a list whose first element is the number of addresses found
and whose remaining elements are the addresses.  This is needed to disambiguate
failure (invalid) from success with no addresses found, because an empty string
is a valid list.

=head1 AUTHOR

Paul Warren, pdw@ex-parrot.com

=head1 CREDITS

Most of the test suite in test.pl is taken from RFC::RFC822::Address, written
by Abigail, abigail@foad.org

=head1 COPYRIGHT and LICENSE

This program is copyright 2001-2002 by Paul Warren.

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions: The above copyright notice and this
permission notice shall be included in all copies or substantial portions of
the Software.  

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHOR BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.  

=head1 SEE ALSO

RFC::RFC822::Address, Mail::Address

=cut
