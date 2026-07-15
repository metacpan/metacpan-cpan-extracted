use strict;
use warnings;
use Test::More;
use Eshu;

sub hl { Eshu->highlight_string($_[0], lang => 'pod') }

# ── POD commands ──────────────────────────────────────────────────

{
    my $got = hl("=pod\n");
    like($got, qr{<span class="esh-d">=pod}, '=pod command');
}

{
    my $got = hl("=cut\n");
    like($got, qr{<span class="esh-d">=cut}, '=cut command');
}

{
    my $got = hl("=head1 NAME\n");
    like($got, qr{<span class="esh-d">=head1 NAME}, '=head1 with title');
}

{
    my $got = hl("=head2 DESCRIPTION\n");
    like($got, qr{<span class="esh-d">=head2 DESCRIPTION}, '=head2 with title');
}

{
    my $got = hl("=head3 Details\n");
    like($got, qr{<span class="esh-d">=head3 Details}, '=head3 with title');
}

{
    my $got = hl("=head4 Sub-section\n");
    like($got, qr{<span class="esh-d">=head4 Sub-section}, '=head4 with title');
}

{
    my $got = hl("=over 4\n");
    like($got, qr{<span class="esh-d">=over 4}, '=over with indent');
}

{
    my $got = hl("=item *\n");
    like($got, qr{<span class="esh-d">=item \*}, '=item bullet');
}

{
    my $got = hl("=item 1.\n");
    like($got, qr{<span class="esh-d">=item 1\.}, '=item numbered');
}

{
    my $got = hl("=back\n");
    like($got, qr{<span class="esh-d">=back}, '=back command');
}

{
    my $got = hl("=begin html\n");
    like($got, qr{<span class="esh-d">=begin html}, '=begin command');
}

{
    my $got = hl("=end html\n");
    like($got, qr{<span class="esh-d">=end html}, '=end command');
}

{
    my $got = hl("=for html <p>inline</p>\n");
    like($got, qr{<span class="esh-d">=for html}, '=for command');
}

{
    my $got = hl("=encoding utf-8\n");
    like($got, qr{<span class="esh-d">=encoding utf-8}, '=encoding command');
}

# ── plain text paragraphs ─────────────────────────────────────────

{
    my $got = hl("=head1 NAME\n\nSome plain text here.\n");
    # The blank line and text paragraph should appear as esh-d (they're in a POD body)
    like($got, qr{Some plain text here\.}, 'body text is included in output');
}

{
    my $got = hl("=pod\n\nFirst para.\n\nSecond para.\n\n=cut\n");
    like($got, qr{First para\.},  'first paragraph text preserved');
    like($got, qr{Second para\.}, 'second paragraph text preserved');
}

# ── verbatim paragraphs ───────────────────────────────────────────

{
    my $got = hl("=head1 EXAMPLES\n\n    my \$x = 42;\n");
    like($got, qr{<span class="esh-k">my</span>}, 'verbatim paragraph: my keyword highlighted');
}

{
    my $got = hl("=pod\n\n    sub foo {\n        return 1;\n    }\n");
    like($got, qr{<span class="esh-k">sub</span> foo},  'verbatim sub declaration highlighted');
    like($got, qr{<span class="esh-k">return</span>},    'verbatim body line: return highlighted');
    like($got, qr{    \}},                             'verbatim closing brace preserved');
}

# ── HTML safety ──────────────────────────────────────────────────

{
    my $got = hl("=head1 Entities & <angle brackets>\n");
    like($got, qr{&amp;},  'ampersand in POD command is HTML-escaped');
    like($got, qr{&lt;},   'less-than in POD command is HTML-escaped');
    like($got, qr{&gt;},   'greater-than in POD command is HTML-escaped');
}

{
    my $got = hl("=pod\n\nSee C<< foo < bar >>.\n");
    like($got, qr{&lt;&lt;}, 'angle brackets in POD text are HTML-escaped');
}

# ── combined full POD document ────────────────────────────────────

{
    my $src = <<'END';
=head1 NAME

MyModule - does things

=head1 SYNOPSIS

    use MyModule;
    my $obj = MyModule->new;

=head2 Constructor

=over 4

=item new(%args)

Create a new object.

=back

=head1 DESCRIPTION

This module does useful things.

=cut
END
    my $got = hl($src);
    like($got, qr{<span class="esh-d">=head1 NAME},      '=head1 NAME in full doc');
    like($got, qr{<span class="esh-d">=head1 SYNOPSIS},  '=head1 SYNOPSIS in full doc');
    like($got, qr{<span class="esh-k">use</span> MyModule},        'verbatim use line highlighted');
    like($got, qr{<span class="esh-d">=head2 Constructor},'=head2 in full doc');
    like($got, qr{<span class="esh-d">=over 4},           '=over in full doc');
    like($got, qr{<span class="esh-d">=item new\(%args\)},'=item in full doc');
    like($got, qr{<span class="esh-d">=back},            '=back in full doc');
    like($got, qr{<span class="esh-d">=head1 DESCRIPTION},'=head1 DESCRIPTION in full doc');
    like($got, qr{<span class="esh-d">=cut},             '=cut in full doc');
    like($got, qr{This module does useful things\.}, 'body text in full doc');
}


