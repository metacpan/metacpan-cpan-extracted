#!/usr/bin/perl -w
use strict;
use Font::FreeType;

die "Usage: $0 font-filename\n"
  unless @ARGV == 1;
my ($filename) = @ARGV;

my $face = Font::FreeType->new->face($filename);

$face->foreach_char(sub {
    print join("\t", map { defined() ? ($_) : () } $_->char_code, $_->name),
          "\n";
});

# vi:ts=4 sw=4 expandtab
