use strict;
use Test::More tests => 3;

use_ok $_ for qw(
    Google::ISBNNumbers
);

# make sure we can initiate -- note, get your own API key!
my $books = Google::ISBNNumbers->new('AIzaSyBorBmYpbBMTCb0wqQuukR93dzmME4Z1mk'); 
isa_ok( $books, 'Google::ISBNNumbers' );

# make sure we can find a good good
my $book_info = $books->lookup_isbn(9781680500882);
ok($$book_info{title} =~ /Modern Perl/, 'Able to look up 9781680500882');

done_testing;

