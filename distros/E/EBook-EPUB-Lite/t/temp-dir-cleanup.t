#!perl

use utf8;
use strict;
use warnings;
use Test::More tests => 4;
use EBook::EPUB::Lite;
use File::Spec;

my ($test_tempdir, $test_epub);
{
    my $epub = EBook::EPUB::Lite->new;
    $test_tempdir = $epub->tmpdir;
    ok (-d $test_tempdir, "$test_tempdir exists");
    $test_epub = build_test_epub($epub);
    ok (-f $test_epub, "$test_epub generated");
}
ok (! -d $test_tempdir, "Directory cleaned up");
ok (-f $test_epub, "EPUB still here");
unlink $test_epub or die "Cannot remove $test_epub: $!";
# cleanup
# unlink $test_epub;

sub build_test_epub {
    my $epub = shift;
    $epub->add_stylesheet("stylesheet.css", "/* blabla bla */");
    $epub->add_xhtml("page.xhtml", "<body><p>test</p></body>");
    my $out = File::Spec->catfile(qw/t cleanuptest.epub/);
    $epub->pack_zip($out);
    return $out;
}
