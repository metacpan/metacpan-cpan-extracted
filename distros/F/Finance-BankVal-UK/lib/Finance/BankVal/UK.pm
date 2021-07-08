package Finance::BankVal::UK;

use 5.008000;
use strict;
use warnings;
use vars qw(@params $size $account $error $sortcode $uid $pin &responseString $ua);
use LWP::UserAgent;
use JSON;

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(bankValUK new);
our $VERSION   = '0.9';

my $sortcode;          #sortcode to be validated
my $account;           #account number to be validated
my $uid;               #userID
my $pin;               #PIN
my $size;              #holds length of param array
my $url;               #the URL built for the REST call
my $responseString;    #the return to the calling method
my $error; #holds any error messages etc from the module, erors from the web servoce will be returned in $response string
my $json;    #holds the data to call the service with

#constructor
sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self  = {};
	bless( $self, $class );
	return $self;
}

#
# Exportable sub can take parameter array of 4 or 2 elements
# these must be in the order detailed in the perldoc for this module
#
sub bankValUK {
	$error = "";
	my @params = @_;
	$size = @params;

	#the following block checks to see if the first param is a reference
	#if it is then the sub was called as an object ref so size is reduced
	#accordingly
	#my $refCheck = shift @_;    #remove the leftmost array element
	#if ( ref($refCheck) ) {     #check if its a reference
#		$size--;    #if it is reduce the size value to account for it
#	}
#	else {          #otherwise
#		unshift( @_, $refCheck );    #put it back
#	}
	$sortcode = $_[0];               #set the sortcode

	#strip sortcode of seperating - or spaces
	$sortcode =~ s/-| //g;
    print STDOUT $sortcode;
	#Switch to handle different amount of parameters
  SWITCH: {
		$size == 4 && do {
			$account = $_[1];
			$uid     = $_[2];
			$pin     = $_[3];
			last SWITCH;
		};
		$size == 3 && do {    #todo this is now an error with only sortcode
			$uid = $_[1];
			$pin = $_[2];
			last SWITCH;
		};
		$size == 2 && do {
			$account = $_[1];
			&loadUidPin;
			last SWITCH;
		};
		$size == 1 && do {    #todo this is now an error with only sortcode
			&loadUidPin;
			last SWITCH;
		};
	}

	#call validation sub now all elements are loaded
	&validateFormat;

	if ($error) {
		$responseString = "$error";
		&formatErrorMsg;
		return $responseString;
	}

	#call validation sub
	&goValidate;
	print STDOUT $responseString;
	return $responseString;
}

#call main servers REST services passing url with relevant parameters
sub goValidate {
    $responseString = "";
	#create user agent
	local $ua = LWP::UserAgent->new();

	#set the URL
	$url = 'https://www.unifiedservices.co.uk/services/enhanced/bankval';

	#call the service
	&loadContent;
	my $req = HTTP::Request->new( 'POST', $url );
	$req->header( 'Content-Type' => 'application/json' );
	$req->content($json);
	my $response = $ua->request($req);

#Check the response code anything under 200 or over 399 is an error with main server try backup
	if ( $response->code < 200 || $response->code > 399 ) {
		&goFallOver;
	}
	else {
		$responseString = $response->content();   #otherwise return the returned
	}
}

#sub to call backup servers
sub goFallOver {

	#set the URL
	$url = 'https://www.unifiedsoftware.co.uk/services/enhanced/bankval';

	#call the service
	my $req = HTTP::Request->new( 'POST', $url );
	$req->header( 'Content-Type' => 'application/json' );
	$req->content($json);
	my $response = $ua->request($req);

	#Check the response code
	if ( $response->code < 200 || $response->code > 399 ) {
		$responseString .=
		  $response->code;    #still a problem so return error code
	}
	else {
		$responseString =
		  $response->content();    #ok this time so return the returned
	}
}

#sub to validate the parameters input
sub validateFormat {

 #Validate sortcode all numeric 6 chars (-'s and ws stripped in calling routine)
	if ( $sortcode !~ /^\d\d\d\d\d\d$/ ) {
		$error .= "INVALID - Sortcode";
		return;
	}

	#Validate account all numeric between 6 and 12 digits
	if (   ( length($account) < 6 )
		|| ( length($account) > 12 )
		|| ( $account !~ /^\d+\d$/ ) )
	{
		$error .= "INVALID - Account";
		return;
	}

	#Validate PIN all numeric 5 characters
	if ( $pin !~ /^\d\d\d\d\d$/ ) {
		$error .= "ERROR - Invalid User ID/PIN";
		return;
	}

#Validate UID must end with 3 numerics exactly and start with 3 Alpha variable length otherwise
	if ( $uid !~ /^[a-zA-Z\-_][a-zA-Z][a-zA-Z]*\D\d\d\d$/ ) {
		$error .= "ERROR - Invalid User ID/PIN";
		return;
	}
}

