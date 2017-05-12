package Finance::Bank::Wachovia::Credit;
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
		current_balance
		available_credit
		limit	
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
	return Finance::Bank::Wachovia::Credit->Error("no account number set in Finance::Bank::Wachovia::Credit->new")
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


sub balance { current_balance(@_) }

# these values are loaded on-demand
sub limit {
	my $self = shift;
	if(@_){ $self->[ _limit ] = shift; return $self; }
	return $self->[ _limit ] if $self->[ _limit ];
	my $do = $self->data_obtainer();	
	my $limit = $do->get_credit_account_limit( $self->number() );
	$self->[ _limit ] = $limit;	
	return $limit;
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

sub current_balance {
	my $self = shift;
	if(@_){ $self->[ _current_balance ] = shift; return $self; }
	return $self->[ _current_balance ] if $self->[ _current_balance ];
	$self->[ _current_balance ] = $self->data_obtainer->get_credit_account_current_balance( $self->number );
	return $self->[ _current_balance ];	
}


sub available_credit {
	my $self = shift;
	if(@_){ $self->[ _available_credit ] = shift; return $self; }
	return $self->[ _available_credit ] if $self->[ _available_credit ];
	$self->[ _available_credit ] = $self->data_obtainer->get_credit_account_available_credit( $self->number );
	return $self->[ _available_credit ];	
}

sub DESTROY {}

__END__

=begin

=head1 NAME

Finance::Bank::Wachovia::Credit

=head1 SYNOPSIS

Used by Finance::Bank::Wachovia to represent credit accounts ("credit card accounts"|"credit lines"?).  After instantiating 
a Finance::Bank::Wachovia object, you can get the Account object for any account (whether it be credit or not) 
by using the account( $account_num_goes_here ) method.  See perldocs for Finance::Bank::Wachovia for more on that.

  my $credit = $wachovia->account( $account_num );
  
  # $credit is Finance::Bank::Wachovia::Credit object
  print "Name: ", $credit->name, "\n";
  print "Balance: ", $credit->balance, "\n"; # balance() is the same as current_balance()
  
=head1 METHODS

=head2 name

returns name of account (eg: "visa platinum") in lower case.

=head2 number

returns account number

=head2 type

returns type of credit (eg: "mbna" ) in lower case.

=head2 current_balance

returns current balance

=head2 balance

alias for current_balance

=head2 limit

returns credit limit for this account

=head1 SEE ALSO

L<Finance::Bank::Wachovia>  L<Finance::Bank::Wachovia::Transaction> L<Finance::Bank::Wachovia::Account>

=cut
