#!/usr/bin/perl -w
use strict;
use warnings;
use Test::Simple tests => 4;
use MathML::itex2MML;

my $text = 'This is an inline equation: $\sin(\pi/2)=1$.';

ok(itex_html_filter($text) eq "This is an inline equation: <math xmlns='http://www.w3.org/1998/Math/MathML' display='inline'><semantics><mrow><mi>sin</mi><mo stretchy=\"false\">(</mo><mi>&pi;</mi><mo stretchy=\"false\">/</mo><mn>2</mn><mo stretchy=\"false\">)</mo><mo>=</mo><mn>1</mn></mrow><annotation encoding='application/x-tex'>\\sin(\\pi/2)=1</annotation></semantics></math>.", 'html_filter');
ok(itex_filter($text) eq "<math xmlns='http://www.w3.org/1998/Math/MathML' display='inline'><semantics><mrow><mi>sin</mi><mo stretchy=\"false\">(</mo><mi>&pi;</mi><mo stretchy=\"false\">/</mo><mn>2</mn><mo stretchy=\"false\">)</mo><mo>=</mo><mn>1</mn></mrow><annotation encoding='application/x-tex'>\\sin(\\pi/2)=1</annotation></semantics></math>", 'html_filter');

$text = '\sin(\pi/2)=1';

ok(itex_inline_filter($text) eq "<math xmlns='http://www.w3.org/1998/Math/MathML' display='inline'><semantics><mrow><mi>sin</mi><mo stretchy=\"false\">(</mo><mi>&pi;</mi><mo stretchy=\"false\">/</mo><mn>2</mn><mo stretchy=\"false\">)</mo><mo>=</mo><mn>1</mn></mrow><annotation encoding='application/x-tex'>\\sin(\\pi/2)=1</annotation></semantics></math>", 'inline_filter');
ok(itex_block_filter($text) eq "<math xmlns='http://www.w3.org/1998/Math/MathML' display='block'><semantics><mrow><mi>sin</mi><mo stretchy=\"false\">(</mo><mi>&pi;</mi><mo stretchy=\"false\">/</mo><mn>2</mn><mo stretchy=\"false\">)</mo><mo>=</mo><mn>1</mn></mrow><annotation encoding='application/x-tex'>\\sin(\\pi/2)=1</annotation></semantics></math>", 'block_filter');
