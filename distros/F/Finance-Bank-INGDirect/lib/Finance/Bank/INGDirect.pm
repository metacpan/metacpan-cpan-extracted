package Finance::Bank::INGDirect;

use strict;
use Carp qw(carp croak);                                                                                                                                             
use HTTP::Cookies;                                                                                                                                                   
use LWP::UserAgent;                                                                                                                                                  
use HTML::Parser;                                                                                                                                                    
#use Data::Dump qw (dump);

our $VERSION = '1.05'; 

# $Id: INGDirect.pm,v 1.2 2005/12/16 22:30:20 jmrenouard Exp $
# $Log: INGDirect.pm,v $
# Revision 1.2  2005/12/16 22:30:20  jmrenouard
# Modification tag TD empéchant la lecture des transactions
#
# Revision 1.1.1.1  2005/12/16 22:01:09  jmrenouard
# Imported sources
#

=pod

=head1 NAME

Finance::Bank::INGDirect -  Check your "ING Direct France" accounts from Perl

=head1 SYNOPSIS

  use Finance::Bank::INGDirect;

  my @accounts = Finance::Bank::INGDirect->check_balance(
  	  	 ACN => "167845",
	  	 PIN => "1234",
	  	 JOUR => "25", # Day of birthday
	  	 MOIS => "8",  # month of birthday
	  	 ANNEE => "1952" # year of birthday
	  	 );

  foreach my $account (@accounts) {
 	 	print "Name: ", $account->name, " Account_no: ", $account->account_no, "\n", "*" x 80, "\n";
		print $_->as_string, "\n" foreach $account->statements;
  }

=head1 DESCRIPTION

This module provides a read-only interface to the INGDirect online banking
system at L<https://www.ingdirect.fr/>. You will need either Crypt::SSLeay
installed.

The interface of this module is similar to other Finance::Bank::* modules.

=head1 WARNING

This is code for B<online banking>, and that means B<your money>, and that
means B<BE CAREFUL>. You are encouraged, nay, expected, to audit the source
of this module yourself to reassure yourself that I am not doing anything
untoward with your banking data. This software is useful to me, but is
provided under B<NO GUARANTEE>, explicit or implied.

=cut

=pod

=head1 METHODS

=head2 new( ACN => "167845", PIN => "1234", JOUR => "25", MOIS => "8", ANNEE => "1952"  feedback => sub { warn "Finance::Bank::INGDirect : $_[0]\n" })

Return an object . You can optionally provide to this method a LWP::UserAgent
object (argument named "ua"). You can also provide a function used for
feedback (useful for verbose mode or debugging) (argument named "feedback")

=cut

my $urlMain="https://www.ingdirect.fr/secure/general";
my $urlLogin="$urlMain?command=displayLogin";
my $urlContent="$urlMain?command=displayTRAccountSummary";
my $urlAccount="$urlMain?command=goToAccount&account=";
my $urlAccount2="$urlMain?command=displayTRHistorique";
sub normalize_number {
	my ($self,$s) = @_;
	
	$s =~ s/ //;
	$s =~ s/,/./;
	$s;
}

sub _parse_content {
	my ($self, $content) = @_;
	my ($type, $num, $balance); 
	my $f=0;
	my $i=0;
	@{$self->{Accounts}}=();
	while ( $content =~ /(.*)\n/g ) {
		if ( !$f && $1 =~ /class=\"Bleu11\">(.*?)-(.*?)<\/a><\/td>/ ) {
			$type=$1;
			$num=$2;
			$f=1;
		#	print "\n#Found : $type $num";
		}
	if ( $f && $1 =~ /class="Bleu11">(.*)<\/a><\/td>/) {
		push ( @{$self->{Accounts}}, Finance::Bank::INGDirect::Account->new( $type, $num, $self->normalize_number($1), $self->{ua}, "$urlAccount$i" ));
		#print "\n\t $type, $num, $1, $urlAccount$i";
		$f=0;
		$i++;
		}
	}                
}

sub _get_cookie {
	my ($self) = @_;
	$self->{feedback}->("get cookie") if $self->{feedback};
	my $cookie_jar = HTTP::Cookies->new;
	my $response = $self->{ua}->simple_request(HTTP::Request->new(GET => $urlLogin));
	$cookie_jar->extract_cookies($response);
	$self->{ua}->cookie_jar($cookie_jar);
}

sub _login {
	my ($self) = @_;
	$self->{feedback}->("login") if $self->{feedback};

	my $request = HTTP::Request->new(POST => $urlMain);                                                                                                                      
	$request->content_type('application/x-www-form-urlencoded');                                                                                                         
	$request->content("ACN=$self->{ACN}&PIN=$self->{PIN}&command=login&locale=fr_FR&device=web&logdatelogin=1&JOUR=$self->{JOUR}&MOIS=$self->{MOIS}&ANNEE=$self->{ANNEE}");                                            
	my $response = $self->{ua}->request($request);
	$response->is_success or die "login failed\n" . $response->error_as_HTML;
}

sub _list_accounts {
	my ($self) = @_;
	$self->{feedback}->("list accounts") if $self->{feedback};
	my $response = $self->{ua}->request(HTTP::Request->new(GET => "$urlContent"));
	$response->is_success or die "can't access account\n" . $response->error_as_HTML;

	_parse_content($self, $response->content);
}

