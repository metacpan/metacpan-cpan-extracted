use strict;
use warnings;
use Test::Base;
use HTTP::DetectUserAgent;
use YAML 0.83;

plan tests =>  (3 * blocks);

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
}

__END__

=== Web::Scraper
--- input
Web::Scraper/0.24
--- expected
name: "Web::Scraper"
version: "0.24"
