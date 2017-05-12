use strict;
use warnings;
use utf8;

use Test::More tests => 1;

use EBook::MOBI;

use File::Temp qw( tempfile );

##########################################
# THIS VALUE IS FIX AND WHAT WE TEST FOR #
##########################################
my $expected_file_size = 624;

# let's go...
 
my ($fh, $filename) = tempfile( SUFFIX => '.mobi',
                                UNLINK => 1,
                              );

my $book = EBook::MOBI->new();

$book->set_filename($filename);
$book->set_title   ('Hello World');
$book->set_author  ('Alfred Beispiel');
$book->set_encoding(':encoding(UTF-8)');

$book->add_mhtml_content("hello world");
$book->make();
$book->save();

my $filesize  = -s $filename;

is ( $filesize, $expected_file_size, "book size ($expected_file_size)");

