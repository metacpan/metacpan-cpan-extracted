package DomainOperations::ResellerClubHTTP;

use warnings;
use strict;
=head1 NAME

DomainOperations::ResellerClubHTTP - A class to search and book a Domain Name via ResellerClub HTTP API!

=head1 VERSION

Version 0.02

=cut

#NOTE: Distributing this script is permitted but requires a licence. Contact author of this module for requesting
#that . Provide the reason for distributing the script ie. for which application do you want to use the cript. You will be responded within hours.
#Disclaimer: This program is distributed as it is and the author or sms1.in does not claim any responsibilities for the successful operation of this program or that we are not sure that it will or can cause any abnormality in your computer. However during our testing no such problem occured.
#
#
#This script is Prepared by ,
#Abhsihek jain

our $VERSION = '0.02';

use base 'DomainOperations';

use LWP::UserAgent;
use JSON::XS;
use Data::Dumper;
use HTTP::Request;
use constant ResellerClubHTTPURL_Sandbox    => 'https://test.httpapi.com/api/';
use constant ResellerClubHTTPURL_Production => 'https://httpapi.com/api/';

=head1 SYNOPSIS

This module presents an easy to use Resellerclub's HTTP APIs on Perl.
 

	use DomainOperations::ResellerClubHTTP;
	use Data::Dumper;
	my $do = DomainOperations::ResellerClubHTTP->new(username=>'USER',password=>'PASS',account=>'Sandbox');

	print Dumper $do->checkDomainAWithoutSuggestion({'domains'=>['thisisthedomain' ],'tlds'=>['com' ,'net']});

=head1 FUNCTIONS

=head2 new

=head2 createCustomer

=head2 createContact

=head2 checkDomainAWithoutSuggestion

=head2 checkDomainAWithSuggestion

=head2 registerDomain

=cut

sub new {
	my $self = shift;
	my %options = @_;
	
	my $ua = LWP::UserAgent->new;
	$ua->agent("Mozilla/8.0");

	my $req = HTTP::Request->new( GET => 'https://test.httpapi.com/api/' );
	$req->header( 'Accept' => 'text/html' );

	
	my $options = {
		type     => 'ResellerClubHTTP',
		username => $options{'username'},
		password => $options{'password'},
		ua       => $ua,
		req      => $req,
		url => defined $options{'account'} && lc $options{'account'} eq 'sandbox'
		? ResellerClubHTTPURL_Sandbox
		: ResellerClubHTTPURL_Production,
	};
	my $obj = bless $options, $self;
	$obj->SUPER::new(%options);
	print $obj->{url};
	return $obj;
}

sub createCustomer {
	my $self    = shift;
	my $options = shift;
	$self->{req}->uri(
		    $self->{url}
		  . 'customers/signup.json?auth-userid='
		  . $self->{username}
		  . '&auth-password='
		  . $self->{password}
		  . '&username='
		  . $options->{'cemail'}
		  . '&passwd='
		  . $options->{'cpassword'}
		  . '&name='
		  . $options->{'cname'}
		  . '&company='
		  . ( $options->{'ccompany'} || 'n/a' )
		  . '&address-line-1='
		  . $options->{'caddress1'}
		  .

		  (
			defined $options->{'caddress2'}
			? '&address-line-2=' . $options->{'caddress2'}
			: ''
		  )
		  . '&city='
		  . $options->{'ccity'}
		  . '&state='
		  . $options->{'cstate'}
		  . '&country='
		  . $options->{'ccountry'}
		  . '&zipcode='
		  . $options->{'czip'}
		  . '&phone-cc='
		  . $options->{'ccountrycode'}
		  . '&phone='
		  . $options->{'cphone'}
		  . (
			defined $options->{'cmobile'}
			? ( '&mobile-cc=' . $options->{'cmobilecountrycode'}
				  || $options->{'ccountrycode'} )
			  . '&mobile='
			  . $options->{'cmobile'}
			: ''
		  )
		  . '&lang-pref='
		  . ( $options->{'lang'} || 'en' ) . ''
	);

	# send request
	my $res = $self->{ua}->request( $self->{req} );

	# check the outcome
	if ( $res->is_success ) {
		my $coder = JSON::XS->new->ascii->pretty->allow_nonref;

		my $perl_scalar = $coder->decode( $res->content );

		if ( $options->{'_add_default_contact'} ) {
			my $contact_array =
			  $self->createContact( { %$options, customerid => $perl_scalar } );
			return {
				res     => $perl_scalar,
				contact => $contact_array->{res},
				'error' => 0,
			  }
			  if !$contact_array->{'error'};
			return {
				res          => $perl_scalar,
				'error'      => 0,
				errormessage => $contact_array->{errormessage}
			};
		}
		return { res => $perl_scalar, 'error' => 0, };
	}
	else {

		#		print Dumper $req;
		return { error => 1, errormessage => $res->status_line, };
	}

}

