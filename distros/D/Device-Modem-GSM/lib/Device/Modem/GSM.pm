# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# Perl licensing terms for details.
#
# $Id: GSM.pm 14 2007-12-25 21:41:48Z kattoo $

=head1 NAME

Device::Modem::GSM - Perl module to communicate with a GSM cell phone connected via some sort of Serial port (including but not limited to most USB data cables, IrDA, ... others ?).

=head1 SYNOPSIS

 use Device::Modem::GSM;
 
 my $gsm = new Device::Modem::GSM(
     port     => '/dev/ttyUSB0',
     log      => 'file,gsm_pb.log',
     loglevel => 'info');
 
 if ($gsm->connect(baudrate => 38400)) {
     print "Connected\n";
 }
 else {
     die "Couldn't connect, stopped";
 }
 if (not $gsm->pb_storage("SM")) {
     croak("Couldn't change phonebook storage");
 }
 $gsm->pb_write_entry(
     index => 0,
     text => "Daddy",
     number => '+1234567');

 $entries = $gsm->pb_read_entries(1,10);
 # or even $entries = $gsm->pb_read_all;
 foreach (@$entries) {
     print $_->{index}, ':', $_->{text}, ':', $_->{number}, "\n";
 }

=head1 DESCRIPTION

C<Device::Modem::GSM> extends C<Device::Modem> (which provides the basic
communication layer) to provide access to high-level GSM functionnalities
(such as access to phonebook or dealing with SMSes).

This module inherits from C<Device::Modem> so if you need lower level access methods, start looking there.

=cut

package Device::Modem::GSM;

use strict;
use warnings;

use Carp;
use Device::Modem;

our $VERSION = '0.3';
our @ISA = ("Device::Modem");

=head1 METHODS

=head2 pb_storage

=over 4

pb_storage must be called before any other method dealing with the phonebook. This method will set the storage on which other method calls will operate.

Supported storages will depend on the cell phone, but the following should always exist :

=over 4

=item .

SM is the SIM card

=item .

ME is the phone memory

=back

Ex :
 $gsm->pb_storage("SM");

=back

=cut

sub pb_storage {
	my $self = shift;

	if (@_) {
		my $new_pb_storage = shift;

		if (not defined($self->{pb_storage}) or
				$new_pb_storage ne $self->{pb_storage}) {
			# trying to change storage
			$self->atsend('AT+CPBS="' .
				 $new_pb_storage . '"' . Device::Modem::CR);
			my ($result, @lines) = $self->parse_answer;
			if ($result eq "OK") {
				$self->{pb_storage} = $new_pb_storage;
				$self->log->write('info',
					'Phonebook storage changed to ' .
					$new_pb_storage);
				# trying to get storage specs
				$self->atsend('AT+CPBR=?' . Device::Modem::CR);
				($result, @lines) = $self->parse_answer();
				if ($result eq 'OK') {
					if ($lines[0] =~ /^\+CPBR:\s\((.*)-(.*)\),(.*),(.*)$/) {
						$self->{pb_storage_min} = $1;
						$self->{pb_storage_max} = $2;
						$self->{pb_storage_nlength} = $3;
						$self->{pb_storage_tlength} = $4;
					} else {
						$self->log->write('warning',
							"Ill formated phonebook storage specs");
					}
				} else {
					$self->log->write('warning',
						"Couldn't retrieve phonebook storage specs");
				}
			} else {
				$self->log->write('error', 
					'Failed to change phonebook storage to ' .
					$new_pb_storage);
				return undef;
			}
		}
		else {
			# same storage : do nothing
		}
	}
	return $self->{pb_storage};
}

# check if storage was properly init'd
# returns 0 if not, 1 if storage is set, and 2 if storage is set AND
# specs were retrieved
sub pb_storage_ok {
	my $self = shift;

	if (exists $self->{pb_storage}) {
		if ((exists $self->{pb_storage_min}) and 
			(exists $self->{pb_storage_max})) {
			# storage is ok
			return 2;
		} else {
			# but the specs were not retrieved
			$self->log->write('warning',
				'Storage initialized, but was not able to get specs');
			return 1;
		}
	} else {
		# storage wasn't init'd
		$self->log->write('warning',
			'Storage not initialized ... did you first call pb_storage ?');
		return 0;
	}
}

=head2 pb_write_entry

=over 4

This method will write an entry into the phonebook.

Ex :

 $gsm->pb_write_entry(
     index => 1,
     text => 'John Doe',
     number => '+3312345');

The "index" parameter specifies the storage slot to fill. If none specified, then the first empty is used.

=back

=cut

sub pb_write_entry {
	my $self = shift;
	my %args = @_;

	$args{'index'} ||= "";

	$self->log->write('info', "writing entry " . $args{'index'} . "/" .
		$args{'text'} . "/" . $args{'number'});
	
	if ($args{'index'} ne "") {
		if ($self->pb_storage_ok >= 2) {
			if (($args{'index'} < $self->{pb_storage_min}) or 
				($args{'index'} > $self->{pb_storage_max})) {
				carp "Index should be between " .
					$self->{pb_storage_min} . " and " .
					$self->{pb_storage_max};
					return undef;
			}
		} else {
			$self->log->write('warning',
				"index specified but storage spec unavailable ... will try" .
				" but might fail !");
		} 
	}
	my $type;
	if ($args{'number'} =~ /^\+(.*)$/) {
		# international format phone number
		$args{'number'} = $1;
		$type = 145;
	} else {
		# not international
		$type = 129;
	}
	if (length($args{'number'}) > $self->{pb_storage_nlength}) {
		carp "Number too long, max is " . $self->{pb_storage_nlength};
		return undef;
	}
	if (length($args{'text'}) > $self->{pb_storage_tlength}) {
		carp "Text too long, max is " . $self->{pb_storage_tlength};
		return undef;
	}
	my $atcmd = 
		'AT+CPBW=' .
		$args{'index'} . "," .
		'"' . $args{'number'} . '",' .
		$type . "," .
		'"' . $args{'text'} . '"';
	$self->log->write('info', $atcmd);
	$self->atsend(
		$atcmd .
		Device::Modem::CR
	);
	my ($result, @lines) = $self->parse_answer();
	if ($result ne 'OK') {
		$self->log->write('error', "Couldn't write phonebook entry");
		return undef;
	}
	return 1;
}

