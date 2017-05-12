no warnings 'experimental::lexical_subs'; # YES SUB,main::BEGIN,BEGIN
use feature 'lexical_subs';               # YES SUB,main::BEGIN,BEGIN

my $a;                                    # YES
my $covered = sub {
    $a = 1;                               # YES SUB,main::__ANON__,RUN
};                                        # YES
my $uncovered = sub {
    $a = 2;                               # NO  SUB,main::__ANON__,
};                                        # YES

sub foo {
    $a = 3;                               # YES SUB,main::foo,RUN
    my sub lexical {
        $a = 4;                           # YES SUB,main::lexical,RUN
    }
    $a = 5;                               # YES
    lexical();                            # YES
}

foo();                                    # YES
$covered->();                             # YES
