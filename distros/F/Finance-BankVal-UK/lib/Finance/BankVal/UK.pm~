#!/usr/bin/perl
package Finance::BankVal::UK;

use 5.008000;
use strict;
use warnings;
use vars qw(@params $size $format $account $error $sortcode $uid $pin &responseString $ua);
use LWP::UserAgent;
use XML::Simple;
use JSON;
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(bankValUK new);
our $VERSION = '0.02';

my $account;			#account number to be validated
my $uid;                        #userID
my $pin;                        #PIN
my $size;                       #holds length of param array
my $format;                     #format the response should be in
my $sortcode;                   #sortcode to be validated
my $url;                        #the URL built for the REST call
my $responseString;             #the return to the calling method
my $error;                      #holds any error messages etc from the module, erors from the web servoce will be returned in $response string

#constructor
sub new {
        my $proto = shift;
        my $class = ref($proto) || $proto;
        my $self = {};
	bless ($self, $class);
        return $self;
}

#
# Exportable sub can take parameter array of 5,4,3,2 elements
# these must be in the order detailed in the perldoc for this module
#
sub bankValUK{
	$error = "";
	local @params = @_;
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
        $format = lc($_[0]); 							#ensure format element is in lower case
        $sortcode = $_[1];							#set the sortcode


        #strip sortcode of seperating - or spaces
        $sortcode =~ s/-| //g;

        #Switch to handle different amount of parameters
        SWITCH:{
        	$size == 5 && do {
                	$account = $_[2];
                        $uid = $_[3];
                        $pin = $_[4];
                        last SWITCH;
              	};
                $size == 4 && do {
                	$uid = $_[2];
                        $pin = $_[3];
                        last SWITCH;
                };
                $size == 3 && do {
                 	$account = $_[2];
                        &loadUidPin;
                        last SWITCH;
                };
                $size == 2 && do {
                 	&loadUidPin;
                        last SWITCH;
                };
        }

        #call validation sub now all elements are loaded
        &validateFormat;

        if ($error){
        	$responseString = "$error";
                &formatErrorMsg;
                return $responseString;
        }

        #call validation sub
    	&goValidate;
        return $responseString;
}
#call main servers REST services passing url with relevant parameters
sub goValidate{
        #create user agent
	local $ua = LWP::UserAgent->new();

	#build the URL (differs depending on parameters supplied - ie account val or branch val)
        #params divisible by 2 have no account number
        if (($size%2)==0){
                my $baseUrl = 'https://www.unifiedsoftware.co.uk/services/bankvaluk/branchdets2';
	        $url = "$baseUrl/userid/$uid/pin/$pin/sortcode/$sortcode/$format/";
        }else{
        	my $baseUrl = 'https://www.unifiedsoftware.co.uk/services/bankvaluk/bankvalplus2';
	        $url = "$baseUrl/userid/$uid/pin/$pin/sortcode/$sortcode/account/$account/$format/";
         }
	#call the service
	my $response = $ua->get($url);

	#Check the response code anything under 200 or over 399 is an error with main server try backup
	if($response->code<200||$response->code>399){
                &goFallOver;
	} else {
	        $responseString = $response->content();  			#otherwise return the returned
	}
}
#sub to call backup servers
sub goFallOver{
	#build the URL
        if (($size%2)==0){
                my $baseUrl = 'https://www.unifiedservices.co.uk/services/bankvaluk/branchdets2';
	        $url = "$baseUrl/userid/$uid/pin/$pin/sortcode/$sortcode/$format/";
        }else{
        	my $baseUrl = 'https://www.unifiedservices.co.uk/services/bankvaluk/bankvalplus2';
	        $url = "$baseUrl/userid/$uid/pin/$pin/sortcode/$sortcode/account/$account/$format/";
        }

	#call the service
	my $response = $ua->get($url);

	#Check the response code
	if($response->code<200||$response->code>399){
                $responseString .= $response->code;                             #still a problem so return error code
	} else {
	        $responseString = $response->content();                         #ok this time so return the returned
	}
}

