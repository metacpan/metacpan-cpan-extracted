use Test::More tests => 10;

use_ok ( 'Eval::Logic' );

our $warning;
local $SIG{__WARN__} = sub {
  $warning = $_[0];
};

my $empty = Eval::Logic->new;
ok ( ! $empty->evaluate,                    			'emtpy expression evaluates to false' );
like ( $warning, qr/No expression, returning false/,		'warning for undefined expression' );
$warning = undef;

is_deeply ( [ $empty->truth_values ], [],			'empty list of truth values for undefined expression' );
like ( $warning, qr/No expression, returning empty list/,	'warning for undefined expression' );
$warning = undef;

my $or = Eval::Logic->new ( 'a || b' );
ok ( ! $or->evaluate ( a => 0 ),				'undef defaults to false' );
like ( $warning, qr/Unspecified truth value .+? defaults to false/,				'warning for undefined truth value' );
$warning = undef;

$or->undef_default ( 1 );
ok ( $or->evaluate ( a => 1 ),					'undef default set' );
ok ( ! defined $warning,					'no warning when undef default set' );
is ( $or->undef_default, 1, 					'return value of undef_default' );
