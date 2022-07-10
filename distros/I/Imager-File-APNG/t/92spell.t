#!perl
use strict;
use warnings;
use Test::More;

BEGIN {
  plan skip_all => "Spelling tests only for authors"
    unless $ENV{IMAGER_AUTHOR_TESTING};
}

BEGIN {
  eval 'use Test::Spelling; 1'
    or plan skip_all => "Test::Spelling not available";
}

has_working_spellchecker()
  or plan skip_all => "no spellchecker";

add_stopwords(<DATA>);
pod_file_spelling_ok("lib/Imager/File/APNG.pm");
done_testing();


__DATA__
APNG
Imager
RGBA
TODO
paletted
grayscale
