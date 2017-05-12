use strict;
use warnings;

use Test::More;
use Test::Name::FromLine;
use Test::Requires qw(
    FormValidator::Lite
    FormValidator::Simple
);

use t::lib::Util;
use t::lib::Object;
use Test::HTCT::Parser;

use HTML::ValidationRules;
use FormValidator::Simple qw(HTML);
use FormValidator::Lite;
FormValidator::Lite->load_constraints('HTML');

for_each_test t::lib::Util::data_file('validation.dat'), {
    html    => { is_prefixed => 1               },
    input   => { is_prefixed => 1, is_list => 1 },
    parsed  => { is_prefixed => 1               },
    invalid => { is_prefixed => 1, is_list => 1 },
}, sub {
    my $test = shift;

    my $query = t::lib::Object->new;
    my @input = map { split /=/, $_, 2 } @{$test->{input}->[0]};
    my %param;
    while (@input) {
        my $name = shift @input;
        $query->param($name, shift @input);
        $param{$name} = 1;
    }

    my $parser = HTML::ValidationRules->new;
    my $rules  = $parser->load_rules(html => $test->{html}->[0]);

    for (@{$test->{invalid}->[0] || []}) {
        $param{$_} = 0;
    }

    {
        my $validator = FormValidator::Lite->new($query);
        my $result    = $validator->check(@{$rules || []});

        is !!$result->is_error($_), !$param{$_}, $_ for keys %param;
    }

    {
        my $result = FormValidator::Simple->check($query => $rules);

        is !!$result->record($_)->is_valid, !!$param{$_}, $_ for keys %param;
    }
};

done_testing;
