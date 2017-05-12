package tests::QuoteFilters;

use Test::Class::Most parent => 'Mason::Test::Class';

sub before : Test(setup) {
    my $self = shift;

    $self->setup_interp(
        plugins                => ['QuoteFilters'],
        no_source_line_numbers => 1,
    );
}

sub test_q : Test(1) {
    my $self = shift;

    $self->test_comp(
        src  => <<'EOF',
single quote test: <% 2 + 2 |Q %> ok
escaping: <% q{foo'bar"baz} |Q %> ok
EOF
        expect => <<'EOF',
single quote test: '4' ok
escaping: 'foo\'bar"baz' ok
EOF
    );
}

sub test_qq : Test(1) {
    my $self = shift;

    $self->test_comp(
        src  => <<'EOF',
double quote test: <% 2 + 2 |QQ %> ok
escaping: <% q{foo'bar"baz} |QQ %> ok
EOF
        expect => <<'EOF',
double quote test: "4" ok
escaping: "foo'bar\"baz" ok
EOF
    );
}

1;
