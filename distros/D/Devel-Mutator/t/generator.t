use strict;
use warnings;

use Test::More;
use Devel::Mutator::Generator;

subtest 'return list of hashrefs' => sub {
    my $code = '1 > 1';

    my $generator = Devel::Mutator::Generator->new;

    my @mutants = $generator->generate($code);

    ok ref $mutants[0] eq 'HASH';
};

subtest 'generate id' => sub {
    my $code = '1 > 1';

    my $generator = Devel::Mutator::Generator->new;

    my @mutants = $generator->generate($code);

    is $mutants[0]->{id}, 'f1ee370f06603029a758210b914cda90';
};

subtest 'mutate code' => sub {
    my $code = '1 > 1';

    my $generator = Devel::Mutator::Generator->new;

    my @mutants = $generator->generate($code);

    is $mutants[0]->{content}, '1 <= 1';
};

done_testing;
