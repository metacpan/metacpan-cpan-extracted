#!perl

use 5.010001;
use strict;
use warnings;
use Test::More 0.98;

use Filename::Type::Ebook qw(check_ebook_filename);

ok( check_ebook_filename(filename=>"foo.txt"));
ok( check_ebook_filename(filename=>"foo bar.pdf"));
ok( check_ebook_filename(filename=>"FOO.DOC"));
ok(!check_ebook_filename(filename=>"foo"));
ok(!check_ebook_filename(filename=>"foo.jpg"));

DONE_TESTING:
done_testing;
