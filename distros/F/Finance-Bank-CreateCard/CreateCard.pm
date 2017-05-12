#
# Finace::Bank::CreateCard
#
# Version : 1.03
# Date    : Fri Mar 14 13:05:33 GMT 2003 
# By      : Robert J. McKay <robert@mckay.com>
# Desc    : This module provides an interface to the createcard.co.uk 
#	    online banking website.
#

use strict;
use Carp;
use HTTP::Cookies;
use LWP::UserAgent;

#
# UserAgent 
#
package Finance::Bank::CreateCard::WebClient;
our @ISA = qw(LWP::UserAgent);

sub new {

	my ($class, %args) = @_;

	#my $self = LWP::UserAgent->new(@_);

	my $self = LWP::UserAgent->new;

	my $cookiejar = new HTTP::Cookies;

	$self->agent("Mozilla/4.0 (compatible; MSIE 5.01; Windows NT)");

	$self->env_proxy(1);

	$self->timeout(30);

	$self->cookie_jar($cookiejar);

	if (defined($args{login}) && defined($args{password})) {
		$self->auth($args{login}, $args{password});
	}

	bless $self, 'Finance::Bank::CreateCard::WebClient';

	return $self;

}

sub auth {

	my ($self,$login,$password) = @_;

	$self->{login} = $login;

	$self->{password} = $password;

}

sub get_basic_credentials {

	my($self, $realm, $uri) = @_;

	my $netloc = $uri->host_port;

	return ($self->{login}, $self->{password});

}

#
# MAIN PACKAGE
#
package Finance::Bank::CreateCard;
use Carp;
use HTML::TreeBuilder;
our $VERSION = "1.03";
our $BASEURL = "https://www.createcard.co.uk";

our $ua = new Finance::Bank::CreateCard::WebClient;

sub new {

	my ($class, %args) = @_;

	my $self = {};

	bless $self, $class;

	return $self;

}

sub auth {
	my ($self, %args) = @_;

	return $ua->auth($args{login}, $args{password});

}

#
# Log into the website.
# 
sub login {

	my ($class, %args) = @_;

	croak "Must provide a password" unless exists $args{password};
	croak "Must provide a username" unless exists $args{username};

	my $self = bless { %args }, $class;

	my $orig_r = $ua->get("$BASEURL/create-servicing/Start.jsp?PERL");

	croak $orig_r->error_as_HTML unless $orig_r->is_success;

	my $login =
	$ua->post("$BASEURL/create-servicing/login.do", {
		username=> $args{username},
		password=> $args{password},
		"submit.x"=>"1",
		"submit.y"=>"1",
		"submit"=>"Login"});

	my $page = $login->content();

	if ($page =~ /We are sorry the createcard login details you have supplied are not recognised/msg ) {
		return 0;
	}

	if ($page =~ /Please enter your user name/msg ) {
		return 0;
	}

	return 1;

}

sub account_overview {
	
	my $statement =
	$ua->get ("$BASEURL/create-servicing/viewAccountOverview.do");

	my $account = Finance::Bank::CreateCard::Account->new();
	
	croak $statement->error_as_HTML unless $statement->is_success;

	my $root = HTML::TreeBuilder->new_from_content($statement->content);

	foreach my $foo (@{$root->{'_body'}{'_content'}[1]{'_content'}[0]{'_content'}[1]{'_content'}[2]{'_content'}}){

		my $key = $foo->{'_content'}[0]->as_text();
		$key =~ tr /[A-Z]/[a-z]/;
		$key =~ s/\s//g;
		$key =~ s/\://g;

		$account->{$key} = $foo->{'_content'}[1]->as_text();

	}

	return $account;

}

sub card_settings {

	my $AccountOverview = $ua->get("$BASEURL/create-servicing/viewCardSettings.do");

	croak $AccountOverview->error_as_HTML unless $AccountOverview->is_success;

	my $root = HTML::TreeBuilder->new_from_content($AccountOverview->content);

	my $settings = Finance::Bank::CreateCard::Settings->new();

	foreach my $foo ( @{$root->{'_body'}{'_content'}[1]{'_content'}[0]{'_content'}[1]{'_content'}[2]{'_content'}} ) {

		my $key = $foo->{'_content'}[0]->as_text();
		$key =~ tr /[A-Z]/[a-z]/;
		$key =~ s/\W//g;

		$settings->{$key} = $foo->{'_content'}[1]->as_text();

	}

	return $settings;

}

sub recent_transactions {

	my $viewRecentTransactions = $ua->get("$BASEURL/create-servicing/viewRecentTransactions.do");

	my $root = HTML::TreeBuilder->new_from_content($viewRecentTransactions->content);

	my $transactions = Finance::Bank::CreateCard::Transactions->new();

	foreach my $foo (@{$root->{'_body'}{'_content'}[1]{'_content'}[0]{'_content'}[1]{'_content'}[5]{'_content'}}){

		my $date   = $foo->{'_content'}[0]->as_text();
		my $desc   = $foo->{'_content'}[1]->as_text();
		my $payin  = $foo->{'_content'}[2]->as_text();
		my $payout = $foo->{'_content'}[3]->as_text();

		# strip space
		$payin =~ s/\s//g;
		$payout =~ s/\s//g;

		if ($date =~ /(\d\d)\/(\d\d)\/(\d\d)/) {

			$transactions->add($date, $desc, $payin, $payout);

		}

		if ($desc =~ /^Sub Total/) {
			$transactions->{laststatementbalance} = $payout;
		}

		if ($desc =~ /^Total/) {
			$transactions->{total} = $payout;
		}

	}

	return $transactions;

}

