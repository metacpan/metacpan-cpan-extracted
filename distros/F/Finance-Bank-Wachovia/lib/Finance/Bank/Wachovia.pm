package Finance::Bank::Wachovia;

use Finance::Bank::Wachovia::ErrorHandler;
use Finance::Bank::Wachovia::Account;
use Finance::Bank::Wachovia::Credit;
use Finance::Bank::Wachovia::Transaction;
use Finance::Bank::Wachovia::DataObtainer::WWW;
use strict;
use warnings;

our $VERSION = '0.5';
my @attrs;
our @ISA = qw/Finance::Bank::Wachovia::ErrorHandler/;

BEGIN{ 
	@attrs = qw(
		customer_access_number
		pin
		code_word
		user_id
		password
		accounts
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
	unless( ( $self->user_id && $self->password ) || ( $self->customer_access_number && $self->pin && $self->code_word ) ){
		return Finance::Bank::Wachovia->Error( "Must use either user_id/password OR customer_access_number/pin/code_word" );	
	}
	my %login_info = ( $self->user_id && $self->password )
					? ( user_id => $self->user_id, password => $self->password )
					: ( 	customer_access_number => $self->customer_access_number, pin => $self->pin, code_word => $self->code_word	);
	my $data_obtainer = Finance::Bank::Wachovia::DataObtainer::WWW->new(
		%login_info
	);
	$self->data_obtainer( $data_obtainer );		
	$self->accounts({});
	return $self;
}


sub AUTOLOAD {
	no strict 'refs';
	our $AUTOLOAD;
	my $self = shift;
	my $attr = lc $AUTOLOAD;
	$attr =~ s/.*:://;
	return $self->Error("$attr not a valid attribute")
		unless grep /$attr/, @attrs;
	# get if no args passed
	return $self->[ &{"_$attr"} ] unless @_;	
	# set if args passed
	$self->[ &{"_$attr"} ] = shift;
	return $self; 
}

sub account_numbers {
	my $self = shift;	
	my $do = $self->data_obtainer();
	return $do->get_account_numbers();
}

sub account_names {
	my $self = shift;	
	my $do = $self->data_obtainer();
	return map { $do->get_account_name($_) } $self->account_numbers();
}

sub account_balances {
	my $self = shift;
	my $do = $self->data_obtainer();
	return map { $do->get_account_available_balance($_) } $self->account_numbers();	
}

sub account {
	my($self, $account_number) = @_;	
	return $self->Error("Must pass account number to account() method") 
		unless $account_number;
	if( exists $self->accounts->{$account_number} ){
		return $self->accounts->{$account_number};
	}
	return $self->Error("must pass valid account number to account(), got '$account_number'")
		unless $account_number =~ /^\d+$/;
	my $do = $self->data_obtainer();
	my $account;
	#note: we don't set posted_balance here, since that requires extra
	# work by the obtainer, we defer the retrieval of that until it's 
	# needed (asked for via $account->posted_balance)
	if( $account_number =~ /\d{16}/ ){ # must be credit?
			$account = Finance::Bank::Wachovia::Credit->new(
				number			=> $account_number,
				data_obtainer	=> $do,
			)
			or return Error( "Couldn't create Credit object: ".Finance::Bank::Wachovia::Credit->ErrStr );
			
	}
	else{ # must be checkings or savings?
			$account = Finance::Bank::Wachovia::Account->new(
				number			=> $account_number,
				data_obtainer	=> $do,
			)
			or return Error( "Couldn't create Account object: ".Finance::Bank::Wachovia::Account->ErrStr );
	}
	$self->accounts->{$account_number} = $account;
	return $account;
}

sub DESTROY {}

__END__

=begin

=head1 NAME

Finance::Bank::Wachovia - access account info from Perl

=over 1

=item * Account numbers

=item * Account names

=item * Account balances (posted and available)

=item * Account transaction data (in all their detailed glory)

=back

Does not (yet) provide any means to transfer money or pay bills.

=head1 SYNOPSIS

Since this version uses the website to get account info, it will need the information to login:
There are two ways to login via the wachovia website, and depending on which login method you use, that decides which parameters you'll provide to the new() method.
If you use the Customer access number method (left form on the website) then provide "customer_access_number", "pin", and "code_word".  If you use the user id method (right form on the website)
then provide "user_id" and "password".

  use Finance::Bank::Wachovia;
  
  # Two different types of login information,
  # if you login using can/pin/codeword:
  my $wachovia  = Finance::Bank::Wachovia->new(
      customer_access_number => '123456789',
      pin                    => '1234',
      code_word              => 'blah'
  ) or die Finance::Bank::Wachovia->ErrStr();
  
  # OR if you login using user_id/password:
  $wachovia = Finance::Bank::Wachovia->new(
      user_id  => 'foo',
      password => 'bar'  
  ) or die Finance::Bank::Wachovia->ErrStr();
  
  my @account_numbers		= $wachovia->account_numbers();
  my @account_names		= $wachovia->account_names();
  my @account_balances	= $wachovia->account_balances();

  my $account = $wachovia->account( $account_numbers[0] )
  	or die $wachovia->ErrStr();
  	
  print "Number: ", $account->number, "\n";
  print "Name: ", $account->name, "\n";
  print "Type: ", $account->type, "\n";
  print "Avail. Bal.: ", $account->available_balance, "\n";
  print "Posted.Bal.: ", $account->posted_balance, "\n";
  
  my $transactions = $account->transactions
  	or die $account->ErrStr;
  
  foreach my $t ( @$transactions ){
  	print "Date: ",     $t->date,              "\n",
  	      "Action: ",   $t->action,            "\n",
  	      "Desc: ",     $t->description,       "\n",
  	      "Withdrawal", $t->withdrawal_amount, "\n",
  	      "Deposit",    $t->deposit_amount,    "\n",
  	      "Balance",    $t->balance,           "\n",
  	      "seq_no",     $t->seq_no,            "\n",
  	      "trans_code", $t->trans_code,        "\n",
  	      "check_num",  $t->check_num,         "\n";
  } 	
  

=head1 DESCRIPTION

Internally uses WWW::Mechanize to scrape the bank's website.  The idea was to keep
the interface as logical as possible.  The user is completely abstracted from how the
data is obtained, and to a large degree so is the module itself.  In case wachovia ever offers
an XML interface, or soap, or DBI (right) this should be an easy module to add to/modify, 
but the application interface will not change, so YOUR code won't have to either.

=head1 METHODS

=head2 new

Returns object Finance::Bank::Wachovia object.  This is when you should define your login
information.  There are currently two login methods, the 3 argument "can/pin/codeword" method,
and the two argument "user_id/password" method.  Which one you need to use depends on how you 
login to your account via the wachovia website.

If you use the can/pin/codeword method, then:

  my $wachovia = Finance::Bank::Wachovia->new(
      customer_access_number => '123456789',
      pin                    => '1234',
      code_word              => 'blah'
  );
  
And if you use the user_id/password method, then:

  my $wachovia = Finance::Bank::Wachovia->new(
      user_id  => 'foo',
      password => 'bar'
  );
  
On wachovia's website they say that eventually everyone will be migrated to the userid/password method.
  
=head2 account_numbers

Returns a list of account numbers (from the Relationship Summary Page).

  my @numbers = $wachovia->account_numbers();
  
=head2 account_names

Returns (in lowercase) a list of account names (ie: "exp access") (from the Relationship Summary Page).

  my @names = $wachovia->account_names;
  
=head2 account_balances

Returns a list of account balances (from Relationship Summary page ).

  my @balances = $wachovia->account_balances;
  
=head2 account

Returns a Finance::Bank::Wachovia::Account object OR a Finance::Bank::Wachovia::Credit object.  Currently
the module looks at the length of the account number to decide whether you are retrieving a credit account
object or a regular (savings/checkings) account object.  Both the Credit and Account classes have some common 
attributes: name, type, number.  You can use the type to figure out what kind of account you have, OR you can
just look at the ref() of the object (better, since type can be unclear (like "mbna")).

  my $account = $wachovia->account( $account_num );

See L<Finance::Bank::Wachovia::Account> and L<Finance::Bank::Wachovia::Credit> to learn what you can do with the
returned object.

=head1 WORTH MENTIONING

Doug Feuerbach had the idea for storing login information in an encrypted file to be accessed via a password (like apple's keychain).  
Then he gave me the code to implement it.  He thinks it's silly to thank him for something "so trivial", but he should know that
it's not an official perl module without a "thanks" going out to someone by name.  The program included with the module makes use of 
his contribution.  Thanks Doug.

Also, thanks to the Giants that authored all the modules that made the conception and creation of this module so easy.  Your shoulder's are awesome.

Where would we all be without Perl?  Checking our account balances over the phone, that's where.  Thanks to Larry Wall.

Thanks to Jason Marcell for helping me test/debug the user_id/password login in a pretty short amount of time. 
 
=head1 TODO

=over 1

=item * finish documentation

=item * handle rejected logins with elegance, right now you just kind of guess something went wrong when you don't see what you expected to see.

=item * work errorhandling into each of the methods

Really, I want to redo the errorhandling.  I hate the uppercase method names too.  WHY did I do that?

=item * re-write the dataobtaining stuff so it's more elegant, say, by a factor of 10

=item * add in fancy stuff like transfers and billpay -- maybe

=back
  
=head1 AUTHOR

Jim Garvin E<lt>jg.perl@thegarvin.comE<gt>

Copyright 2004 by Jim Garvin

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=head1 SEE ALSO

L<Finance::Bank::Wachovia::Account>  L<Finance::Bank::Wachovia::Transaction>  L<Finance::Bank::Wachovia::Credit>

=cut