sub modifyCustomer {
	my $self    = shift;
	my $options = shift;
	$self->{req}->uri(
		    $self->{url}
		  . 'customers/modify.json?auth-userid='
		  . $self->{username}
		  . '&auth-password='
		  . $self->{password}
		  . '&customer-id='
		  . $options->{'customerid'}

		  . '&username='
		  . $options->{'cemail'}
		  . '&name='
		  . $options->{'cname'}
		  . '&company='
		  . ( $options->{'ccompany'} || 'n/a' )
		  . '&address-line-1='
		  . $options->{'caddress1'}
		  .

		  (
			defined $options->{'caddress2'}
			? '&address-line-2=' . $options->{'caddress2'}
			: ''
		  )
		  . '&city='
		  . $options->{'ccity'}
		  . '&state='
		  . $options->{'cstate'}
		  . '&country='
		  . $options->{'ccountry'}
		  . '&zipcode='
		  . $options->{'czip'}
		  . '&phone-cc='
		  . $options->{'ccountrycode'}
		  . '&phone='
		  . $options->{'cphone'}
		  . (
			defined $options->{'cmobile'}
			? ( '&mobile-cc=' . $options->{'cmobilecountrycode'}
				  || $options->{'ccountrycode'} )
			  . '&mobile='
			  . $options->{'cmobile'}
			: ''
		  )
		  . '&lang-pref='
		  . ( $options->{'lang'} || 'en' ) . ''
	);

	# send request
	my $res = $self->{ua}->request( $self->{req} );

	# check the outcome
	if ( $res->is_success ) {
		my $coder = JSON::XS->new->ascii->pretty->allow_nonref;

		my $perl_scalar = $coder->decode( $res->content );

		return { res => $perl_scalar, 'error' => 0, };
	}
	else {
		return { error => 1, errormessage => $res->status_line, };
	}

}

sub modifyCustomerPassword {
	my $self    = shift;
	my $options = shift;
	$self->{req}->uri(
		    $self->{url}
		  . 'customers/change-password.json?auth-userid='
		  . $self->{username}
		  . '&auth-password='
		  . $self->{password}
		  . '&customer-id='
		  . $options->{'customerid'}

		  . '&new-passwd=' . $options->{'newpassword'}
	);

	# send request
	my $res = $self->{ua}->request( $self->{req} );

	# check the outcome
	if ( $res->is_success ) {
		my $coder = JSON::XS->new->ascii->pretty->allow_nonref;

		my $perl_scalar = $coder->decode( $res->content );

		return { res => $perl_scalar, 'error' => 0, };
	}
	else {
		return { error => 1, errormessage => $res->status_line, };
	}

}

