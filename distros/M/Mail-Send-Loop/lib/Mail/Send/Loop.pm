package Mail::Send::Loop;

# h2xs -O -AX -n Mail::Send::Loop -v 0.1

use strict;
use warnings;

use IO::Socket;
use MIME::Lite;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Mail::Send::Loop ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.3';


# -----
my $EOF = "\x0d\x0a";
my $SMTP_DATA = "DATA" . $EOF;
my $SMTP_QUIT = "QUIT" . $EOF;

my $debug = 1;
my $recv_data;
my %gMediaTypes;
my $gCOUNT;

sub new {
	my ($unknown, %usr_parms)= @_;
	my $class = ref($unknown) ? ref($unknown) : $unknown;

	my %obj_parms ;
	while(my($k, $v) = each %usr_parms){
		$obj_parms{lc($k)} = $v;
	}

    my $self = {};

	$self->{mail_host}	= $obj_parms{mail_host};
	$self->{mail_port}	= $obj_parms{mail_port}	|| 25;
	$self->{greeting}   = $obj_parms{greeting}  || 'test.net';
	$self->{debug}		= $obj_parms{debug};
	$self->{senders}	= $obj_parms{senders};
	$self->{recipients}	= $obj_parms{recipients};
	$self->{mail_mode}	= $obj_parms{mail_mode} || '1tom';	# in 1 TCP session, how many emails sent
	$self->{mail_count} = $obj_parms{mail_count}|| '0';		# 0 run once, # > 0, only send # of emails, -1 endless loop

	if( defined $self->{debug}){
		$debug = 1;
	}else{
		undef $debug;
	}
	
	&readMediaTypes(\%gMediaTypes);
	
    bless $self, $class;
	$self;
}

sub setDebug(){
    my $self   = shift;
	my $status = shift;

	if( $status =~ /(off|0|disable)/i ){
		undef $debug;
	}else{
		$debug = 1;
	}
}

sub emailMode(){
    my $self = shift;
	my $mode = shift || '';

	if( $mode =~ /(1tom|1to1)/i ){
		$self->{mail_mode} = $mode;
	}
	return $self->{mail_mode};
}

sub sendMail_EML(){
    my $self = shift;
	my $emlf = shift;
	my $mailSender = shift;
	my $recepient  = shift;

	if( ! -e $emlf ){
		print "  Error: Cannot find $emlf\n";
		return 0;
	}

	open(INPUT, $emlf);
	my $content = do { local $/; <INPUT> };
	close INPUT;
	#$content =~ s/\x0a\./\x0a\.\./sg;			# . at beginning of the line need be 2

	my $mail_socket = &createMailSocket($self->{mail_host}, $self->{mail_port}, $self->{greeting});

	$gCOUNT++;
	&sendMail_OneTcpSession(\$mail_socket, $mailSender, $recepient, $content);
	
	&closeMailSocket(\$mail_socket);

	return 1;
}

