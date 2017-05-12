use strict;
use warnings;
use Test::Base;
use HTTP::DetectUserAgent;
use YAML 0.83;

plan tests =>  (5 * blocks);

filters {
    input    => [qw(chomp)],
    expected => [qw(yaml)],
};

run {
    my $block = shift;
    my $ua = HTTP::DetectUserAgent->new($block->input);
    my $expected = $block->expected;

    is $ua->type, "Browser", "TYPE";
    is $ua->name, $expected->{name}, "NAME";
    is $ua->version, $expected->{version}, "VERSION";
    is $ua->vendor, $expected->{vendor}, "VENDOR";
    is $ua->os, $expected->{os}, "OS";
}

__END__
=== Internet Explorer 1
--- input
Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; SV1; .NET CLR 1.1.4322)
--- expected
name: "Internet Explorer"
version: "7.0"
vendor: "Microsoft"
os: "Windows"

=== Internet Explorer 1
--- input
Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; SV1; .NET CLR 1.1.4322)
--- expected
name: "Internet Explorer"
version: "7.0"
vendor: "Microsoft"
os: "Windows"

=== Internet Explorer 2
--- input
Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.0; InfoPath.1)
--- expected
name: "Internet Explorer"
version: "6.0"
vendor: "Microsoft"
os: "Windows"

=== Internet Explorer 3
--- input
Mozilla/4.0 (compatible; MSIE 8.0; Windows NT 5.1; Trident/4.0; GTB6; .NET CLR 1.1.4322) 
--- expected
name: "Internet Explorer"
version: "8.0"
vendor: "Microsoft"
os: "Windows"

=== Sleipnir
--- input
Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; SV1; .NET CLR 1.1.4322; .NET CLR 2.0.50727; InfoPath.1) Sleipnir/2.8.0
--- expected
name: "Sleipnir"
version: "2.8.0"
vendor: "Fenrir"
os: "Windows"

=== Lunascape
--- input
Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; SV1; .NET CLR 1.1.4322; .NET CLR 2.0.50727; Lunascape 4.7.3)
--- expected
name: "Lunascape"
version: "4.7.3"
vendor: "Lunascape"
os: "Windows"

=== Safari
--- input
Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_5_4; ja-jp) AppleWebKit/525.18 (KHTML, like Gecko) Version/3.1.2 Safari/525.20.1
--- expected
name: "Safari"
version: "3.1.2"
vendor: "Apple"
os: "Macintosh"

=== Chorme
--- input
Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US) AppleWebKit/525.13 (KHTML, like Gecko) Chrome/0.2.149.27 Safari/525.13
--- expected
name: "Chrome"
version: "0.2.149.27"
vendor: "Google"
os: "Windows"

=== Opera
--- input
Opera/9.52 (Windows NT 5.1; U; ja)
--- expected
name: "Opera"
version: "9.52"
vendor: "Opera"
os: "Windows"

=== Firefox
--- input
Mozilla/5.0 (Windows; U; Windows NT 5.1; ja; rv:1.9.0.2) Gecko/2008091620 Firefox/3.0.2,gzip(gfe),gzip(gfe)
--- expected
name: "Firefox"
version: "3.0.2"
vendor: "Mozilla"
os: "Windows"

=== iPhone
--- input
Mozilla/5.0 (iPhone; U; CPU iPhone OS 3_0_1 like Mac OS X; ja-jp) AppleWebKit/528.18 (KHTML, like Gecko) Version/4.0 Mobile/7A400 Safari/528.16
--- expected
name: "Safari"
version: "4.0"
vendor: "Apple"
os: "iPhone OS"

