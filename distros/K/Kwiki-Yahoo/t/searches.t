use strict;
use warnings;
use Test::More;


BEGIN {
    eval {require Kwiki::Test;};
    $::skip = 1 if $@;
}

use lib '../lib';

my @tests = (
    {
        wafl    => '{yahoo_doc kwiki}',
        count   => 10,
        output1 => qr{KwikiKwiki - The Official},
    },
    {
        wafl    => '{yahoo_image groundhog |Count => 20}',
        count   => 20,
        output1 => qr{<img.*src=}
    },
    {
        wafl    => '{yahoo_video international poverty site:worldbank.org}',
        output1 => qr{\.rm},
    },
    {
        wafl    => q({yahoo_news "les enfants" |Language => 'fr'}),
        output1 => qr{les enfants},
    },
    {
        wafl    => q({yahoo_local vegetarian teapot |PostalCode => 98112}),
        output1 => qr{Teapot Vegetarian.*House},
    },
    {
        wafl    => q({yahoo_spell vegtarian}),
        output1 => qr{vegetarian},
    },
    {   
        wafl    => q({yahoo_related sport}),
        count   => 10,
    },
);

my $test_count = grep($_->{count}, @tests) + grep($_->{output1}, @tests);
plan tests => $test_count;

SKIP: {
    skip "Kwiki::Test required for testing", $test_count if $::skip;
    my $kwiki = Kwiki::Test->new->init(['Kwiki::Yahoo']);

    # XXX should perhaps just do this against the data class...
    my $formatter = $kwiki->hub->formatter;

    for my $test (@tests) {
        my $result = $formatter->text_to_html("\n" . $test->{wafl} . "\n\n");
        my $count = $test->{count};
        if ($count) {
            my @lines = split(/<div class="yahoo_item/, $result);
            my $lines = scalar(@lines) - 1;
            is($lines, $count, "got $count results");
        }
        my $output = $test->{output1};
        if ($output) {
            like($result, $output, "seeing correct $output");
        }
    }

    $kwiki->cleanup;
}
