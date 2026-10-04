#!perl
use strict;
use warnings;

use Test2::V1 qw( -utf8 -x -strict -warnings ), -include => ['Data::Dumper'];
use Test2::Tools::Subtest qw( subtest_streamed );

use Env::Assert::Functions qw( file_to_desc :constants );

subtest_streamed 'file_to_desc #1' => sub {
    my $content = <<'EOF';
# shellcheck disable=SC2034,SC2125

# Simply assert the var exists
ALERT_EMAIL=^.*$

# Looks like a domain address
SITE_URL=^https

# POSIX regular expressions supported
GITHUB_TOKEN=^[[:word:]]{1,}$
EOF
    my $fp     = 'made/up/filepath/.envdesc';
    my %desc   = file_to_desc( $fp, ( split qr{\n}msx, $content ) );
    my %wanted = (
        opts => { 'env:exact' => 0, },
        vars => {
            ALERT_EMAIL  => { 'var:regexp' => '^.*$',             'var:required' => 1, },
            SITE_URL     => { 'var:regexp' => '^https',           'var:required' => 1, },
            GITHUB_TOKEN => { 'var:regexp' => '^[[:word:]]{1,}$', 'var:required' => 1, },
        },
    );

    # T2->diag( T2->Dumper( $desc{opts} ) );
    # T2->diag( T2->Dumper( $desc{vars} ) );
    T2->is( \%desc, \%wanted, 'Env desc data is correctly read from file' );

    T2->done_testing;
};

subtest_streamed 'file_to_desc #2' => sub {
    my $content = <<'EOF';
# shellcheck disable=SC2034,SC2125

# The env we need

## envassert (opts: env:exact)

## envassert (opts: var:required=0)
USER=^[[:word:]]{1,}$
## envassert (opts: var:required = 1)
HOME=^[/]{1}[a-z0-9/_-]{1,}[a-z0-9]{1}
## envassert (opts: var:required)
A_DIGIT=\d+
A_MISSING_VAR=^[[:word:]]{1,}$
EOF
    my $fp     = 'made/up/filepath/.envdesc';
    my %desc   = file_to_desc( $fp, ( split qr{\n}msx, $content ) );
    my %wanted = (
        opts => { 'env:exact' => 1, },
        vars => {
            USER          => { 'var:regexp' => '^[[:word:]]{1,}$',                  'var:required' => 0, },
            HOME          => { 'var:regexp' => '^[/]{1}[a-z0-9/_-]{1,}[a-z0-9]{1}', 'var:required' => 1, },
            A_DIGIT       => { 'var:regexp' => '\d+',                               'var:required' => 1, },
            A_MISSING_VAR => { 'var:regexp' => '^[[:word:]]{1,}$',                  'var:required' => 1, },
        },
    );
    T2->is( \%desc, \%wanted, 'Env desc data is correctly read from file' );

    T2->done_testing;
};

subtest_streamed 'file_to_desc #3' => sub {
    my $content = <<'EOF';
## envassert (opts: env:exact,var:required=0)
USER=^[[:word:]]{1,}$
HOME=^[/]{1}[a-z0-9/_-]{1,}[a-z0-9]{1}
EOF
    my $fp     = 'made/up/filepath/.envdesc';
    my %desc   = file_to_desc( $fp, ( split qr{\n}msx, $content ) );
    my %wanted = (
        opts => { 'env:exact' => 1, },
        vars => {
            USER => { 'var:regexp' => '^[[:word:]]{1,}$',                  'var:required' => 0, },
            HOME => { 'var:regexp' => '^[/]{1}[a-z0-9/_-]{1,}[a-z0-9]{1}', 'var:required' => 1, },
        },
    );
    T2->is( \%desc, \%wanted, 'Env desc data is correctly read from file' );

    T2->done_testing;
};

subtest_streamed 'file_to_desc #4 - compatibility' => sub {
    my $content = <<'EOF';
## envassert (opts: exact=0)
## envassert (opts: required)
USER=^[[:word:]]{1,}$
## envassert (opts: var:required=0)
HOME=^[/]{1}[a-z0-9/_-]{1,}[a-z0-9]{1}
## envassert (opts: )
A_DIGIT=\d+
EOF
    my $fp     = 'made/up/filepath/.envdesc';
    my %desc   = file_to_desc( $fp, ( split qr{\n}msx, $content ) );
    my %wanted = (
        opts => { 'env:exact' => 0, },
        vars => {
            USER    => { 'var:regexp' => '^[[:word:]]{1,}$',                  'var:required' => 1, },
            HOME    => { 'var:regexp' => '^[/]{1}[a-z0-9/_-]{1,}[a-z0-9]{1}', 'var:required' => 0, },
            A_DIGIT => { 'var:regexp' => '\d+',                               'var:required' => 1, },
        },
    );
    T2->is( \%desc, \%wanted, 'Env desc data is correctly read from file' );

    T2->done_testing;
};

=begin over comment

subtest_streamed 'file_to_desc #5 - unknown option' => sub {
    my $content = <<'EOF';
## envassert (opts: exact=0)
## envassert (opts: required)
USER=^[[:word:]]{1,}$
## envassert (opts: required=0)
HOME=^[/]{1}[a-z0-9/_-]{1,}[a-z0-9]{1}
## envassert (opts: )
A_DIGIT=\d+
EOF
    my $fp = 'made/up/filepath/.envdesc';
    T2->like( T2->dies( { file_to_desc( $fp, ( split qr{\n}msx, $content ) ) } ), qr/asdfads/msx, 'Croaked', );

    # like(
    #     dies { die 'xxx' },
    #     qr/xxx/,
    #     "Got exception"
    # );

    T2->done_testing;
};

=end over comment

=cut

T2->done_testing;
