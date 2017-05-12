use strict;
use Test::More tests => 98;

my $class = 'Language::MinCaml::Token';

use_ok($class);

### test new
{
    my $token = $class->new('hoge', 'fuga');
    isa_ok($token, $class);
    is($token->kind, 'hoge');
    is($token->value, 'fuga');
}

### test to_str
{
    my $token = $class->new('hoge', 'fuga');
    is($token->to_str, 'hoge[fuga]');
}

### test Token_XXX
{
    no strict 'refs';
    my @func_names =
        qw(Token_BOOL Token_FLOAT Token_INT Token_IDENT Token_LPAREN Token_RPAREN
           Token_PLUS Token_PLUS_DOT Token_MINUS Token_MINUS_DOT Token_AST_DOT
           Token_SLASH_DOT Token_EQUAL Token_LESS_GREATER Token_LESS_EQUAL
           Token_LESS_MINUS Token_LESS Token_GREATER_EQUAL Token_GREATER Token_COMMA
           Token_DOT Token_SEMICOLON Token_ARRAY_CREATE Token_NOT Token_IF
           Token_THEN Token_ELSE Token_LET Token_IN Token_REC Token_EOF);

    for my $func_name (@func_names){
        my $token = $func_name->('fuga');
        isa_ok($token, $class);
        my $token_kind = $func_name;
        $token_kind =~ s/^Token_//;
        is($token->kind, $token_kind);
        is($token->value, 'fuga');
    }
}
