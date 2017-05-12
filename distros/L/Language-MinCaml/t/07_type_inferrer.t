use strict;
use Test::More tests => 87;
use Language::MinCaml::Type;
use Language::MinCaml::Node;

my $class = 'Language::MinCaml::TypeInferrer';

use_ok($class);

### test new
{
    my $inferrer = $class->new;

    isa_ok($inferrer, $class);
}

### test deref_type
{
    my $inferrer = $class->new;

    my $var_type = Type_Var(Type_Int());
    my $ret_var_type = Type_Var(Type_Float());

    is_deeply($inferrer->deref_type($var_type), Type_Int());
    is_deeply($inferrer->deref_type(Type_Array($var_type)), Type_Array(Type_Int()));
    is_deeply($inferrer->deref_type(Type_Tuple([$var_type])), Type_Tuple([Type_Int()]));
    is_deeply($inferrer->deref_type(Type_Fun([$var_type], $ret_var_type)),
              Type_Fun([Type_Int()], Type_Float()));
}

### test deref_ident_type
{
    my $inferrer = $class->new;

    is_deeply($inferrer->deref_ident_type(['hoge', Type_Var(Type_Int())]),
              ['hoge', Type_Int()]);
}

### test deref_node
{
    my $inferrer = $class->new;
    my $var_type = Type_Var(Type_Int());

    is_deeply($inferrer->deref_node(Node_Not(Node_Bool('true'))),
              Node_Not(Node_Bool('true')));
    is_deeply($inferrer->deref_node(Node_Neg(Node_Int('100'))),
              Node_Neg(Node_Int('100')));
    is_deeply($inferrer->deref_node(Node_FNeg(Node_Float('100.0'))),
              Node_FNeg(Node_Float('100.0')));
    is_deeply($inferrer->deref_node(Node_Add(Node_Int('1'), Node_Int('2'))),
              Node_Add(Node_Int('1'), Node_Int('2')));
    is_deeply($inferrer->deref_node(Node_Sub(Node_Int('1'), Node_Int('2'))),
              Node_Sub(Node_Int('1'), Node_Int('2')));
    is_deeply($inferrer->deref_node(Node_Eq(Node_Int('1'), Node_Int('2'))),
              Node_Eq(Node_Int('1'), Node_Int('2')));
    is_deeply($inferrer->deref_node(Node_LE(Node_Int('1'), Node_Int('2'))),
              Node_LE(Node_Int('1'), Node_Int('2')));
    is_deeply($inferrer->deref_node(Node_FAdd(Node_Float('1.0'), Node_Float('2.0'))),
              Node_FAdd(Node_Float('1.0'), Node_Float('2.0')));
    is_deeply($inferrer->deref_node(Node_FSub(Node_Float('1.0'), Node_Float('2.0'))),
              Node_FSub(Node_Float('1.0'), Node_Float('2.0')));
    is_deeply($inferrer->deref_node(Node_FMul(Node_Float('1.0'), Node_Float('2.0'))),
              Node_FMul(Node_Float('1.0'), Node_Float('2.0')));
    is_deeply($inferrer->deref_node(Node_FDiv(Node_Float('1.0'), Node_Float('2.0'))),
              Node_FDiv(Node_Float('1.0'), Node_Float('2.0')));
    is_deeply($inferrer->deref_node(Node_Array(Node_Int('10'), Node_Int('2'))),
              Node_Array(Node_Int('10'), Node_Int('2')));
    is_deeply($inferrer->deref_node(Node_Get(Node_Var('hoge'), Node_Int('0'))),
              Node_Get(Node_Var('hoge'), Node_Int('0')));

    is_deeply($inferrer->deref_node(Node_If(Node_Bool('true'), Node_Int('0'), Node_Int('1'))),
              Node_If(Node_Bool('true'), Node_Int('0'), Node_Int('1')));
    is_deeply($inferrer->deref_node(Node_Put(Node_Var('hoge'), Node_Int('0'), Node_Int('1'))),
              Node_Put(Node_Var('hoge'), Node_Int('0'), Node_Int('1')));

    is_deeply($inferrer->deref_node(Node_Let(['hoge', $var_type], Node_Int('0'), Node_Int('1'))),
              Node_Let(['hoge', Type_Int()], Node_Int('0'), Node_Int('1')));

    is_deeply($inferrer->deref_node(Node_LetRec({ident => ['hoge', $var_type],
                                                 args => [['foo', Type_Int()],
                                                          ['bar', Type_Float()]],
                                                 body => Node_Int('10')},
                                                Node_Bool('false'))),
              Node_LetRec({ident => ['hoge', Type_Int()],
                           args => [['foo', Type_Int()],
                                    ['bar', Type_Float()]],
                           body => Node_Int('10')},
                          Node_Bool('false')));

    is_deeply($inferrer->deref_node(Node_App(Node_Var('hoge'),
                                             [Node_Var('foo'), Node_Var('bar')])),
              Node_App(Node_Var('hoge'),
                       [Node_Var('foo'), Node_Var('bar')]));

    is_deeply($inferrer->deref_node(Node_Tuple([Node_Var('foo'), Node_Var('bar')])),
              Node_Tuple([Node_Var('foo'), Node_Var('bar')]));

    is_deeply($inferrer->deref_node(Node_LetTuple([['hoge', $var_type]], 
                                                  Node_Var('foo'),
                                                  Node_Var('bar'))),
              Node_LetTuple([['hoge', Type_Int()]],
                            Node_Var('foo'),
                            Node_Var('bar')));
}