#sub to load PIN and UserID from LoginConfig.txt file if they weren't passed in with the method call
#returns an error if unsuccessful
sub loadUidPin {
	my $fileOpened = open UIDCONF, "LoginConfig.txt";
	if ( !$fileOpened ) {
		$error .=
"No UserID / PIN supplied, please visit https://www.unifiedsoftware.co.uk/request-a-free-trial/: ";
	}
	else {
		while (<UIDCONF>) {
			if ( $_ =~ /^UserID/ ) {
				chomp( my @line = split( / |\t/, $_ ) );
				$uid = $line[-1];
			}
			elsif ( $_ =~ /^PIN/ ) {
				chomp( my @line = split( / |\t/, $_ ) );
				$pin = $line[-1];
			}

		}

#check to see if conf file has empty params - if so return error message directing to free trial page
		if ( ( $uid !~ /\w/ ) || ( $pin !~ /\w/ ) ) {
			$error .=
"No UserID / PIN supplied, please visit https://www.unifiedsoftware.co.uk/request-a-free-trial/: ";
		}
		close UIDCONF;
	}
}

sub loadContent {
	$json =
"{'credentials':{'uname':'$uid','pin':'$pin'},'account':{'account':'$account','sortcode':'$sortcode'}}";
}

#sub to format the error message in the correct expected format with all nodes etc
sub formatErrorMsg {
	if ( substr( $responseString, 0, 7 ) eq 'INVALID' ) {
		$responseString =
		  "{\"validationID\": \"\",\"BankValUK\": {\"result\":\""
		  . $responseString . "\"}}";
	}
	else {
		$responseString = "{\"Error\": \"Invalid Credentials\"}";
	}

}

1;
__END__

=head1 NAME

Finance::BankValUK - Perl extension for accessing Unified Software's bankValUK web
services

=head1 SYNOPSIS

  use Finance::BankVal::UK qw(&bankValUK);

  $result = &bankValUK(@params);

  ============= or for OO =============

  use Finance::BankVal::UK;

  my $bvObj = Finance::BankVal::UK->new();
  $result = $bvObj->bankValUK(@params);


=head1 DESCRIPTION

This module handles all of the restful web service calls to Unified Software's
BankValUK service. It also handles fail over to the back up services transparently to the
calling script. It can be called either in a procedural sense or an OO one (see synopsis)

The exposed method &bankValUK(); takes a number of parameters including;

1: Sort code	- 6 digit number either 00-00-00, 00 00 00 or 000000

2: Account no.	- 6 to 12 digit (unseperated i.e. 00000000)

3: UserID	- available from www.unifiedsoftware.co.uk

4: PIN		- available from www.unifiedsoftware.co.uk

(UserID and PIN are available from https://www.unifiedsoftware.co.uk/request-a-free-trial/)

The order of the parameters B<must> be as above.
The UserID and PIN can also be stored in the LoginConfig.txt file bundled with this module, the
use of this file saves passing the PIN and user ID data with each call to bankValUK.
For example a call to validate a UK bank account passing the user ID and PIN as parameters
and printing the reply to console should follow this form:

=====================================================================

 #!/usr/bin/perl

 use Finance::BankVal::UK qw(&bankValUK);

 my $ans = bankValUK('01-02-03','12345678','xmpl123','12345');

 print $ans;

=====================OR for Object Orientation=======================

 use Finance::BankVal::UK

 my $bvObj = Finance::BankVal::UK->new();
 my $ans = $bvObj->bankValUK('01-02-03','12345678','xmpl123','12345');

 print $ans;

=====================================================================

valid parameter lists are:-

bankValUK('$sortcode','$account no.','$userID','$PIN');

bankValUK('$sortcode','$account no.');

n.b. the last parameter list requires that the user ID and PIN are stored
in the I<LoginConfig.txt> file bundled with this module.


=head2 EXPORT

None by default.
&bankValUK is exported on request i.e. "use Finance::BankVal::UK qw(&bankValUK);"

=head1 SEE ALSO

Please see L<http://www.unifiedsoftware.co.uk> for full details on Unified Software's web services.


=head1 AUTHOR

A. Evans - Unified Software, E<lt>support@unifiedsoftware.co.ukE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2021 by Unified Software Limited

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.


=cut

