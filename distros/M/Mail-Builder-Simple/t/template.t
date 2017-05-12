
use strict;
use Test::More tests => 6;

use_ok('Mail::Builder::Simple::HTML::Template');

my $t = Mail::Builder::Simple::HTML::Template->new;

can_ok($t, 'new');
can_ok($t, 'process');

my $t2 = Mail::Builder::Simple::HTML::Template->new({}, {name => 'Teddy'});

can_ok($t2, 'new');
can_ok($t2, 'process');

is($t2->process('Hello <tmpl_var name>', 'scalar'), 'Hello Teddy', 'HT scalar OK');
