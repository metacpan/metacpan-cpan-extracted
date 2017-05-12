use strict;
use warnings;
use Test::More;

use lib '../lib';

my $key = 'febe762f0c746d1b15ed54168c0d58e6';

my @tests = (
    [ "\n{technorati http://www.burningchrome.com/~cdent/mt}\n\n" =>
      qr{Glacial Erratics}
    ],
);

my $test_count = scalar @tests;

plan tests => $test_count;

SKIP: {
    eval {require Kwiki::Test};
    skip 'we need Kwiki::Test to test', $test_count if $@;
    skip 'we need a technorati key to test', $test_count unless $key;
        
    my $kwiki = Kwiki::Test->new->init([
        'Kwiki::FetchRSS',
        'Kwiki::Technorati',
        ]);

    $kwiki->hub->config->technorati_key($key);
    my $formatter = $kwiki->hub->formatter;


    for my $test (@tests) {
        my $result = $formatter->text_to_html( $test->[0] );
        like( $result, $test->[1], $test->[0] );
    }

    $kwiki->cleanup;
}