### test occur
{
    my $inferrer = $class->new;
    my $var_type = Type_Var();

    is($inferrer->occur($var_type, Type_Unit()), 0);

    is($inferrer->occur($var_type, Type_Fun([$var_type, Type_Int()], Type_Var())), 1);
    is($inferrer->occur($var_type, Type_Fun([Type_Var(), Type_Int()], Type_Var())), 0);

    is($inferrer->occur($var_type, Type_Tuple([$var_type, Type_Int()])), 1);
    is($inferrer->occur($var_type, Type_Tuple([Type_Var(), Type_Int()])), 0);

    is($inferrer->occur($var_type, Type_Array($var_type)), 1);
    is($inferrer->occur($var_type, Type_Array(Type_Var())), 0);

    is($inferrer->occur($var_type, $var_type), 1);
    is($inferrer->occur($var_type, Type_Var()), 0);
}

### test unify
{
    my $inferrer = $class->new;
    my $left_type;
    my $right_type;

    $left_type = Type_Unit();
    $right_type = Type_Unit();
    $inferrer->unify($left_type, $right_type);
    is_deeply($left_type, Type_Unit());
    is_deeply($right_type, Type_Unit());

    $left_type = Type_Bool();
    $right_type = Type_Bool();
    $inferrer->unify($left_type, $right_type);
    is_deeply($left_type, Type_Bool());
    is_deeply($right_type, Type_Bool());

    $left_type = Type_Int();
    $right_type = Type_Int();
    $inferrer->unify($left_type, $right_type);
    is_deeply($left_type, Type_Int());
    is_deeply($right_type, Type_Int());

    $left_type = Type_Float();
    $right_type = Type_Float();
    $inferrer->unify($left_type, $right_type);
    is_deeply($left_type, Type_Float());
    is_deeply($right_type, Type_Float());

    $left_type = Type_Fun([Type_Var(), Type_Int()], Type_Var());
    $right_type = Type_Fun([Type_Var(Type_Bool()), Type_Var()], Type_Float());
    $inferrer->unify($left_type, $right_type);
    is_deeply($left_type, Type_Fun([Type_Var(Type_Bool()), Type_Int()],
                                   Type_Var(Type_Float)));
    is_deeply($right_type, Type_Fun([Type_Var(Type_Bool()), Type_Var(Type_Int())],
                                    Type_Float()));

    $left_type = Type_Tuple([Type_Var(), Type_Int()]);
    $right_type = Type_Tuple([Type_Var(Type_Bool()), Type_Var()]);
    $inferrer->unify($left_type, $right_type);
    is_deeply($left_type, Type_Tuple([Type_Var(Type_Bool()), Type_Int()]));
    is_deeply($right_type, Type_Tuple([Type_Var(Type_Bool()), Type_Var(Type_Int())]));

    $left_type = Type_Array(Type_Var());
    $right_type = Type_Array(Type_Bool());
    $inferrer->unify($left_type, $right_type);
    is_deeply($left_type, Type_Array(Type_Var(Type_Bool())));
    is_deeply($right_type, Type_Array(Type_Bool()));

    $left_type = Type_Var(Type_Bool());
    $right_type = Type_Var(Type_Bool());
    $inferrer->unify($left_type, $right_type);
    is_deeply($left_type, Type_Var(Type_Bool()));
    is_deeply($right_type, Type_Var(Type_Bool()));

    $left_type = Type_Var(Type_Bool());
    $right_type = Type_Var();
    $inferrer->unify($left_type, $right_type);
    is_deeply($left_type, Type_Var(Type_Bool()));
    is_deeply($right_type, Type_Var(Type_Bool()));

    $left_type = Type_Var();
    $right_type = Type_Var(Type_Bool());
    $inferrer->unify($left_type, $right_type);
    is_deeply($left_type, Type_Var(Type_Bool()));
    is_deeply($right_type, Type_Var(Type_Bool()));

    $left_type = Type_Var();
    $right_type = Type_Bool();
    $inferrer->unify($left_type, $right_type);
    is_deeply($left_type, Type_Var(Type_Bool()));
    is_deeply($right_type, Type_Bool());

    $left_type = Type_Bool();
    $right_type = Type_Var();
    $inferrer->unify($left_type, $right_type);
    is_deeply($left_type, Type_Bool());
    is_deeply($right_type, Type_Var(Type_Bool()));
}

