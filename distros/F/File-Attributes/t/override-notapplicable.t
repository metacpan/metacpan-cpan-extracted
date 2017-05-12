#!/usr/bin/perl
# override-notapplicable.t 
# Copyright (c) 2007 Jonathan Rockway <jrockway@cpan.org>

use Test::More tests => 9;
use FindBin qw($Bin);
use File::Spec;
use lib (File::Spec->catfile($Bin, 'lib'));
use File::Attributes::Simple;
BEGIN { no warnings; *File::Attributes::Simple::priority = sub { 999_999 }};
use File::Attributes ':all';
use Directory::Scratch;
use strict;
use warnings;

my @backends = File::Attributes::_modules;
ok(scalar @backends > 1, 'at least 2 backends');
my $test = shift @backends;
is($test->VERSION, File::Attributes::Test->VERSION);
ok($test->isa('File::Attributes::Test'), 'isa F::A::T');
my $simple = shift @backends;
is($simple->VERSION, File::Attributes::Simple->VERSION);
ok($simple->isa('File::Attributes::Simple'), 'isa F::A::S');

my  $tmp = Directory::Scratch->new;
my $FILE = $tmp->touch('fileNONONO');
ok(-e $FILE, 'have a real test file');

my @result = list_attributes($FILE);
is_deeply([@result], [], 'no attributes yet');

set_attribute($FILE, foo => 'bar');
set_attribute($FILE, bar => 'baz');

@result = list_attributes($FILE);
is_deeply([sort @result], [qw|bar foo|], 'set bar and foo ok');

ok($tmp->exists('.fileNONONO.attributes'), 'make sure we used ::Simple');
