use strict;
use warnings;
use Test::More;
use Markdown::Simple;

# A line that starts with `**` immediately after a list is part of the
# preceding list paragraph in lazy continuation per CommonMark — accept
# either the paragraph-after-list or lazy-continuation shape; what matters
# is that the bullets are <li>s and the emphasis is rendered.

for my $bang ('**no**', '*no*') {
    my $md = "__bold__ _italic_\n\n* __bold__\n* _italic_\n$bang\n";
    my $html = markdown_to_html($md);
    like $html, qr|<p><strong>bold</strong> <em>italic</em></p>|, "$bang: paragraph";
    # `$bang` is a lazy continuation of the second list item per CommonMark,
    # so it lives inside the last <li>. Just assert both list items render and
    # the emphasised tail is present somewhere inside the list.
    like $html, qr|<ul>.*<li><strong>bold</strong>.*<li>.*<em>italic</em>|s,
        "$bang: both list items render with emphasis";
    if ($bang eq '**no**') {
        like $html, qr|<strong>no</strong>|, '** no ** rendered as strong';
    } else {
        like $html, qr|<em>no</em>|, '* no * rendered as em';
    }
}

done_testing;
