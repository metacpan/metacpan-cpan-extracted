use strict;
use Test::More tests => 40;
use Language::MinCaml::Node;

my $class = 'Language::MinCaml::Evaluator';

use_ok($class);

### test new
{
    my $evaluator = $class->new;

    isa_ok($evaluator, $class);
}

### test compare
{
    my $evaluator = $class->new;

    is($evaluator->compare(undef, undef), 0);
    is($evaluator->compare(1, 2), -1);
    is($evaluator->compare(1, 1), 0);
    is($evaluator->compare(2, 1), 1);
    is($evaluator->compare([1, 3], [1, 2, 3]), -1);
    is($evaluator->compare([1, 2, 3], [1, 3]), 1);
    is($evaluator->compare([1, 2, 3], [1, 2, 4]), -1);
    is($evaluator->compare([1, 2, 3], [1, 2, 3]), 0);
    is($evaluator->compare([1, 2, 4], [1, 2, 3]), 1);
}

### test evaluate
{
    my $evaluator = $class->new;

    is($evaluator->evaluate(Node_Unit()), undef);

    is($evaluator->evaluate(Node_Bool('true')), 1);
    is($evaluator->evaluate(Node_Bool('false')), 0);

    is($evaluator->evaluate(Node_Int('10')), 10);
    is($evaluator->evaluate(Node_Float('10.0')), 10.0);

    is($evaluator->evaluate(Node_Not(Node_Bool('true'))), 0);
    is($evaluator->evaluate(Node_Not(Node_Bool('false'))), 1);

    is($evaluator->evaluate(Node_Neg(Node_Int('10'))), -10);
    is($evaluator->evaluate(Node_FNeg(Node_Float('10.0'))), -10.0);

    is($evaluator->evaluate(Node_Add(Node_Int('10'), Node_Int('20'))), 30);
    is($evaluator->evaluate(Node_FAdd(Node_Float('10.0'), Node_Float('20.0'))), 30.0);

    is($evaluator->evaluate(Node_Sub(Node_Int('10'), Node_Int('20'))), -10);
    is($evaluator->evaluate(Node_FSub(Node_Float('10.0'), Node_Int('20.0'))), -10.0);

    is($evaluator->evaluate(Node_FMul(Node_Float('10.0'), Node_Int('20.0'))), 200.0);

    is($evaluator->evaluate(Node_FDiv(Node_Float('10.0'), Node_Int('20.0'))), 0.5);

    is($evaluator->evaluate(Node_Eq(Node_Int('10'), Node_Int('20'))), 0);
    is($evaluator->evaluate(Node_Eq(Node_Int('10'), Node_Int('10'))), 1);

    is($evaluator->evaluate(Node_LE(Node_Int('10'), Node_Int('20'))), 1);
    is($evaluator->evaluate(Node_LE(Node_Int('10'), Node_Int('10'))), 1);
    is($evaluator->evaluate(Node_LE(Node_Int('20'), Node_Int('10'))), 0);

    is($evaluator->evaluate(Node_If(Node_Bool('true'),
                                    Node_Bool('true'),
                                    Node_Bool('false'))), 1);
    is($evaluator->evaluate(Node_If(Node_Bool('false'),
                                    Node_Bool('true'),
                                    Node_Bool('false'))), 0);

    is($evaluator->evaluate(Node_Let(['hoge', undef],
                                     Node_Int('20'),
                                     Node_Add(Node_Int('10'), Node_Var('hoge')))), 30);

    is($evaluator->evaluate(Node_LetRec({ident => ['hoge', undef], 
                                         args => [['a', undef], ['b', undef]],
                                         body => Node_Add(Node_Var('a'), Node_Var('b'))},
                                        Node_App(Node_Var('hoge'), 
                                                 [Node_Int('10'), Node_Int('20')]))), 30);

    is_deeply($evaluator->evaluate(Node_Tuple([Node_Int('10'), Node_Float('20.5'), Node_Bool('true')])),
              [10, 20.5, 1]);

    is($evaluator->evaluate(Node_LetTuple(['a', 'b'],
                                          Node_Tuple([Node_Int('10'),
                                                      Node_Int('20')]),
                                          Node_Add(Node_Var('a'), Node_Var('b')))), 30);

    is_deeply($evaluator->evaluate(Node_Array(Node_Int('3'), Node_Float('0.5'))),
              [0.5, 0.5, 0.5]);

    is($evaluator->evaluate(Node_Get(Node_Var('hoge'), Node_Int('1')),
                            (hoge => [1, 2, 3])), 2);

    is_deeply($evaluator->evaluate(Node_Let(['Unit0', undef],
                                            Node_Put(Node_Var('hoge'), Node_Int('1'), Node_Int('10')),
                                            Node_Var('hoge')),
                                            (hoge => [1, 2, 3])), [1, 10, 3]);
}