sub sendMail_AllFilesInFolder(){
    my $self = shift;
	my %usr_parms = @_;

	my $mail_folder = $usr_parms{mail_folder};
	my $mail_mode   = $usr_parms{mail_mode}    || $self->{mail_mode};
	my $mail_subject= $usr_parms{mail_subject} || "send the file as attachment";
	my $mail_text_bd= $usr_parms{mail_txt_body}|| "this is a test email with MIME attachment";
	my $greeting    = $usr_parms{greeting}     || $self->{greeting};
	my $sender_list = $usr_parms{senders}      || $self->{senders};
	my $rpient_list = $usr_parms{recipients}   || $self->{recipients};
	my $mail_count  = $usr_parms{mail_count}   || $self->{mail_count};

	if(! $sender_list || ! $rpient_list){
		print "  Error: please define sender and recipient lists!\n";
		exit;
	}

	$gCOUNT =0;

	my $mail_host   = $self->{mail_host};
	my $mail_port   = $self->{mail_port};

	my @files = glob("$mail_folder/*.*");

	my $socketClosed;   # TRUE or FALSE

	# when 0, send all files only once
	$self->{mail_count} = $mail_count	if( $mail_count =~ /^\d+$/ );
	$self->{mail_count} = scalar @files	if( $mail_count == 0);

	my $mail_socket;
	$mail_socket = &createMailSocket($mail_host, $mail_port, $greeting) if($mail_mode =~ /1tom/i);

	while(1){
		my @mailSender = ( @{$sender_list} ) x (int(scalar @files / scalar @{$sender_list}) + 1 ) ;
		my @recepients = ( @{$rpient_list} ) x (int(scalar @files / scalar @{$rpient_list}) + 1 ) ;

		foreach(@files){
			my $org = $_;

			$gCOUNT++;

			$mail_socket = &createMailSocket($mail_host, $mail_port, $greeting) if($mail_mode =~ /1to1/i);

			if($org =~ /\.eml$/i){
				open(INPUT, $org) or die "Could not open file: org\n";
				my $content = do { local $/; <INPUT> };
				close INPUT;

				&sendMail_OneTcpSession(\$mail_socket, shift @mailSender, shift @recepients, $content);
				
			}else{
				my $mSender    = shift @mailSender;
				my $mRecepient = shift @recepients;

				### Create the multipart container
				my $msg = MIME::Lite->new (
					From    => $mSender,
					To      => $mRecepient,
					Subject => "$mail_subject: $mail_mode " . $gCOUNT,
					Type    =>'multipart/mixed'
				) or die "Error creating multipart container: $!\n";

				$org =~ /(.*)\.(.*)$/i;
				my $ext = lc($2);
				#print "$ext  $gMediaTypes{$ext} \n";

				### Add the text message part
				$msg->attach (
					Type => 'TEXT',
					Data => $mail_text_bd
				) or die "Error adding the text message part: $!\n";

				$msg->attach (
					Type 	 => $gMediaTypes{$ext},
					Path 	 => $org,
					Filename => $org,
					Disposition => 'attachment'
				) or die "Error adding $org: $!\n";

				&sendMail_OneTcpSession(\$mail_socket, $mSender, $mRecepient, $msg->as_string);
			}

			if($self->{mail_count} == $gCOUNT){
				&closeMailSocket(\$mail_socket);
				$socketClosed = 1;
				goto MAIL_CLOSE;
			}

			&closeMailSocket(\$mail_socket) if($mail_mode =~ /1to1/i);
		}
	}

	MAIL_CLOSE:
	&closeMailSocket(\$mail_socket) if($mail_mode =~ /1tom/i && $socketClosed != 1);

	$self->{mail_count} = 0;
	return $gCOUNT;
}

sub sendMail_LoopAllUsers(){
    my $self = shift;
	my %usr_parms = @_;

	my $mail_body   = $usr_parms{mail_body};
	my $mail_mode   = $usr_parms{mail_mode}    || $self->{mail_mode};
	my $greeting    = $usr_parms{greeting}     || $self->{greeting};
	my $sender_list = $usr_parms{senders}      || $self->{senders};
	my $rpient_list = $usr_parms{recipients}   || $self->{recipients};
	my $mail_count  = $usr_parms{mail_count}   || $self->{mail_count};

	my $mail_host   = $self->{mail_host};
	my $mail_port   = $self->{mail_port};

	if(! $sender_list || ! $rpient_list || ! $mail_body){
		print "  Error: please define sender, recipient lists and email body!\n";
		exit;
	}

	$gCOUNT =0;

	my $socketClosed;

	# when 0, send all files only once
	$self->{mail_count} = $mail_count if( $mail_count =~ /^\d+$/ );
	$self->{mail_count} = ( scalar @{$sender_list} ) * ( scalar @{$rpient_list} ) if( $mail_count == 0);

	my $mail_socket;
	$mail_socket = &createMailSocket($mail_host, $mail_port, $greeting) if($mail_mode =~ /1tom/i);

	while(1){

		foreach(@{$sender_list}){
			my $sender = $_;

			foreach(@{$rpient_list}){

				$mail_socket = &createMailSocket($mail_host, $mail_port, $greeting) if($mail_mode =~ /1to1/i);

				$gCOUNT++;
				&sendMail_OneTcpSession(\$mail_socket, $sender, $_, $mail_body);

				if($self->{mail_count} == $gCOUNT){
					&closeMailSocket(\$mail_socket);
					$socketClosed = 1;
					goto MAIL_CLOSE;
				}

				&closeMailSocket(\$mail_socket) if($mail_mode =~ /1to1/i);
			}
		}
	}

	MAIL_CLOSE:
	&closeMailSocket(\$mail_socket) if($mail_mode =~ /1tom/i && $socketClosed != 1);

	$self->{mail_count} = 0;
	return $gCOUNT;
}