sub createContact {
	my $self    = shift;
	my $options = shift;
	$self->{req}->uri(
		    $self->{url}
		  . 'contacts/add.json?auth-userid='
		  . $self->{username}
		  . '&auth-password='
		  . $self->{password}
		  . '&email='
		  . $options->{'cemail'}
		  . '&name='
		  . $options->{'cname'}
		  . '&company='
		  . ( $options->{'ccompany'} || 'n/a' )
		  . '&address-line-1='
		  . $options->{'caddress1'}
		  .

		  (
			defined $options->{'caddress2'}
			? '&address-line-2=' . $options->{'caddress2'}
			: ''
		  )
		  . '&city='
		  . $options->{'ccity'}
		  . '&state='
		  . $options->{'cstate'}
		  . '&country='
		  . $options->{'ccountry'}
		  . '&zipcode='
		  . $options->{'czip'}
		  . '&phone-cc='
		  . $options->{'ccountrycode'}
		  . '&phone='
		  . $options->{'cphone'}
		  . '&type='
		  .

		  (
			defined $options->{'type'}
			? $options->{'type'}
			: 'Contact'
		  )
		  . '&customer-id='
		  . $options->{customerid}

	);
	print $self->{req}->uri();

	# send request
	my $res = $self->{ua}->request( $self->{req} );

	# check the outcome
	if ( $res->is_success ) {
		my $coder = JSON::XS->new->ascii->pretty->allow_nonref;

		my $perl_scalar = $coder->decode( $res->content );
		if ( defined $perl_scalar->{error} ) {
			return { error => 1, errormessage => $perl_scalar->{error} };
		}
		return { res => $perl_scalar, 'error' => 0, };
	}
	else {
		return { error => 1, errormessage => $res->status_line, };
	}

}

sub modifyContact {
	my $self    = shift;
	my $options = shift;
	$self->{req}->uri(
		    $self->{url}
		  . 'contacts/modify.json?auth-userid='
		  . $self->{username}
		  . '&auth-password='
		  . $self->{password}
		  . '&email='
		  . $options->{'cemail'}
		  . '&name='
		  . $options->{'cname'}
		  . '&company='
		  . ( $options->{'ccompany'} || 'n/a' )
		  . '&address-line-1='
		  . $options->{'caddress1'}
		  .

		  (
			defined $options->{'caddress2'}
			? '&address-line-2=' . $options->{'caddress2'}
			: ''
		  )
		  . '&city='
		  . $options->{'ccity'}
		  . '&state='
		  . $options->{'cstate'}
		  . '&country='
		  . $options->{'ccountry'}
		  . '&zipcode='
		  . $options->{'czip'}
		  . '&phone-cc='
		  . $options->{'ccountrycode'}
		  . '&phone='
		  . $options->{'cphone'}
		  . '&type='
		  .

		  (
			defined $options->{'type'}
			? $options->{'type'}
			: 'Contact'
		  )
		  . '&contact-id='
		  . $options->{contactid}

	);
	print $self->{req}->uri();

	# send request
	my $res = $self->{ua}->request( $self->{req} );

	# check the outcome
	if ( $res->is_success ) {
		my $coder = JSON::XS->new->ascii->pretty->allow_nonref;

		my $perl_scalar = $coder->decode( $res->content );

		return { res => $perl_scalar, 'error' => 0, };
	}
	else {
		return { error => 1, errormessage => $res->status_line, };
	}

}

sub checkDomainAWithoutSuggestion {
	my $self    = shift;
	my $options = shift;
	$self->checkDomainA(
		{
			'checkwithsuggestion' => 0,
			tlds                  => $options->{'tlds'},
			domains               => $options->{'domains'},
		}
	);

}

sub checkDomainAWithSuggestion {
	my $self    = shift;
	my $options = shift;
	$self->checkDomainA(
		{
			'checkwithsuggestion' => 1,
			tlds                  => $options->{'tlds'},
			domains               => $options->{'domains'},
		}
	);

}

