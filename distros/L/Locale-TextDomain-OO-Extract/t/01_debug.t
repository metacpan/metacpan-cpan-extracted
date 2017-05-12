#!perl -T

use strict;
use warnings;

use Test::More;
BEGIN {
    $ENV{AUTHOR_TESTING}
        or plan skip_all => 'Author test. Set $ENV{AUTHOR_TESTING} to a true value to run.';
}
use Test::NoWarnings;
use Test::Differences;

BEGIN {
    plan tests => 4;
    use_ok 'Locale::TextDomain::OO::Extract::Base::RegexBasedExtractor';
}

my $text_rule
    = [
        # 'text with 0 .. n escaped chars'
        qr{
            \s* ( ['] )
            (
                [^\\']*              # normal text
                (?: \\ . [^\\']* )*  # maybe followed by escaped char and normal text
            )
            [']
        }xms,
    ];

my $start_rule = qr{ loc_ \( }xms;

my $rules = [
    'begin',
    qr{ \b loc_ \s* [(] }xms,
    'and',
    $text_rule,
    'end',
];

sub _chomp ($) {
    local $_ = shift;

    chomp;

    return $_;
};

my @expected_debug = (
    [
        'stack start',
        _chomp(<<'EOT'),
$stack = [
{
start_pos => 1
}
];
EOT
    ],
    [
        'rules start',
        '0: Starting at pos 1.',
    ],
    [
        'rules begin',
        '0: Begin.',
    ],
    [
        'rules current pos',
        '0: Set the current pos to 1.',
    ],
    [
        'rules match',
        _chomp(<<'EOT'),
0: Rule
(?^msx: \b loc_ \s* [(] )
has matched
loc_(
The current pos is 6.
EOT
    ],
    [
        'rules next',
        '0: And next rule.',
    ],
    [
        'rules child',
        '0: Going to child.',
    ],
    [
        'rules current pos',
        '1: Set the current pos to 6.',
    ],
    [
        'rules match',
        _chomp(<<'EOT'),
1: Rule
(?^msx:
\s* ( ['] )
(
[^\\']* # normal text
(?: \\ . [^\\']* )* # maybe followed by escaped char and normal text
)
[']
)
has matched
'foo bar'
The current pos is 16.
EOT
    ],
    [
        'rules last',
        '1: No more rules found.',
    ],
    [
        'rules parent',
        '1: Going back to parent.',
    ],
    [
        'rules end',
        '0: End, so store data.',
    ],
    [
        'rules last',
        '0: No more rules found.',
    ],
    [
        'stack clean',
        _chomp(<<'EOT'),
$stack = [
{
line_number => 1,
match => [
"'",
"foo bar"
],
start_pos => 1
}
];
EOT
    ]
);
my @got_debug;
my $extractor = Locale::TextDomain::OO::Extract::Base::RegexBasedExtractor->new(
    content_ref => \q{ loc_( 'foo bar' ) },
    start_rule => $start_rule,
    rules      => $rules,
    debug_code => sub {
        my ( $group, $message )  = @_;
        $message =~ s{ ^ [ ]+ }{}xmsg;
        $message =~ s{ [ ]{2,} }{ }xmsg;
        push @got_debug, [ $group, $message ]
    },
);
$extractor->extract;

eq_or_diff
    \@got_debug,
    \@expected_debug,
    'debug output';

my @stack_data = (
    {
        line_number => 1,
        match => [
            q{'},
            'foo bar',
        ],
        start_pos => 1,
    },
);
eq_or_diff
    $extractor->stack,
    \@stack_data,
    'stack data';