#sub to validate the parameters input
sub validateFormat {
        #Validate response format must match json, xml, or, csv
        if ($format !~ /^json$|^xml$|^csv$/){
                $error .= "INVALID - Result Format";
                return;
        }
        #Validate sortcode all numeric 6 chars (-'s and ws stripped in calling routine)
        if ($sortcode !~ /^\d\d\d\d\d\d$/){
                $error .= "INVALID - Sortcode";
                return;
        }
        #Validate account all numeric between 6 and 12 digits
        if (($account)&&((length($account) < 6) || (length($account) > 12) || ($account !~ /^\d+\d$/))){
                $error .= "INVALID - Account";
        }
	#Validate PIN all numeric 5 characters
        if ($pin !~ /^\d\d\d\d\d$/){
                $error .= "ERROR - Invalid User ID/PIN";
                return;
        }
        #Validate UID must end with 3 numerics exactly and start with 3 Alpha variable length otherwise
        if ($uid !~ /^[a-zA-Z\-_][a-zA-Z][a-zA-Z]*\D\d\d\d$/){
                $error .= "ERROR - Invalid User ID/PIN";
                return;
        }
}

#sub to load PIN and UserID from LoginConfig.txt file if they weren't passed in with the method call
#returns an error if unsuccessful
sub loadUidPin {
	my $fileOpened = open UIDCONF, "LoginConfig.txt";
        if ( ! $fileOpened){
                $error .= "No UserID / PIN supplied, please visit http://www.unifiedsoftware.co.uk/freetrial/free-trial-home.html: ";
        }else{
         	while (<UIDCONF>){
        		if ($_ =~ /^UserID/){
                        	chomp(my @line = split (/ |\t/,$_));
                                $uid = $line[-1];
                        }elsif($_ =~ /^PIN/){
                                chomp(my @line = split (/ |\t/,$_));
                                $pin = $line[-1];
                        }

                }
                #check to see if conf file has empty params - if so return error message directing to free trial page
                if (($uid !~ /\w/) || ($pin !~ /\w/)){
                        $error .= "No UserID / PIN supplied, please visit http://www.unifiedsoftware.co.uk/freetrial/free-trial-home.html: ";
                }
        close UIDCONF;
        }
}

