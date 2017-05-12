#!/usr/bin/perl

use EBook::MOBI;
use File::Slurp;

my $pod = read_file( 'backslashQ.pod' ) ;

warn EBook::MOBI->VERSION;

my $book = EBook::MOBI->new();

# let's define a debug sub witch will be used by all modules
sub debug {
    my ($package, $filename, $line) = caller;
    print "$package\t$_[0]\n";
}

# pass the reference of the sub to our book
$book->debug_on(\&debug);

# fill the book with meta info
$book->set_filename('backslashQ.mobi');
$book->set_title   ('Backslash Q');
$book->set_author  ('Boris');
$book->set_encoding(':encoding(UTF-8)');

# fill the book with content
$book->add_toc_once;
$book->add_content( data => $pod,
                    driver => 'EBook::MOBI::Driver::POD',
                  );
$book->make();
$book->print_mhtml();
$book->save();

