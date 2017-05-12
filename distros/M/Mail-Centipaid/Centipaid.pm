package Mail::Audit::Centipaid;
use Mail::Audit;
use vars q(@VERSION);
$VERSION = '1.0';
1;


# Mail::Audit::Centipaid
#
# Written by Adonis El Fakih (adonis /at/ aynacorp dot com) Copyright 2003
# based on Apache::Cetipaid v1.3
#
# This module allows mail users / administrators to charge for incoming
# mail using centipaid's internet stamps (centipix).  This modules was 
# inspired by the design of AMDPmail.com which proposes an alternate mail
# delivery cycle that does many new cool things including charging epostage
# as a mode of controlling spam
#
# centipaid offers a micropayment solution that allows users
# to pay using an internet stamp. For more information on the 
# micro-payment system please visit http://www.centipaid.com/
# 
#
# This module may be distributed under the GPL v2 or later.
#
#


package Mail::Audit;


use 5.005;

use IO::Socket;
use Net::hostent;




sub need_to_pay($$$$$) {
	my $https = shift(@_);
	my $payto = shift(@_);
	my $amount = shift(@_);
	my $lang = shift(@_);
	my $email = shift(@_);

	$msg = qq {$https?payto=$payto&amount=$amount&mode=mail&email=$email};
	return $msg;
}

sub check_mail {

my $self = shift;
die "bad %conf key/values !" if (@_ % 2);
my %conf = @_ ;
my $debug = $conf{debug};
my $payto = $conf{acct} || 0;
my $https = $conf{https} || 0;
my $server = $conf{authserver} || 0;
my $port = $conf{authport} || 0;
my $pass = $conf{pass} || 0;
my $amount = $conf{amount} || 0;
my $email = $conf{email} || $self->to;
my $prefix = "$$ Mail::Audit::Centipaid"; 
my $connect_to ="$server:$port";
my @header      = split("\n",$self->header);
my $item_body = $self->body;
my @body = @$item_body;
my $rcvcount      = 0;
my $rcpt = 0;

print $body;

# loop through the oconfiguration hash and print it  
# if it is requiered
foreach my $key (keys %conf) {
	print "DEBUG: $key = $conf{$key}\n" if $debug;
}
 

# loop through the header first to see if it has a
# compliant AMDP mail header AMDP-PAYMENT-RCPT 
print "DEBUG: Checking SMTP header\n" if $debug;
for (@header) {

	if ( /AMDP-PAYMENT-RCPT:(.*)/ ) {
		$rcpt = $1;
		#clean rcpt from any spaces..
		$rcpt =~ s/\s+//g;
		last;
	}

	print  "HEADER: $_\n" if $debug;
	$rcvcount++;  # Any further Received lines won't be the first.
}


#if no receipt in header then check the body
unless($rcpt) {
	# loop through the body next to see if it has a
	# compliant AMDP mail receipt AMDP-PAYMENT-RCPT 
	print "DEBUG: Checking mail BODY\n" if $debug;
	for (@body) {
	chomp;

	if ( /AMDP-PAYMENT-RCPT:\s*(\S+)\s*[!^<]/ || /AMDP-PAYMENT-RCPT:\s*(\S+)/) {
                $rcpt = $1;
                #clean rcpt from any spaces..
                $rcpt =~ s/\s+//g;
                last;
        }


	print  "BODY: $_\n" if $debug;
	$rcvcount++;  # Any further Received lines won't be the first.
	}
}

if ( $rcpt ) {

	print "DEBUG: Found AMDP receipt $rcpt\n" if $debug;
	print "DEBUG: Checking with CENTIPAID at $connect_to\n" if $debug;
	
	my $auth_server = IO::Socket::INET->new("$connect_to");
   	my $crlf = "\015\012";
   	unless ( $auth_server ) { 
		print "DEBUG: Could not connect to $connect_to\n" if $debug;
		return (1,"Can not connect to $connect_to"); 
	}
   
	$auth_server->autoflush(1);
   	print $auth_server "PAYTO:$payto"."$crlf";
   	print $auth_server "PASS:$pass"."$crlf";
   	print $auth_server "RCPT:$rcpt"."$crlf";

	# format the amount in a way that we make sure it becomes a float
	$amount = sprintf("%.6f",$amount);
	while (<$auth_server>) {
		chomp;
		my $received = $_;

		
		print "DEBUG: CLIENT:$received\n" if $debug;
		
		if ($received =~ /^250 OK PAID(.+)/) {
			# format the paid in a way that we make sure it becomes a float
			my $paid = sprintf("%.6f",$1);
			print "DEBUG: Paid [$paid] Amount [$amount]\n" if $debug;
			
			# if the amount paid is greater or equal to what 
			# is requiered then it is ok
			if ( $paid >= $amount ) { 
				print "DEBUG: $paid  == $amount\n" if $debug;
				print "DEBUG: epostage verified\n" if $debug;

				return (0,"OK"); # success

			}# if paid == amount
			
		}#end if 250
		
		
		if ($received =~ /^500/) {
			# if we get a 500 code then it was an invalid receipt
			print "DEBUG: Invalid transaction for receipt $rcpt\n" if $debug;

			#send a payment slip
			$msg = need_to_pay($https,$payto,$amount,$lang,$email);
			print "DEBUG: need_to_pay called\n" if $debug;
			return (1,$msg); 

		}#end if 500
		
		
   	}# end while	

} else {

	$msg = need_to_pay($https,$payto,$amount,$lang,$email);
	return (1,$msg);

} #end of rcpt found
	
} 

