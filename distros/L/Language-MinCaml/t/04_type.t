use strict;
use Test::More tests => 28;

my $class = 'Language::MinCaml::Type';

use_ok($class);

### test new
{
    my $type = $class->new('hoge', 'fuga', 'hige');
    isa_ok($type, $class);
    is($type->kind, 'hoge');
    ok(eq_array($type->children, ['fuga', 'hige']));
}

### test Type_XXX
{
    no strict 'refs';
    my @func_names = 
        qw(Type_Unit Type_Bool Type_Int Type_Float Type_Tuple
           Type_Array Type_Var Type_Fun);

    for my $func_name (@func_names){
        my $type = $func_name->('hoge', 'fuga');
        my $type_kind = $func_name;
        $type_kind =~ s/^Type_//;

        isa_ok($type, $class);
        is($type->kind, $type_kind);
        ok(eq_array($type->children, ['hoge', 'fuga']));
    }
}


