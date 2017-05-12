use Test::More;
use MarpaX::Simple::Rules 'parse_rules';

my $rules = parse_rules(<<"RULES");
Expression ::= Term                  => Return_0
Term       ::= Factor                => Return_0
Term       ::= Term Plus Term        => Plus
Factor     ::= Number                => Return_0
Factor     ::= Factor Star Factor    => Mul
Factor     ::= 0      Star Factor    => Mul
Factor     ::= 0000   Star Factor    => Mul
Factor     ::= 0000   block_1 Factor => Mul
Factor     ::= 0000   block_1 Factor => valid_perl_name
RULES

is_deeply($rules, [
    { lhs => 'Expression', rhs => [ qw/Term/ ],               action => 'Return_0' },
    { lhs => 'Term',       rhs => [ qw/Factor/ ],             action => 'Return_0' },
    { lhs => 'Term',       rhs => [ qw/Term Plus Term/ ],     action => 'Plus' },
    { lhs => 'Factor',     rhs => [ qw/Number/ ],             action => 'Return_0' },
    { lhs => 'Factor',     rhs => [ qw/Factor Star Factor/ ], action => 'Mul' },
    { lhs => 'Factor',     rhs => [ qw/0 Star Factor/ ], action => 'Mul' },
    { lhs => 'Factor',     rhs => [ qw/0000 Star Factor/ ], action => 'Mul' },
    { lhs => 'Factor',     rhs => [ qw/0000 block_1 Factor/ ], action => 'Mul' },
    { lhs => 'Factor',     rhs => [ qw/0000 block_1 Factor/ ], action => 'valid_perl_name' },
]);

done_testing();

