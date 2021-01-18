#!/usr/bin/env perl
use warnings;
use strict;

use Test::More tests => 58;

use Log::Report::Util;

#
## parse_locale
#

sub try_parse($@)
{   my $locale = shift;
    my @l = parse_locale $locale;
    is($l[0], $_[0], $locale);
    is($l[1], $_[1], ' ... territory');
    is($l[2], $_[2], ' ... charset');
    is($l[3], $_[3], ' ... modifier');
}

try_parse('nl', 'nl');
try_parse('');
try_parse('nl_NL', 'nl', 'NL');
try_parse('nl_NL.utf-8', 'nl', 'NL', 'utf-8');
try_parse('nl_NL.utf-8@mod', 'nl', 'NL', 'utf-8', 'mod');
try_parse('nl.utf-8', 'nl', undef, 'utf-8');
try_parse('nl.utf-8@mod', 'nl', undef, 'utf-8', 'mod');
try_parse('nl_NL@mod', 'nl', 'NL', undef, 'mod');
try_parse('nl@mod', 'nl', undef, undef, 'mod');

try_parse('C', 'C');
try_parse('POSIX', 'POSIX');

#
## expand_reasons
#

sub try_expand($$)
{   my ($reasons, $expanded) = @_;
    my @got = expand_reasons $reasons;
    my $got = join ',', @got;
    is($got, $expanded, $reasons);
}

my $all = join ',', @reasons;
try_expand('', '');
try_expand('TRACE', 'TRACE');
try_expand('PANIC,TRACE', 'TRACE,PANIC');
try_expand('USER', 'MISTAKE,ERROR');
try_expand('USER,PROGRAM,SYSTEM', $all);
try_expand('ALL', $all);
try_expand('WARNING-FAULT','WARNING,MISTAKE,ERROR,FAULT');
try_expand('-INFO','TRACE,ASSERT,INFO');
try_expand('ALERT-','ALERT,FAILURE,PANIC');
try_expand('NONE','');
try_expand([],'');
try_expand(['INFO', 'ASSERT-INFO'],'ASSERT,INFO');
try_expand(undef, '');

#
## to_thml
#

is to_html('<a>b&c"d'), '&lt;a&gt;b&amp;c&quot;d';
