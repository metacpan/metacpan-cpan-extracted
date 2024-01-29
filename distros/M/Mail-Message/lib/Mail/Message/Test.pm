# Copyrights 2001-2023 by [Mark Overmeer <markov@cpan.org>].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.03.
# This code is part of distribution Mail-Message.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package Mail::Message::Test;
use vars '$VERSION';
$VERSION = '3.015';

use base 'Exporter';

use strict;
use warnings;

use File::Copy 'copy';
use List::Util 'first';
use IO::File;            # to overrule open()
use File::Spec;
use Cwd qw(getcwd);
use Sys::Hostname qw(hostname);
use Test::More;


our @EXPORT =
  qw/compare_message_prints reproducable_text
     $raw_html_data
     $crlf_platform
    /;

our $crlf_platform = $^O =~ m/mswin32/i;

#
# Compare the text of two messages, rather strict.
# On CRLF platforms, the Content-Length may be different.
#

sub compare_message_prints($$$)
{   my ($first, $second, $label) = @_;

    if($crlf_platform)
    {   $first  =~ s/Content-Length: (\d+)/Content-Length: <removed>/g;
        $second =~ s/Content-Length: (\d+)/Content-Length: <removed>/g;
    }

    is($first, $second, $label);
}

#
# Strip message text down the things which are the same on all
# platforms and all situations.
#

sub reproducable_text($)
{   my $text  = shift;
    my @lines = split /^/m, $text;
    foreach (@lines)
    {   s/((?:references|message-id|date|content-length)\: ).*/$1<removed>/i;
        s/boundary-\d+/boundary-<removed>/g;
    }
    join '', @lines;
}

#
# A piece of HTML text which is used in some tests.
#

our $raw_html_data = <<'TEXT';
<HTML>
<HEAD>
<TITLE>My home page</TITLE>
</HEAD>
<BODY BGCOLOR=red>

<H1>Life according to Brian</H1>

This is normal text, but not in a paragraph.<P>New paragraph
in a bad way.

And this is just a continuation.  When texts get long, they must be
auto-wrapped; and even that is working already.

<H3>Silly subsection at once</H3>
<H1>and another chapter</H1>
<H2>again a section</H2>
<P>Normal paragraph, which contains an <IMG
SRC=image.gif>, some
<I>italics with linebreak
</I> and <TT>code</TT>

<PRE>
And now for the preformatted stuff
   it should stay as it was
      even   with   strange blanks
  and indentations
</PRE>

And back to normal text...
<UL>
<LI>list item 1
    <OL>
    <LI>list item 1.1
    <LI>list item 1.2
    </OL>
<LI>list item 2
</UL>
</BODY>
</HTML>
TEXT

1;
