#!perl
#
# can logic expressions be parsed? correctly? without allowing any known
# oddities to slip through? and code coverage.

use Scalar::Util 'refaddr';
use Test2::V0;

plan(17);

use Logic::Expr::Parser;
my $le = Logic::Expr::Parser->new;

my $pe = $le->from_string('X');
is( [ keys %Logic::Expr::atoms ], ['X'] );
is( scalar @Logic::Expr::bools,   1 );
my $addr = refaddr \$Logic::Expr::bools[0];
is( $addr,                  refaddr $Logic::Expr::atoms{X} );
is( $addr,                  refaddr $pe->expr );
is( $Logic::Expr::bools[0], 1 );          # bools TRUE by default
is( ref $pe->expr,          'SCALAR' );

Logic::Expr::reset;

$pe = $le->from_string('CAT&(DOGv(FISH&!CAT))');
is( [ sort keys %Logic::Expr::atoms ], [qw(CAT DOG FISH)] );
is( scalar @Logic::Expr::bools,        3 );
is( ref $pe->expr,                     'ARRAY' );

Logic::Expr::reset;

$pe = $le->from_string('X&Y');
is( [ sort keys %Logic::Expr::atoms ], [qw(X Y)] );
is( scalar @Logic::Expr::bools,        2 );

Logic::Expr::reset;

# negation reduction; should not get nested [ '!', ...
$pe   = $le->from_string('!!!!X');
$addr = refaddr \$Logic::Expr::bools[0];
is( $addr, refaddr $pe->expr );

# bad expressions -- error string may come from Parser::MGC so these
# tests could break if that module changes
like( dies { $le->from_string('') },               qr/parse/ );
like( dies { $le->from_string('!') },              qr/parse/ );
like( dies { $le->from_string('jamna ja jansu') }, qr/parse/ );
# Parser::MGC 'list_of' allows for a trailing op which is typical in
# Perl but not in logic expressions, so something else is now used
like( dies { $le->from_string('X&Y&') }, qr/end of input/ );
# can easily chain AND, OR but more complicated binary operators not so
# much. so, disallow chained operations
like( dies { $le->from_string('X&Y&Z') }, qr/end of input/ );