#sub to format the error message in the correct expected format with all nodes etc
sub formatErrorMsg{
 	if($format eq "xml" && ($size%2)==0){
        	$responseString = "<?xml version=\"1.0\" encoding=\"UTF-8\"?><branchdets><result>" . $responseString . "</result>"
                . "<sortcode></sortcode><bicbank></bicbank><bicbranch></bicbranch><subbranchsuffix></subbranchsuffix><bankname></bankname>"
                . "<owningbank></owningbank><longbank1></longbank1><longbank2></longbank2><ownbc></ownbc><ccode></ccode>"
                . "<supervisorybody></supervisorybody><deletedate></deletedate><changedate></changedate><printindicator></printindicator>"

                . "<bacsstatus></bacsstatus><bacschangedate></bacschangedate><bacsclosedate></bacsclosedate><bacsredirectfrom></bacsredirectfrom>"
                . "<bacsredtoscode></bacsredtoscode><bacssettbank></bacssettbank><bacssettsec></bacssettsec><bacssettsubsec>"
                . "</bacssettsubsec><bacshandbank></bacshandbank><bacshandst></bacshandst><bacsaccnumflg></bacsaccnumflg>"
                . "<bacsddiflg></bacsddiflg><bacsdrdisallowed></bacsdrdisallowed><bacscrdisallowed></bacscrdisallowed>"
                . "<bacscudisallowed></bacscudisallowed><bacsprdisallowed></bacsprdisallowed><bacsbsdisallowed></bacsbsdisallowed>"
                . "<bacsdvdisallowed></bacsdvdisallowed><bacsaudisallowed></bacsaudisallowed><spare1></spare1><spare2></spare2>"
                . "<spare3></spare3><spare4></spare4><chapsretind></chapsretind><chapssstatus></chapssstatus><chapsschangedate>"
                . "</chapsschangedate><chapssclosedate></chapssclosedate><chapsssettmem></chapsssettmem><chapssrbicbank></chapssrbicbank>"
                . "<chapssrbicbr></chapssrbicbr><chapsestatus></chapsestatus><chapsechangedate></chapsechangedate><chapseclosedate>"
                . "</chapseclosedate><chapserbicbank></chapserbicbank><chapserbicbr></chapserbicbr><chapsesettmem></chapsesettmem>"
                . "<chapseretind></chapseretind><chapseswift></chapseswift><spare5></spare5><ccccstatus></ccccstatus><ccccchangedate>"
                . "</ccccchangedate><ccccclosedate></ccccclosedate><ccccsettbank></ccccsettbank><ccccdasc></ccccdasc><ccccretind></ccccretind>"
                . "<ccccgbni></ccccgbni><fpsstatus></fpsstatus><fpschangedate></fpschangedate><fpsclosedate></fpsclosedate><fpsredirectfrom>"
                . "</fpsredirectfrom><fpsredirecttosc></fpsredirecttosc><fpssettbankct></fpssettbankct><fpsspare1></fpsspare1><fpssettbankbc>"
                . "</fpssettbankbc><fpshandbankct></fpshandbankct><fpsspare2></fpsspare2><fpshandbankbc></fpshandbankbc><fpsaccnumflag>"
                . "</fpsaccnumflag><fpsagencytype></fpsagencytype><fpsspare3></fpsspare3><printbti></printbti><printmainsc></printmainsc>"
                . "<printmajlocname></printmajlocname><printminlocname></printminlocname><printbranchname></printbranchname><printsecentryind>"
                . "</printsecentryind><printsecbrname></printsecbrname><printfbrtit1></printfbrtit1><printfbrtit2></printfbrtit2><printfbrtit3>"
                . "</printfbrtit3><printaddr1></printaddr1><printaddr2></printaddr2><printaddr3></printaddr3><printaddr4></printaddr4>"
                . "<printtown></printtown><printcounty></printcounty><printpcode1></printpcode1><printpcode2></printpcode2><printtelarea>"
                . "</printtelarea><printtelno></printtelno><printtelarea2></printtelarea2><printtelno2></printtelno2></branchdets>";
        }elsif($format eq "xml" && ($size%2)!=0){
        	$responseString = "<?xml version=\"1.0\" encoding=\"UTF-8\"?><bankvalplus>" . $responseString . "<result>INVALID - Sortcode</result>"
        	. "<transposedsortcode></transposedsortcode><transposedaccount></transposedaccount><sortcode>"
	        . "</sortcode><bicbank></bicbank><bicbranch></bicbranch><subbranchsuffix></subbranchsuffix>"
	        . "<bankname></bankname><owningbank></owningbank><longbank1></longbank1><longbank2></longbank2>"
	        . "<ownbc></ownbc><ccode></ccode><supervisorybody></supervisorybody><deletedate></deletedate>"
	        . "<changedate></changedate><printindicator></printindicator><bacsstatus></bacsstatus><bacschangedate>"
	        . "</bacschangedate><bacsclosedate></bacsclosedate><bacsredirectfrom></bacsredirectfrom><bacsredtoscode>"
	        . "</bacsredtoscode><bacssettbank></bacssettbank><bacssettsec></bacssettsec><bacssettsubsec></bacssettsubsec>"
	        . "<bacshandbank></bacshandbank><bacshandst></bacshandst><bacsaccnumflg></bacsaccnumflg><bacsddiflg></bacsddiflg>"
	        . "<bacsdrdisallowed></bacsdrdisallowed><bacscrdisallowed></bacscrdisallowed><bacscudisallowed></bacscudisallowed>"
	        . "<bacsprdisallowed></bacsprdisallowed><bacsbsdisallowed></bacsbsdisallowed><bacsdvdisallowed></bacsdvdisallowed>"
	        . "<bacsaudisallowed></bacsaudisallowed><spare1></spare1><spare2></spare2><spare3></spare3><spare4></spare4>"
	        . "<chapsretind></chapsretind><chapssstatus></chapssstatus><chapsschangedate></chapsschangedate><chapssclosedate>"
	        . "</chapssclosedate><chapsssettmem></chapsssettmem><chapssrbicbank></chapssrbicbank><chapssrbicbr></chapssrbicbr>"
	        . "<chapsestatus></chapsestatus><chapsechangedate></chapsechangedate><chapseclosedate></chapseclosedate><chapserbicbank>"
	        . "</chapserbicbank><chapserbicbr></chapserbicbr><chapsesettmem></chapsesettmem><chapseretind></chapseretind><chapseswift>"
	        . "</chapseswift><spare5></spare5><ccccstatus></ccccstatus><ccccchangedate></ccccchangedate><ccccclosedate></ccccclosedate>"
	        . "<ccccsettbank></ccccsettbank><ccccdasc></ccccdasc><ccccretind></ccccretind><ccccgbni></ccccgbni><fpsstatus></fpsstatus>"
	        . "<fpschangedate></fpschangedate><fpsclosedate></fpsclosedate><fpsredirectfrom></fpsredirectfrom><fpsredirecttosc></fpsredirecttosc>"
	        . "<fpssettbankct></fpssettbankct><fpsspare1></fpsspare1><fpssettbankbc></fpssettbankbc><fpshandbankct></fpshandbankct>"
	        . "<fpsspare2></fpsspare2><fpshandbankbc></fpshandbankbc><fpsaccnumflag></fpsaccnumflag><fpsagencytype></fpsagencytype>"
	        . "<fpsspare3></fpsspare3><printbti></printbti><printmainsc></printmainsc><printmajlocname></printmajlocname><printminlocname>"
	        . "</printminlocname><printbranchname></printbranchname><printsecentryind></printsecentryind><printsecbrname>"
	        . "</printsecbrname><printfbrtit1></printfbrtit1><printfbrtit2></printfbrtit2><printfbrtit3></printfbrtit3><printaddr1>"
	        . "</printaddr1><printaddr2></printaddr2><printaddr3></printaddr3><printaddr4></printaddr4><printtown></printtown><printcounty>"
	        . "</printcounty><printpcode1></printpcode1><printpcode2></printpcode2><printtelarea></printtelarea><printtelno></printtelno>"
	        . "<printtelarea2></printtelarea2><printtelno2></printtelno2></bankvalplus>";
        }elsif($format eq "json" && ($size%2)== 0 ){
         	$responseString = "{\"result\":\"" . $responseString . "\",\"sortcode\":\"\",\"bicbank\":\"\",\"bicbranch\":\"\","
                . "\"subbranchsuffix\":\"\",\"bankname\":\"\",\"owningbank\":\"\",\"longbank1\":\"\",\"longbank2\":\"\",\"ownbc\":"
                . "\"\",\"ccode\":\"\",\"supervisorybody\":\"\",\"deletedate\":\"\",\"changedate\":\"\",\"printindicator\":\"\",\"bacsstatus\":"
                . "\"\",\"bacschangedate\":\"\",\"bacsclosedate\":\"\",\"bacsredirectfrom\":\"\",\"bacsredtoscode\":\"\",\"bacssettbank\":\"\",\""
                . "bacssettsec\":\"\",\"bacssettsubsec\":\"\",\"bacshandbank\":\"\",\"bacshandst\":\"\",\"bacsaccnumflag\":\"\",\"bacsddiflg\":\"\""
                . ",\"bacsdrdisallowed\":\"\",\"bacscrdisallowed\":\"\",\"bacscudisallowed\":\"\",\"bacsprdisallowed\""
                . ":\"\",\"bacsbsdisallowed\":\"\",\"bacsdvdisallowed\":\"\",\"bacsaudisallowed\":\"\",\"spare1\":\"\",\"spare2\":\"\""
                . ",\"spare3\":\"\",\"spare4\":\"\",\"chapsretind\":\"\",\"chapssstatus\":\"\",\"chapsschangedate\":\"\",\"chapssclosedate\""
                . ":\"\",\"chapsssettmem\":\"\",\"chapssrbicbank\":\"\",\"chapssrbicbr\":\"\",\"chapsestatus\":\"\",\"chapsechangedate\":\"\""
                . ",\"chapseclosedate\":\"\",\"chapserbicbank\":\"\",\"chapserbicbr\":\"\",\"chapsesettmem\":\"\",\"chapseretind\":\"\""
                . ",\"chapseswift\":\"\",\"spare5\":\"\",\"ccccstatus\":\"\",\"ccccchangedate\":\"\",\"ccccclosedate\":\"\",\"ccccsettbank\""
                . ":\"\",\"ccccdasc\":\"\",\"ccccretind\":\"\",\"ccccgbni\":\"\",\"fpsstatus\":\"\",\"fpschangedate\":\"\",\"fpsclosedate\""
                . ":\"\",\"fpsredirectfrom\":\"\",\"fpsredirecttosc\":\"\",\"fpssettbankct\":\"\",\"fpsspare1\":\"\",\"fpssettbankbc\""
                . ":\"\",\"fpshandbankct\":\"\",\"fpsspare2\":\"\",\"fpshandbankbc\":\"\",\"fpsaccnumflag\":\"\",\"fpsagencytype\":\"\",\""
                . "fpsspare3\":\"\",\"printbti\":\"\",\"printmainsc\":\"\",\"printmajlocname\":\"\",\"printminlocname\":\"\",\"printbranchname\""
                . ":\"\",\"printsecentryind\":\"\",\"printsecbrname\":\"\",\"printfbrtit1\":\"\",\"printfbrtit2\":\"\",\"printfbrtit3\":\"\",\""
                . "printaddr1\":\"\",\"printaddr2\":\"\",\"printaddr3\":\"\",\"printaddr4\":\"\",\"printtown\":\"\",\"printcounty\""
                . ":\"\",\"printpcode1\":\"\",\"printpcode2\":\"\",\"printtelarea\":\"\",\"printtelno\":\"\",\"printtelarea2\":\"\",\""
                . "printtelno2\":\"\"}";
        }elsif($format eq "json" && ($size%2) !=0 ){
                $responseString = "{\"result\":\"" . $responseString . "\",\"transposedsortcode\":\"\",\"transposedaccount\":\"\",\"sortcode\":\"\",\"bicbank\":\"\",\"bicbranch\":\"\",\"subbranchsuffix\":\"\",\""
	        . "bankname\":\"\",\"owningbank\":\"\",\"longbank1\":\"\",\"longbank2\":\"\",\"ownbc\":\"\",\"ccode\":\"\",\"supervisorybody\":\"\",\"deletedate\":\"\",\""
	        . "changedate\":\"\",\"printindicator\":\"\",\"bacsstatus\":\"\",\"bacschangedate\":\"\",\"bacsclosedate\":\"\",\"bacsredirectfrom\":\"\",\""
	        . "bacsredtoscode\":\"\",\"bacssettbank\":\"\",\"bacssettsec\":\"\",\"bacssettsubsec\":\"\",\"bacshandbank\":\"\",\"bacshandst\":\"\",\""
	        . "bacsaccnumflag\":\"\",\"bacsddiflg\":\"\",\"bacsdrdisallowed\":\"\",\"bacscrdisallowed\":\"\",\"bacscudisallowed\":\"\",\""
	        . "bacsprdisallowed\":\"\",\"bacsbsdisallowed\":\"\",\"bacsdvdisallowed\":\"\",\"bacsaudisallowed\":\"\",\"spare1\":\"\",\"spare2\":\"\",\""
	        . "spare3\":\"\",\"spare4\":\"\",\"chapsretind\":\"\",\"chapssstatus\":\"\",\"chapsschangedate\":\"\",\"chapssclosedate\":\"\",\""
	        . "chapsssettmem\":\"\",\"chapssrbicbank\":\"\",\"chapssrbicbr\":\"\",\"chapsestatus\":\"\",\"chapsechangedate\":\"\",\""
	        . "chapseclosedate\":\"\",\"chapserbicbank\":\"\",\"chapserbicbr\":\"\",\"chapsesettmem\":\"\",\"chapseretind\":\"\",\""
	        . "chapseswift\":\"\",\"spare5\":\"\",\"ccccstatus\":\"\",\"ccccchangedate\":\"\",\"ccccclosedate\":\"\",\"ccccsettbank\":\"\",\""
	        . "ccccdasc\":\"\",\"ccccretind\":\"\",\"ccccgbni\":\"\",\"fpsstatus\":\"\",\"fpschangedate\":\"\",\"fpsclosedate\":\"\",\""
	        . "fpsredirectfrom\":\"\",\"fpsredirecttosc\":\"\",\"fpssettbankct\":\"\",\"fpsspare1\":\"\",\"fpssettbankbc\":\"\",\""
	        . "fpshandbankct\":\"\",\"fpsspare2\":\"\",\"fpshandbankbc\":\"\",\"fpsaccnumflag\":\"\",\"fpsagencytype\":\"\",\"fpsspare3\":\"\",\""
	        . "printbti\":\"\",\"printmainsc\":\"\",\"printmajlocname\":\"\",\"printminlocname\":\"\",\"printbranchname\":\"\",\""
	        . "printsecentryind\":\"\",\"printsecbrname\":\"\",\"printfbrtit1\":\"\",\"printfbrtit2\":\"\",\"printfbrtit3\":\"\",\""
	        . "printaddr1\":\"\",\"printaddr2\":\"\",\"printaddr3\":\"\",\"printaddr4\":\"\",\"printtown\":\"\",\"printcounty\":\"\",\""
	        . "printpcode1\":\"\",\"printpcode2\":\"\",\"printtelarea\":\"\",\"printtelno\":\"\",\"printtelarea2\":\"\",\"printtelno2\":\"\"}";
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

1: Format 	- the response format (either xml, json or csv)

2: Sort code	- 6 digit number either 00-00-00, 00 00 00 or 000000

3: Account no.	- 6 to 12 digit (unseperated i.e. 00000000)

4: UserID	- available from www.unifiedsoftware.co.uk

5: PIN		- available from www.unifiedsoftware.co.uk

(UserID and PIN are available from http://www.unifiedsoftware.co.uk/freetrial/free-trial-home.html)

The order of the parameters B<must> be as above although supplying an account number is optional.
The UserID and PIN can also be stored in the LoginConfig.txt file bundled with this module, the
use of this file saves passing the PIN and user ID data with each call to bankValUK.
For example a call to validate a UK bank account passing the user ID and PIN as parameters
and printing the reply to console should follow this form:

=====================================================================

 #!/usr/bin/perl

 use Finance::BankVal::UK qw(&bankValUK);

 my $ans = bankValUK('XML','01-02-03','12345678','xmpl123','12345');

 print $ans;

=====================OR for Object Orientation=======================

 use Finance::BankVal::UK

 my $bvObj = Finance::BankVal::UK->new();
 my $ans = $bvObj->bankValUK('XML','01-02-03','12345678','xmpl123','12345');

 print $ans;

=====================================================================

valid parameter lists are:-

bankValUK('$format','$sortcode','$account no.','$userID','$PIN');

bankValUK('$format','$sortcode','$userID','$PIN');

bankValUK('$format','$sortcode','$account no.');

bankValUK('$format','$sortcode');

n.b. the last two parameter lists require that the user ID and PIN are stored
in the I<LoginConfig.txt> file bundled with this module.


=head2 EXPORT

None by default.
&bankValUK is exported on request i.e. "use Finance::BankVal::UK qw(&bankValUK);"

=head1 DEPENDENCIES

This module requires these other modules and libraries:

use LWP::UserAgent;
use XML::Simple;
use JSON;

Crypt::SSLeay is also required as it is a dependency of LWP::UserAgent.

Crypt::SSLeay is typically bundled with windows Perl ports, however on *nix you may need to install it by:

sudo aptitude install libssl-dev (might not be neccessary and can be removed after install)
sudo cpan -i Crypt::SSLeay


=head1 SEE ALSO

Please see L<http://www.unifiedsoftware.co.uk> for full details on Unified Software's web services.


=head1 AUTHOR

A. Evans - Unified Software, E<lt>support@unifiedsoftware.co.ukE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Unified Software Limited

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
