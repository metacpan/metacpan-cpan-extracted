use strict;
use Test::More tests => 38;
use Language::MinCaml::Code;
use Language::MinCaml::Lexer;
use Language::MinCaml::Node;
use Language::MinCaml::Type;

my $class = 'Language::MinCaml::Parser';

use_ok($class);

### test new
{
    my $parser = $class->new;
    isa_ok($parser, $class);
}

my $code_class = 'Language::MinCaml::Code';
my $lexer_class = 'Language::MinCaml::Lexer';

### test next_token
{
    my $parser = $class->new;
    $parser->{lexer} = 
        $lexer_class->new($code_class->from_string('hoge'));

    my @first_token_data = $parser->next_token;
    is($first_token_data[0], 'IDENT');
    is($first_token_data[1], 'hoge');

    my @second_token_data = $parser->next_token;
    is($second_token_data[0], '');
    is($second_token_data[1], undef);
}

### test parse
{
    my $parser = $class->new;
    my $lexer;

    $lexer = $lexer_class->new($code_class->from_string('10'));
    is_deeply($parser->parse($lexer), Node_Int('10'));

    $lexer = $lexer_class->new($code_class->from_string('10.0'));
    is_deeply($parser->parse($lexer), Node_Float('10.0'));

    $lexer = $lexer_class->new($code_class->from_string('hoge'));
    is_deeply($parser->parse($lexer), Node_Var('hoge'));

    $lexer = $lexer_class->new($code_class->from_string('true'));
    is_deeply($parser->parse($lexer), Node_Bool('true'));

    $lexer = $lexer_class->new($code_class->from_string('()'));
    is_deeply($parser->parse($lexer), Node_Unit());

    $lexer = $lexer_class->new($code_class->from_string('(10)'));
    is_deeply($parser->parse($lexer), Node_Int('10'));

    $lexer = $lexer_class->new($code_class->from_string('hoge.(10)'));
    is_deeply($parser->parse($lexer), Node_Get(Node_Var('hoge'), Node_Int(10)));

    $lexer = $lexer_class->new($code_class->from_string('not true'));
    is_deeply($parser->parse($lexer), Node_Not(Node_Bool('true')));

    $lexer = $lexer_class->new($code_class->from_string('-10.0'));
    is_deeply($parser->parse($lexer), Node_Float('-10.0'));

    $lexer = $lexer_class->new($code_class->from_string('-10'));
    is_deeply($parser->parse($lexer), Node_Neg(Node_Int('10')));

    $lexer = $lexer_class->new($code_class->from_string('1 + 2'));
    is_deeply($parser->parse($lexer), Node_Add(Node_Int('1'), Node_Int('2')));

    $lexer = $lexer_class->new($code_class->from_string('1 - 2'));
    is_deeply($parser->parse($lexer), Node_Sub(Node_Int('1'), Node_Int('2')));

    $lexer = $lexer_class->new($code_class->from_string('hoge = 1'));
    is_deeply($parser->parse($lexer), Node_Eq(Node_Var('hoge'), Node_Int('1')));

    $lexer = $lexer_class->new($code_class->from_string('hoge <> 1'));
    is_deeply($parser->parse($lexer), Node_Not(Node_Eq(Node_Var('hoge'), Node_Int('1'))));

    $lexer = $lexer_class->new($code_class->from_string('hoge < 1'));
    is_deeply($parser->parse($lexer), Node_Not(Node_LE(Node_Int('1'), Node_Var('hoge'))));

    $lexer = $lexer_class->new($code_class->from_string('hoge > 1'));
    is_deeply($parser->parse($lexer), Node_Not(Node_LE(Node_Var('hoge'), Node_Int('1'))));

    $lexer = $lexer_class->new($code_class->from_string('hoge <= 1'));
    is_deeply($parser->parse($lexer), Node_LE(Node_Var('hoge'), Node_Int('1')));

    $lexer = $lexer_class->new($code_class->from_string('hoge >= 1'));
    is_deeply($parser->parse($lexer), Node_LE(Node_Int('1'), Node_Var('hoge')));

    $lexer = $lexer_class->new($code_class->from_string('if hoge then true else false'));
    is_deeply($parser->parse($lexer), Node_If(Node_Var('hoge'), Node_Bool('true'), Node_Bool('false')));

    $lexer = $lexer_class->new($code_class->from_string('-. 10.0'));
    is_deeply($parser->parse($lexer), Node_FNeg(Node_Float('10.0')));

    $lexer = $lexer_class->new($code_class->from_string('10.0 +. 20.0'));
    is_deeply($parser->parse($lexer), Node_FAdd(Node_Float('10.0'), Node_Float('20.0')));

    $lexer = $lexer_class->new($code_class->from_string('10.0 -. 20.0'));
    is_deeply($parser->parse($lexer), Node_FSub(Node_Float('10.0'), Node_Float('20.0')));

    $lexer = $lexer_class->new($code_class->from_string('10.0 *. 20.0'));
    is_deeply($parser->parse($lexer), Node_FMul(Node_Float('10.0'), Node_Float('20.0')));

    $lexer = $lexer_class->new($code_class->from_string('10.0 /. 20.0'));
    is_deeply($parser->parse($lexer), Node_FDiv(Node_Float('10.0'), Node_Float('20.0')));

    $lexer = $lexer_class->new($code_class->from_string('let hoge = 10 in hoge'));
    is_deeply($parser->parse($lexer),
              Node_Let(['hoge', Type_Var()], Node_Int('10'), Node_Var('hoge')));

    $lexer = $lexer_class->new($code_class->from_string('let rec hoge a b = c in true'));
    is_deeply($parser->parse($lexer),
              Node_LetRec({ident => ['hoge', Type_Var()],
                           args => [['a', Type_Var()], ['b', Type_Var()]],
                           body => Node_Var('c')},
                          Node_Bool('true')));

    $lexer = $lexer_class->new($code_class->from_string('hoge 10 20'));
    is_deeply($parser->parse($lexer),
              Node_App(Node_Var('hoge'),
                       [Node_Int('10'), Node_Int('20')]));

    $lexer = $lexer_class->new($code_class->from_string('true,10.0,10'));
    is_deeply($parser->parse($lexer),
              Node_Tuple([Node_Bool('true'), Node_Float('10.0'), Node_Int('10')]));

    $lexer = $lexer_class->new($code_class->from_string('let (hoge,fuga,hige) = foo in bar'));
    is_deeply($parser->parse($lexer),
              Node_LetTuple([['hoge', Type_Var()], ['fuga', Type_Var()], ['hige', Type_Var()]],
                            Node_Var('foo'),
                            Node_Var('bar')));

    $lexer = $lexer_class->new($code_class->from_string('hoge.(10) <- fuga'));
    is_deeply($parser->parse($lexer),
              Node_Put(Node_Var('hoge'), Node_Int('10'), Node_Var('fuga')));

    $lexer = $lexer_class->new($code_class->from_string('hoge;fuga'));
    is_deeply($parser->parse($lexer),
              Node_Let(['Unit0', Type_Unit()], Node_Var('hoge'), Node_Var('fuga')));

    $lexer = $lexer_class->new($code_class->from_string('Array.create 10 20'));
    is_deeply($parser->parse($lexer),
              Node_Array(Node_Int('10'), Node_Int('20')));
}
