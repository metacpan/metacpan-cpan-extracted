#!/usr/bin/perl
use strict;
use warnings;
use Text::Table;
use Lingua::Conlang::Numbers qw( :all );

my @languages = num2conlang_languages();
my $table = Text::Table->new(q{}, @languages);

for my $number (0 .. 9, map { $_ * 10 } 1 .. 10, 100) {
    $table->add($number, map { num2conlang($_ => $number) } @languages);
}

binmode STDOUT, ':utf8';
print $table;
