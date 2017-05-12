#!perl

use strict;
use warnings;
use Test::More;
use File::Temp;
use File::Find;
use File::Spec::Functions qw/catfile catdir abs2rel/;
use EBook::EPUB::Lite;
use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
use Cwd;
use Data::Dumper;

eval "use EBook::EPUB";
if ($@) {
    plan skip_all => "No EBook::EPUB installed, skipping compatibility tests";
}
else {
    plan tests => 4;
}

my $tmpdir = File::Temp->newdir(CLEANUP => !$ENV{EPUB_NO_CLEANUP});
my $litefile = create_epub(EBook::EPUB::Lite->new,
                           catfile($tmpdir->dirname, 'new.epub'));
my $heavyfile = create_epub(EBook::EPUB->new,
                            catfile($tmpdir->dirname, 'old.epub'));
ok (-f $litefile, "$litefile created");
ok (-f $heavyfile, "$heavyfile created");

my $newfiles = extract_epub($litefile);
my $oldfiles = extract_epub($heavyfile);
ok $newfiles->{mimetype}, "Found mimetype file";
is_deeply($newfiles, $oldfiles, "1:1 match!");

sub create_epub {
    my ($epub, $target) = @_;
    $epub->add_identifier('urn:uuid:dfeda35e-4815-11e5-98f3-e58d784a01b6');
    $epub->add_stylesheet("stylesheet.css" => 'html { font-size: 9pt }');
    $epub->add_author('Author');
    $epub->add_author('Author 2');
    $epub->add_title('Title');
    $epub->add_language('en');
    $epub->add_source('Source');
    $epub->add_date('2015');
    $epub->add_description('Description');
    my $counter = 0;
    my $nav;
    foreach my $html ('<h2>First</h2>', '<h3>Second</h3>', '<h4>Third</h4>') {
        $counter++;
        my $filename = 'piece' . $counter . '.xhtml';
        my $id = $epub->add_xhtml($filename, html_wrap($html, $counter));
        $nav ||= $epub;
        $nav = $nav->add_navpoint(label => "Piece $counter",
                                  id => $id,
                                  play_order => $counter,
                                  content => $filename);
    }
    $epub->copy_file(catfile(qw/t compat.t/), 'compat.t', 'text/plain');
    $epub->add_image('test.jpg', 'lakjsdflj', 'image/jpeg');
    $epub->add_data('test.dat', 'lasdjklkasd',  'application/x-garbage');
    $epub->encrypt_file(catfile(qw/t compat.t/), 'test.t', 'text/plain');
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

sub extract_epub {
    my $target = shift;
    my $zip = Archive::Zip->new;
    $zip->read($target) == AZ_OK or die "Couldn't read $target";
    my $cwd = getcwd;
    my $dir = File::Temp->newdir;
    my $wd = $dir->dirname;
    chdir $wd or die $!;
    $zip->extractTree;
    chdir $cwd;
    my %data;
    find(sub {
             my $target = $File::Find::name;
             if (-f $target) {
                 my $basename = abs2rel($target, $wd);
                 open (my $fh, '<', $target) or die $!;
                 local $/ = undef;
                 my $content = <$fh>;
                 close $fh;
                 $data{$basename} = $content;
             }
         }, $wd);
    return \%data;
}