=head2 pb_erase

=over 4

This method will erase the entry at the specified index of the storage

Ex :
 $gsm->pb_erase(10);

=back

=cut

sub pb_erase {
	my $self = shift;
	my $idx = shift;

	if ($self->pb_storage_ok > 1) {
		if ($idx < $self->{pb_storage_min} or $idx > $self->{pb_storage_max}) {
			carp("index out of bounds");
			return undef;
		}
	}
	$self->pb_write_entry(index => $idx, text => "", number => "");
}

=head2 pb_erase_all

=over 4

This method will clear the whole phonebook for the used storage. Handle with care !

Ex :
 $gsm->pb_erase_all;

=back

=cut

sub pb_erase_all {
	my $self = shift;

	if ($self->pb_storage_ok < 2) {
		carp("Storage spec unavailable");
		return undef;
	}
	for (my $i = $self->{pb_storage_min};
		$i <= $self->{pb_storage_max}; $i++) {
		$self->pb_write_entry(index => $i, text => "", number => "");
	}
}

=head2 pb_read_entries

=over 4

This method will fetch the specified entries in the phonebook storage and return them in a reference to an array. Each cell of the array is a reference to a hash holding the information.

Ex :

 my $entries = $gsm->pb_read_entries(1,10);

 foreach (@$entries) {
     print $_->{index}, ':', $_->{text}, ':', $_->{number}, "\n";
 }

With 2 arguments, the arguments are interpreted as an index range and entries inside of this range are returned.

With 1 argument, the argument is interpreted as an index and only this entry is returned.

=back

=cut

sub pb_read_entries {
	my $self = shift;
	my $idx = shift;
	my $idx2 = shift;

	if ($self->pb_storage_ok < 2) {
		$self->log->write('warning',
			"Storage specs unavailable... will try, but might fail");
	}
	if ($idx < $self->{pb_storage_min} or
		$idx > $self->{pb_storage_max} or 
		(defined($idx2) and 
				($idx2 < $self->{pb_storage_min} or 
				$idx2 > $self->{pb_storage_max}))) {
		$self->log->write('error', "Index out of bound");
		return undef;
	}

	my $atcmd = "AT+CPBR=$idx";
	if (defined $idx2) {
		$atcmd .= ("," . $idx2);
	}
	$atcmd .= Device::Modem::CR;
	$self->atsend($atcmd);
	# timeout of 10sec to leave time to get all the data, or till
	# OK or ERROR comes back
	my ($result, @lines) = $self->parse_answer(qr/OK|ERROR/, 10000);
	my $entries = [];
	foreach my $line (@lines) {
		my ($type, $number, $text);
		next if ($line =~ /^$/);
		if ($line =~ /^\+CPBR:\s+([0-9]+),\"([0-9]*)\",([0-9]+),\"(.*)\"$/) {
			$idx = $1;
			$number = $2;
			$type = $3;
			$text = $4;	
		} else {
			$self->log->write('warning',
				"Phonebook entry is ill formated, got " .
				$lines[0]);
		}
		if ($type == 145) {
			$number = '+' . $number;
		}
		push @$entries, 
			{ 'number' => $number, 'text' => $text, '$index' => $idx }; 
	}
	return $entries;
}

=head2 pb_read_all

=over 4

This is equivalent to a pb_read_entry where the range extends from the beginning of the phonebook storage to its end.

=back

=cut

sub pb_read_all {
	my $self = shift;

	if ($self->pb_storage_ok < 2) {
		$self->log->write('error', 'Storage spec were not retrieved, ' .
			'unable to perform this operation');
		return undef;
	}
	return $self->pb_read_entries(
		$self->{pb_storage_min},
		$self->{pb_storage_max}
	);
}

=head2 sms_send

=over 4

This method will let you send an SMS to the specified phone number

Ex :

 $gsm->sms_send("+33123456", "Message to send as an SMS");

=back

=cut

sub sms_send {
	my $self = shift;
	my $number = shift;
	my $sms = shift;

	# sets the SMS format to TEXT instead of default PDU
	my $atcmd = "AT+CMGF=1" . Device::Modem::CR;
	$self->atsend($atcmd);
	my ($result, @lines) = $self->parse_answer;

	if ($result ne 'OK') {
		carp('Failed to set SMS format to text');
		return undef;
	}
	$atcmd = "AT+CMGS=\"".$number."\"".Device::Modem::CR;
	$self->atsend($atcmd);
	$result = $self->answer; # to collect the > sign
	$atcmd = $sms . chr(26); # ^Z terminated string
	$self->atsend($atcmd);
	($result, @lines) = $self->parse_answer(qr/OK|ERROR/, 10000);;
	if ($result ne "OK") {
		carp('Unable to send SMS');
		return undef;
	}
	return 1;
}


1;

=head1 SUPPORT

Feel free to contact me at my email skattoor@cpan.org for questions or suggestions.

=head1 AUTHOR

Stephane KATTOOR, skattoor@cpan.org

=head1 COPYRIGHT

(c) 2007, Stephane KATTOOR, skattoor@cpan.org

This library is free software; you can only redistribute it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

Device::Modem

=cut


# vim:ts=4:sw=4:
