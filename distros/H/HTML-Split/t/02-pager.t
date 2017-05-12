use strict;
use Test::More tests => 10;
use HTML::Split::Pager;

my $html = <<HTML;
<div class="pkg">
<h1>HTML::Split</h1>
<p>Splitting HTML text by number of characters.</p>
</div>
HTML

my $pager = HTML::Split::Pager->new(
    html   => $html,
    length => 50,
);

isa_ok $pager, 'HTML::Split::Pager';

is $pager->total_pages, 2;

is $pager->current_page, 1;
is $pager->next_page, 2;
is $pager->prev_page, undef;
is $pager->text . "\n", <<HTML;
<div class="pkg">
<h1>HTML::Split</h1>
<p>Splittin</p></div>
HTML

$pager->current_page(2);
is $pager->current_page, 2;
is $pager->next_page, undef;
is $pager->prev_page, 1;
is $pager->text, <<HTML;
<div class="pkg"><p>g HTML text by number of characters.</p>
</div>
HTML
