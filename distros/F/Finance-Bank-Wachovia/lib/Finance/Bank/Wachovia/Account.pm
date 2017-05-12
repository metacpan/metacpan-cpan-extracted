package Finance::Bank::Wachovia::Account;
use Finance::Bank::Wachovia::ErrorHandler;
use strict;
use warnings;

my @attrs;
our @ISA = qw/Finance::Bank::Wachovia::ErrorHandler/;

BEGIN{ 
	@attrs = qw(
		name
		number
		type
		available_balance
		posted_balance
		transactions
		data_obtainer
	);
	
	my $x = @__SUPER__::ATTRIBUTES;
	for( @attrs ){
		eval "sub _$_ { $x }";
		$x++;
	}
}

sub new {
	my($class, %attrs) = @_;
	my $self = [];
	bless $self, $class;	
	foreach my $att ( keys %attrs ){
		$self->$att( $attrs{$att} );	
	}
	return Finance::Bank::Wachovia::Account->Error("no account number set in Finance::Bank::Wachovia::Account->new")
		unless $self->number;
	return $self;
}

sub AUTOLOAD {
	no strict 'refs';
	our $AUTOLOAD;
	my $self = shift;
	my $attr = lc $AUTOLOAD;
	$attr =~ s/.*:://;
	return $self->Error( "$attr not a valid attribute" )
		unless grep /$attr/, @attrs;
	# get if no args passed
	return $self->[ &{"_$attr"} ] unless @_;	
	# set if args passed
	$self->[ &{"_$attr"} ] = shift;
	return $self; 
}

sub add_transaction {
	my($self) = shift;
	foreach my $t ( @_ ){
		return $self->Error( "Must pass valid Transaction object" )
			unless $t->isa('Finance::Bank::Wachovia::Transaction');
		push @{ $self->[ _transactions ] }, $t; 
	}
	return $self;
}

sub set_transactions {
	my($self, $transactions) = @_;
	unless ( ref $transactions eq 'ARRAY' ){
		$self->[ _transactions ] = [];
		return $self;	
	}
	foreach my $t ( @$transactions ){
		return $self->Error( "Must pass valid Transaction objects" )
			unless $t->isa('Finance::Bank::Wachovia::Transaction');
	}
	$self->[ _transactions ] = $transactions;
	return $self;	
}

sub balance { available_balance(@_) }
sub transactions { get_transactions(@_) }


# these values are loaded on-demand
sub posted_balance {
	my $self = shift;
	if(@_){ $self->[ _posted_balance ] = shift; return $self; }
	return $self->[ _posted_balance ] if $self->[ _posted_balance ];
	my $do = $self->data_obtainer();	
	my $posted_bal = $do->get_account_posted_balance( $self->number() );
	$self->[ _posted_balance ] = $posted_bal;	
	return $posted_bal;
}

sub get_transactions {
	my $self = shift;
	return $self->[ _transactions ] if $self->[ _transactions ];
	
	my $do = $self->data_obtainer();	
	my $transactions = $do->get_account_transactions( $self->number() );
	foreach ( @$transactions ){
		my $t = Finance::Bank::Wachovia::Transaction->new( %$_	)
			or return $self->Error( "Couldn't make transaction object" );	
		$self->add_transaction( $t );	
	}
	return $self->[ _transactions ];
}

sub name {
	my $self = shift;
	if(@_){ $self->[ _name ] = shift; return $self; }
	return $self->[ _name ] if $self->[ _name ];
	$self->[ _name ] = $self->data_obtainer->get_account_name( $self->number );
	return $self->[ _name ];	
}

sub type {
	my $self = shift;
	if(@_){ $self->[ _type ] = shift; return $self; }
	return $self->[ _type ] if $self->[ _type ];
	$self->[ _type ] = $self->data_obtainer->get_account_type( $self->number );
	return $self->[ _type ];	
}

sub available_balance {
	my $self = shift;
	if(@_){ $self->[ _available_balance ] = shift; return $self; }
	return $self->[ _available_balance ] if $self->[ _available_balance ];
	$self->[ _available_balance ] = $self->data_obtainer->get_account_available_balance( $self->number );
	return $self->[ _available_balance ];	
}

sub DESTROY {}

__END__

=begin

=head1 NAME

Finance::Bank::Wachovia::Account

=head1 SYNOPSIS

Used by Finance::Bank::Wachovia to represent bank accounts.  After instantiating 
a Finance::Bank::Wachovia object, you can get the Account object for any account 
by using the account( $account_num_goes_here ) method.  See perldocs for Finance::Bank::Wachovia for more on that.

  my $account = $wachovia->account( $account_num );
  
  # $account is Finance::Bank::Wachovia::Account object
  print "Name: ", $account->name, "\n";
  print "Balance: ", $account->balance, "\n";
  
=head1 METHODS

=head2 name

returns name of account (eg: "exp access") in lower case.

=head2 number

returns account number

=head2 type

returns type of account (eg: "checking" ) in lower case.

=head2 available_balance

returns available balance

=head2 balance

alias for available_balance

=head2 posted_balance

returns posted balance

=head2 get_transactions

returns array ref of Transaction objects.  See Finance::Bank::Wachovia::Transaction for more.

=head2 transactions

alias for get_transactions

=head1 SEE ALSO

L<Finance::Bank::Wachovia>  L<Finance::Bank::Wachovia::Transaction>  L<Finance::Bank::Wachovia::Credit>

=cut