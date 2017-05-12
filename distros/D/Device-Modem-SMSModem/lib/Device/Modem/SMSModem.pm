package Device::Modem::SMSModem;

use 5.008001;
use strict;
use warnings;

use strict;
use warnings;

use Carp;
use Device::Modem;

our $VERSION = '0.9';
our @ISA = ("Device::Modem");

=head1 NAME

Device::Modem::SMSModem - Perl extension for Device::Modem module

=head1 WARNING

This software has a BETA status. It has been carefully tested with Huawei E173 and Huawei E398 (E3276), but since AT commands
may be imlemented differently, 100% compliance with all dongles is not guaranteed. See SUPPORT section for details


=head1 SYNOPSIS

 use Device::Modem::SMSModem;

 my $modem = new Device::Modem::SMSModem(
     port     => '/dev/ttyUSB0',
     log      => 'file,smstest.log',
     loglevel => 'info');
  
 if ($modem->connect(baudrate => 38400)) {
     print "Modem connected\n";
 }
 else {
     die "Couldn't connect $!, stopped\n";
 }

 # get operator MCC+MNC
 my $op= $modem->get_operator_info();
 print "Operator name: ".$op->{"long_name"}." MCC ".$op->{"mcc"}." MNC:".$op->{"mnc"}."\n";
 # LAC+BTS ID
 my $loc= $modem->get_lac_dec();
 print "LAC: ".$loc->{"lac"}." CELL ID ".$loc->{"cell_id"}."\n";
 
 print "IMSI: ".$modem->get_imsi()."\n";

 # SMSC addr 
 print "SMSC address: ".$modem->get_smsc_address()."\n";

 print "Setting up SM storage...\n";
 $modem->init_sms_storage("SM");

 print "Cleaning up storage...\n";
 $modem->clean_sms_storage();

 print "Getting number of messages...\n";

 print "Number of messages in the storage: ".$modem->read_sms_count()."\n";

 print "Looking for new messages...\n";

 while(1)
 {
 	
	my $n= $modem->new_sms_count();
	if($n)
	{
		print "Got $n new messages...\n";
		my $last= $modem->sms_count()-1; 
		my $sms= $modem->read_sms($last);
		print $sms->{"status"}." ".$sms->{"from"}." ".$sms->{"date_time"}." ".$sms->{"smsc"}." ".$sms->{"text"}."\n";
		$modem->delete_sms($last);
	}
	else
	{
		print "No new messages...\n";		
	}       	
	sleep(10);
 }

=head1 DESCRIPTION

This is an extension of Device::Modem intended to be be used as high level 
API to handle SMS in USB dongles. It works (as base class Device::Modem) via serial port and 
implements basic SMS functionality handling through AT (Hayes) commands.

=head2 What the module can do

=over 4

=item *

Get network and registration details

=item *

Get serving SMSC address

=item *

Get IMSI

=item *

Send SMS

=item *

Receive SMS

=item *

Handle SMS storage change

=back


=head2 What it can be used for

=over 4

=item *

Simple SMS gateways to send/receive SMS

=item *

SMS notification features

=item *

Just a convenient way to get actual network environment

=back

=head2 Limitations

=over 4

=item *

At the moment it works through SMS read (AT+CMGR) commands but not through SMS list (AT+CMGL), since I discovered that
CMGL does not work on my dongle properly. This is not very ideal from SMS handling convenience point of view.
As soon as I get device with AT+CMGL working it will be  implemented as well

=item *

Some SMS related commands (like setting SMSC address) has not been implemented. If these commands are really 
required please drop me a line to contacts below

=back

=head1 METHODS

=head2 init_sms_storage

=over 4

This method sets sms memory being used. If you rae going to use(receive) SMS the method MUST be called prior of usage 
Possible values:

=over 4

=item *

SM. It refers to the message storage area on the SIM card.

=item *

ME. It refers to the message storage area on the GSM/GPRS modem or mobile phone. Usually its storage space is larger than that of the message storage area on the SIM card.

=item *

MT. It refers to all message storage areas associated with the GSM/GPRS modem or mobile phone. For example, suppose a mobile phone can access two message storage areas: "SM" and "ME". The "MT" message storage area refers to the "SM" message storage area and the "ME" message storage area combined together.

=item *

BM. It refers to the broadcast message storage area. It is used to store cell broadcast messages.

