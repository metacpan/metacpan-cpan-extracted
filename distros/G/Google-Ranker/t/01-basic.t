use Test::More;

use Google::Ranker;

#plan skip_all => "Do TEST_RELEASE=1 to go out to Google and run some tests" unless $ENV{TEST_RELEASE};
plan qw/no_plan/;

my $referer = "http://search.cpan.org/~rkrimen/";
my $key = "ABQIAAAAtDqLrYRkXZ61bOjIaaXZyxQRY_BHZpnLMrZfJ9KcaAuQJCJzjxRJoUJ6qIwpBfxHzBbzHItQ1J7i0w";

SKIP: {
    skip "Do TEST_RELEASE=1 to go out to Google and run some tests" unless $ENV{TEST_RELEASE};
    my $rank;

    $rank = Google::Ranker->rank("search.cpan.org", { q => "perl network", key => $key, referer => $referer });
    is($rank, 8);

    $rank = Google::Ranker->rank("rock.com", { q => "rock", key => $key, referer => $referer });
    is($rank, 1);

    $rank = Google::Ranker->rank("rock.com", { q => "snoo snoo time!", key => $key, referer => $referer });
    is($rank, undef);

    $search = Google::Search->Video(q => "tay zonday", key => $key, referer => $referer);
    $rank = Google::Ranker->rank(sub { $_[0]->titleNoFormatting =~ m/Chocolate Rain/i }, $search);
    is($rank, 1);

    $rank = Google::Ranker->rank("search.cpan.org", "perl network");
    is($rank, 8);
}
