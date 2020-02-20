#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 7;
use HTML::Form;

my $html = '<html><body><form></form></body></html>';

my $form = HTML::Form->parse($html, 'http://example.com');
ok($form, 'form created');

ok(! eval {
    $form->find_input('submit', 'button', 0);
    1
}, 'index 0');
like($@, qr/Invalid index 0/, 'exception text');

ok(! eval {
    $form->find_input('submit', 'button', 'a');
    1
}, 'index a');
like($@, qr/Invalid index a/, 'exception text');

{
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, shift };
    my @inputs = $form->find_input('submit', 'input', 1);
    is(scalar @warnings, 1, 'warns');
    is($warnings[0], "find_input called in list context with index specified\n",
       'warning text');
}
