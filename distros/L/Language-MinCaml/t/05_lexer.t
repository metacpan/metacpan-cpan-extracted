use strict;
use Test::More tests => 139;
use Language::MinCaml::Code;
use Language::MinCaml::Token;

my $class = 'Language::MinCaml::Lexer';

use_ok($class);

### test new
{
    my $lexer = $class->new('hoge');
    isa_ok($lexer, $class);
    is($lexer->{code}, 'hoge');
}

### test next_token
{
    my $code_class = 'Language::MinCaml::Code';
    my $token_class = 'Language::MinCaml::Token';

    my $string =
        join "\n", ("100.0e+10 100 ( ) + +. - -. *. /. =",
                    "< <> <= <- > >= , _ . ; hoge0 Array.create",
                    "true false not if then else let in rec");
    my $code = $code_class->from_string($string);
    my $lexer = $class->new($code);

    my $float_token = $lexer->next_token;
    isa_ok($float_token, $token_class);
    is($float_token->kind, 'FLOAT');
    is($float_token->value, '100.0e+10');
    is($float_token->line, 1);
    is($float_token->column, 1);

    my $int_token = $lexer->next_token;
    isa_ok($int_token, $token_class);
    is($int_token->kind, 'INT');
    is($int_token->value, '100');
    is($int_token->line, 1);
    is($int_token->column, 11);

    my $lparen_token = $lexer->next_token;
    isa_ok($lparen_token, $token_class);
    is($lparen_token->kind, 'LPAREN');
    is($lparen_token->line, 1);
    is($lparen_token->column, 15);

    my $rparen_token = $lexer->next_token;
    isa_ok($rparen_token, $token_class);
    is($rparen_token->kind, 'RPAREN');
    is($rparen_token->line, 1);
    is($rparen_token->column, 17);

    my $plus_token = $lexer->next_token;
    isa_ok($plus_token, $token_class);
    is($plus_token->kind, 'PLUS');
    is($plus_token->line, 1);
    is($plus_token->column, 19);

    my $plus_dot_token = $lexer->next_token;
    isa_ok($plus_dot_token, $token_class);
    is($plus_dot_token->kind, 'PLUS_DOT');
    is($plus_dot_token->line, 1);
    is($plus_dot_token->column, 21);

    my $minus_token = $lexer->next_token;
    isa_ok($minus_token, $token_class);
    is($minus_token->kind, 'MINUS');
    is($minus_token->line, 1);
    is($minus_token->column, 24);

    my $minus_dot_token = $lexer->next_token;
    isa_ok($minus_dot_token, $token_class);
    is($minus_dot_token->kind, 'MINUS_DOT');
    is($minus_dot_token->line, 1);
    is($minus_dot_token->column, 26);

    my $ast_dot_token = $lexer->next_token;
    isa_ok($ast_dot_token, $token_class);
    is($ast_dot_token->kind, 'AST_DOT');
    is($ast_dot_token->line, 1);
    is($ast_dot_token->column, 29);

    my $slash_dot_token = $lexer->next_token;
    isa_ok($slash_dot_token, $token_class);
    is($slash_dot_token->kind, 'SLASH_DOT');
    is($slash_dot_token->line, 1);
    is($slash_dot_token->column, 32);

    my $equal_token = $lexer->next_token;
    isa_ok($equal_token, $token_class);
    is($equal_token->kind, 'EQUAL');
    is($equal_token->line, 1);
    is($equal_token->column, 35);

    my $less_token = $lexer->next_token;
    isa_ok($less_token, $token_class);
    is($less_token->kind, 'LESS');
    is($less_token->line, 2);
    is($less_token->column, 1);

    my $less_greater_token = $lexer->next_token;
    isa_ok($less_greater_token, $token_class);
    is($less_greater_token->kind, 'LESS_GREATER');
    is($less_greater_token->line, 2);
    is($less_greater_token->column, 3);

    my $less_equal_token = $lexer->next_token;
    isa_ok($less_equal_token, $token_class);
    is($less_equal_token->kind, 'LESS_EQUAL');
    is($less_equal_token->line, 2);
    is($less_equal_token->column, 6);

    my $less_minus_token = $lexer->next_token;
    isa_ok($less_minus_token, $token_class);
    is($less_minus_token->kind, 'LESS_MINUS');
    is($less_minus_token->line, 2);
    is($less_minus_token->column, 9);

    my $greater_token = $lexer->next_token;
    isa_ok($greater_token, $token_class);
    is($greater_token->kind, 'GREATER');
    is($greater_token->line, 2);
    is($greater_token->column, 12);

    my $greater_equal_token = $lexer->next_token;
    isa_ok($greater_equal_token, $token_class);
    is($greater_equal_token->kind, 'GREATER_EQUAL');
    is($greater_equal_token->line, 2);
    is($greater_equal_token->column, 14);

    my $comma_token = $lexer->next_token;
    isa_ok($comma_token, $token_class);
    is($comma_token->kind, 'COMMA');
    is($comma_token->line, 2);
    is($comma_token->column, 17);

    my $unit_ident_token = $lexer->next_token;
    isa_ok($unit_ident_token, $token_class);
    is($unit_ident_token->kind, 'IDENT');
    is($unit_ident_token->value, 'Unit0');
    is($unit_ident_token->line, 2);
    is($unit_ident_token->column, 19);

    my $dot_token = $lexer->next_token;
    isa_ok($dot_token, $token_class);
    is($dot_token->kind, 'DOT');
    is($dot_token->line, 2);
    is($dot_token->column, 21);

    my $semicolon_token = $lexer->next_token;
    isa_ok($semicolon_token, $token_class);
    is($semicolon_token->kind, 'SEMICOLON');
    is($semicolon_token->line, 2);
    is($semicolon_token->column, 23);

    my $ident_token = $lexer->next_token;
    isa_ok($ident_token, $token_class);
    is($ident_token->kind, 'IDENT');
    is($ident_token->value, 'hoge0');
    is($ident_token->line, 2);
    is($ident_token->column, 25);

    my $array_token = $lexer->next_token;
    isa_ok($array_token, $token_class);
    is($array_token->kind, 'ARRAY_CREATE');
    is($array_token->line, 2);
    is($array_token->column, 31);

    my $true_token = $lexer->next_token;
    isa_ok($true_token, $token_class);
    is($true_token->kind, 'BOOL');
    is($true_token->value, 'true');
    is($true_token->line, 3);
    is($true_token->column, 1);

    my $false_token = $lexer->next_token;
    isa_ok($false_token, $token_class);
    is($false_token->kind, 'BOOL');
    is($false_token->value, 'false');
    is($false_token->line, 3);
    is($false_token->column, 6);

    my $not_token = $lexer->next_token;
    isa_ok($not_token, $token_class);
    is($not_token->kind, 'NOT');
    is($not_token->line, 3);
    is($not_token->column, 12);

    my $if_token = $lexer->next_token;
    isa_ok($if_token, $token_class);
    is($if_token->kind, 'IF');
    is($if_token->line, 3);
    is($if_token->column, 16);

    my $then_token = $lexer->next_token;
    isa_ok($then_token, $token_class);
    is($then_token->kind, 'THEN');
    is($then_token->line, 3);
    is($then_token->column, 19);

    my $else_token = $lexer->next_token;
    isa_ok($else_token, $token_class);
    is($else_token->kind, 'ELSE');
    is($else_token->line, 3);
    is($else_token->column, 24);

    my $let_token = $lexer->next_token;
    isa_ok($let_token, $token_class);
    is($let_token->kind, 'LET');
    is($let_token->line, 3);
    is($let_token->column, 29);

    my $in_token = $lexer->next_token;
    isa_ok($in_token, $token_class);
    is($in_token->kind, 'IN');
    is($in_token->line, 3);
    is($in_token->column, 33);

    my $rec_token = $lexer->next_token;
    isa_ok($rec_token, $token_class);
    is($rec_token->kind, 'REC');
    is($rec_token->line, 3);
    is($rec_token->column, 36);

    my $eof_token = $lexer->next_token;
    isa_ok($eof_token, $token_class);
    is($eof_token->kind, 'EOF');
}
