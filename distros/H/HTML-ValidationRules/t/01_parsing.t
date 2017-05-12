use strict;
use warnings;

use Test::More;
use Test::Differences;
use Test::Name::FromLine;

use t::lib::Util;
use Test::HTCT::Parser;

use HTML::ValidationRules;

for_each_test t::lib::Util::data_file('parsing.dat'), {
    html   => { is_prefixed => 1 },
    parsed => { is_prefixed => 1 },
}, sub {
    my $test = shift;

    my $parser = HTML::ValidationRules->new;
    my $rules  = $parser->load_rules(html => $test->{html}->[0]);

    my @actual;
    while (@$rules) {
        my $name  = shift @$rules;
        my $value = shift @$rules;

        push @actual, $name . "\n" . join "\n",
            map  { ref $_->[0] ? "@{$_->[0]}" : $_->[0] }
            sort { $a->[1] cmp $b->[1] }
            map  { [$_, ref $_ ? $_->[0] : $_] }
            @$value
    }
    my $actual = join "\n\n", sort { $a cmp $b } @actual;

    eq_or_diff $actual, $test->{parsed}->[0];
};

done_testing;