1;

__END__

=head1 NAME

$Revision: 1.0 $

B<Mail::Audit::Centipaid> - Mail::Audit plugin to check for email postage


=head1 SYNOPSIS


use Mail::Audit qw(Centipaid);
my $mail = Mail::Audit->new;

# Configure the filter

%conf = (
        'acct'   => "AEF001",                   # account_name merchant id 
        'amount' =>  0.005,                     # amount to charge per email
        'https'  => "http://pay.centipaid.com/",# payment url
        'pass'   => "adonis",                   # receipt_password
        'lang'   => "en",                       # language setting
        'authserver' => "pay001.centipaid.com", # centipaid_receipt_server
        'authport' => '2021',                   # port of receipt server
        'email' => 'you@domain.com',            # email
        'debug' => 0                            # 1=show output, 0=supress output
        );


        # check mail for epostage
        ($code,$reason)= $mail->check_mail(%conf);

        $reply_msg = qq{Your message here..};

        # reject email without postage
        if ( $code == 1 ) {
                $mail->reply(from=>$mail->from, 
                             subject=>"Email postage missing: could not deliver",
                             body=>$reply_msg);
                $mail->ignore;
        }

        # accept the ones that do have one
        if ( $code == 0 ) {$mail->accept; }




=head1 DESCRIPTION

B<Mail::Audit::Centipaid> is an email filter that is used to detect
the precence of electronic postage. Once detected, the postage is 
checked against the receipt server of Centipaid.com to insure that the
the proper payment has been made.  

Centipaid.com can process electronic postage as low as $0.001.  
The idea of this filter came about as another method to control the growing
problem of SPAM, which was proposed by the Adaptive Mail Delivery 
Protocol (AMDP). Please refer to amdpmail.com for more info.

Mail::Audit::Centipaid can be used by individuals or companies to designate 
one or more email accounts SPAM free.  This is done by installing a .forward
for these accounts, and use the enclosed centifilter.pl program to filter out
mail that does not contain valid postage.  Only paid email will be allowed
through the filter.

Centipaid supports two types of stamps.

1. CENTIPIX stamps, which are bought by the sender and used to make payments.
   Payment processing is deducted from the payment done by the sender.

2. EZPASS stamps, which are issued by the receiver and given to individuals
   he/she wants to grant them postage-free access the email account.
  Payment processing is paid by the recepient.
           
The module can also be used in conjunction with SpamAssassin to autoamtically
reject email messages with a certain spam ranking, and to be directed to pay 
for postage. 

Other uses include the designation of postage-requiered email accounts such 
as the ones used for consulting, support, business to business, etc..

B<Postage paying>
Paying for postage is easy, once the sender has obtained a CENTPIX from 
www.centipix.com.  The sender can re-use the same CENTIPIX in payments
for postage, online access, shopping online, etc.. until its funds are
completely used up.