sub checkDomainA {
	my $self       = shift;
	my $options    = shift;
	my $suggestion = 'true';

	if ( !$options->{checkwithsuggestion} ) {
		$suggestion = 'false';
	}
	$self->{req}->uri( $self->{url}
		  . 'domains/available.json?auth-userid='
		  . $self->{username}
		  . '&auth-password='
		  . $self->{password}
		  . '&domain-name='
		  . join( '&domain-name=', @{ $options->{'domains'} } )
		  . '&tlds='
		  . join( '&tlds=', @{ $options->{'tlds'} } )
		  . '&suggest-alternative='
		  . $suggestion );

	# send request
	my $res = $self->{ua}->request( $self->{req} );

	# check the outcome
	if ( $res->is_success ) {
		my $coder = JSON::XS->new->ascii->pretty->allow_nonref;

		# $pretty_printed_unencoded = $coder->encode ($perl_scalar);
		my $perl_scalar = $coder->decode( $res->content );

		#		print Dumper $perl_scalar;

		#$res->decoded_content;
		return { $self->formatdomains($perl_scalar), 'error' => 0, };
	}
	else {

		#		print Dumper $req;
		return { error => 1, errormessage => $res->status_line, };
	}
}

sub formatdomains() {
	my $self             = shift;
	my $perl_scalar      = shift;
	my $formatted_scalar = {};
	my $suggestions      = {};
	foreach my $domain ( keys %$perl_scalar ) {
		if ( $domain =~ /\./ && $perl_scalar->{$domain}->{status} ) {
			if ( $perl_scalar->{$domain}->{status} eq 'available' ) {
				$formatted_scalar->{$domain}->{status} = 'a';
			}
			elsif ( $perl_scalar->{$domain}->{status} eq 'regthroughothers' ) {
				$formatted_scalar->{$domain}->{status} = 'o';
			}
			else {
				$formatted_scalar->{$domain}->{status} = 's';
			}
			$formatted_scalar->{$domain}->{name} =
			  ( split( /\./, $domain, 2 ) )[0];
			$formatted_scalar->{$domain}->{tld} =
			  ( split( /\./, $domain, 2 ) )[1];

			#			$formatted_scalar->{$_}->{search}
		}
		else {
			foreach my $sdomain ( keys %{ $perl_scalar->{$domain} } ) {

				#				print Dumper $sdomain;
				foreach
				  my $stld ( keys %{ $perl_scalar->{$domain}->{$sdomain} } )
				{
					if ( $perl_scalar->{$domain}->{$sdomain}->{$stld} eq
						'available' )
					{
						$suggestions->{$sdomain}->{$stld} = 'a';
					}
					elsif ( $perl_scalar->{$domain}->{$sdomain}->{$stld} eq
						'regthroughothers' )
					{
						$suggestions->{$sdomain}->{$stld} = 'o';
					}
					else {
						$suggestions->{$sdomain}->{$stld} = 's';
					}
				}
			}
		}

	}
	return ( 'searchres', $formatted_scalar, 'suggestions', $suggestions );
}

sub registerDomain {
	my $self    = shift;
	my $options = shift;
	my $cedcontact;
	$cedcontact = $options->{contact}
	  if ( ( split( /\./, $options->{domain}, 2 ) )[1] eq 'asia' );
	$self->{req}->uri( $self->{url}
		  . 'domains/register.json?auth-userid='
		  . $self->{username}
		  . '&auth-password='
		  . $self->{password}
		  . '&domain-name='
		  . $options->{'domain'}
		  . '&years='
		  . $options->{years} . '&ns='
		  . join( '&ns=', @{ $options->{'nameservers'} } )
		  . '&customer-id='
		  . $options->{customer}
		  . '&reg-contact-id='
		  . ( $options->{regcontact} || $options->{contact} )
		  . '&admin-contact-id='
		  . ( $options->{admincontact} || $options->{contact} )
		  . '&tech-contact-id='
		  . ( $options->{techcontact} || $options->{contact} )
		  . '&billing-contact-id='
		  . ( $options->{billingcontact} || $options->{contact} )
		  . '&invoice-option='
		  . ( $options->{'invoiceoption'} || 'NoInvoice' )
		  . '&protect-privacy='
		  . ( $options->{privacy} || 'true' )
		  . ( defined $cedcontact ? $cedcontact : '' ) );

	# send request
	my $res = $self->{ua}->request( $self->{req} );

	# check the outcome
	if ( $res->is_success ) {
		my $coder       = JSON::XS->new->ascii->pretty->allow_nonref;
		my $perl_scalar = $coder->decode( $res->content );
		if ( defined $perl_scalar->{error} ) {
			return { error => 1, errormessage => $perl_scalar->{error} };
		}
		return {
			res     => $perl_scalar->{entityid},
			'error' => 0,
			hash    => $perl_scalar,
			desc    => $perl_scalar->{actiontypedesc}
		};
	}
	else {
		return { error => 1, errormessage => $res->status_line, };
	}
}

