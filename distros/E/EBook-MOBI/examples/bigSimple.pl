#!/usr/bin/perl

use strict;
use warnings;

use EBook::MOBI;
use GD::Simple;

my $someText = '';
for (1..500) {
    $someText .= 'Hello World! This is just a test. '
}

my $pod = '';
my @image_paths = ();
my $img_path = '';

for (my $i=0;$i<50;$i++) {
    $img_path = "./examples/img/img_$i.jpg";
    push (@image_paths, $img_path);

    print "creating $img_path\n";

    $pod .= "=head1 Title $i\n\nThis picture should have the same number as the title...\n\n";
    $pod .= "=for image $img_path Pic number $i\n\n$someText\n\n";

    my $im = GD::Simple->new(200, 80);
    $im->fgcolor('black');
    $im->bgcolor('yellow');
    $im->moveTo(20,40);
    $im->font('Times:italic');
    $im->fontsize(18);
    $im->string("Nr. $i"); 

    open(my $PICTURE, ">$img_path") or die("Cannot open file for writing");
    binmode $PICTURE;
    print $PICTURE $im->jpeg;
    close $PICTURE;
}

$pod .= "=cut\n";

my $book = EBook::MOBI->new();

# let's define a debug sub witch will be used by all modules
sub debug {
    my ($package, $filename, $line) = caller;
    print "$package\t$_[0]\n";
}

# pass the reference of the sub to our book
$book->debug_on(\&debug);

# fill the book with meta info
$book->set_filename('BigSimple.mobi');
$book->set_title   ('A Test: BigSimple');
$book->set_author  ('Boris');
$book->set_encoding(':encoding(UTF-8)');

# fill the book with content
$book->add_mhtml_content(" <h1>A Test Titlepage</h1><p>Very simple...</p>");
$book->add_pagebreak();
$book->add_toc_once();
$book->add_pagebreak();
$book->add_content(data => $pod, pagemode => 1);

$book->make();
#$book->print_mhtml();
$book->save();

print "\n\neBook done... cleaning up...\n\n";

foreach my $pic (@image_paths) {
    print "deleting $pic\n";
    unlink $pic;
}

