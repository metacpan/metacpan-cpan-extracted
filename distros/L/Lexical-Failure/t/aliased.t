use Test::Effects;
use 5.014;

plan tests => 13;

use lib 'tlib';

{
    use AliasModule;

    my $CROAK_LINE = __FILE__ . ' line ' . (__LINE__ + 1);
    eval { AliasModule::dont_succeed() };
    like $@, qr{\A \QDidn't succeed at $CROAK_LINE\E }xms => 'fail --> default';
#    effects_ok { AliasModule::dont_succeed() }
#               { die => qr{\A \QDidn't succeed at $CROAK_LINE\E }xms }
#               => 'fail --> default';
};

{
    use AliasModule errors => 'croak';

    my $CROAK_LINE = __FILE__ . ' line ' . (__LINE__ + 1);
    eval { AliasModule::dont_succeed() };
    like $@, qr{\A \QDidn't succeed at $CROAK_LINE\E }xms => 'fail --> croak';
#    effects_ok { AliasModule::dont_succeed() }
#               { die => qr{\A \QDidn't succeed at $CROAK_LINE\E }xms }
#               => 'fail --> croak';
};

{
    use AliasModule errors => 'confess';

    my $CROAK_LINE = __FILE__ . ' line ' . (__LINE__ + 1);
    eval { AliasModule::dont_succeed() };
    like $@, qr{\QAliasModule::dont_succeed() called at $CROAK_LINE\E}xms => 'fail --> confess';
#    effects_ok { AliasModule::dont_succeed() }
#               { die => qr{\QAliasModule::dont_succeed() called at $CROAK_LINE\E}xms }
#               => 'fail --> confess';
};

{
    use AliasModule errors => 'die';

    effects_ok { AliasModule::dont_succeed() }
               { die => qr{\A \QDidn't succeed at $AliasModule::DIE_LINE\E }xms }
               => 'fail --> die';
};

{
    use AliasModule errors => 'null';

    effects_ok { AliasModule::dont_succeed() }
               { scalar_return => undef }
               => 'fail --> null';

    effects_ok { AliasModule::dont_succeed() }
               { list_return => [] }
               => 'fail --> [null]';
};

{
    use AliasModule errors => 'undef';

    effects_ok { AliasModule::dont_succeed() }
               { scalar_return => undef }
               => 'fail --> undef';

    effects_ok { AliasModule::dont_succeed() }
               { list_return => [undef] }
               => 'fail --> [undef]';
};

subtest 'fail --> failobj', sub {
    plan tests => 9;

    use AliasModule errors => 'failobj';

    my $FAIL_LINE  = __LINE__ + 3;
    my $CROAK_LINE = __FILE__ . ' line ' . $FAIL_LINE;
    my $FAIL_CONTEXT = "call to AliasModule::dont_succeed at $CROAK_LINE";
    my $result = AliasModule::dont_succeed();

    is ref($result), 'Lexical::Failure::Objects'     => 'Correct return type';
    ok !$result                                      => 'Correct boolean value';
    is $result->line,    $FAIL_LINE                  => 'Correct context line';
    is $result->file,    (__FILE__)                  => 'Correct context file';
    is $result->subname, 'AliasModule::dont_succeed' => 'Correct context sub';
    is $result->context, $FAIL_CONTEXT               => 'Correct context string';

    my $TRIGGER_LINE = __FILE__ . ' line ' . (__LINE__ + 1);
    effects_ok { 1 + $result }
               { die => qr{\A \QDidn't succeed at $CROAK_LINE\E \s* \QAttempt to use failure returned by AliasModule::dont_succeed in addition at $TRIGGER_LINE\E }xms }
               => 'Correct death when misused as number';

    $TRIGGER_LINE = __FILE__ . ' line ' . (__LINE__ + 1);
    effects_ok { "$result" }
               { die => qr{\A \QDidn't succeed at $CROAK_LINE\E \s* \QAttempt to use failure returned by AliasModule::dont_succeed as string at $TRIGGER_LINE\E }xms }
               => 'Correct death when misused as string';

    $TRIGGER_LINE = __FILE__ . ' line ' . (__LINE__ + 1);
    effects_ok { %{$result} }
               { die => qr{\A \QDidn't succeed at $CROAK_LINE\E \s* \QAttempt to use failure returned by AliasModule::dont_succeed as hash reference at $TRIGGER_LINE\E }xms }
               => 'Correct death when misused as hashref';
};

{
    my $errmsg;
    subtest 'fail --> func', sub {
        plan tests => 2;

        use AliasModule errors => sub { $errmsg = "@_"; return; };

        my $CROAK_LINE = __FILE__ . ' line ' . (__LINE__ + 1);
        effects_ok { AliasModule::dont_succeed() }
                { return => undef }
                => 'fail --> func';

        is $errmsg, "Didn't succeed"
                    => 'Correct error message';
    };
}

{
    my $errmsg;
    subtest 'fail --> scalar', sub {
        plan tests => 2;

        use AliasModule errors => \$errmsg;

        effects_ok { AliasModule::dont_succeed() }
                { return => undef }
                => 'Correct effects';

        is $errmsg->[0], "Didn't succeed"
                    => 'Correct error message';
    };
}


{
    my @errmsgs;
    subtest 'fail --> array', sub {
        plan tests => 7;

        use AliasModule errors => \@errmsgs;

        effects_ok { AliasModule::dont_succeed() }
                   { return => undef }
                   => 'Correct effects';

        ok @errmsgs == 1                    => 'Correct number of pushes';
        is $errmsgs[0][0], "Didn't succeed" => 'Correct error message';

        $errmsgs[0] = undef;

        effects_ok { AliasModule::dont_succeed() }
                   { return => undef }    => 'Correct effects again';

        ok @errmsgs == 2                    => 'Correct number of pushes again';
        is $errmsgs[0], undef()             => 'Correct slot pushed';
        is $errmsgs[1][0], "Didn't succeed" => 'Correct error message again';

    };
}


{
    my %errmsg_from;
    subtest 'fail --> hash', sub {
        plan tests => 4;

        use AliasModule errors => \%errmsg_from;

        effects_ok { AliasModule::dont_succeed() }
                   { return => undef }                                => 'Correct effects';

        ok keys %errmsg_from == 1                                         => 'Correct number of entries';
        ok exists $errmsg_from{'AliasModule::dont_succeed'}               => 'Correct key';
        is $errmsg_from{'AliasModule::dont_succeed'}[0], "Didn't succeed" => 'Correct value';
    };
}

