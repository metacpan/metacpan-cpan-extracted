#!/usr/bin/perl -w
use strict;
use Music_Translate_Fields;
use MP3::Tag;

my $tag = MP3::Tag->new(q(/dev/null)) or die;
$tag->config(parse_data => [qw(mi %a), shift]);
$tag->Music_Translate_Fields::normalize_file_lines(shift);
