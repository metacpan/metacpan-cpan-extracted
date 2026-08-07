#!/usr/bin/perl -w

BEGIN { # CPAN users don't have ME::*, so use eval
  eval 'use ME::FindLibs'
}

use Test::More tests => 9;
use HTML::Defang;

use strict;
use warnings;

# Comment / CDATA tokenization has a pile of browser quirks that a regex based
# parser does not model directly:
#
#   <!-->        is a COMPLETE (empty) comment in HTML5
#   <!--->       is a COMPLETE (empty) comment in HTML5
#   --!>         closes a comment (comment-end-bang), like -->
#   <![CDATA[..  in HTML (non-foreign) content is a BOGUS COMMENT that ends at
#                the first '>', NOT at ]]>
#
# HTML::Defang does not try to match the browser's comment boundaries exactly.
# Instead it relies on a stronger invariant: it consumes a *superset* of the
# questionable region, strips *every* '--' from the captured data, and re-emits
# it as a single well formed <!-- ... --> comment. Because the data can no
# longer contain '--' (a run of N dashes collapses to N mod 2), the output
# comment has no internal '-->' or '--!>', so a browser reading our output
# cannot break out of the comment early. Anything active that ends up outside
# the comment is parsed and defanged normally.
#
# The '--' stripping is therefore security critical: if a future change let a
# '-->' survive inside the comment body, a browser could close the wrapper
# early and run whatever we tucked inside. These tests lock that down.

my $D = HTML::Defang->new();

# Oracle: emulate a browser removing well formed comments (safe to do with a
# non greedy <!--...--> match precisely *because* we guarantee no internal
# '-->'), then check whether any live (non-defanged) event handler survives.
# A surviving handler would be script that executes in a real browser.
sub is_safe {
  my ($Html, $Name) = @_;
  my $Out = $D->defang($Html);
  (my $Stripped = $Out) =~ s/<!--.*?-->//gs;
  ok($Stripped !~ /(?<!defang_)\bon\w+\s*=/i, $Name)
    or diag("defanged output still has a live handler after comment strip:\n  $Out");
}

# Short/empty comments: browser closes at <!--> / <!---> and runs what follows.
is_safe(q{<!--><img src=x onerror=alert(1)>},  "empty comment <!--> breakout");
is_safe(q{<!---><img src=x onerror=alert(1)>}, "empty comment <!---> breakout");

# comment-end-bang and stray-dash forms that a browser treats as comment ends.
is_safe(q{<!-- --!-> <img src=x onerror=alert(1)> -->}, "comment-end-bang --!-> breakout");
is_safe(q{<!-- ---> <img src=x onerror=alert(1)> -->},  "stray dashes ---> breakout");
is_safe(q{<!-- a---->b <img src=x onerror=alert(1)> -->}, "embedded ----> breakout");

# CDATA in HTML content is a bogus comment ending at the first '>'; we treat it
# as ]]>-terminated. Either way the payload must not come out live.
is_safe(q{<![CDATA[ ]> <img src=x onerror=alert(1)> ]]>}, "CDATA bogus-comment boundary breakout");
is_safe(q{<![CDATA[<img src=x onerror=alert(1)>},         "CDATA with no ]]> close");

# Nested comment openers and a would-be reopened comment.
is_safe(q{<!-- <!-- --> <img src=x onerror=alert(1)> -->}, "nested <!-- opener breakout");

# The load-bearing invariant, asserted directly: a defanged comment body must
# not contain '--', so the only comment-closer is the single trailing '-->'.
# Feed a nasty run of dashes and confirm every emitted comment body is clean.
{
  my $Out = $D->defang(q{<!-- ----- x --!-- ----> -->});
  my @Bodies = $Out =~ /<!--(.*?)-->/gs;    # non-greedy: each comment's body
  ok(@Bodies && !grep(/--/, @Bodies), "no '--' survives inside a defanged comment body")
    or diag("a comment body still contains '--':\n  $Out");
}
