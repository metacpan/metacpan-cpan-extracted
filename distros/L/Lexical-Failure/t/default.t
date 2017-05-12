use Test::Effects;
use 5.014;

plan tests => 1;

use lib 'tlib';

subtest 'fail --> default failobj', sub {
    plan tests => 9;

    use DefaultModule;

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

