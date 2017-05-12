#!/usr/bin/perl -I.

use strict;
use Test::More qw(no_plan);
use HTML::Transmorgify;
use warnings;

my $finished = 0;

END { ok($finished, "finished"); }

my $attr = HTML::Transmorgify::Attributes->new('a', [ href => 'http://foo/bar' ], 0);

ok($attr, "constructor");
is("$attr", '<a href="http://foo/bar">', 'stringify');

$HTML::Transmorgify::xml_quoting = 1;

$attr = HTML::Transmorgify::Attributes->new('input', [ type => 'checkbox', name => 'cb', value => 'cbv', auto_defaults => 'true' ], 0);
ok($attr, "constructor2");
is("$attr", '<input type="checkbox" name="cb" value="cbv" auto_defaults="true">', 'stringify2');
$attr->hide('auto_defaults');
is("$attr", '<input type="checkbox" name="cb" value="cbv">', 'hide');
$attr->set(value => 'cbv2');
is("$attr", '<input type="checkbox" name="cb" value="cbv2">', 'set');
$attr->set(checked => undef);
is("$attr", '<input type="checkbox" name="cb" value="cbv2" checked>', 'checked');
$attr->hide('checked');
is("$attr", '<input type="checkbox" name="cb" value="cbv2">', 'hide checked');

$HTML::Transmorgify::xml_quoting = 0;

is("$attr", '<input type=checkbox name=cb value=cbv2>', 'non-quoted words');

$HTML::Transmorgify::xml_quoting = 1;

$attr = HTML::Transmorgify::Attributes->new('input', [ type => 'checkbox', name => 'cb', value => 'cbv', checked => undef ], 0);
is("$attr", '<input type="checkbox" name="cb" value="cbv" checked>', 'checked, again');

is($attr->get('name'), 'cb', 'get');
is($attr->get('other'), undef, 'get undef');
is($attr->boolean('checked', undef, 0), 1, 'boolean true');
is($attr->boolean('other', undef, 0), 0, 'boolean true');
is($attr->boolean('other', undef, 1), 1, 'boolean true');

$finished = 1;