=item *

SR. It refers to the status report message storage area. It is used to store status reports.

=item *

TA. It refers to the terminal adaptor message storage area.

=back

SM or ME are recommended. The same value is used for all type of messages

Example:

 $gsm->init_sms_storage("SM"); 

=back

=cut

sub init_sms_storage {
   	my ($self, $name) = @_;


	my $command="AT+CPMS= \"".$name."\", \"".$name."\", \"".$name."\"".Device::Modem::CR;;

        $self->_at_send($command);

	my ($result, @lines) = $self->parse_answer(qr/OK|ERROR/, 3000);
	if ($result ne "OK") 
	{
		carp('Failed to change storage. Making a query to current storage');
		
		# lets' try another way- query current storage
		$self->{"storage_name"}= undef;
		# Sometimes modem does not allow to change storage
		$self->read_sms_count();
	}
	else  # successful
	{
		if($lines[0] =~ /CPMS\:\s*(\d+)\,\s*(\d+)/)
		{
			$self->{"capacity"}= $2;
			$self->{"sms_in_storage"}= $1;

		}                             
		else
		{
			carp("Unable to parse CPMS output");  
		}
		$self->{"storage_name"}= $name;
	}
	

	# sets the SMS format to TEXT instead of default PDU
	my $atcmd = "AT+CMGF=1" . Device::Modem::CR;
	$self->_at_send($atcmd);
	($result, @lines) = $self->parse_answer;

	if ($result ne 'OK') {
		carp('Failed to set SMS format to text');
		return undef;
	}

	# sets sms detlais output to extended mode
	$atcmd = "AT+CSDH=1" . Device::Modem::CR;
	$self->_at_send($atcmd);
	($result, @lines) = $self->parse_answer;

	if ($result ne 'OK') {
		carp('Failed to set SMS format to text');
		return undef;
	}
	


}


=head2 get_imsi

=over 4

This method returns IMSI 

Example:

my $imsi= $modem->get_imsi();

=back

=cut

sub get_imsi {
	my ($self) = @_;	
	#get  imsi
	if(! $self->_at_send("AT+CIMI".Device::Modem::CR))
	{
		carp("Failed to send CIMI command $!");
		return undef;
	}

	my $reply= $self->answer("OK", 1000);  # expect smth like 123456778855434
	if($reply =~ /(\d+)/)
	{
		return $1;
	}
	else
	{
		carp("Could not match CIMI reply");
		return undef;
	}

}

=head2 get_smsc_address

=over 4

This method returns Serving SMSC address 

Example:

my $imsi= $modem->get_smsc_address();

=back

=cut