sub renewDomain {
	my $self    = shift;
	my $options = shift;
	$self->{req}->uri(
		    $self->{url}
		  . 'domains/renew.json?auth-userid='
		  . $self->{username}
		  . '&auth-password='
		  . $self->{password}
		  . '&order-id='
		  . $options->{'orderid'}
		  . '&years='
		  . $options->{years}
		  . '&exp-date='
		  . $options->{expdate}
		  . '&invoice-option='
		  . ( $options->{'invoiceoption'} || 'NoInvoice' )

	);

	# send request
	my $res = $self->{ua}->request( $self->{req} );

	# check the outcome
	if ( $res->is_success ) {
		my $coder       = JSON::XS->new->ascii->pretty->allow_nonref;
		my $perl_scalar = $coder->decode( $res->content );
		if ( defined $perl_scalar->{error} ) {
			return { error => 1, errormessage => $perl_scalar->{error} };
		}
		return { res => $perl_scalar, 'error' => 0, hash => $perl_scalar };
	}
	else {
		return { error => 1, errormessage => $res->status_line, };
	}
}

sub transferDomain {
	my $self    = shift;
	my $options = shift;
	my $cedcontact;
	$cedcontact = $options->{contact}
	  if ( ( split( /\./, $options->{domain}, 2 ) )[1] eq 'asia' );
	$self->{req}->uri( $self->{url}
		  . 'domains/register.json?auth-userid='
		  . $self->{username}
		  . '&auth-password='
		  . $self->{password}
		  . '&domain-name='
		  . $options->{'domain'}
		  . '&auth-code='
		  . $options->{authcode} . '&ns='
		  . join( '&ns=', @{ $options->{'nameservers'} } )
		  . '&customer-id='
		  . $options->{customer}
		  . '&reg-contact-id='
		  . ( $options->{regcontact} || $options->{contact} )
		  . '&admin-contact-id='
		  . ( $options->{admincontact} || $options->{contact} )
		  . '&tech-contact-id='
		  . ( $options->{techcontact} || $options->{contact} )
		  . '&billing-contact-id='
		  . ( $options->{billingcontact} || $options->{contact} )
		  . '&invoice-option='
		  . ( $options->{'invoiceoption'} || 'NoInvoice' )
		  . '&protect-privacy='
		  . ( $options->{privacy} || 'true' )
		  . ( defined $cedcontact ? $cedcontact : '' ) );

	# send request
	my $res = $self->{ua}->request( $self->{req} );

	# check the outcome
	if ( $res->is_success ) {
		my $coder       = JSON::XS->new->ascii->pretty->allow_nonref;
		my $perl_scalar = $coder->decode( $res->content );
		if ( defined $perl_scalar->{error} ) {
			return { error => 1, errormessage => $perl_scalar->{error} };
		}
		return { res => $perl_scalar, 'error' => 0, hash => $perl_scalar };
	}
	else {
		return { error => 1, errormessage => $res->status_line, };
	}
}
=head1 AUTHOR

"abhishek jain", C<< <"goyali at cpan.org"> >>

=head1 BUGS

Please report any bugs or feature requests directly to the author at C<< <"goyali at cpan.org"> >>




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc DomainOperations::ResellerClubHTTP

You can also email the author and rest assured of the reply

=head1 COPYRIGHT & LICENSE