package Finance::Bank::CreateCard::Account;
sub AUTOLOAD { 

	no strict 'refs';
	use vars '$AUTOLOAD';

	my ( $self, %args ) = @_;

	$AUTOLOAD =~ s/.*:://;

	$self->{$AUTOLOAD};

}

sub new {

	my ( $class, %args ) = @_;

	my $self={};

	bless $self, $class;

	return $self;
}

package Finance::Bank::CreateCard::Settings;
sub AUTOLOAD { 

	no strict 'refs';
	use vars '$AUTOLOAD';

	my ( $self, %args ) = @_;

	$AUTOLOAD =~ s/.*:://;

	$self->{$AUTOLOAD};

}

sub new {

	my ( $class, %args ) = @_;

	my $self={};

	bless $self, $class;

	return $self;
}

package Finance::Bank::CreateCard::Transactions;
sub AUTOLOAD { 

	no strict 'refs';
	use vars '$AUTOLOAD';

	my ( $self, %args ) = @_;

	$AUTOLOAD =~ s/.*:://;

	$self->{$AUTOLOAD};

}

sub new {

	my ( $class, %args ) = @_;

	my $self={};

	bless $self, $class;

	return $self;
}

sub add {
	
	my ( $self, $date, $desc, $payin, $payout ) = @_;

	push @{$self->{transactions}}, { date=>$date, description=>$desc, payin=>$payin, payout=>$payout };

}

1;
__END__
# module documentation

=head1 NAME

CreateCard - Check your CreateCard account from Perl. 

=head1 SYNOPSIS

	use Finance::Bank::CreateCard;

	my $cc = new Finance::Bank::CreateCard;

	$cc->login(username=>"$username", password=>"$password") or die "Username or password incorrect.";
	my $account = $cc->account_overview();

	print "Current Balance is:  " . $account->currentbalance() . "\n";
	print "Available Credit:    " . $account->availablecredit() . "\n";
	print "Minimum Payment:     " . $account->minimumpayment() . "\n";
	print "Cashback Rate:       " . $account->cashbackrate() . "\n";
	print "Last Statement Date: " . $account->laststatementdate(). "\n";
	print "Cash Back To Date:   " . $account->cashbacktodate() . "\n";
	print "Card Number:         " . $account->cardnumber() . "\n";
	print "Name:                " . $account->name() ."\n";
	print "Payment Date Due:    " . $account->paymentduedate() . "\n";
	print "Credit Limit:        " . $account->creditlimit() . "\n";

	my $settings = $cc->card_settings();

	print "Next Cashback Reward   :" . $settings->nextdateofcashbackreward() . "\n";
	print "Cashback Reward Rate   :" . $settings->cashbackrewardonpurchases() . "\n";
	print "Number of Free Changes :" . $settings->numberoffreechangesavailable() ."\n";
	print "Statement Option       :" . $settings->statementoption() . "\n";
	print "APR Purchases Only     :" . $settings->aprpurchasesonly() . "\n";
	print "Annual Fee             :" . $settings->annualfee() . "\n";
	print "Servicing Option       :" . $settings->servicingoption () . "\n";
	print "Annual Interest Rate   :" . $settings->annualinterestrate() . "\n";

	my $transactions = $cc->recent_transactions();

	print "Last statement Balance: " . $transactions->laststatementbalance() . "\n";
	print "Total                 : " . $transactions->total() . "\n";

	for my $transaction ( @{$transactions->transactions()} ) {


		printf("%10s  %40s  %10s %10s\n",
		 $transaction->{date},
		 $transaction->{description},
		 $transaction->{payin},
		 $transaction->{payout}
		);


	}

=head1 DESCRIPTION

	This module provides a basic interface to the CreateCard 
	(http://www.createcard.co.uk/ ) online credit card.

=head1 CLASS METHODS

	account_overview();

	card_settings();

	recent_transactions();

=head1 ACCOUNT OBJECT METHODS

	$ao->currentbalance()
	$ao->availablecredit()
	$ao->minimumpayment()
	$ao->cashbackrate()
	$ao->cardnumber()
	$ao->name()
	$ao->paymentduedate()
	$ao->creditlimit()

=head1 STATEMENT OBJECT METHODS

	$st->nextdateofcashbackreward()
	$st->cashbackrewardonpurchases()
	$st->numberoffreechangesavailable()
	$st->statementoption()
	$st->aprpurchasesonly()
	$st->annualfee()	
	$st->servicingoption()
	$st->annualinterestrate()

=head1 RECENT TRANSACTIONS OBJECT METHODS

	$rt->laststatementbalance()
	$rt->total()
	$rt->transactions()

=head1 WARNING

	This module is for online banking/credit cards, you are expected to 
	audit the source code yourself.


=head1 AUTHOR

Robert J. McKay <robert@mckay.com>

=cut
