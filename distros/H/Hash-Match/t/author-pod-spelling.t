#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use English qw( -no_match_vars );

my $DICTIONARY = 't/etc/custom-dictionary.txt';

unless ( $ENV{AUTHOR_TESTING} ) {
    plan( skip_all => "Author tests not required for installation" );
}

eval "use File::Slurp";
plan skip_all => 'File::Slurp required' if $@;

eval "use Text::Aspell";
plan skip_all => 'Text::Aspell required' if $@;

eval "use Text::Ispell";
plan skip_all => 'Text::Ispell required' if $@;

eval "use Lingua::Ispell";
plan skip_all => 'Lingua::Ispell required' if $@;

eval "require Test::Pod::Spelling";
plan skip_all => 'Test::Pod::Spelling required' if $@;

Test::Pod::Spelling->import(
    spelling => {
        allow_words => [
            (map { chomp($ARG); $ARG } read_file($DICTIONARY))
        ],
    },
);

all_pod_files_spelling_ok(qw( lib ));

done_testing;
