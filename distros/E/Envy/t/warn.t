#!./perl -w
use strict;
use Test; plan test => 5;

require Envy::DB;
my $db = Envy::DB->new(\%ENV);
$db->warnlevel(4);

$db->e('error');
$db->w('warn');
$db->n('noisy');
$db->d('debug');

$db->commit;

my @w = $db->warnings;
ok @w, 4;
chop @w;
ok $w[0], 'ERROR: error';
ok $w[1], 'warn';
ok $w[2], 'noisy';
ok $w[3], 'D debug';
