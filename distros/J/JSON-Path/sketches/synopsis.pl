use strict;
use warnings;
my $data = {
    "store" => {
        "book" => [
            {   "category" => "reference",
                "author"   => "Nigel Rees",
                "title"    => "Sayings of the Century",
                "price"    => 8.95,
            },
            {   "category" => "fiction",
                "author"   => "Evelyn Waugh",
                "title"    => "Sword of Honour",
                "price"    => 12.99,
            },
            {   "category" => "fiction",
                "author"   => "Herman Melville",
                "title"    => "Moby Dick",
                "isbn"     => "0-553-21311-3",
                "price"    => 8.99,
            },
            {   "category" => "fiction",
                "author"   => "J. R. R. Tolkien",
                "title"    => "The Lord of the Rings",
                "isbn"     => "0-395-19395-8",
                "price"    => 22.99,
            },
        ],
        "bicycle" => [
            {   "color" => "red",
                "price" => 19.95,
            },
        ],
    },
};

use JSON::Path 'jpath_map';
use Data::Dumper;

# All books in the store
print Dumper my $jpath = JSON::Path->new('$.store.book[*]');
print Dumper my $books = [ $jpath->values($data) ];

# The author of the last (by order) book
print Dumper my $jpath   = JSON::Path->new('$..book[-1:].author');
print Dumper my $tolkien = $jpath->value($data);

# Convert all authors to uppercase
print Dumper jpath_map { uc $_ } $data, '$.store.book[*].author';
