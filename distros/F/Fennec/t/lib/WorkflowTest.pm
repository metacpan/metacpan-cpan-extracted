package WorkflowTest;
use strict;
use warnings;

use Test::More;
use Test::Workflow;

our @RUN_ORDER;

describe a => sub {
    push @RUN_ORDER => "Describe";

    before_all b  => sub { push @RUN_ORDER => "Before All" };
    before_each c => sub { push @RUN_ORDER => "Before Each" };

    it d => sub {
        push @RUN_ORDER => "It";
    };

    after_each e => sub { push @RUN_ORDER => "After Each" };
    after_all f  => sub { push @RUN_ORDER => "After All" };

    describe aa => sub {
        push @RUN_ORDER => "Describe Nested";

        before_all bb  => sub { push @RUN_ORDER => "Before All Nested" };
        before_each cc => sub { push @RUN_ORDER => "Before Each Nested" };

        around_each ar => sub {
            my $self = shift;
            my ($runme) = @_;
            push @RUN_ORDER => "around start";
            $runme->();
            push @RUN_ORDER => "around end";
        };

        it dd => sub {
            push @RUN_ORDER => "It Nested";
        };

        it xx => sub {
            push @RUN_ORDER => "It Nested xx";
        };

        after_each ee => sub { push @RUN_ORDER => "After Each Nested" };
        after_all ff  => sub { push @RUN_ORDER => "After All Nested" };
    };
};

cases m => sub {
    push @RUN_ORDER => 'm';
    case a  => sub { push @RUN_ORDER => 'a' };
    case b  => sub { push @RUN_ORDER => 'b' };
    case c  => sub { push @RUN_ORDER => 'c' };
    tests x => sub { push @RUN_ORDER => 'x' };
    tests y => sub { push @RUN_ORDER => 'y' };
    tests z => sub { push @RUN_ORDER => 'z' };
};

tests verify => sub {
    is_deeply(
        \@RUN_ORDER,
        [
            # Generators
            "Describe",
            "Describe Nested",
            "m",

            # Cases
            qw/a x  a y  a z/,
            qw/b x  b y  b z/,
            qw/c x  c y  c z/,

            #<<< no-tidy
            "Before All",
                "Before Each",
                    "It",
                "After Each",

                "Before All Nested",
                    "Before Each",
                        "Before Each Nested",
                            "around start",
                                "It Nested",
                            "around end",
                        "After Each Nested",
                    "After Each",

                    "Before Each",
                        "Before Each Nested",
                            "around start",
                                "It Nested xx",
                            "around end",
                        "After Each Nested",
                    "After Each",
                "After All Nested",
            "After All",
            #>>>
        ],
        "Order is correct"
    );
};

1;
