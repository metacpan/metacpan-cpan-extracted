#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 2;

use MediaWiki::CleanupHTML;

{
    my $filename = 't/data/English-Wikipedia-Perl-Page-2012-04-26.html';
    open my $fh, '<:encoding(UTF-8)', $filename
        or die "Cannot open '$filename' for input - $!";
    my $cleaner = MediaWiki::CleanupHTML->new({ fh => $fh });

    # TEST
    ok ($cleaner, "Object was created.");

    my $out_buffer = '';
    open my $out_fh, '>:encoding(UTF-8)', \$out_buffer,
        or die "Cannot write to out_buffer - $!";

    $cleaner->print_into_fh($out_fh);

    $cleaner->destroy_resources();

    # TEST
    ok(1, "Success.");

}