B<Including postage in emails>
The postage can be included in the BODY or HEADER of the email message.

Mail::Audit::Centipaid generate a valid payment url for postage payment.
When used, centipaid will give the payee the option to include the 
postage receipt in the body of the email by copying and pasting the
text into the body of the email message, or using the online email
interface, which includes the postage receipt in the header of the
message. Both are supported by this module.


B<How does it work?>
Email messages are parsed for AMDP-PAYMENT-RCPT string which specifies
that the message contains an AMDP style electronic postage. Once it is
detected the receipt number is extracted, and centipaid receipt server
is contacted to get a verification that a payment has been made for the
postage rate set in the configuration.

Ideally the AMDP-PAYMENT-RCPT should reside in the header, however since
AMDP protocol is new, and email applications do not support its inclusion
in the header area of a message, the BODY of the message is searched for
the string. Please refer to amdpmail.com for information about the protocol.

If the receipt is found, and it is a valid one, check_mail() returns an
Ok code, but if the rcpt is not found, it returns an error code, and a
well formed url that is used to send to the sender to ask them to pay 
for the postage.

Please refer to centipaid.com for the most updated version of this 
module, since other methods of payment may be available.


=head1 METHODS

=over 4

=item C<check_mail(%conf)>

Checks the mail header and body for the presence of electronic postage
(AMDP-PAYMENT-RCPT).

Returns an array containing two elements. The first array element contains 
one of the following codes 0 = success, 1 = no/bad receipt, 2 = problem contacting
Centipaid receipt server.  The second array element is primarily used with
error code 1, which contains the properly formated payment url.

if the error code is 0, then the message should be accepted, other wise it should
be rejected, or dropped.



=head1 CONFIGURATION

=over

=item B<acct> account_name

 The account number is issued by ceentipaid.com 
 for a given domain name.  This number is unique 
 and it determines who gets paid.
 
=item B<pass> receipt_password

 The password is used only in socket authetication.  
 It does not grant the owner any special access 
 except to be able to query the receipt server for 
 a given receipt number.

=item B<amount> 0.5

 The amount is a real number (float, non-integer) 
 that specifies how much the user must pay to be 
 granted access to the site.  For example amount 
 0.5 will ask the user to pay 50 cents to access the
 site.  The value of amount is in dollar currency.
 
=item B<lang> en

 This defines the language of the payment page 
 displayed to the user. It is set by the site admin 
 using the two letter ISO 639 code for the language. 
 For example ayna.com requieres the payment info to
 be displayed in arabic on centipaid,  CNN.com will 
 need several sections of its site to show payment 
 requests in different languages. Some of the ISO
 639 language codes are: English (en), Arabic (ar), 
 japanese (ja), Spanish (es), etc..


=item B<email> foo@bar.com

 This defines the email to be used when emailling
 back with the proper postage. default to the 
 $mail->to


=item B<https> https://pay.centipaid.com

 This should contain the payment url assigned to the
 account number. This defaults to 
 http://pay.centipaid.com


=item B<authserver> centipaid_receipt_server

 This should contain the receipt server assigned to 
 the account number above
 
=item B<authport> 2021

 This should contain the port number of receipt 
 server assigned to the account number above
    


=back

=head1 REFERENCE

=item Centipaid: http://www.centipaid.com
  Micropayment solution used in collecting and clearing epostage

=item CentiPIX:  http://www.centipix.com
  Centipaid Portable payment media which is used to make payments
  instead of using a credit card.  This gives allows the payment of
  postage as low as $0.001 
  
=item AMDPMAIL: http://www.amdpmail.com
  Proposed protocol used to control the wide spread of SPAM.  One
  of its features is the adoption of postage as a method of controlling
  spam.


=head1 ACKNOWLEDGEMENTS 

Thanks to Simon Cozens for the Mail::Audit module, which allowed me to develope
a consitent and easy to use Centipaid mail plugin.

=head1 AUTHOR

Adonis El Fakih, <aelfakih@cpan.org>

=head1 SEE ALSO

L<Mail::Audit>

=cut
