use strict;
use Mail::Send::Loop;

my @sender = ('Acting@netdlp.com', 'Actors@netdlp.com', 'Administrator@netdlp.com');
my @rpient = ('tiger@freedom.net', 'lion@freedom.net');

my $mail_host = $ARGV[0] || '127.0.0.1';
my $mail_port = "25";
	
my $mailer = Mail::Send::Loop->new(
	mail_host  => '127.0.0.1',
	mail_port  => 25,
	mail_mode  => '1tom',
	greeting   => 'www.com',
	senders    => \@sender,
	recipients => \@rpient,	
	mail_count => 8,
);


$mailer->sendMail_EML('test_emails/mail.eml', $sender[0], $rpient[0]);

$mailer->sendMail_EML('test_emails/mail.eml', $sender[1], $rpient[1]);