Copyright 2010 "abhishek jain".

=head1 DESCRIPTION

This module implements the HTTP APIs of ResellerClub a popular domian registrar from India,

At the moment these methods are implemented:

=over 4

=item C<new>

A constructor

The parameters sent are :
username  :	resellerid of the reseller, can be viewed under the Settings , Personal Information from the web interface. 
password  :	password
account   :	whether this is 'Sandbox' or 'Production'

returns an object


=item C<checkDomainAWithoutSuggestion>
The parameters are:
A Hash Ref with the following keys:
domains : value is an arrayref of the domain name(s) to query the registry database
tlds	: value is an arrayref of the TLDs to query for.

		
example:
$do->checkDomainAWithoutSuggestion({'domains'=>['domaintosearch','another' ],'tlds'=>['com' ,'net']});

Returns an hashref, and as the name suggests along with the availability of domains will not return suggestions alternative of domains. 


=item C<checkDomainAWithSuggestion>
The parameters are:
A Hash Ref with the following keys:
domains : value is an arrayref of the domain name(s) to query the registry database
tlds	: value is an arrayref of the TLDs to query for.

		
example:
$do->checkDomainAWithSuggestion({'domains'=>['domaintosearch','another' ],'tlds'=>['com' ,'net']});

Returns an hashref, and as the name suggests along with the availability of domains will also return suggestions alternative of domains.

=item C<createCustomer>
The parameters are:
A Hash Ref with the following keys:
_add_default_contact	:	Also create and return a contact along with a customer.
cemail					:	valid email address of the customer who wants to book a domain
cpassword				:	valid password of customer,Rules > 8 chars and alphanumeric 
cname 					:	Customer Name
caddress1 				:	Customer Address Line 1
caddress2 				:	Customer Address Line 1
ccity					:	City
cstate					:	State
ccountry 				:	2 digit ISO Code for country
czip					:	Zip / Post Code
ccountrycode			:	Country ISD Code 
cphone					:	Phone with the STD Code
		
example:
print Dumper $do->createCustomer({_add_default_contact=>'1',	cemail=>'valid email', cpassword=>'valid password', cname =>'abhishek jain',caddress1 =>'test add 1',caddress2 =>'add 2',ccity=>'delhi', cstate=>'delhi', 
		  ccountry =>'IN', czip=>'110000' ,ccountrycode=>'91',  cphone =>'1122222222',});

Returns an hashref, with the customer id and the contact id.

=item C<registerDomain>
The parameters are:
A Hash Ref with the following keys:
domain			:	domain name with the TLD to book,
years			: 	Number of years
nameservers		:	Array ref with the nameservers 
customer 		:	Customer id (integer)
contact			:	Contact id (integer)



example:
print Dumper $do->registerDomain({
 domain=>'abhidddd.com' ,years=>4, nameservers=>['ns1.xyz.com','ns1.xyz.com'], 
		   customer => '111111',contact=>'11111'});

Returns an hashref, along with that the status of the domain registration.


=item C<modifyContact>
Not yet implemented, please dont use this function for now.

=item C<checkDomainA>
Not yet implemented, please dont use this function for now.

=item C<formatdomains>
Not yet implemented, please dont use this function for now.

=item C<renewDomain>
Not yet implemented, please dont use this function for now.

=item C<transferDomain>
Not yet implemented, please dont use this function for now.


=item C<modifyCustomer>
Not yet implemented, please dont use this function for now.


=item C<modifyCustomerPassword>
Not yet implemented, please dont use this function for now.

=back

=head1 TODO

Need to add more functions like whois.

=head1 NOTE:

This module is provided as is, and is still underdevelopment, not suitable for Production use.

Virus free , Spam Free , Spyware Free Software and hopefully Money free software .

=head1 AUTHOR

<Abhishek jain>
goyali at cpan.org

=head1 SEE ALSO

http://www.ejain.com

=cut
1;    # End of DomainOperations::ResellerClubHTTP
