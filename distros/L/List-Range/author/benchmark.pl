use strict;
use warnings;

use Benchmark qw/cmpthese timethese/;

use List::Range;
use List::Range::Set;
use List::Range::Search::Binary;
use List::Range::Search::Liner;

my $small = List::Range::Set->new('Small' => [
    map { List::Range->new(name => $_.'..'.($_+9), lower => $_, upper => $_+9) } grep { $_ % 10 == 0 } 0..100,
]);

my $middle = List::Range::Set->new('Middle' => [
    map { List::Range->new(name => $_.'..'.($_+9), lower => $_, upper => $_+9) } grep { $_ % 10 == 0 } 0..1000,
]);

my $large = List::Range::Set->new('Large' => [
    map { List::Range->new(name => $_.'..'.($_+9), lower => $_, upper => $_+9) } grep { $_ % 10 == 0 } 0..10000,
]);

my @target = map { $_ - 10000 } grep { $_ % 13 == 0 } 0..100000;

{
    warn '============== SMALL ==============';
    my $binary = List::Range::Search::Binary->new($small);
    my $liner  = List::Range::Search::Liner->new($small);
    cmpthese timethese -10 => {
        binary => sub {
            $binary->find($_) for @target;
        },
        liner => sub {
            $liner->find($_) for @target;
        },
    };
}

{
    warn '============== MIDDLE ==============';
    my $binary = List::Range::Search::Binary->new($middle);
    my $liner  = List::Range::Search::Liner->new($middle);
    cmpthese timethese -10 => {
        binary => sub {
            $binary->find($_) for @target;
        },
        liner => sub {
            $liner->find($_) for @target;
        },
    };
}

{
    warn '============== LARGE ==============';
    my $binary = List::Range::Search::Binary->new($large);
    my $liner  = List::Range::Search::Liner->new($large);
    cmpthese timethese -10 => {
        binary => sub {
            $binary->find($_) for @target;
        },
        liner => sub {
            $liner->find($_) for @target;
        },
    };
}


