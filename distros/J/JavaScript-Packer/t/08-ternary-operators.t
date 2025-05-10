#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 5;
use File::Spec;
use lib File::Spec->catdir(qw(lib));

use JavaScript::Packer;

my $packer = JavaScript::Packer->init();

my $input = qq~
// Test ternary operator with + and - literals
options.position = {
  my: "left top",
  at: "left" + ( left >= 0 ? "+" : "" ) + left + " " +
       "top" + ( top >= 0 ? "+" : "" ) + top,
  of: that.window
};

// Another variation
o.position = {
  my: "left top",
  at: "left" + ( 0 <= s ? "+" : "" ) + s + " top" + ( 0 <= i ? "+" : "" ) + i,
  of: n.window
};
~;

my $expected_clean = 'options.position={my:"left top",at:"left"+(left>=0?"+":"")+left+" top"+(top>=0?"+":"")+top,of:that.window};o.position={my:"left top",at:"left"+(0<=s?"+":"")+s+" top"+(0<=i?"+":"")+i,of:n.window};';

$packer->minify( \$input, { compress => 'clean' } );
is($input, $expected_clean, 'Ternary operator with "+" literal is preserved');

# Try with nested conditional to handle more complex cases
my $nested_input = qq~
// Test nested ternary with + and - literals
options.format = ( value > 0 ? "+" : value < 0 ? "-" : "" ) + Math.abs(value);
~;

my $expected_nested = 'options.format=(value>0?"+":value<0?"-":"")+Math.abs(value);';

$packer->minify( \$nested_input, { compress => 'clean' } );
is($nested_input, $expected_nested, 'Nested ternary with "+"/"-" literals is preserved');

# Test with single quotes
my $single_quotes = qq~
// Test ternary with single quotes
options.prefix = ( value >= 0 ? '+' : '-' ) + Math.abs(value);
~;

my $expected_single = 'options.prefix=(value>=0?\'+\':\'-\')+Math.abs(value);';

$packer->minify( \$single_quotes, { compress => 'clean' } );
is($single_quotes, $expected_single, 'Ternary with single-quoted "+"/"-" literals is preserved');

# Test with more complex expressions
my $complex = qq~
// Test more complex expressions
var result = x > 10 ? "+" + (y * 2) : "-" + Math.min(5, z);
~;

my $expected_complex = 'var result=x>10?"+"+(y*2):"-"+Math.min(5,z);';

$packer->minify( \$complex, { compress => 'clean' } );
is($complex, $expected_complex, 'Complex expressions with "+"/"-" literals are preserved');

# Test with template literals (backticks)
my $template = qq~
// Test with template literals
var sign = value > 0 ? \`+\` : \`-\`;
~;

my $expected_template = 'var sign=value>0?`+`:`-`;';

$packer->minify( \$template, { compress => 'clean' } );
is($template, $expected_template, 'Ternary with template literals is preserved');