#!/usr/bin/perl -w

use GnaData::Parse;
use IO::String;
use Test::Simple tests=>15;
use strict;

my ($parser) = GnaData::Parse->new();
my ($inh) = IO::String->new("
<hr>
<b>test
<b>foo
");
my ($outh) = IO::String->new();

ok($parser->substitute_fields("
<hr>
<b>test
<b>foo", [["field1", "<b>", ""], ["field2", "<b>", ""]]) eq
"
<hr>
field1   test
field2   foo");

ok($parser->transform_entry("foo   test
bar   foo", [["foo", sub {my($f) = @_; return $f->{'foo'} . "a";}]]) eq
"foo   testa
bar   foo");

ok($parser->transform_entry("foo   test
bar   foo", [["foo", sub {my($h) = @_; return $h->{'foo'} . $h->{'bar'};}]]) eq
"foo   testfoo
bar   foo");

ok($parser->transform_entry("foo   test
bar   foo", [["foo", sub {return undef;}]]) eq
"bar   foo");

ok($parser->transform_entry("foo   test
bar   foo", [["pow", "bam"]]) eq
"foo   test
bar   foo
pow   bam");


ok($parser->transform_entry("foo", [["pow", "bam"]]) eq
"foo" . "   " . "
pow   bam");


ok($parser->transform_entry("foo   test
bar   foo", [["pow"=> sub {my ($h) = @_; return $h->{'foo'};}]]) eq
"foo   test
bar   foo
pow   test");

$parser->extract_data('0123 adfdas',
		      [['foo', '([0-9]+)']]);

ok($parser->{'extract_data'}->[0]->[0] eq 'foo', "extracting data");
ok($parser->{'extract_data'}->[0]->[1] eq '0123');

$parser->extract_data('0123 adfdas',
		      [['foo', '([adf]+)']]);

ok($parser->{'extract_data'}->[0]->[0] eq 'foo');
ok($parser->{'extract_data'}->[0]->[1] eq 'adfda');

$parser->extract_data('0123 adfdas',
		      [['bar', '([0-9]+)']]);

ok($parser->{'extract_data'}->[1]->[0] eq 'bar');
ok($parser->{'extract_data'}->[1]->[1] eq '0123');


$parser->extract_data('0123 adfdas',
		      [['bar', '([0-1]+)']]);

ok($parser->{'extract_data'}->[1]->[0] eq 'bar');
ok($parser->{'extract_data'}->[1]->[1] eq '01');
		       

$parser->input_handle($inh);
$parser->output_handle($outh);
$parser->substitute_list ([
	['href', '<b>', ''],
	['description', '<b>', '']]);
$parser->entry_bounds("<hr>");
$parser->parse();
my($stringref) = $outh->string_ref();

#print $outh->getline(), "\n";
