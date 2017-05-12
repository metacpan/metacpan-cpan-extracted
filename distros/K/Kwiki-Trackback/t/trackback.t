use strict;
use warnings;
use Test::More tests => 6;

use lib '../lib';


my $ping_content = {
    url => 'http://www.burningchrome.com/~cdent/mt/archives/000361.html',
    title => 'Why Wiki?',
    blog_name => 'Glacial Erratics',
    excerpt => 'this is the excerpt',
};

SKIP: {
    eval {require Kwiki::Test};
    skip 'we need Kwiki::Test to test', 5 if $@;

    my $kwiki = Kwiki::Test->new->init([
        'Kwiki::Trackback',
        ]);

    my $hub = $kwiki->hub;
    my $trackback = $hub->trackback;

    my $xml = $trackback->trackback_ping_receive('HomePage', $ping_content);
    my $err = $trackback->trackback_ping_receive('HomePageButt', $ping_content);

    like($xml, qr{<error>0</error>}, 'correct success response code');
    like($err, qr{<error>1</error>}, 'correct error response code');

    $hub->pages->current($hub->pages->new_from_name('HomePage'));
    my $trackbacks = $trackback->trackbacks;

    is(@$trackbacks, 1, 'one trackback result');
    is($trackbacks->[0]->{url}, $ping_content->{url}, 'correct url');
    is($trackbacks->[0]->{blog_name}, $ping_content->{blog_name},
        'correct blog title');
    is($trackbacks->[0]->{excerpt}, $ping_content->{excerpt},
        'correct excerpt');

    $kwiki->cleanup;
}
