use strict;
use Mail::Send::Loop;

my @sender = ('Acting@netdlp.com', 'Actors@netdlp.com', 'Administrator@netdlp.com', 'bachkethinaveen@netdlp.com', 'chein@netdlp.com', 'epotest@netdlp.com', 'matsldap@netdlp.com', 'nchand@netdlp.com', 'rasmalai@netdlp.com', 'stest@netdlp.com');
my @rpient = ('tiger@freedom.net', 'lion@freedom.net');

my $mail_host = $ARGV[0] || '127.0.0.1';
my $mail_port = "25";
my $domian = "ndlp.org";
	
my $mailer = Mail::Send::Loop->new(
	mail_host  => '127.0.0.1',
	mail_port  => 25,
	mail_mode  => '1to1',
	greeting   => 'www.com',
	senders    => \@sender,
	recipients => \@rpient,	
	debug      => 1,
	mail_count => -1,
);

print  $mailer->emailMode() . "\n";

my $ret = $mailer->sendMail_AllFilesInFolder(
	mail_folder  => 'test_emails', 
	mail_mode    => '1to1',
	mail_subject => "babbaaba",
	mail_txt_body=> "7777",
	greetings    => "ccc.com"
);

print "  $ret mails sent\n";