use strict;
use warnings;
use Test::Base;
use HTTP::DetectUserAgent;
use YAML 0.83;

plan tests =>  (4 * blocks);

filters {
    input    => [qw(chomp)],
    expected => [qw(yaml)],
};

run {
    my $block = shift;
    my $ua = HTTP::DetectUserAgent->new($block->input);
    my $expected = $block->expected;
    is $ua->type, "Robot";
    is $ua->name, $expected->{name};
    is $ua->version, $expected->{version};
    is $ua->vendor, $expected->{vendor};
}

__END__

=== hatena bookmark
--- input
Hatena Bookmark/0.1 (http://b.hatena.ne.jp; 40 users)
--- expected
name: "Hatena Bookmark"
version: "0.1"
vendor: "Hatena"

=== hatena antenna
--- input
Hatena Antenna/0.5 (http://a.hatena.ne.jp/help)
--- expected
name: "Hatena Antenna"
version: "0.5"
vendor: "Hatena"

=== Yahoo Pipes
--- input
Yahoo Pipes 1.0
--- expected
name: "Yahoo Pipes"
version: "1.0"
vendor: "Yahoo"

=== Pathtraq
--- input
Pathtraq/0.1 Gungho/0.09007
--- expected
name: "Pathtraq"
version: "0.1"
vendor: "Cybozu Labs"