sub new {
	my ($class, %opts) = @_;
	my $self = bless \%opts, $class;

	exists $self->{ACN} or croak "Must provide a ACN";
	exists $self->{PIN} or croak "Must provide a PIN";
	exists $self->{JOUR} or croak "Must provide a JOUR";
	exists $self->{MOIS} or croak "Must provide a MOIS";
	exists $self->{ANNEE} or croak "Must provide a ANNEE";

	$self->{ua} ||= LWP::UserAgent->new;

	_get_cookie($self);
	_login($self);
	_list_accounts($self);
	$self;
}

sub default_account {
	my ($self) = @_;
	return $self->{Accounts}[0];
}

=pod

=head2 check_balance( ACN => "167845", PIN => "1234", JOUR => "25", MOIS => "8", ANNEE => "1952"  feedback => sub { warn "Finance::Bank::INGDirect : $_[0]\n" })

Return a list of account (F::B::INGDirect::Account) objects, one for each of
your bank accounts.

=cut

sub check_balance {
	my $self = &new;
	@{$self->{Accounts}};
}

package Finance::Bank::INGDirect::Account;
use Data::Dump qw (dump);

=pod

=head1 Account methods

=head2 type( )

Returns the human-readable name of the account.

=head2 account_no( )

Return the account number, in the form C<0123456L012>.

=head2 balance( )

Returns the balance of the account.

=head2 statements( )

Return a list of Statement object (Finance::Bank::INGDirect::Statement).

=head2 currency( )

Returns the currency of the account as a three letter ISO code (EUR, CHF,etc.).

=cut

sub new {
	my ($class, $type, $num, $bal, $ua, $url) = @_; 
	my %account;
	$account{type}=$type;
	$account{account_no}=$num;
	$account{balance}=$bal;
	$account{ua}=$ua;
	$account{url}=$url;
	$account{statements}=();
	my $self2 = bless \%account, $class;
	$self2;
}

sub type       { $_[0]->{type} }
sub account_no { $_[0]->{account_no} }
sub balance    { $_[0]->{balance} }
sub currency   { 'EUR' }

my $response;
sub statements { 
	my ($self) = @_;
	$self->{url} or return;
	unless (defined  @{$self->{statements}}) {
		$self->{feedback}->("get statements") if $self->{feedback};
		my $response = $self->{ua}->request(HTTP::Request->new(GET => $self->{url}));
		$response->is_success or die "can't access account $self->{url} statements\n" . $response->error_as_HTML;
		$response = $self->{ua}->request(HTTP::Request->new(GET => $urlAccount2));  
		$response->is_success or die "can't access account $urlAccount2 statements\n" . $response->error_as_HTML;
		_parse_content_account($self, $response->content);
	};
	@{$self->{statements}};
}

sub normalize_number {
	my ($self, $s) = @_;
	$s =~ s/ //;
	$s =~ s/,/./;
	$s;
}

sub _parse_content_account {
	my ($self, $content)=@_;
	#Parsing html content
	while ( $content =~ /BgdTabOra\">(\d+\/\d+\/\d+)<\/TD>(.|\n)+?Bleu11\">(.*?)<\/span>(.|\n)+?BgdTabOra" align="right">(.*?)<\/TD>/g) {
	#print "\n# $1 $3 $5";	
	push (@{$self->{statements}}, Finance::Bank::INGDirect::Statement->new ($1, $3, $self->normalize_number($5)));
	}	
}

package Finance::Bank::INGDirect::Statement;

=pod

=head1 Statement methods

=head2 date( )

Returns the date when the statement occured, in DD/MM/YY format.

=head2 description( )

Returns a brief description of the statement.

=head2 amount( )

Returns the amount of the statement (expressed in Euros or the account's currency). 
Although the Crédit Mutuel website displays number in continental
format (i.e. with a coma as decimal separator), amount() returns a real number.

=head2 as_string( $separator )

Returns a tab-delimited representation of the statement. By default, it uses
a tabulation to separate the fields, but the user can provide its own
separator.

=cut

sub new {
	my ($class, $date, $description, $amount) = @_;
	my %stat;
	$stat{date}=$date;
	$stat{description}=$description;
	$stat{amount}=$amount;
	bless \%stat, $class;
}

sub description { $_[0]{description} }
sub amount      { $_[0]{amount} }
sub date        {  $_[0]{date} }

sub as_string { 
	my ($self, $separator) = @_;
	join($separator || "\t", $self->{date}, $self->{description}, $self->{amount});
}
1;

=pod

=head1 COPYRIGHT

Copyright 2005, Jean-Marie Renouard. All Rights Reserved. This module
can be redistributed under the same terms as Perl itself.

=head1 AUTHOR

Thanks to Pixel for Finance::Bank::LaPoste, Cédric Bouvier for Finance::Bank::CreditMut
(and also to Simon Cozens and Briac Pilpré for various Finance::Bank::*)

=head1 SEE ALSO

Finance::Bank::BNPParibas, Finance::Bank::CreditMut, Finance::Bank::LaPoste, ...

=cut
