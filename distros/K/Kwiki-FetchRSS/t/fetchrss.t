use strict;
use warnings;
use Test::More;

use lib '../lib';

my @tests = (
    [ "\n{fetchrss http://www.burningchrome.com/~cdent/mt/index.xml}\n\n" =>
      qr{Glacial Erratics}
    ],
    [ "\n{fetchrss http://www.flickr.com/services/feeds/photos_public.gne?id=44124457654\@N01&format=atom_03 1}\n\n" =>
      qr{cdent's Photos}
    ],
);

my $test_count = scalar @tests;

plan tests => $test_count;

SKIP: {
    eval {require Kwiki::Test};
    skip 'we need Kwiki::Test to test', $test_count if $@;
        
    my $kwiki = Kwiki::Test->new->init([
        'Kwiki::FetchRSS',
        ]);

    my $formatter = $kwiki->hub->formatter;

    for my $test (@tests) {
        my $result = $formatter->text_to_html( $test->[0] );
        like( $result, $test->[1], $test->[0] );
    }

    $kwiki->cleanup;
}
