#!/usr/bin/perl

use warnings;
use strict;

use lib 't/lib', 'lib';

use Frost::Test;

#use Test::More 'no_plan';
use Test::More tests => 51;

use Frost::Asylum;

#	from Moose-0.87/t/000_recipes/moose_cookbook_basics_recipe2.t

# =begin testing SETUP
{
	package BankAccount;
#	use Moose;
	use Frost;

	has 'balance' => ( isa => 'Int', is => 'rw', default => 0 );

	sub deposit {
		my ( $self, $amount ) = @_;
		$self->balance( $self->balance + $amount );
	}

	sub withdraw {
		my ( $self, $amount ) = @_;
		my $current_balance = $self->balance();
		( $current_balance >= $amount )
				|| die "Account overdrawn";
		$self->balance( $current_balance - $amount );
	}

	no Frost;

	__PACKAGE__->meta->make_immutable()		unless $::MAKE_MUTABLE;

	package CheckingAccount;
	use Moose;

	extends 'BankAccount';

	has 'overdraft_account' => ( isa => 'BankAccount', is => 'rw' );

	before 'withdraw' => sub {
		my ( $self, $amount ) = @_;
		my $overdraft_amount = $amount - $self->balance();
		if ( $self->overdraft_account && $overdraft_amount > 0 ) {
				$self->overdraft_account->withdraw($overdraft_amount);
				$self->deposit($overdraft_amount);
		}
	};

	no Moose;

	__PACKAGE__->meta->make_immutable()		unless $::MAKE_MUTABLE;
}

# =begin testing

#	my $savings_account;

my $savings_account_id		= 1000;
my $checking_account_id		= 2000;
my $checking_account_no_id	= 2001;

{
	my $ASYL;

	lives_ok		{ $ASYL = Frost::Asylum->new ( data_root => $TMP_PATH ) }	'Asylum constructed';

	{
	#		$savings_account = BankAccount->new( balance => 250 );
		my $savings_account = BankAccount->new( balance => 250, asylum => $ASYL, id => $savings_account_id );
		isa_ok( $savings_account, 'BankAccount',				'savings_account' );
		isa_ok( $savings_account, 'Frost::Locum',	'savings_account' );

		is( $savings_account->balance, 250, '... got the right savings balance' );
	}

	lives_ok	{ $ASYL->close;	}	'Asylum closed and saved';
}

{
	my $ASYL;

	lives_ok		{ $ASYL = Frost::Asylum->new ( data_root => $TMP_PATH ) }	'Asylum constructed';

	{
		my $savings_account = BankAccount->new( asylum => $ASYL, id => $savings_account_id );

		lives_ok {
				$savings_account->withdraw(50);
		}
		'... withdrew from savings successfully';
		is( $savings_account->balance, 200,
				'... got the right savings balance after withdrawl' );
	}

	lives_ok	{ $ASYL->close;	}	'Asylum closed and saved';
}

{
	my $ASYL;

	lives_ok		{ $ASYL = Frost::Asylum->new ( data_root => $TMP_PATH ) }	'Asylum constructed';

	{
		my $savings_account = BankAccount->new( asylum => $ASYL, id => $savings_account_id );

		$savings_account->deposit(150);
		is( $savings_account->balance, 350,
				'... got the right savings balance after deposit' );
	}

	lives_ok	{ $ASYL->close;	}	'Asylum closed and saved';
}

{
	my $ASYL;

	lives_ok		{ $ASYL = Frost::Asylum->new ( data_root => $TMP_PATH ) }	'Asylum constructed';
	{
		my $savings_account = BankAccount->new( asylum => $ASYL, id => $savings_account_id );

		my $checking_account = CheckingAccount->new(
			asylum => $ASYL, id => $checking_account_id,
			balance					 => 100,
			overdraft_account => $savings_account
		);
		isa_ok( $checking_account, 'CheckingAccount',		'checking_account' );
		isa_ok( $checking_account, 'BankAccount',				'checking_account' );
		isa_ok( $checking_account, 'Frost::Locum',	'checking_account' );

	#	is( $checking_account->overdraft_account, $savings_account,
	#			'... got the right overdraft account' );

		is( $checking_account->overdraft_account->id, $savings_account->id,
				'... got the right overdraft account' );

		is( $checking_account->balance, 100,
				'... got the right checkings balance' );
	}

	lives_ok	{ $ASYL->close;	}	'Asylum closed and saved';
}

