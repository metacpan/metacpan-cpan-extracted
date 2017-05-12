package Finance::Bank::Wachovia::Transaction;

use Finance::Bank::Wachovia::ErrorHandler;
use strict;
use warnings;

our @ISA = qw/Finance::Bank::Wachovia::ErrorHandler/;
my @attrs;

BEGIN{ 
	@attrs = qw(
		date
		action
		description
		withdrawal_amount
		deposit_amount
		balance
		seq_no
		trans_code
		check_num
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
	return $self;
}

sub AUTOLOAD {
	no strict 'refs';
	our $AUTOLOAD;
	my $self = shift;
	my $attr = lc $AUTOLOAD;
	$attr =~ s/.*:://;
	die "$attr not a valid attribute"
		unless grep /$attr/, @attrs;
	# get if no args passed
	return $self->[ &{"_$attr"} ] unless @_;	
	# set if args passed
	$self->[ &{"_$attr"} ] = shift;
	return $self; 
}

sub DESTROY {}

__END__

=begin

=head1 NAME

Finance::Bank::Wachovia::Transaction

=head1 SYNOPSIS

Used by Finance::Bank::Wachovia::Account to represent transactions.  After instantiating 
a Finance::Bank::Wachovia::Account object you can get a list of all the transactions for that account
using the $account->transactions() method.  It returns a reference to an array of transaction objects.

  my $tran = $account->transactions->[-1];
  
  print "Most recent transaction: ",
        $tran->description, " -- ",
        $tran->date,        " -- ",
        ( $tran->withdrawal_amount || $deposit_amount ), "\n";
  
By default, the transactions are stored in oldest to newest.

=head1 METHODS

All the methods (except new) are merely accessors for the attributes of the transaction.  
The names of the methods pretty much describe the data as well as is needed.  The ones that don't have
what could best be described as a generally well understood meaning (by myself anyways), I don't know 
what they are either.  The ones that I don't really know what purpose they serve are: 'action', 'seq_no', and 'check_num'.
You would think that 'check_num' corresponded to the number on any checks processed, but this doesn't appear to be the case.
In my experience 'action' has always been empty, and seq_no I don't know what it is used for.  If you know how to use it, there it is.

=over 1

=item * date

=item * action

=item * description

=item * withdrawal_amount

=item * deposit_amount

=item * balance

=item * seq_no

=item * trans_code

=item * check_num

=back

=head1 SEE ALSO

L<Finance::Bank::Wachovia>  L<Finance::Bank::Wachovia::Account> L<Finance::Bank::Wachovia::Credit>

=cut
