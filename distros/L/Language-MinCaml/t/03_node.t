use strict;
use Test::More tests => 82;

my $class = 'Language::MinCaml::Node';

use_ok($class);

### test new
{
    my $node = $class->new('hoge', 'fuga', 'hige');
    isa_ok($node, $class);
    is($node->kind, 'hoge');
    ok(eq_array($node->children, ['fuga', 'hige']));
}

### test to_str
{
    my $node = $class->new('hoge', 'fuga', 'hige');
    is($node->to_str, "hoge\n");
}

{
    my $node = $class->new('hoge', 'fuga', 'hige');
    is($node->to_str(3), "\t\t\thoge\n");
}

{
    my $node = $class->new('hoge', $class->new('fuga'), 'hige');
    is($node->to_str, "hoge\n\tfuga\n");
}

### test Node_XXX
{
    no strict 'refs';
    my @func_names =
        qw(Node_Unit Node_Bool Node_Int Node_Float Node_Tuple
           Node_Array Node_Var Node_Not Node_Neg Node_Add Node_Sub
           Node_FNeg Node_FAdd Node_FSub Node_FMul Node_FDiv
           Node_Eq Node_LE Node_If Node_Let Node_LetRec Node_App
           Node_LetTuple Node_Get Node_Put);

    for my $func_name (@func_names){
        my $node = $func_name->('fuga', 'hige');
        isa_ok($node, $class);
        my $node_kind = $func_name;
        $node_kind =~ s/^Node_//;
        is($node->kind, $node_kind);
        ok(eq_array($node->children, ['fuga', 'hige']));
    }
}
