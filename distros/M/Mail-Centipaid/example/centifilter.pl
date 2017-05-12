#!/usr/bin/perl
#
# This filter is intended to be called by MTAs prior to mail delivery
# to determine if the message contains a valid email postage obtained 
# from centipaid.  If the message contains the stamp receipt and it is
# acknowledged by centipaid as being valid for the recpient account, then
# it is acceptedm, otherwise a custom reply is sent to the sender with
# instructions on how to pay for postage, and a properly formatted
# url. 
#
# This software is release under GPL license
#


# Mail::Audit::Centipaid returns an array of length equal to 2, where the first element 
# has the error code, and the second has the error message, or email message that has to
# be sent with rejected email to inform the sender to pay
#
# 0 = success a valid stamps receipt was found
# 1 = an invalid receipt is found
# 2 = problem connecting with centipaid payment
#
#
# Configure the filter
%conf = (
	'acct'   => "AEF001", 			# account_name merchant id 
	'amount' =>  0.005, 			# amount to charge per email
	'https'  => "http://pay.centipaid.com/",# payment url
 	'pass'   => "adonis",			# receipt_password
 	'lang'   => "en",			# language setting
	'authserver' => "pay001.centipaid.com", # centipaid_receipt_server
 	'authport' => '2021',			# port of receipt server
 	'email' => 'you@domain.com',		# email assigned to accept paid postage emails
	'debug' => 1 				# 1=show output, 0=supress output
	);

########### DO NOT CHANGE ANYTHING BELOW THIS LINE ############
############# UNLESS YOU KNOW WHAT YOU ARE DOING ##############

use Mail::Audit qw(KillDups);
use Mail::Audit qw(Centipaid);
my $mail = Mail::Audit->new;

my $subject = $mail->subject;			# get subject
my $to = $mail->to;    				# get to
$to =~ s/>//g;    $to =~ s/<//g;		# clean to from <>
my $from = $mail->from;				# get from


# check mail for epostage
($code,$reason)= $mail->check_mail(%conf);


$reply_msg = qq{
Dear Sender,

We are contacting you in regards to the following message:

To: $to
Subject: $subject  

This message has been rejected due to the lack of epostage payment. 
This email account requries that you pay a postage of $conf{amount}
to allow email to be delivered.

To make this payment, please click the link below and make payment.
When you complete your payment you will be given a two options to
to email us again.  

1) You can use the form presented to you on the site.
2) You can cut and paste the postage receipt into your email 
   message and resend it to us.

To pay click or cut and paste the following url:
$reason
};





# reject email without postage
if ( $code == 1 ) {

	$mail->reply(from=>$mail->from, subject=>"Email postage missing: could not deliver",body=>$reply_msg);
	$mail->ignore;
}

# accept the ones that do have one
if ( $code == 0 ) {$mail->accept; }

