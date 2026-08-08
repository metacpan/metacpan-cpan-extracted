#!perl

# The shared C ABI (include/mds_abi.h), resolved at runtime through
# Markdown::Simple::_abi_ptr. Consumers such as Punk's markdown mount fetch
# that pointer once at boot, gate on abi_version, and then call the parser
# with no Perl frame in between.
#
# There is no second distribution here to consume it, so the coverage comes
# from _abi_selftest, which drives the table the way a consumer would: resolve
# the pointer, check the version, then go through the function pointers rather
# than calling the C directly. If the table is mis-ordered or an entry is
# wired to the wrong function, these fail.

use 5.010;
use strict;
use warnings;
use Test::More;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Markdown::Simple;

# ---- the pointer and the gate -----------------------------------------------

my $ptr = Markdown::Simple::_abi_ptr();
ok defined $ptr, '_abi_ptr returns something';
ok $ptr > 0, 'and it is a usable address';

is Markdown::Simple::_abi_version(), 1, 'compiled against ABI version 1';

is Markdown::Simple::_abi_ptr(), $ptr,
    'the table is a fixed address, not rebuilt per call';

# ---- session_of / session_render / strip through the table ------------------

{
    my $md = Markdown::Simple->new;
    my ($html, $toc, $plain) = Markdown::Simple::_abi_selftest(
        $md, "# Title\n\nSome **text** here.\n\n## Next\n"
    );

    like $html, qr{<h1 id="title">Title</h1>},
        'session_render produced html, with anchors because a toc was asked for';
    like $html, qr{<strong>text</strong>}, 'inline markup rendered';

    is ref $toc, 'ARRAY', 'the toc out-param came back as an arrayref';
    is_deeply $toc, [
        { level => 1, text => 'Title', id => 'title' },
        { level => 2, text => 'Next',  id => 'next'  },
    ], 'with one entry per heading';

    like $plain, qr{^Title}, 'strip produced plain text';
    unlike $plain, qr{<}, 'with no markup left in it';
    unlike $plain, qr{\*\*}, 'and no emphasis delimiters';
}

# ---- session_of rejects a non-session without croaking ----------------------

{
    # A consumer probing whether an SV is renderable must be able to ask
    # without an eval, so session_of returns NULL rather than croaking and
    # the selftest reports that as an empty list.
    my @out = eval {
        Markdown::Simple::_abi_selftest(bless({}, 'Not::A::Session'), 'x')
    };
    is $@, '', 'probing a foreign object does not croak';
    is scalar @out, 0, 'and yields nothing, which is the fall-back signal';

    @out = eval { Markdown::Simple::_abi_selftest(\'plain ref', 'x') };
    is $@, '', 'nor does a plain reference';
    is scalar @out, 0, 'also nothing';

    @out = eval { Markdown::Simple::_abi_selftest('not a ref', 'x') };
    is $@, '', 'nor does a string';
    is scalar @out, 0, 'also nothing';
}

# ---- the sessionless render entry -------------------------------------------

{
    my ($html) = Markdown::Simple::_abi_selftest_render(
        "# Sessionless\n", { heading_ids => 1 }
    );
    like $html, qr{<h1 id="sessionless">Sessionless</h1>},
        'render works with a local arena and flags decoded by flags_from_hv';
}

{
    my ($html) = Markdown::Simple::_abi_selftest_render("# No Ids\n");
    like $html, qr{<h1>No Ids</h1>},
        'and flags_from_hv defaults leave heading ids off';
}

{
    my ($html) = Markdown::Simple::_abi_selftest_render(
        "```perl\nmy \$x = 1;\n```\n", { highlight => 1 }
    );
    like $html, qr{class="esh-}, 'flags_from_hv carried the highlight option through';
}

# ---- flags_from_hv agrees with the documented defaults ----------------------

{
    # GFM is the default preset, so a table renders as a table.
    my ($html) = Markdown::Simple::_abi_selftest_render(
        "| a | b |\n| - | - |\n| 1 | 2 |\n"
    );
    like $html, qr{<table>}, 'a NULL/absent options hash gives the GFM preset';

    my ($cm) = Markdown::Simple::_abi_selftest_render(
        "| a | b |\n| - | - |\n| 1 | 2 |\n", { gfm => 0 }
    );
    unlike $cm, qr{<table>}, 'and gfm => 0 selects strict CommonMark';
}

# ---- errors arrive through the out-param, not as exceptions -----------------

{
    # Nothing in the table croaks; strict_utf8 on malformed bytes is the one
    # failure the parser reports, and it comes back as ($html, $error).
    my $md = Markdown::Simple->new({ strict_utf8 => 1 });
    my @out = eval { Markdown::Simple::_abi_selftest($md, "\xff\xfe bad bytes") };
    is $@, '', 'a malformed document does not croak through the ABI';
    is scalar @out, 2, 'it reports failure as a two-value return';
    ok !defined $out[0], 'with no html';
    like $out[1], qr/UTF-8/i, 'and an error message naming the problem';
}

# ---- output is appended, and stays bytes ------------------------------------

{
    # The ABI deals in raw bytes and never sets the UTF-8 flag; the caller
    # knows whether its input was characters. A consumer writing an HTTP body
    # depends on this, since Content-Length counts bytes.
    my $md = Markdown::Simple->new;
    my $src = "# Caf\x{c3}\x{a9}\n";     # utf-8 octets, flag off
    my ($html) = Markdown::Simple::_abi_selftest($md, $src);
    ok !utf8::is_utf8($html), 'the ABI leaves the UTF-8 flag off its output';
    like $html, qr/\x{c3}\x{a9}/, 'and passes the octets through unchanged';
}

done_testing();
