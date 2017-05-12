#!perl

use utf8;
use strict;
use warnings;

use Test::More;
use File::Spec::Functions qw/catfile catdir/;
use File::Temp;
use Archive::Zip qw( :ERROR_CODES :CONSTANTS );

# produce the epub
use_ok('EBook::EPUB::Lite');


my $epub_file = catfile(qw/t test.epub/);
my $specs = {
             css => '@page { margin: 5pt; } html, body { font-family: serif; font-size: 9pt; }',
             html => [
                      '<div>First piece</div>',
                      '<div>Second piece</div>',
                      '<div>Third piece</div>',
                     ],
             title => 'My title',
             author => 'My author',
             lang => 'it',
             source => 'My source',
             date => '2014',
             desc => 'My description of this piece',
            };

create_epub($epub_file, $specs);
ok (-f $epub_file, "$epub_file generated");
check_epub($epub_file, $specs);

if (-f $epub_file) {
    if ($ENV{EPUB_NO_CLEANUP}) {
        diag "Leaving $epub_file in the tree";
    }
    else {
        unlink $epub_file or die "Can't unlink $epub_file $!";
    }
}

done_testing;

sub create_epub {
    my ($target, $spec) = @_;
    die unless $target && $spec;
    my $epub = EBook::EPUB::Lite->new;
    $epub->add_stylesheet("stylesheet.css" => $spec->{css} || 'html { font-size: 9pt }');
    $epub->add_author($spec->{author} || 'Author');
    $epub->add_title($spec->{title} || 'Title');
    $epub->add_language($spec->{lang} || 'en');
    $epub->add_source($spec->{source} || 'Source');
    $epub->add_date($spec->{date} || '2015');
    $epub->add_description($spec->{desc} || 'Description');
    my $counter = 0;
    my $nav;
    foreach my $html (@{$spec->{html}}) {
        $counter++;
        my $filename = 'piece' . $counter . '.xhtml';
        my $id = $epub->add_xhtml($filename, html_wrap($html));
        $nav ||= $epub;
        $nav = $nav->add_navpoint(label => "Piece $counter",
                                  id => $id,
                                  play_order => $counter,
                                  content => $filename);
    }
    foreach my $file (@{$spec->{files} || []}) {
        $epub->copy_file(undef, $file);
    }
    # and some garbage
    $epub->add_image('test.jpg', 'lakjsdflj', 'image/jpeg');
    $epub->add_data('test.dat', 'lasdjklkasd',  'application/x-garbage');
    $epub->encrypt_file(catfile(qw/t epub.t/), 'test.t', 'text/plain');
    $epub->pack_zip($target);
    return $target;
}

sub html_wrap {
    my ($body, $title) = @_;
    $title ||= "No title";
    my $xhtml = <<"XHTML";
<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
  <head>
    <title>$title</title>
    <link href="stylesheet.css" type="text/css" rel="stylesheet" />
  </head>
  <body>
    <div id="page">
      $body
    </div>
  </body>
</html>

XHTML
    return $xhtml;
}

sub check_epub {
    my ($epub, $spec) = @_;
    my $zip = Archive::Zip->new;
    die "Couldn't read $epub" if $zip->read($epub) != AZ_OK;
    my $tmpdir = File::Temp->newdir(CLEANUP => !$ENV{EPUB_NO_CLEANUP});
    diag "Using " . $tmpdir->dirname;
    $zip->extractTree('OPS', $tmpdir->dirname);
    $zip->extractTree('META-INF', $tmpdir->dirname);
    my $counter = 0;
    foreach my $html (@{$spec->{html}}) {
        $counter++;
        my $filename = 'piece' . $counter . '.xhtml';
        my $target = catfile($tmpdir->dirname, $filename);
        my $content = read_file($target);
        ok(index($content, $html) >= 0, "Found $html in $filename");
    }
    if (my $css = $spec->{css}) {
        ok(index(read_file(catfile($tmpdir->dirname, 'stylesheet.css')),
                 $css) >= 0, "Found CSS in stylesheet.css");
    }
    foreach my $meta ('container.xml', 'content.opf', 'toc.ncx') {
        my $meta_content = read_file(catfile($tmpdir->dirname, $meta));
        ok($meta_content, "Found content of $meta");
        # diag $meta_content;
    }
}

sub read_file {
    my $file = shift;
    open (my $fh, '<:encoding(UTF-8)', $file) or die "Couldn't open $file $!";
    local $/;
    my $content = <$fh>;
    close $fh or die "Couldn't close $file $!";
    return $content;
}