sub sendMail_OneTcpSession(){
	my $SOCKET     = shift;
	my $mailf_addr = shift;
	my $rcptT_addr = shift;
	my $mail_body  = shift;

	my $mail_socket = ${$SOCKET};

	my $mail_from = "MAIL FROM: " . $mailf_addr . $EOF;
	my $rcpt_to   = "RCPT TO: "   . $rcptT_addr . $EOF;

	#MAIL FROM
	$mail_socket->send($mail_from);
	$mail_socket->recv($recv_data, 1024);
	if( $recv_data !~ /^250/){
		print "  Error: $mail_from->$recv_data";
		close $mail_socket;
	}
	&dbg_print("$mail_from->$recv_data");

	#RCPT TO
	$mail_socket->send($rcpt_to);
	$mail_socket->recv($recv_data, 1024);
	if( $recv_data !~ /^250/){
		print "  Error: $rcpt_to\t\t->$recv_data";
		close $mail_socket;
	}
	&dbg_print("$rcpt_to->$recv_data");

	#DATA
	$mail_socket->send($SMTP_DATA);
	$mail_socket->recv($recv_data, 1024);
	if( $recv_data !~ /^354/){
		print "  Error: $SMTP_DATA->$recv_data";
		close $mail_socket;
	}
	&dbg_print("$SMTP_DATA->$recv_data");

	$mail_socket->send( $mail_body . "$EOF\.$EOF");
	$mail_socket->recv($recv_data, 1024);
	if( $recv_data !~ /^250/){
		print "  Error: Mail Body->$recv_data";
		close $mail_socket;
	}
	&dbg_print("Mail Body->$recv_data " . ' email length: ' . length($mail_body) . "\t $gCOUNT sent");
}

sub createMailSocket(){
	my $mail_host = shift || "127.0.0.1";
	my $mail_port = shift || "25";
	my $greeting = shift || "test.net";

	my $smtp_EHLO = "HELO $greeting" . $EOF;

	my $mail_socket = new IO::Socket::INET (
		PeerAddr  => $mail_host,
		PeerPort  => $mail_port,
		Proto     => 'tcp',
		)                
	or die "Couldn't connect to Server\n";

	#Greeting
	$mail_socket->recv($recv_data, 1024);
	print "Greeting->$recv_data" if($debug);

	#EHLO
	$mail_socket->send($smtp_EHLO);
	$mail_socket->recv($recv_data, 1024);
	if( $recv_data !~ /^250/){
		print "  Error: $smtp_EHLO->$recv_data";
		close $mail_socket;
	}
	&dbg_print("$smtp_EHLO->$recv_data");
	return $mail_socket;
}

sub closeMailSocket(){
	my $SOCKET  = shift;
	my $mail_socket = ${$SOCKET};

	#QUIT
	$mail_socket->send( $SMTP_QUIT );
	$mail_socket->recv($recv_data, 1024);
	if( $recv_data !~ /^221/){
		print "  Error: QUIT->$recv_data";
		close $mail_socket;
	}
	&dbg_print("QUIT->$recv_data");
	print "\n";

	close $mail_socket;	
}

sub dbg_print(){
	my $str = shift;

	$str =~ s/\x0d//g;
	$str =~ s/\x0a//g;
	print "  INFO : $str\n" if($debug);
}

