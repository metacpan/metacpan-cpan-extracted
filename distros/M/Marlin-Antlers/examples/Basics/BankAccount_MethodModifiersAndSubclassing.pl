BEGIN {{{ # Port of Moose::Cookbook::Basics::BankAccount_MethodModifiersAndSubclassing

package BankAccount {
	use Marlin::Antlers;
	use Carp 'confess';

	has balance => (
		is          => rw,
		isa         => Int,
		default     => 0,
		handles_via => 'Number',
		handles     => {
			deposit  => 'add',
			withdraw => 'sub',
		},
	);

	before withdraw => sub ( $self, $amount ) {
		confess 'Account overdrawn' if $amount > $self->balance;
	};
}

package CheckingAccount {
	use Marlin::Antlers;
	extends 'BankAccount';

	has overdraft_account => ( is => 'rw', isa => 'BankAccount', predicate => true );

	before withdraw => sub ( $self, $amount ) {
		my $overdraft_amount = $amount - $self->balance;
		if ( $overdraft_amount > 0 and $self->has_overdraft_account ) {
			$self->overdraft_account->withdraw($overdraft_amount);
			$self->deposit($overdraft_amount);
		}
	};
}

}}};

use Test2::V0;
use Data::Dumper;

my $checking_account = CheckingAccount->new(
	balance           => 100,
	overdraft_account => BankAccount->new( balance => 250 ),
);

$checking_account->withdraw( 5 );
is( $checking_account->balance, 95 );
is( $checking_account->overdraft_account->balance, 250 );

$checking_account->withdraw( 120 );
is( $checking_account->balance, 0 );
is( $checking_account->overdraft_account->balance, 225 );

done_testing;