### test infer_rec
{
    my $inferrer = $class->new;

    is_deeply($inferrer->infer_rec(Node_Unit()), Type_Unit());
    is_deeply($inferrer->infer_rec(Node_Bool('truen')),
              Type_Bool());
    is_deeply($inferrer->infer_rec(Node_Int('10')), Type_Int());
    is_deeply($inferrer->infer_rec(Node_Float('10.0')),
              Type_Float());
    is_deeply($inferrer->infer_rec(Node_Float('10.0')),
              Type_Float());
    is_deeply($inferrer->infer_rec(Node_Not(Node_Bool('true'))),
              Type_Bool());
    is_deeply($inferrer->infer_rec(Node_Neg(Node_Int('10'))),
              Type_Int());
    is_deeply($inferrer->infer_rec(Node_Add(Node_Int('1'), Node_Int('2'))),
              Type_Int());
    is_deeply($inferrer->infer_rec(Node_Sub(Node_Int('1'), Node_Int('2'))),
              Type_Int());
    is_deeply($inferrer->infer_rec(Node_FNeg(Node_Float('10.0'))),
              Type_Float());
    is_deeply($inferrer->infer_rec(Node_FAdd(Node_Float('1.0'), Node_Float('2.0'))),
              Type_Float());
    is_deeply($inferrer->infer_rec(Node_FSub(Node_Float('1.0'), Node_Float('2.0'))),
              Type_Float());
    is_deeply($inferrer->infer_rec(Node_FMul(Node_Float('1.0'), Node_Float('2.0'))),
              Type_Float());
    is_deeply($inferrer->infer_rec(Node_FDiv(Node_Float('1.0'), Node_Float('2.0'))),
              Type_Float());
    is_deeply($inferrer->infer_rec(Node_Eq(Node_Int('1'), Node_Int('2'))),
              Type_Bool());
    is_deeply($inferrer->infer_rec(Node_LE(Node_Int('1'), Node_Int('2'))),
              Type_Bool());
    is_deeply($inferrer->infer_rec(Node_If(Node_Bool('true'),
                                           Node_Int('1'),
                                           Node_Int('2'))),
              Type_Int());
    is_deeply($inferrer->infer_rec(Node_Let(['hoge', Type_Var()],
                                            Node_Int('10'),
                                            Node_Var('hoge')), ()),
              Type_Var(Type_Int()));
    is_deeply($inferrer->infer_rec(Node_Var('hoge'), (hoge => Type_Int())),
              Type_Int());
    is_deeply($inferrer->infer_rec(Node_LetRec({ident => ['hoge', Type_Var()],
                                                args => [['a', Type_Var()]],
                                                body => Node_Var('a')},
                                               Node_App(Node_Var('hoge'), [Node_Int('10')])),
                                   ()),
              Type_Var(Type_Int()));
    is_deeply($inferrer->infer_rec(Node_App(Node_Var('hoge'), [Node_Int('10')]),
                                   (hoge => Type_Fun([Type_Int()], Type_Float()))),
              Type_Var(Type_Float()));
    is_deeply($inferrer->infer_rec(Node_Tuple([Node_Var('a'), Node_Var('b'), Node_Var('c')]),
                                   (a => Type_Int(), b => Type_Float(), c => Type_Bool())),
              Type_Tuple([Type_Int(), Type_Float(), Type_Bool()]));
    is_deeply($inferrer->infer_rec(Node_LetTuple([['a', Type_Var()], ['b', Type_Var()]],
                                                 Node_Tuple([Node_Int('10'), Node_Int('20')]),
                                                 Node_Add(Node_Var('a'), Node_Var('b'))),
                                   ()),
              Type_Int());
    is_deeply($inferrer->infer_rec(Node_Array(Node_Int('10'), Node_Float('1.0')), ()),
              Type_Array(Type_Float()));
    is_deeply($inferrer->infer_rec(Node_Get(Node_Array(Node_Int('3'), Node_Float('1.0')),
                                            Node_Int('1')), ()),
              Type_Var(Type_Float()));
    is_deeply($inferrer->infer_rec(Node_Put(Node_Array(Node_Int('3'), Node_Float('1.0')),
                                            Node_Int('1'),
                                            Node_Float('2.0')), ()),
              Type_Unit());
}

### test infer
{
    my $inferrer = $class->new;
    my $root_node =Node_Let(['hoge', Type_Var()],
                            Node_Int('10'),
                            Node_App(Node_Var('fuga'), [Node_Var('hoge')]));

    $inferrer->infer($root_node, ('fuga' => Type_Fun([Type_Int()], Type_Unit())));

    is_deeply($root_node,
              Node_Let(['hoge', Type_Int()],
                       Node_Int('10'),
                       Node_App(Node_Var('fuga'), [Node_Var('hoge')])));
}
