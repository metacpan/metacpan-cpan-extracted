#!perl
use strict;
use warnings FATAL => 'all';
use Test::More;

BEGIN {
    use_ok( 'MarpaX::Languages::ECMAScript::AST' ) || print "Bail out!\n";
}

my $ecmaAst = MarpaX::Languages::ECMAScript::AST->new();
my $JSON = $ecmaAst->JSON;


my $ntest = 0;
my $JSONText = do {local $/; <DATA>};
my $parse = $JSON->{grammar}->parse($JSONText, $JSON->{impl});
my $value = eval { $JSON->{grammar}->value($JSON->{impl}) };
ok(defined($value), 'JSON test data');

++$ntest;

done_testing(1 + $ntest);

__DATA__
{"bindings": [
        {"ircEvent": "PRIVMSG", "method": "newURI", "regex": "^http://.*"},
        {"ircEvent": "PRIVMSG", "method": "deleteURI", "regex": "^delete.*"},
        {"ircEvent": "PRIVMSG", "method": "randomURI", "regex": "^random.*"}
    ]
}
