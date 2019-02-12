#!/usr/bin/env perl

=head1 DESCRIPTION

This script:

    * processes the Big List of Naughty Strings (or some version of it)
    * prints it to a file
    * tries to open this file in a browser

This is helpful for finding naughty strings which might get turned into
something clickable.  A visual scan is required.

=cut

use strict;
use warnings;

use Browser::Open qw( open_browser );
use Data::BLNS qw( get_naughty_strings );
use HTML::Restrict ();
use Path::Tiny     ();

my $hr = HTML::Restrict->new;

my @clean = map { $_ . '<br>' }
    grep { $_ } map { $hr->process($_) } get_naughty_strings;

my $file = Path::Tiny->tempfile( CLEANUP => 1, SUFFIX => '.html', );
$file->spew_raw( '<body>', @clean, '</body>' );
open_browser( $file->stringify );
