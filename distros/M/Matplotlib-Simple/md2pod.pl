#!/usr/bin/env perl

use 5.042;
no source::encoding;
use warnings FATAL => 'all';
use autodie ':default';
use Util 'file2string';
use Markdown::To::POD 'markdown_to_pod';

my $md = file2string('README.md');
my $pod = markdown_to_pod($md);
open my $tmp, '>', 'README.pod';
say $tmp $pod;