sub readMediaTypes(){
	my $mediaType = shift;		# reference to hash

	my $mediaFile;
	foreach(@INC){ 
		if(-e "$_/LWP/media.types") {
			$mediaFile = "$_/LWP/media.types"; 
			last;
		} 
	}

	open(MIME, $mediaFile);
	while(<MIME>){
		chomp $_;
		next if($_ =~ /^#/);

		my $line = $_;
		my @part = split /\s+/, $line;
		next if(scalar @part < 2);

		#print "$line\n";

		my $last = scalar @part - 1;
		foreach( @part[1..$last] ){
			${$mediaType}{lc($_)} = $part[0];
		}
	}
	close MIME;
	#print sort values %{$mediaType};
	
	${$mediaType}{xlsx} = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
	${$mediaType}{docx} = 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
	${$mediaType}{pptx} = 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
	${$mediaType}{db}   = 'application/binary';		# Thumbs.db
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Mail::Send::Loop - Perl extension for sending emails that attach each file in a specified folder and loop a set of users

=head1 SYNOPSIS

	use strict;
	use Mail::Send::Loop;

	my @sender = ('Acting@netdlp.com', 'Actors@netdlp.com', 'Administrator@netdlp.com');
	my @rpient = ('tiger@freedom.net', 'lion@freedom.net');

	my $mailer = Mail::Send::Loop->new(
		mail_host  => '127.0.0.1',
		mail_port  => 25,
		mail_mode  => '1tom',
		greeting   => 'www.com',
		senders    => \@sender,
		recipients => \@rpient,	
		mail_count => 8,
	);

	my $email_body = &getMIME(); 

	$mailer->setDebug(1);

	my $ret = $mailer->sendMail_LoopAllUsers(
		mail_body	=> $email_body,
		mail_mode	=> '1to1',
		mail_count	=> 3,
	);
	print "  $ret mails sent\n";

	$ret = $mailer->sendMail_AllFilesInFolder(
		mail_folder  => 'test_emails', 
		mail_mode    => '1to1',
		mail_subject => "blabla...",
		mail_txt_body=> "7777",
		greetings    => "ccc.com",
		mail_count   => 2,

	);

	print  $mailer->emailMode() . "\n";

	$mailer->sendMail_EML('test_emails/mail.eml', $sender[0], $rpient[0]);

	sub getMIME(){

	return 	qq(MIME-Version: 1.0
		Content-Transfer-Encoding: binary
		Content-Type: multipart/mixed; boundary="_----------=_128097394742080"
		X-Mailer: MIME::Lite 3.027 (F2.76; T1.30; A2.06; B3.08; Q3.08)
		Date: Wed, 4 Aug 2010 19:05:47 -0700
		From: jkang\@freedom.net
		To: bill\@freedom.net
		Subject: A message with 2 parts ...

		This is a multi-part message in MIME format.

		--_----------=_128097394742080
		Content-Disposition: inline
		Content-Transfer-Encoding: 8bit
		Content-Type: text/plain

		Here's the attachment file(s) you wanted
		--_----------=_128097394742080
		Content-Disposition: attachment; filename="head.gif"
		Content-Transfer-Encoding: base64
		Content-Type: image/gif; name="head.gif"

		R0lGODlhUABQAPcAABgICC9vcTw6MC+jtKlvVHg7KcGLayQiG4BXRLR2bGEj
		...
		--_----------=_128097394742080--
		);
	}

=head1 DESCRIPTION

The Module is designed to stress any MTA with different files, senders and recipients.

=head1 METHODS

=head2 new

	my $mailer = Mail::Send::Loop->new(option => 'value', ...);

Create an Email Client. Other functions can override some parameters.
	
Options:

=over 4

=item * debug

Print all SMTP conversation

=item * mail_host

MTA's IP

=item * mail_port

MTA's Port. The default port is 25 if not given.

=item * greeting

HELO greeting. The default domain is 'test.net' if not given.

=item * senders

Users set for 'MAIL FROM'. It takes an ARRAY reference.

=item * recipients

Users set for 'RCPT TO'. It takes an ARRAY reference.

=item * mail_mode

1tom:	One TCP connection to MTA is used to send MANY emails.

1to1:	One TCP connection to MTA is used to send ONE email.

=item * mail_count

Stop sending email after specified number of emails sent

-1:		Keep sending emails endlessly

=back

=head2 setDebug

	$mailer->setDebug(1);

1/0: Enable/Disable SMTP conversation information

=head2 emailMode

	 $mailer->emailMode()

Print current email Mode or Set it to 1to1/1tom.

=head2 sendMail_AllFilesInFolder
	
	$mailer->sendMail_AllFilesInFolder(option => 'value', ...);

Options:

=over 4

=item * mail_folder

All files in this specified folder will be sent one by one as an attachment. EML file is sent as-it. Other files will be 
MIME-encrypted first based on LWP/media.types, and then sent out. Each email has only One attachment.

=item * mail_mode

1tom:	One TCP connection to MTA is used to send MANY emails.

1to1:	One TCP connection to MTA is used to send ONE email.

=item * mail_subject

Static subject for each email

=item * mail_txt_body

Static email text body

=item * greeting

HELO greeting

=item * senders

Users set for 'MAIL FROM'. It takes an ARRAY reference.

=item * recipients

Users set for 'RCPT TO'. It takes an ARRAY reference.

=item * mail_count

Stop sending email after specified number of emails sent

=back

=head2 sendMail_LoopAllUsers
	
	$mailer->sendMail_LoopAllUsers(option => 'value', ...);
	
Send SAME email to all users.

Options:

=over 4

=item * mail_body

It takes text string that can be prepared MIME-encrypted email content.

=item * mail_mode

1tom:	One TCP connection to MTA is used to send MANY emails.

1to1:	One TCP connection to MTA is used to send ONE email.

=item * greeting

HELO greeting

=item * senders

Users set for 'MAIL FROM'. It takes an ARRAY reference.

=item * recipients

Users set for 'RCPT TO'. It takes an ARRAY reference.

=item * mail_count

Stop sending email after specified number of emails sent

=back

=head2 sendMail_EML
	
	$mailer->sendMail_EML($eml, $mailfrom, $mailto);
	
Send one specified EML email file

Options:

=over 4

=item * $eml

EML file's path

=item * $mailfrom

MAIL FROM email address

=item * $mailto

RCPT TO email address

=back

=head1 SEE ALSO

Please, see L<MIME::Lite>.

=head1 AUTHOR

Jing Kang E<lt>kxj@hotmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by jkang

This library is free software.

=cut
