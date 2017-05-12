use strict;
use v5.10.0;
use Test::More;
use Test::Deep;
plan 'no_plan';

require_ok 'FusqlFS::Formatter::Htmltable';
our $_tcls = 'FusqlFS::Formatter::Htmltable';

#=begin testing
{
my $_tname = '';
my $_tcount = undef;

#!noinst

my $hvalue = { a => 1, b => 2, c => 3 };
my $avalue = [ 1, 2, 3 ];
my $svalue = "123";
is FusqlFS::Formatter::Htmltable::_Dump($hvalue), q{<table class="table"><tbody><tr><th>a</th><td>1</td></tr><tr><th>b</th><td>2</td></tr><tr><th>c</th><td>3</td></tr></tbody></table>}, "hash dumped correctly";
is FusqlFS::Formatter::Htmltable::_Dump($avalue), q{<table class="table"><thead><tr><th>#</th><th>Value</th></tr></thead><tbody><tr><th>1</th><td>1</td></tr><tr><th>2</th><td>2</td></tr><tr><th>3</th><td>3</td></tr></tbody></table>}, "array dumped correctly";
is FusqlFS::Formatter::Htmltable::_Dump($svalue), "123", "scalar dumped correctly";

my $complex = { a => 1, b => [2, 3, 4], c => [5] };
is FusqlFS::Formatter::Htmltable::_Dump($complex), q{<table class="table"><tbody><tr><th>a</th><td>1</td></tr><tr><th>b</th><td><table class="table"><thead><tr><th>#</th><th>Value</th></tr></thead><tbody><tr><th>1</th><td>2</td></tr><tr><th>2</th><td>3</td></tr><tr><th>3</th><td>4</td></tr></tbody></table></td></tr><tr><th>c</th><td><table class="table"><thead><tr><th>#</th><th>Value</th></tr></thead><tbody><tr><th>1</th><td>5</td></tr></tbody></table></td></tr></tbody></table>}, "complex structure dumped correctly";
}

1;