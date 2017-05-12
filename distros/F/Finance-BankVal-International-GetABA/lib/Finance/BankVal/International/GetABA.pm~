package Finance::BankVal::International::GetABA;

use 5.008000;
use strict;
use warnings;
use vars qw($size $format $aba $userid $pin $error $ua $url);
use LWP::UserAgent;
use XML::Simple;
use JSON;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(getABA new);
our $VERSION = '0.02';

my $format;		#response return format i.e. xml json csv
my $aba;      		#the ABA to be validated
my $userid;
my $pin;
my $size;               #the number of parameters passed only 2 and 4 are valid
my $error;              #any error messages generated here, not from unifieds servers
my $responseString;     #the return value of getSWIFT either $errors or web service response
my $ua;
my $url;

#constructor
sub new {
        my $proto = shift;
        my $class = ref($proto) || $proto;
        my $self = {};
	bless ($self, $class);
        return $self;
}

# exportable sub takes parameter array of 2 or 4 elements
# see perldoc for this module for more details
# getABA($format,$aba,$userid,pin);
# or getABA($format,$swiftbic);
sub getABA{
	$error="";
	my @params = @_;
        $size = @params;
        #the following block checks to see if the first param is a reference
        #if it is then the sub was called as an object ref so size is reduced
        #accordingly
        my $refCheck = shift @_;       						#remove the leftmost array element
        if (ref($refCheck)){                                                    #check if its a reference
        	$size--;                                                        #if it is reduce the size value to account for it
        }else{                                                                  #otherwise
        	unshift(@_, $refCheck);                                         #put it back
    	}
        $format = lc($_[0]);
        $aba = $_[1];
        if ($size > 2){
        	$userid = $_[2];
                $pin = $_[3];
        }else{
                &loadUidPin;
        }
        #all params should now be present so call validate formats sub
        &validateFormat;
        #if invalid formats are found return error message
        if ($error){
           	$responseString = "$error";
                &formatErrorMsg;
                return $responseString;
        }
        #if all formats are ok call web service sub then return response
        &goValidate;
        return $responseString;

}

sub goValidate{
        #create user agent
	$ua = LWP::UserAgent->new();

	#build the URL
        my $baseUrl = 'https://www.unifiedsoftware.co.uk/services/bankvalint/abadetails';
    	$url = "$baseUrl/userid/$userid/pin/$pin/aba/$aba/$format/";

	#call the service
	my $response = $ua->get($url);

	#Check the response code if its fail call backup server sub
	if($response->code<200||$response->code>399){
                &goFallOver;
	} else {
	        $responseString = $response->content();
	}
}

sub goFallOver{
	#build the URL
        my $baseUrl = 'https://www.unifiedservices.co.uk/services/bankvalint/abadetails';
    	$url = "$baseUrl/userid/$userid/pin/$pin/aba/$aba/$format/";

	#call the service
	my $response = $ua->get($url);

	#Check the response code
	if($response->code<200||$response->code>399){
                $responseString .= $response->code;
	} else {
	        $responseString = $response->content();
	}
}

sub validateFormat{
        #Validate response format must match json, xml, or, csv
        if ($format !~ /^json$|^xml$|^csv$/){
                $error .= "INVALID - Result Format ";
                return;
        }
        #Validate ABA routing no. 9 numerics
        if ($aba !~ /^[0-9]{9}$/) {
                $error .= "INVALID";
                return;
        }
        #Validate PIN all numeric 5 characters
        if ($pin){
                if ($pin !~ /^\d\d\d\d\d$/){
                        $error .= "ERROR - Invalid User ID/PIN";
                        return;
                }
        }
        #Validate UID must end with 3 numerics exactly and start with 3 Alpha variable length otherwise
        if ($userid){
                 if ($userid !~ /^[a-zA-Z\-_][a-zA-Z][a-zA-Z]*\D\d\d\d$/){
                    	$error .= "ERROR - Invalid User ID/PIN";
                        return
                 }
        }
}

sub loadUidPin {
	my $fileOpened = open UIDCONF, "InternationalLoginConfig.txt";
        if ( ! $fileOpened){
                $error .= "No UserID / PIN supplied, please visit http://www.unifiedsoftware.co.uk/freetrial/free-trial-home.html: ";
        }else{
         	while (<UIDCONF>){
        		if ($_ =~ /^UserID/){
                        	chomp(my @line = split (/ |\t/,$_));
                                $userid = $line[-1];
                        }elsif($_ =~ /^PIN/){
                                chomp(my @line = split (/ |\t/,$_));
                                $pin = $line[-1];
                        }

                }
                #check to see if conf file has empty params - if so return error message directing to free trial page
                if (($userid !~ /\w/) || ($pin !~ /\w/)){
                        $error .= "No UserID / PIN supplied, please visit http://www.unifiedsoftware.co.uk/freetrial/free-trial-home.html: ";
                }
        close UIDCONF;
        }
}

