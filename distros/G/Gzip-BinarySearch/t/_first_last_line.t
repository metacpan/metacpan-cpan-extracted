# Test get first/last line functions

use Test::More tests => 28;

use strict;
use warnings;
use Gzip::BinarySearch;

my @tests = (
    { input => ["a\nbcd\nefg\nhij", 0, 12],
      first => ["bcd\n", 2],
      last => ["efg\n", 6],
      desc => 'first/last complete line, mid-file'
    },
    { input => ["a\nbcd\nef", 0, 7, 1],
      first => ["a\n", 0],
      last => ["ef", 6],
      desc => 'allow partial lines',
    },
    {
      input => ["a\nbcd\nef", 0, 6, 1],
      first => ["a\n", 0],
      last => ["e", 6],
      desc => 'allow partial lines - variant',
    },
    {
      input => ["a\nbcd\nef\n", 0, 8, 1],
      first => ["a\n", 0],
      last => ["ef\n", 6],
      desc => 'check that partial lines works with trailing newline',
    },
    { input => ["abc", 0, 2],
      first => [],
      last => [],
      desc => 'not enough data',
    },
    { input => ["abc\n", 0, 3],
      first => [],
      last => [],
      desc => 'not enough data (with newline)',
    },
    { input => ["abc", 0, 2, 1],
      first => ["abc", 0],
      last => ["abc", 0],
      desc => 'not enough data - partials allowed',
    },
    { input => ["abc\n", 0, 3, 1],
      first => ["abc\n", 0],
      last => ["abc\n", 0],
      desc => 'not enough data - partials allowed (with newline)',
    },
    { input => ["a\nbcdef\nef", 0, 9],
      first => ["bcdef\n", 2],
      last => ["bcdef\n", 2],
      desc => 'first and last are the same',
    },
    { input => ["\nab\ncdef\nghi\nkl", 3, 15],
      first => ["cdef\n", 4],
      last => ["ghi\n", 9],
      desc => 'start non-zero',
    },
    { input => ["\nab\ncdef\nghi\nkl", 0, 9],
      first => ["ab\n", 1],
      last => ["cdef\n", 4],
      desc => 'end non-zero',
    },
    { input => ["\nab\ncdef\nghi\nkl", 3, 9],
      first => ["cdef\n", 4],
      last => ["cdef\n", 4],
      desc => 'start and end non-zero',
    },
    { input => ["a\nbcd\n", 0, 2],
      first => [],
      last => [],
      desc => 'overcropped',
    },
    { input => ["nobs\n3000\tham and eggs\n4000\tcoffee", 23, 34],
      first => [],
      last => [],
      desc => 'edge case - range is solely "4000\tcoffee"',
    },
);

for my $test (@tests) {
    my @first = Gzip::BinarySearch->_first_line(@{$test->{input}});
    my @last = Gzip::BinarySearch->_last_line(@{$test->{input}});

    my $ok = is_deeply( \@first, $test->{first}, $test->{desc} . ' - first' );
    my $ok2 = is_deeply( \@last, $test->{last}, $test->{desc} . ' - last' );
}