sub get_smsc_address {
	my ($self) = @_;	

	# SMSC addr 
	if(! $self->_at_send("AT+CSCA?".Device::Modem::CR))
	{
		carp("Failed to send CSCA command $!");
		return undef;
	}

	my $reply= $self->answer("CSCA\:", 5000);  # expect smth like +CSCA: "+79202909090",145
	if($reply =~ /CSCA\:.\s*\"\+?(\d+)\"\,/)
	{
		return $1;
	}
	else
	{
		carp("Could not match CSCA reply");
		return undef;
	}

}

=head2 get_operator_info

=over 4

This method returns Serving Operator and registration status. Works only for registered dongle, returns undef otherwise. 

Example:

my $loc= $modem->get_operator_info();
print $loc->{"mcc"};
print $loc->{"mnc"};
print $loc->{"short_name"};
print $loc->{"long_name"};
print $loc->{"reg_status"}; # opStatus. works only for registered operators, always return 2 

=back

=cut

sub get_operator_info {
	my ($self) = @_;	
        my %data= (
	);


	# get operator MCC+MNC
	if(! $self->_at_send("AT+COPS=?".Device::Modem::CR))
	{
		carp("Failed to send COPS command $!");
		return undef;
	}

	my $reply= $self->answer("COPS\:", 20000);  # expect smth like +COPS: 0,2,"25002",2   OR +COPS: 0,0,"MegaFon",0
	# or +COPS: (2,"MegaFon RUS","MegaFon","25002",0),(3,"MTS-RUS","MTS","25001",0),(3,")
	if($reply =~ /COPS\:.\s*\(2\,\s*\"(.*?)\"\,\s*\"(.*?)\"\,\s*\"(\d+)\"/)

	{
		$data{"long_name"}= $1;
		$data{"short_name"}= $2;
		$data{"reg_status"}= 2;
		$data{"mcc"}= substr($3, 0, 3);
		$data{"mnc"}= substr($3, 3, 2);
		return \%data;
	}
	else
	{
		carp("Could not match COPS reply");
		return undef;
	}

}


=head2 sms_send

=over 4

This method sends SMS to the specified phone number.  The SMS is sent in text mode (not PDU).
Phone number is likely to be i the format your network is able to accept.


Example:

 $gsm->send_sms("+33123456", "Message to send as an SMS");

=back

=cut

sub send_sms {
	my ($self, $number, $sms) = @_;
	

	my $atcmd = "AT+CMGS=\"".$number."\"".Device::Modem::CR;
	$self->_at_send($atcmd);
	my $result = $self->answer; # to collect the > sign
	$atcmd = $sms . chr(26); # ^Z terminated string
	$self->_at_send($atcmd);
	my @lines;
	($result, @lines) = $self->parse_answer(qr/OK|ERROR/, 10000);
	if ($result ne "OK") {
		carp('Unable to send SMS');
		return undef;
	}
	return 1;
}



=head2 clean_sms_storage

=over 4

This method removes all SMS in the storage

Example:

 $gsm->clean_sms_storage(); 

=back

=cut

sub clean_sms_storage {
	my ($self) = @_;

	$self->delete_sms(0, 4);
	 
}



=head2 delete_sms

=over 4

This method delete sms rom choosen storage.
By default, removes a message from given index.
Optionally it accepts a flag what says what to remove:

=over 4

=item *

0. Meaning: Delete only the SMS message stored at the location index from the message storage area. This is the default value.

=item *

1. Meaning: Ignore the value of index and delete all SMS messages whose status is "received read" from the message storage area.

=item *

2. Meaning: Ignore the value of index and delete all SMS messages whose status is "received read" or "stored sent" from the message storage area.

=item *

3. Meaning: Ignore the value of index and delete all SMS messages whose status is "received read", "stored unsent" or "stored sent" from the message storage area.

=item *

4. Meaning: Ignore the value of index and delete all SMS messages from the message storage area.

=back

Returns: 1 if success, 0 otherwise

Example:

 $gsm->delete_sms(0); #delete SMS at index 0
 $gsm->delete_sms(0, 1); # delete all READ SMS

=back

=cut

sub delete_sms {
	my ($self, $index, $flag) = @_;
	my $command="AT+CMGD=".$index.Device::Modem::CR;;
	if(defined($flag))
	{
		$command = "AT+CMGD=".$index.", ".$flag.Device::Modem::CR;
	}
        $self->_at_send($command);
	my ($result, @lines) = $self->parse_answer(qr/OK|ERROR/, 2000);;

	if ($result ne 'OK') {
		carp('Failed to delete SMS');
		return 0;
	}
	
	$self->read_sms_count();
	return 1;


}

=head2 read_sms_count

=over 4

This method re-reads number of SMS available in pre-defined storage
Returns: number of SMS, -1 in case of errors

Example:

 print $gsm->read_sms_count();

=back

=cut

sub read_sms_count {
	my ($self) = @_;
	my $storage_name= $self->{"storage_name"};
	my $command="AT+CPMS?".Device::Modem::CR;
        $self->_at_send($command);

	my $result= $self->answer("CPMS", 3000);

	if (! ($result =~ /OK/)) {
		carp('Failed to get storage status');
		return -1;
	}

	if(defined $self->{"storage_name"})
	{
		if ($result =~ /CPMS:\s*\"?$storage_name\"?\,(\d+)/) 
		{
			$self->{"sms_in_storage"}= $1;
			return $1;	
		}
		else
		{
			carp("Failed to parse CPMS");
			return -1;
		
		}
	}
	else
	{
		if ($result =~ /CPMS:\s*\"?([A-Z]+)\"?\,(\d+)/) 
		{
			$self->{"sms_in_storage"}= $2;
			$self->{"storage_name"}= $1;
			return $2;	
		}
		else
		{
			carp("Failed to parse CPMS");
			return -1;
		
		}
		
	}
 
}


=head2 sms_count

=over 4

This method returns number of SMS available in pre-defined storage read during last read_sms_count() call. 
Note- this method does not re-read actual sms count in the storage
Returns: number of SMS, -1 in case of errors

Example:

 print $gsm->sms_count();

=back

=cut

sub sms_count {
	my ($self) = @_;
	return $self->{"sms_in_storage"};
}

=head2 capacity

=over 4

This method returns capacity of message storage being used
Returns: capacity of the storagenumber of SMS, undef is storage has not been initialized

Example:

 print $gsm->capacity();

=back

=cut

sub capacity {
	my ($self) = @_;
	return $self->{"capacity"};
}

=head2 read_sms

=over 4

This method reads sms for given index. Since CMGR is used to read SMS, the method has a side effect that  
after its call the SMS has a READ status. 
Returns: SMS structure, undef if unable to read or index is not valid

Example:

 my $last= $modem->sms_count()-1; 
 my $sms= $modem->read_sms($last);
 print $sms->{"status"}." ".$sms->{"from"}." ".$sms->{"date_time"}." ".$sms->{"smsc"}." ".$sms->{"text"}."\n";

=back

=cut

sub read_sms {
	my ($self, $index) = @_;
	if($index > $self->read_sms_count())
	{
		carp("Index is out of bound");
		return 0;
	}

	my $command="AT+CMGR=$index".Device::Modem::CR;
        $self->_at_send($command);
	my ($result, @lines) = $self->parse_answer(qr/OK|ERROR/, 10000);;

 	#my $result= $self->answer(qr/OK|ERROR/, 5000);

	if ($result ne "OK") 
	{
		carp('Failed to read SMS');
		return undef;
	}

	my %sms= ();

	# expect smth like 
        # +CMGR: "REC READ","+791089111111",,"15/09/02,09:19:10+12",145,4,0,0,"+79101399997
	# Testttt
	# OK                      status         from              date                                             smsc
	if((scalar @lines) != 2)
	{
		carp("Unexpected CMGR output");
		return undef;
	}
	if($lines[0] =~ /CMGR\:\s*\"?([A-Z ]+)\"?\,\s*\"(\+?\d+)\"\,.*?\,\s*\"(.+?)\"\,\s*\d+\,\s*\d+\,\s*\d+\,\s*\d+\,\s*\"?(\+?\d+)\"?/)
	{
		$sms{"status"}= $1;
		$sms{"from"}= $2;
		$sms{"date_time"}= $3;
		$sms{"smsc"}= $4;
		$sms{"text"}=$lines[1];

	}                             
	else
	{
		carp("Unable to parse CPMS output"); 
		return undef; 
	}


	return \%sms;	
	

}


=head2 list_sms

=over 4

This method lists SMS for given status. Possible status values:

=over 4

=item *

"REC UNREAD"   	unread

=item *

"REC READ"   	read

=item *

"STO UNSENT"   	unsent

=item *

"STO SENT"   	sent

=item *

"ALL"   	all (default)

=back

Returns: Array of SMS strucures (the same as for read_sms, except SMSC address), empty array if no SMS for given 
status found or unable to execute SMGL AT command

Example:

 my @list= $modem->list_sms();
 print "Found ".($#list+1). " messages:\n";
 foreach my $sms (@list)
 {
	print $sms->{"status"}." ".$sms->{"from"}." ".$sms->{"date_time"}." ".$sms->{"text"}."\n"\;
 }

=back

=cut

sub list_sms {
	my ($self, $status) = @_;
	if(! defined ($status))
	{
		$status= "ALL";
	}

	my $command="AT+CMGL=\"$status\"".Device::Modem::CR;
        $self->_at_send($command);
	my ($result, @lines) = $self->parse_answer(qr/OK|ERROR/, 10000);;

	my @list= ();

	if ($result ne "OK") 
	{
		carp('Failed to list SMS');
		return @list;
	}

	my $list_size= scalar @lines;
	if($list_size == 0)
	{
		return @list;
	}

#+CMGL: 0,"REC READ","+79108922481",,"15/09/10,09:56:02+12",145,4                       
#Test                                                                                   
#+CMGL: 1,"REC READ","111",,"15/09/13,12:06:05+12",129,134                              
#041D04300020043D043E043C043504400435002000370039003800360037003600390034003700340039002004430441043B04430B
#+CMGL: 2,"REC READ","111",,"15/09/13,12:06:06+12",129,80                               
#0020043E0442043A043B044E04470435043D0430002E00200421043F0430044104380431043E002C002004470442043E002004120E
#+CMGL: 3,"REC READ","+34611211740",,"15/10/09,18:56:58+08",145,6                       
#Lebara 
	for(my $i=0; $i<$list_size; $i++)
	{
		my %sms= ();
		if($lines[$i] =~ /CMGL\:\s*\d+\,\s*\"?([A-Z ]+)\"?\,\s*\"(\+?\d+)\"\,.*?\,\s*\"(.+?)\"\,/)
		{
		$sms{"status"}= $1;
		$sms{"from"}= $2;
		$sms{"date_time"}= $3;
		$sms{"smsc"}= "";

		}                             
		else
		{
			carp("Unable to parse CMGL output"); 
			$i++; 
			next;
		}
	
		$i++;
		if($i==$list_size)
		{
			carp "Unexpected even number of lines in CMGL output found... skipping...";
			next;	

		}

		$sms{"text"}=$lines[$i];
		push @list, \%sms;
	
	}
	

	return @list;

}


=head2 new_sms_count

=over 4

This method returns number of new SMS available in pre-defined storage. 
In fact it returns number of SMS appeared since last query
Returns: number of SMS, -1 in case of errors

Example:

 print $gsm->new_sms_count();

=back

=cut

sub new_sms_count {
        my ($self) = @_;
	my $old= $self->{"sms_in_storage"}; 
        my $total= $self->read_sms_count();
	if(($total > 0) && ($total >$old ))
	{
		my $new_count= $total- $old;
		return $new_count;	
	}
	return 0;
}



=head2 get_lac_hex

=over 4

This method returns vireless location info- ie LAC and CELL ID. The identifiers are returned as a reference to hash.
The values are in hex format. 

Example:

my $loc= $modem->get_lac_hex();
print $loc->{"lac"};
print $loc->{"cell_id"};

=back

=cut

sub get_lac_hex {
	my ($self) = @_;
	my %data= (
	"lac"=>5245,
	"cell_id"=>20012
	);


	# LAC+BTS ID
	# force reportin first
	if(! $self->_at_send("AT+CREG=2".Device::Modem::CR))
	{
		carp("Failed to send CREG command $!");
		return undef;
	}
	my ($reply, @lines) = $self->answer("OK", 1000);

	if ($reply ne 'OK') {
		carp('Failed to set CREG to report location');
		return undef;
	}

	if(! $self->_at_send("AT+CREG?".Device::Modem::CR))
	{
		carp("Failed to send CREG command $!");
		return undef;
	}

	$reply= $self->answer("CREG", 1000);  # expect smth like +CREG: 2,1, 147D, B3BA  
	# +CREG: 2,1,"147D","599E"^M^MOK
	if($reply =~ /CREG\:\s*2\,\s*[0-5]\,\s*\"?([0-9A-F]+)\"?\,\s*\"?([0-9A-F]+)\"?/)
	{
		$data{"lac"}= $1;
		$data{"cell_id"}= $2;
		return \%data;

	}
	else
	{
		carp("Could not match CREG reply");
		return undef;
	}


}



=head2 get_lac_dec

=over 4

This method returns vireless location info- ie LAC and CELL ID. The identifiers are returned as a reference to hash.
The values are in decimal format. 

Example:

my $loc= $modem->get_lac_dec();
print $loc->{"lac"};
print $loc->{"cell_id"};


=back

=cut

sub get_lac_dec {
	my $data= get_lac_hex(@_);
	$data->{"lac"}= hex($data->{"lac"});
	$data->{"cell_id"}= hex($data->{"cell_id"});
	return $data;
	
}


sub _at_send {
        my ($self, $command) = @_;
        $self->log->write('info', "Executing command: $command");
	$self->atsend($command);

}

1;

=head1 SUPPORT

Feel free to contact me at dmitriii@gmail.com for questions or suggestions.
The code has been tested against Huawei E173  and Huawei E398
If you find that your modem is not compatible because of AT commands mismatch 
(it may be different in different dongles) please provide modem name and attach AT command output.

=head1 AUTHOR

Dmitry Cheban, dmitriii@gmail.com

=head1 COPYRIGHT

(c) 2015, Dmitry Cheban, dmitriii@gmail.com

This library is free software; you can only redistribute it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

Device::Modem

=cut