# ── more POD commands ─────────────────────────────────────────────

{
    my $got = hl("=head1 FUNCTIONS\n");
    like($got, qr{<span class="esh-d">=head1 FUNCTIONS}, '=head1 FUNCTIONS command');
}

{
    my $got = hl("=head2 new\n");
    like($got, qr{<span class="esh-d">=head2 new}, '=head2 function name');
}

{
    my $got = hl("=item B<name>\n");
    like($got, qr{<span class="esh-d">=item B&lt;name&gt;}, '=item with inline formatting');
}

{
    my $got = hl("=over\n");
    like($got, qr{<span class="esh-d">=over}, '=over without indent');
}

# ── inline formatting codes in body text ──────────────────────────
# Body text lines are emitted as-is (esh-d) with HTML escaping

{
    my $got = hl("=head1 NAME\n\nSee B<bold> and I<italic> and C<code>.\n");
    like($got, qr{B&lt;bold&gt;},    'B<bold> HTML-escaped in body');
    like($got, qr{I&lt;italic&gt;},  'I<italic> HTML-escaped in body');
    like($got, qr{C&lt;code&gt;},    'C<code> HTML-escaped in body');
}

{
    my $got = hl("=head1 NAME\n\nSee L<Module> and F<file.txt>.\n");
    like($got, qr{L&lt;Module&gt;}, 'L<Module> HTML-escaped');
    like($got, qr{F&lt;file\.txt&gt;}, 'F<file.txt> HTML-escaped');
}

# ── verbatim paragraph indent ─────────────────────────────────────

{
    my $got = hl("=pod\n\n    # indented code\n    my \$x = 1;\n");
    like($got, qr{<span class="esh-c"># indented code</span>}, 'verbatim comment line highlighted');
    like($got, qr{<span class="esh-k">my</span>},               'verbatim my line highlighted');
}

{
    my $got = hl("=pod\n\n        deeply indented\n");
    like($got, qr{        deeply indented}, 'deeply indented verbatim preserved');
}

# ── multiple adjacent verbatim blocks ─────────────────────────────

{
    my $got = hl("=pod\n\nParagraph one.\n\n    verbatim\n\nParagraph two.\n");
    like($got, qr{Paragraph one\.},  'text before verbatim preserved');
    like($got, qr{    verbatim}, 'verbatim block preserved');
    like($got, qr{Paragraph two\.},  'text after verbatim preserved');
}

# ── =encoding ─────────────────────────────────────────────────────

{
    my $got = hl("=encoding UTF-8\n");
    like($got, qr{<span class="esh-d">=encoding UTF-8}, '=encoding command');
}

# ── =pod ... =cut round-trip ──────────────────────────────────────

{
    my $got = hl("=pod\n\n=cut\n");
    like($got, qr{<span class="esh-d">=pod}, '=pod in minimal doc');
    like($got, qr{<span class="esh-d">=cut}, '=cut in minimal doc');
}

# ── lang aliases ──────────────────────────────────────────────────

{
    my $got = Eshu->highlight_string("=head1 NAME\n", lang => 'pod');
    like($got, qr{<span class="esh-d">=head1 NAME}, 'lang=pod dispatches correctly');
}

# ── HTML safety in =item labels ───────────────────────────────────

{
    my $got = hl("=item foo(bar => \$baz)\n");
    # $baz contains $ which should pass through HTML-safe (no special char)
    like($got, qr{<span class="esh-d">=item foo}, '=item with complex label');
}

# ── verbatim with HTML-unsafe content ─────────────────────────────

{
    my $got = hl("=pod\n\n    if (\$x < \$y) { print \"<br>\\n\"; }\n");
    like($got, qr{<span class="esh-k">if</span>},  'verbatim if keyword highlighted');
    like($got, qr{&lt; <span class="esh-v">\$y</span>}, 'less-than in verbatim is HTML-escaped');
    like($got, qr{&lt;br&gt;}, 'HTML tag in string is HTML-escaped');
}

# ── =begin / =end block ───────────────────────────────────────────

{
    my $src = "=begin html\n\n<p>raw HTML</p>\n\n=end html\n";
    my $got = hl($src);
    like($got, qr{<span class="esh-d">=begin html}, '=begin html command');
    like($got, qr{<span class="esh-d">=end html},   '=end html command');
}

done_testing;
