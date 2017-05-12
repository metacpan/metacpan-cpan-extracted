use Test::Effects;
use 5.014;

plan tests => 14;

use lib 'tlib';

{
    my $CROAK_LINE = __FILE__ . ' line ' . (__LINE__ + 1);
    eval{ TestModule::dont_succeed() };
    like $@, qr{\A \QDidn't succeed at $CROAK_LINE\E }xms => 'fail --> default';
#    effects_ok { TestModule::dont_succeed() }
#               { die => qr{\A \QDidn't succeed at $CROAK_LINE\E }xms }
#               => 'fail --> default';
};

{
    use TestModule errors => undef;

    my $CROAK_LINE = __FILE__ . ' line ' . (__LINE__ + 1);
    eval{ TestModule::dont_succeed() };
    like $@, qr{\A \QDidn't succeed at $CROAK_LINE\E }xms => 'fail --> no arg == no change';
#    effects_ok { TestModule::dont_succeed() }
#               { die => qr{\A \QDidn't succeed at $CROAK_LINE\E }xms }
#               => 'fail --> no arg == no change';
};

{
    use TestModule errors => 'croak';

    my $CROAK_LINE = __FILE__ . ' line ' . (__LINE__ + 1);
    eval{ TestModule::dont_succeed() };
    like $@, qr{\A \QDidn't succeed at $CROAK_LINE\E }xms => 'fail --> croak';
#    effects_ok { TestModule::dont_succeed() }
#               { die => qr{\A \QDidn't succeed at $CROAK_LINE\E }xms }
#               => 'fail --> croak';
};

{
    use TestModule errors => 'confess';

    my $CROAK_LINE = __FILE__ . ' line ' . (__LINE__ + 1);
    eval{ TestModule::dont_succeed() };
    like $@, qr{\QTestModule::dont_succeed() called at $CROAK_LINE\E}xms => 'fail --> confess';
#    effects_ok { TestModule::dont_succeed() }
#               { die => qr{\QTestModule::dont_succeed() called at $CROAK_LINE\E}xms }
#               => 'fail --> confess';
};

{
    use TestModule errors => 'die';

    effects_ok { TestModule::dont_succeed() }
               { die => qr{\A \QDidn't succeed at $TestModule::DIE_LINE\E }xms }
               => 'fail --> die';
};

{
    use TestModule errors => 'null';

    effects_ok { TestModule::dont_succeed() }
               { scalar_return => undef }
               => 'fail --> null';

    effects_ok { TestModule::dont_succeed() }
               { list_return => [] }
               => 'fail --> [null]';
};

{
    use TestModule errors => 'undef';

    effects_ok { TestModule::dont_succeed() }
               { scalar_return => undef }
               => 'fail --> undef';

    effects_ok { TestModule::dont_succeed() }
               { list_return => [undef] }
               => 'fail --> [undef]';
};

subtest 'fail --> failobj', sub {
    plan tests => 9;

    use TestModule errors => 'failobj';

    my $FAIL_LINE  = __LINE__ + 3;
    my $CROAK_LINE = __FILE__ . ' line ' . $FAIL_LINE;
    my $FAIL_CONTEXT = "call to TestModule::dont_succeed at $CROAK_LINE";
    my $result = TestModule::dont_succeed();

    is ref($result), 'Lexical::Failure::Objects'    => 'Correct return type';
    ok !$result                                     => 'Correct boolean value';
    is $result->line,    $FAIL_LINE                 => 'Correct context line';
    is $result->file,    (__FILE__)                 => 'Correct context file';
    is $result->subname, 'TestModule::dont_succeed' => 'Correct context sub';
    is $result->context, $FAIL_CONTEXT              => 'Correct context string';

    my $TRIGGER_LINE = __FILE__ . ' line ' . (__LINE__ + 1);
    effects_ok { 1 + $result }
               { die => qr{\A \QDidn't succeed at $CROAK_LINE\E \s* \QAttempt to use failure returned by TestModule::dont_succeed in addition at $TRIGGER_LINE\E }xms }
               => 'Correct death when misused as number';

    $TRIGGER_LINE = __FILE__ . ' line ' . (__LINE__ + 1);
    effects_ok { "$result" }
               { die => qr{\A \QDidn't succeed at $CROAK_LINE\E \s* \QAttempt to use failure returned by TestModule::dont_succeed as string at $TRIGGER_LINE\E }xms }
               => 'Correct death when misused as string';

    $TRIGGER_LINE = __FILE__ . ' line ' . (__LINE__ + 1);
    effects_ok { %{$result} }
               { die => qr{\A \QDidn't succeed at $CROAK_LINE\E \s* \QAttempt to use failure returned by TestModule::dont_succeed as hash reference at $TRIGGER_LINE\E }xms }
               => 'Correct death when misused as hashref';
};

{
    my $errmsg;
    subtest 'fail --> func', sub {
        plan tests => 2;

        use TestModule errors => sub { $errmsg = "@_"; return; };

        my $CROAK_LINE = __FILE__ . ' line ' . (__LINE__ + 1);
        effects_ok { TestModule::dont_succeed() }
                { return => undef }
                => 'fail --> func';

        is $errmsg, "Didn't succeed"
                    => 'Correct error message';
    };
}

{
    my $errmsg;
    subtest 'fail --> inner scalar', sub {
        plan tests => 2;

        use TestModule errors => \$errmsg;

        effects_ok { TestModule::dont_succeed() }
                { return => undef }
                => 'Correct effects';

        is_deeply $errmsg, ["Didn't succeed"] => 'Correct error message';
    };
}

{
    my @errmsgs;
    subtest 'fail --> array', sub {
        plan tests => 7;

        use TestModule errors => \@errmsgs;

        effects_ok { TestModule::dont_succeed() }
                   { return => undef }
                   => 'Correct effects';

        ok @errmsgs == 1                          => 'Correct number of pushes';
        is_deeply $errmsgs[0], ["Didn't succeed"] => 'Correct error message';

        $errmsgs[0] = undef;

        effects_ok { TestModule::dont_succeed() }
                   { return => undef }    => 'Correct effects again';

        ok @errmsgs == 2                          => 'Correct number of pushes again';
        is $errmsgs[0], undef()                   => 'Correct slot pushed';
        is_deeply $errmsgs[1], ["Didn't succeed"] => 'Correct error message again';

    };
}


{
    my %errmsg_from;
    subtest 'fail --> hash', sub {
        plan tests => 4;

        use TestModule errors => \%errmsg_from;

        effects_ok { TestModule::dont_succeed() }
                   { return => undef }                                => 'Correct effects';

        ok keys %errmsg_from == 1                                              => 'Correct number of entries';
        ok exists $errmsg_from{'TestModule::dont_succeed'}                     => 'Correct key';
        is_deeply $errmsg_from{'TestModule::dont_succeed'}, ["Didn't succeed"] => 'Correct value';
    };
}
