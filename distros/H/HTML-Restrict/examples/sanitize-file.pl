#!/usr/bin/env perl

use strict;
use warnings;

use HTML::Restrict ();
use Path::Tiny     qw( path );

my $filename = shift @ARGV;
die "usage: perl $0 path/to/file > path/to/new/file" if !$filename;

my $text = path($filename)->slurp;

my $hr = HTML::Restrict->new;

print $hr->process($text);

=pod

=head1 SYNOPSIS

    perl sanitize_file path/to/filename > path/to/sanitized/file

=cut