{
	my $ASYL;

	lives_ok		{ $ASYL = Frost::Asylum->new ( data_root => $TMP_PATH ) }	'Asylum constructed';

	{
		my $checking_account	= CheckingAccount->new	( asylum => $ASYL, id => $checking_account_id );
		my $savings_account	= BankAccount->new		( asylum => $ASYL, id => $savings_account_id );

		isa_ok( $checking_account, 'CheckingAccount',		'checking_account' );
		isa_ok( $checking_account, 'BankAccount',				'checking_account' );
		isa_ok( $checking_account, 'Frost::Locum',	'checking_account' );

	#	is( $checking_account->overdraft_account, $savings_account,
	#			'... got the right overdraft account' );

		is( $checking_account->overdraft_account->id, $savings_account->id,
				'... got the right overdraft account' );

		is( $checking_account->balance, 100,
				'... got the right checkings balance' );

		lives_ok {
				$checking_account->withdraw(50);
		}
		'... withdrew from checking successfully';
		is( $checking_account->balance, 50,
				'... got the right checkings balance after withdrawl' );
		is( $savings_account->balance, 350,
				'... got the right savings balance after checking withdrawl (no overdraft)'
		);
	}

	lives_ok	{ $ASYL->close;	}	'Asylum closed and saved';
}

{
	my $ASYL;

	lives_ok		{ $ASYL = Frost::Asylum->new ( data_root => $TMP_PATH ) }	'Asylum constructed';

	{
		my $checking_account	= CheckingAccount->new	( asylum => $ASYL, id => $checking_account_id );
		my $savings_account	= $checking_account->overdraft_account;

		lives_ok {
				$checking_account->withdraw(200);
		}
		'... withdrew from checking successfully';
		is( $checking_account->balance, 0,
				'... got the right checkings balance after withdrawl' );
		is( $savings_account->balance, 200,
				'... got the right savings balance after overdraft withdrawl' );
	}

	lives_ok	{ $ASYL->close;	}	'Asylum closed and saved';
}

{
	my $ASYL;

	lives_ok		{ $ASYL = Frost::Asylum->new ( data_root => $TMP_PATH ) }	'Asylum constructed';

	{
		my $checking_account = CheckingAccount->new(
				asylum => $ASYL, id => $checking_account_no_id,
				balance => 100

						# no overdraft account
		);
		isa_ok( $checking_account, 'CheckingAccount',		'checking_account' );
		isa_ok( $checking_account, 'BankAccount',				'checking_account' );
		isa_ok( $checking_account, 'Frost::Locum',	'checking_account' );

		is( $checking_account->overdraft_account, undef,
				'... no overdraft account' );

		is( $checking_account->balance, 100,
				'... got the right checkings balance' );
	}

	lives_ok	{ $ASYL->close;	}	'Asylum closed and saved';
}

{
	my $ASYL;

	lives_ok		{ $ASYL = Frost::Asylum->new ( data_root => $TMP_PATH ) }	'Asylum constructed';

	{
		my $checking_account	= CheckingAccount->new	( asylum => $ASYL, id => $checking_account_no_id );

		lives_ok {
				$checking_account->withdraw(50);
		}
		'... withdrew from checking successfully';
		is( $checking_account->balance, 50,
				'... got the right checkings balance after withdrawl' );

		dies_ok {
				$checking_account->withdraw(200);
		}
		'... withdrawl failed due to attempted overdraft';
		is( $checking_account->balance, 50,
				'... got the right checkings balance after withdrawl failure' );
	}

	lives_ok	{ $ASYL->close;	}	'Asylum closed and saved';
}

{
	my $ASYL;

	lives_ok		{ $ASYL = Frost::Asylum->new ( data_root => $TMP_PATH ) }	'Asylum constructed';

	{
		my $checking_account	= CheckingAccount->new	( asylum => $ASYL, id => $checking_account_no_id );

		is( $checking_account->overdraft_account, undef,
				'... no overdraft account' );

		is( $checking_account->balance, 50,
				'... got the right checkings balance' );
	}

	lives_ok	{ $ASYL->close;	}	'Asylum closed and saved';
}
