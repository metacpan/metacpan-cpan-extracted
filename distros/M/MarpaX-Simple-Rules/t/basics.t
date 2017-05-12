use Test::More;
use MarpaX::Simple::Rules 'parse_rules';

my $rules = parse_rules(<<"RULES");
Expression ::= Term               => Return_0
Term       ::= Factor             => Return_0
Term       ::= Term Plus Term     => Plus
Factor     ::= Number             => Return_0
Factor     ::= Factor Mul Factor  => Mul
RULES

is_deeply($rules, [
    { lhs => 'Expression', rhs => [ qw/Term/ ],              action => 'Return_0' },
    { lhs => 'Term',       rhs => [ qw/Factor/ ],            action => 'Return_0' },
    { lhs => 'Term',       rhs => [ qw/Term Plus Term/ ],    action => 'Plus' },
    { lhs => 'Factor',     rhs => [ qw/Number/ ],            action => 'Return_0' },
    { lhs => 'Factor',     rhs => [ qw/Factor Mul Factor/ ], action => 'Mul' },
]);

done_testing();

