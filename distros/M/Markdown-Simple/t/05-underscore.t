use strict;
use warnings;
use Test::More;
use Markdown::Simple;

# Underscore variants of emphasis.

my $html = markdown_to_html("__bold__ _italic_\n\n- __bold__\n- _italic_\n");
like $html, qr|<p><strong>bold</strong> <em>italic</em></p>|, 'underscore emphasis in paragraph';
like $html, qr|<li><strong>bold</strong></li>|,              'underscore bold in list';
like $html, qr|<li><em>italic</em></li>|,                    'underscore italic in list';

done_testing;
