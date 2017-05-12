#!perl
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

use Lingua::Identifier;

my @files = <t/files/*.txt>;


plan tests => scalar(@files);

my $id = Lingua::Identifier->new();

my @langs = $id->languages();

for my $lang (@langs) {
    my $file = qq{t/files/$lang.txt};
    my $id   = $id->identify_file($file);

    is $id => $lang, "Testing $lang";
}