sub formatErrorMsg{
 	if($format eq "xml"){
        	$responseString = "<?xml version=\"1.0\" encoding=\"UTF-8\"?><aba><result>" . $responseString . "</result>"
                . "<routingnumber></routingnumber><bankname></bankname><bankaddress></bankaddress><city></city><state>"
                . "</state><zipcode></zipcode><telephone></telephone><areacode></areacode><fips></fips><timezone></timezone>"
                . "<dst></dst><latitude></latitude><longitude></longitude><msa></msa><pmsa></pmsa><county></county></aba>";
        }elsif($format eq "json"){
         	$responseString = "{\"result\":\"" . $responseString . "\",\"routingnumber\":\"\",\"bankname\":\"\",\""
                . "bankaddress\":\"\",\"city\":\"\",\"state\":\"\",\"zipcode\":\"\",\"telephone\":\"\",\"areacode\":\"\",\"fips\""
                . ":\"\",\"timezone\":\"\",\"dst\":\"\",\"latitude\":\"\",\"longitude\":\"\",\"msa\":\"\",\"pmsa\":\"\",\"county\""
                . ":\"\"}";
        }
}

1;
__END__


=head1 NAME

BankVal::International::GetABA

=head1 SYNOPSIS

  use Finance::BankVal::International::GetABA qw(&getABA);

  $ans = getABA('format','ABA','userId','PIN');

  ==================== or for OO ========================

  use Finance::BankVal::International::GetABA;

  $abaObj = Finance::BankVal::International::GetABA->new();
  $ans = $abaObj->getABA('format','ABA','userId','PIN');

=head1 DESCRIPTION

This module handles all of the restful web service calls to Unified Software's
BankValInternational ABA service. It also handles fail over to the back up services
transparently to the calling script. It can be called in a procedural or OO fashion
(see synopsis)

The exportable method &getABA(); takes a number of parameters including;

1: Format 	- the response format (either xml, json or csv)

2: ABA		- the ABA code to be validated

3: UserID	- available from www.unifiedsoftware.co.uk

4: PIN		- available from www.unifiedsoftware.co.uk

(UserID and PIN are available from http://www.unifiedsoftware.co.uk/freetrial/free-trial-home.html)

The order of the parameters B<must> be as above. The UserID and PIN can be stored in the InternationalLoginConfig.txt
file bundled with this module, the use of this file saves passing the PIN and user ID data with each call to getABA.
For example, a call to validate an ABA routing code passing the user ID and PIN as parameters
and printing the reply to console should follow this form:

=====================================================================

 #!/usr/bin/perl

 use Finance::BankVal::International::GetABA qw(&getABA);

 my $ans = getABA('XML','ABAcode','xmpl123','12345');

 print $ans;

=============================OR for OO===============================

 use Finance::BankVal::International::GetABA;

 $abaObj = Finance::BankVal::International::GetABA->new();
 my $ans = $abaObj->getABA('format','ABA','xmpl123','12345');

 print $ans;

=====================================================================

valid parameter lists are:-

getABA('$format','$aba','$userID','$PIN');

getABA('$format','$aba');

n.b. the last parameter list requires that the user ID and PIN are stored
in the I<InternationalLoginConfig.txt> file bundled with this module.

=head2 EXPORT

None by default.
&getABA is exported on request i.e. "use Finance::BankVal::International::GetABA qw(&getABA);"
or to use OO just "use Finance::BankVal::International::GetABA;"


=head1 DEPENDENCIES

LWP::UserAgent => 5.835
XML::Simple => 2.18
JSON => 2.21

Crypt::SSLeay => 0.57

Crypt::SSLeay is required by LWP::UserAgent to make use of SSL you may need to install this manually
try:
 sudo aptitude install libssl-dev (might not be neccessary and can be removed after install)
 sudo cpan -i Crypt::SSLeay

=head1 SEE ALSO

Please see L<http://www.unifiedsoftware.co.uk> for full details on Unified Software's web services.


=head1 AUTHOR

A. Evans - Unified Software, E<lt>support@unifiedsoftware.co.ukE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Unified Software Limited

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.08.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
