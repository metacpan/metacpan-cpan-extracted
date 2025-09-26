use strict;
use warnings;

use Encode::Wide qw(wide_to_html wide_to_xml);
use Test::Most;

my @tests = (
    {
        desc     => 'Empty string',
        input    => '',
        html     => '',
        xml      => '',
    }, {
        desc     => 'ASCII only',
        input    => 'Hello, World.',
        html     => 'Hello, World.',
        xml      => 'Hello, World.',
    },
    {
        desc     => 'Control characters',
        input    => "Line1\nLine2\tTabbed",
        html     => "Line1\nLine2\tTabbed",
        xml      => "Line1\nLine2\tTabbed",
    },
    {
        desc     => 'Already encoded entities',
        input    => '10 &lt; 20 &amp; 30',
        html     => '10 &lt; 20 &amp; 30',
        xml      => '10 &lt; 20 &amp; 30',
    },
    {
        desc     => 'Latin-1 accents',
        input    => "Café déjà vu – naïve façade",
        html     => 'Caf&eacute; d&eacute;j&agrave; vu &ndash; na&iuml;ve fa&ccedil;ade',
        xml      => 'Caf&#x0E9; d&#x0E9;j&#x0E0; vu - na&#x0EF;ve fa&#x0E7;ade',
    },
    # {
        # desc     => 'Emoji and Unicode outside BMP',
        # input    => "Smiley: 😀 Rocket: 🚀",
        # html     => 'Smiley: &#x1F600; Rocket: &#x1F680;',
        # xml      => 'Smiley: &#x1F600; Rocket: &#x1F680;',
    # },
    # {
        # desc     => 'CJK characters (Chinese)',
        # input    => "中文测试",
        # html     => '&#x4E2D;&#x6587;&#x6D4B;&#x8BD5;',
        # xml      => '&#x4E2D;&#x6587;&#x6D4B;&#x8BD5;',
    # },
    # {
        # desc     => 'Arabic (RTL text)',
        # input    => "السلام عليكم",
        # html     => '&#x627;&#x644;&#x633;&#x644;&#x627;&#x645; &#x639;&#x644;&#x64A;&#x643;&#x645;',
        # xml      => '&#x627;&#x644;&#x633;&#x644;&#x627;&#x645; &#x639;&#x644;&#x64A;&#x643;&#x645;',
    # },
    # {
        # desc     => 'Combining characters (e.g., a + ́)',
        # input    => "a\u0301",  # "a" followed by U+0301 COMBINING ACUTE ACCENT
        # html     => 'a&#x301;',
        # xml      => 'a&#x301;',
    # },
    # {
        # desc     => 'Bidirectional edge case: Hebrew + numbers',
        # input    => "מספר 123",
        # html     => '&#x5DE;&#x5E1;&#x5E4;&#x5E8; 123',
        # xml      => '&#x5DE;&#x5E1;&#x5E4;&#x5E8; 123',
    # },
    {
        desc     => 'Invalid UTF-8',
        input    => eval { pack("C*", 0x80, 0xFF) },
        html     => '&#x80;&#xFF;',
        xml      => '&#x80;&#xFF;',
    },
);

foreach my $t (@tests) {
	eval { is(wide_to_html($t->{input}), $t->{html}, "HTML: $t->{desc}") }; diag($@) if($@);
	eval { is(wide_to_xml($t->{input}),  $t->{xml},  "XML:  $t->{desc}") }; diag($@) if($@);
}

done_testing();
