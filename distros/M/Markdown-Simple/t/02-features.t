use strict;
use warnings;
use Test::More;
use Markdown::Simple;

# Plain paragraph
like markdown_to_html("Hello world\n"),       qr|<p>Hello world</p>|,        'plain paragraph -> <p>';

# Headers
like markdown_to_html("# Header 1\n"),        qr|<h1>Header 1</h1>|,         'h1';
like markdown_to_html("## Header 2\n"),       qr|<h2>Header 2</h2>|,         'h2';
like markdown_to_html("### Header 3\n"),      qr|<h3>Header 3</h3>|,         'h3';

# Inline emphasis & code
like markdown_to_html("**bold text**\n"),     qr|<strong>bold text</strong>|,'bold';
like markdown_to_html("*italic text*\n"),     qr|<em>italic text</em>|,      'italic';
like markdown_to_html("`code`\n"),            qr|<code>code</code>|,         'inline code';

# Fenced code blocks
like markdown_to_html("```\ncode block\n```\n"),
    qr|<pre><code>code block\n</code></pre>|, 'fenced code';
like markdown_to_html("```javascript\nvar x = 1;\n```\n"),
    qr|<pre><code class="language-javascript">var x = 1;\n</code></pre>|, 'fenced code w/ language';

# Links & images
like markdown_to_html("[link text](http://example.com)\n"),
    qr{<a href="http://example\.com">link text</a>}, 'link';
like markdown_to_html("![alt text](image.jpg)\n"),
    qr{<img src="image\.jpg" alt="alt text" ?/?>}, 'image';

# GFM strikethrough is on by default
like markdown_to_html("~~strikethrough~~\n"),
    qr|<del>strikethrough</del>|, 'strikethrough';

# Task list items appear inside <ul>
{
    my $html = markdown_to_html("- [ ] unchecked task\n");
    like $html, qr|<ul>|, 'task list wrapped in <ul>';
    like $html, qr|<input[^>]*type="checkbox"[^>]*disabled[^>]*/?>|,
        'task list checkbox';
    unlike $html, qr|<input[^>]*\bchecked\b|, 'unchecked task lacks checked attr';

    my $checked = markdown_to_html("- [x] checked task\n");
    like $checked, qr|<input[^>]*checked|, 'checked task has checked attr';
}

# Lists
like markdown_to_html("- list item\n"),  qr|<ul>\s*<li>list item</li>|s, 'dash list';
like markdown_to_html("* list item\n"),  qr|<ul>\s*<li>list item</li>|s, 'asterisk list';
like markdown_to_html("1. first item\n"), qr|<ol>\s*<li>first item</li>|s, 'ordered list';

# Tables
{
    my $md = "| Header 1 | Header 2 |\n|----------|----------|\n| Cell 1   | Cell 2   |\n";
    my $html = markdown_to_html($md);
    like $html, qr|<table>|,        'table tag';
    like $html, qr|<th>Header 1</th>|, 'table header 1';
    like $html, qr|<td>Cell 1</td>|,   'table cell 1';
}

# Options: opt-out of GFM features
{
    # gfm => 0 reverts to strict CommonMark (no tables, no strike scanning,
    # no autolink scanning, no disallow-raw-html). Strike opt-out via flag
    # is currently a no-op (inline scanner unconditional); see Phase 06.5.
    my $html = markdown_to_html("| a | b |\n|---|---|\n| 1 | 2 |\n", { tables => 0 });
    unlike $html, qr|<table>|, 'tables => 0 disables table parsing';

    my $autolink = markdown_to_html("see http://example.com\n");
    like $autolink, qr{<a href="http://example\.com"}, 'autolink on by default (GFM)';

    my $no_autolink = markdown_to_html("see http://example.com\n", { autolink => 0 });
    unlike $no_autolink, qr{<a href="http:}, 'autolink => 0 disables';
}

# Combined inline formatting
like markdown_to_html("**bold** and *italic* with `code`\n"),
    qr|<strong>bold</strong> and <em>italic</em> with <code>code</code>|,
    'multiple inline formats';

done_testing;
