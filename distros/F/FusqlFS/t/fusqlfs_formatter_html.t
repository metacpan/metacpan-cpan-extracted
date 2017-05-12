use strict;
use v5.10.0;
use Test::More;
use Test::Deep;
plan 'no_plan';

require_ok 'FusqlFS::Formatter::Html';
our $_tcls = 'FusqlFS::Formatter::Html';

#=begin testing
{
my $_tname = '';
my $_tcount = undef;

#!noinst

my $hvalue = { a => 1, b => 2, c => 3 };
my $avalue = [ 1, 2, 3 ];
my $svalue = "123";
is FusqlFS::Formatter::Html::_Dump($hvalue), q{<dl><dt>a</dt><dd>1</dd><dt>b</dt><dd>2</dd><dt>c</dt><dd>3</dd></dl>}, "hash dumped correctly";
is FusqlFS::Formatter::Html::_Dump($avalue), q{<ol><li>1</li><li>2</li><li>3</li></ol>}, "array dumped correctly";
is FusqlFS::Formatter::Html::_Dump($svalue), "123", "scalar dumped correctly";

my $complex = { a => 1, b => [2, 3, 4], c => [5] };
is FusqlFS::Formatter::Html::_Dump($complex), q{<dl><dt>a</dt><dd>1</dd><dt>b</dt><dd><ol><li>2</li><li>3</li><li>4</li></ol></dd><dt>c</dt><dd><ol><li>5</li></ol></dd></dl>}, "complex structure dumped correctly";
}

1;