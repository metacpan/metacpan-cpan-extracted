# EAFDSS - Electronic Fiscal Signature Devices Library
#          Ειδική Ασφαλής Φορολογική Διάταξη Σήμανσης (ΕΑΦΔΣΣ)
#
# Copyright (C) 2008 Hasiotis Nikos
#
# ID: $Id: Base.pm 105 2009-05-18 10:52:03Z hasiotis $

package EAFDSS::Base;

=head1 NAME

EAFDSS::Base - EAFDSS Base Class Driver for all other drivers

=head1 DESCRIPTION

Read EAFDSS on how to use the module. This manual page is only of use if you want
to find out what it needs to develop a driver for a new EAFDSS device. This Base
class is to be inherited by any new driver.

=cut

use 5.006_000;
use strict;
use warnings;
use Carp;
use Class::Base;

use base qw ( Class::Base );

our($VERSION) = '0.80';

=head1 Methods

=head2 init

This the constructor, were we make sure we get the correct parameters to handle the
initialization of device object. Things like the signatures directory, the serial
number of the device. Also parameters special to the type of the device, like ip
address, or serial port, or baud rate, etc.

=cut

sub init {
	my($self, $config) = @_;

	if (! exists $config->{DIR}) {
		return $self->error("You need to provide the DIR to save the signnatures!");
	} else {
		$self->{DIR} = $config->{DIR};
	}

	if (! exists $config->{SN}) {
		return $self->error("You need to provide the Serial Number of the device!");
	} else {
		$self->{SN} = $config->{SN};
	}

	return $self;
}

=head2 Sign

The main job of an EAFDSS device is to produce signatures. Signatures of text files (invoices)
or text streams. So in that function we make sure to read the text from the caller of the
function in whatever format. Then we feed the text to the device which in return he gives us
the signature of that text. The function at tha level handles the saving of the text in the
"A file" and of the signature in the "B file", according to the rules set by the law for the
filenames of the files.

=cut

sub Sign {
        my($self)  = shift @_;
        my($fname) = shift @_;
        my($reply, $totalSigns, $dailySigns, $date, $time, $nextZ, $sign, $fullSign);

        $self->debug("Sign operation");

        if ( ($fname eq '-') || (-e $fname) ) {
		my($replySignDir, $deviceDir) = $self->_createSignDir();
		if ($replySignDir != 0) {
			return $self->error($replySignDir);
		}

		# Slurping the invoice
                open(FH, $fname);
	        my($invoice) = do { local($/); <FH> };
                close(FH);

                $self->debug(  "  Checking file [%s] for invalid characters", $fname);
		my($invalid) = $self->_checkCharacters($invoice);
                if ($invalid)  {
			$self->debug("  File contains invalid characters [%s]", $fname);
			return $self->error(64+0x10);
		}

                $self->debug(  "  Signing file [%s]", $fname);
                ($reply, $totalSigns, $dailySigns, $date, $time, $nextZ, $sign) = $self->PROTO_GetSign($invoice);

		if ($reply == 0) {
			$fullSign = sprintf("%s %04d %08d %s%s %s",
				$sign, $dailySigns, $totalSigns, $self->UTIL_date6ToHost($date), substr($time, 0, 4), $self->{SN});

			$self->_createFileA($invoice, $deviceDir, $date, $dailySigns, $nextZ);
			$self->_createFileB($fullSign, $deviceDir, $date, $dailySigns, $nextZ);

	        	return $fullSign;
		} else {
			return $self->error($reply);
		}
        } else {
                $self->debug(  "  No such file [%s]", $fname);
		return $self->error(64+2);
        }

}

=head2 Status

What this function return is a single line containing the values of the following: serial number, 
the index of the last Z, the total signatures, the daily signatures, the last signature's data size,
remaining signatures until the device will force a Z. 

=cut

sub Status {
        my($self) = shift @_;

        $self->debug("Status operation");

	my($reply, $status1, $status2, $lastZ, $total, $daily, $signBlock, $remainDaily) = $self->PROTO_ReadSummary();
	if ($reply == 0) {
		my($statusLine) = sprintf("%s %d %d %d %d %d", $self->{SN}, $lastZ, $total, $daily, $signBlock, $remainDaily);
        	return $statusLine;
	} else {
		return $self->error($reply);
	}
}


=head2 GetTime

GetTime will return the time in "DD/MM/YY HH:MM:SS" format.

=cut

sub GetTime {
        my($self) = shift @_;

        $self->debug("Read time operation");
	my($reply, $time) = $self->PROTO_ReadTime();
	if ($reply == 0) {
        	return $time;
	} else {
		return $self->error($reply);
	}
}

=head2 SetTime

Use this method to set the date/time on the device. Provide the date/time in the "DD/MM/YY HH:MM:SS" format. 

=cut

sub SetTime {
        my($self) = shift @_;
        my($time) = shift @_;

        $self->debug("Set time operation");
	my($reply) = $self->PROTO_SetTime($time);
	if ($reply == 0) {
        	return 0;
	} else {
		return $self->error($reply);
	}
}

=head2 Info

This method will return information about the name of the device and version of it's firmware.

=cut

sub Info {
        my($self) = shift @_;

        $self->debug("Read Info operation");
	my($reply, $version) = $self->PROTO_VersionInfo();
	if ($reply == 0) {
        	return $version;
	} else {
		return $self->error($reply);
	}
}

=head2 Query

This method should Query to find available devicess [NOT IMPLEMENTED]

=cut

sub Query {
        my($self) = shift @_;

        $self->debug("Query for devices");
	my($reply, $devices) = $self->PROTO_Query();
	if ($reply == 0) {
		if ($devices) {
        		return $devices;
		} else {
			return $self->error(64+0x05);
		}
	} else {
		return $self->error($reply);
	}
}

=head2 GetHeaders 

This method will return the printing headers of the device. The returned array contains 6 couples of values. One for the 
type of the printing line, and one for the actual printing message.

=cut

sub GetHeaders {
        my($self) = shift @_;

        $self->debug("Read Headers operation");
	my($reply, @headers) = $self->PROTO_GetHeader();
	if ($reply == 0) {
		return @headers;
	} else {
		return $self->error($reply);
	}
}

=head2 SetHeaders 

This method will set the printing headers on the device. The headers are to be provided in the
following format

  Style1/Line1/Style2/Line2/Style3/Line3/Style4/Line4/Style5/Line5/Style6/Line6

=cut

sub SetHeaders {
        my($self)    = shift @_;
        my($headers) = shift @_;

        $self->debug("Set Headers operation");
	my($reply) = $self->PROTO_SetHeader($headers);
	if ($reply == 0) {
		return 0;
	} else {
		return $self->error($reply);
	}
}

=head2 Report

The second most used function is Z report issuing function. At the end of the day ask for the device to
close the fiscal day by issuing the Z report. It will return the signature of the day. The function will
also take care to save the signature in the "C file"

=cut

sub Report {
        my($self) = shift @_;

	my($replySignDir, $deviceDir) = $self->_createSignDir();
	if ($replySignDir != 0) {
		return $self->error($replySignDir);
	}

	$self->_validateFilesB();
	$self->_validateFilesC();

        $self->debug("Issue Report operation");

	my($reply1) = $self->PROTO_IssueReport();
	if ($reply1 != 0) {
		return $self->error($reply1);
	}

	my($reply2, $status1, $status2, $totalSigns, $dailySigns, $date, $time, $z, $sn, $closure) = $self->PROTO_ReadClosure(0);
	$self->_createFileC($z, $deviceDir, $date, $time, $closure);

        return $z;
}

sub _RecoveryReport {
        my($self) = shift @_;

	my($deviceDir) = sprintf("%s/%s", $self->{DIR}, $self->{SN});

	$self->_validateFilesB();
	$self->_validateFilesC();

        $self->debug("Issue Recovery Report operation");

	my($reply1) = $self->PROTO_IssueReport();
	if ($reply1 != 0) {
		return $self->error($reply1);
	}

	my($reply2, $status1, $status2, $totalSigns, $dailySigns, $date, $time, $z, $sn, $closure) = $self->PROTO_ReadClosure(0);
	$self->_createFileC($z, $deviceDir, $date, $time, $closure);

        return $z;
}

sub _checkCharacters {
        my($self)    = shift @_;
	my($invoice) = shift @_;
	
	my($c);
	foreach $c (unpack('C*', $invoice)) {
		if (grep $_ == ord($c), qw/0 1 2 3 4 5 6 7 8 11 14 15 16 17 18 19 20 21 22 23 24 25 27 28 29 30 31 127 129 130 131 132 133 134 135 136 137 138 139 140 141 142 143 144 145 146 147 148 149 150 151 152 153 154 155 156 157 158 159 160 173 210 255/ ) {
                	$self->debug("     Found invalid character [%d]", ord($c));
			return 1;
		}
	}

	return 0;
}

sub _createSignDir {
	my($self) = shift @_;

	my($result) = $self->_Recover();
	if ($result != 0) {
		return ($result, undef);
	}

	# Create The signs Dir
	if (! -d  $self->{DIR} ) {
		$self->debug("  Creating Base Dir [%s]", $self->{DIR});
		mkdir($self->{DIR});
	}

	my($deviceDir) = sprintf("%s/%s", $self->{DIR}, $self->{SN});
	if (! -d $deviceDir ) {
		$self->debug("  Creating Device Dir [%s]", $deviceDir);
		mkdir($deviceDir);
	}

	return (0, $deviceDir);
}

sub _Recover {
	my($self) = shift @_;
	my($reply, $status1, $status2, $lastZ, $total, $daily, $signBlock, $remainDaily);

	($reply, $status1, $status2) = $self->PROTO_GetStatus();
	if ($reply ne "0") { return $reply };

	my($busy, $fatal, $paper, $cmos, $printer, $user, $fiscal, $battery) = $self->UTIL_devStatus($status1);
	if ($cmos != 1) { return 0 };

	my($day, $signature, $recovery, $fiscalWarn, $dailyFull, $fiscalFull) = $self->UTIL_appStatus($status1);

	$self->debug("   CMOS is set, going for recovery!");

	($reply, $status1, $status2, $lastZ, $total, $daily, $signBlock, $remainDaily) = $self->PROTO_ReadSummary(0);
	if ($reply != 0) {
		$self->debug("   Aborting recovery because of ReadClosure reply [%d]", $reply);
		return $reply
	};

	my($regexA) = sprintf("%s\\d{6}%04d\\d{4}_a.txt", $self->{SN}, $lastZ + 1);
	my($deviceDir) = sprintf("%s/%s", $self->{DIR}, $self->{SN});

	opendir(DIR, $deviceDir) || croak "can't opendir $deviceDir: $!";
	my(@afiles) = grep { /$regexA/ } readdir(DIR);
	closedir(DIR);

	foreach my $curA (@afiles) {
		$self->debug("          Checking [%s]", $curA);
		my($curFileA) = sprintf("%s/%s", $deviceDir, $curA);

		my($curFileB) = $curFileA;
		$curFileB =~ s/_a/_b/;

		my($curB)  = $curA; $curB =~ s/_a/_b/;
		my($curIndex) = substr($curA, 21, 4); $curIndex =~ s/^0*//;

		$self->debug("            Resigning file A [%s]", $curA);
		open(FH, $curFileA);

		my($reply, $totalSigns, $dailySigns, $date, $time, $nextZ, $sign) = $self->PROTO_GetSign(*FH);
		my($fullSign) = sprintf("%s %04d %08d %s%s %s", $sign, $dailySigns, $totalSigns, $self->UTIL_date6ToHost($date), substr($time, 0, 4), $self->{SN});
		close(FH);

		$self->debug("            Updating file  B [%s] -- Index [%d]", $curB, $curIndex);
		open(FB, ">>", $curFileB) || croak "Error: $!";
		print(FB "\n" . $fullSign); 
		close(FB);
	}

	my($z) = $self->_RecoveryReport();
	if ($z) {
		return(0);
	} else {
		my($errNo) = $self->error();
		return $self->error($errNo);
	}

}

sub _createFileA {
	my($self)    = shift @_;
	my($invoice) = shift @_;
	my($dir)     = shift @_;
	my($date)    = shift @_;
	my($ds)      = shift @_;
	my($curZ)    = shift @_;

	my($fnA) = sprintf("%s/%s%s%04d%04d_a.txt", $dir, $self->{SN}, $self->UTIL_date6ToHost($date), $curZ, $ds);
	$self->debug("   Creating File A [%s]", $fnA);
	open(FA, ">", $fnA) || croak "Error: $!";
	print(FA $invoice);
	close(FA);
}

sub _createFileB {
	my($self) = shift @_;
	my($fullSign)   = shift @_;
	my($dir)  = shift @_;
	my($date) = shift @_;
	my($ds)   = shift @_;
	my($curZ) = shift @_;

	my($fnB) = sprintf("%s/%s%s%04d%04d_b.txt", $dir, $self->{SN}, $self->UTIL_date6ToHost($date), $curZ, $ds);
	$self->debug("   Creating File B [%s]", $fnB);
	open(FB, ">", $fnB) || croak "Error: $!";
	print(FB $fullSign);
	close(FB);
}

sub _createFileC {
        my($self) = shift @_;
        my($z)    = shift @_;
        my($dir)  = shift @_;
        my($date) = shift @_;
        my($time) = shift @_;
        my($closure) = shift @_;

        my($fnC) = sprintf("%s/%s%s%s%04d_c.txt", $dir, $self->{SN}, $date, $self->UTIL_time6toHost($time), $closure);
        $self->debug(  "   Creating File C [%s]", $fnC);

        open(FC, ">", $fnC) || croak "Error: $!";
        print(FC $z); 
        close(FC);
}


sub _validateFilesB {
        my($self) = shift @_;

        my($reply, $status1, $status2, $lastZ, $total, $daily, $signBlock, $remainDaily) = $self->PROTO_ReadSummary();
        if ($reply != 0) { return $reply};

        my($regexA) = sprintf("%s\\d{6}%04d\\d{4}_a.txt", $self->{SN}, $lastZ + 1);
        $self->debug(  "    Validating B Files for #%d Z with regex [%s]", $lastZ + 1 , $regexA);
        my($deviceDir) = sprintf("%s/%s", $self->{DIR}, $self->{SN});

        opendir(DIR, $deviceDir) || croak "can't opendir $deviceDir: $!";
        my(@afiles) = grep { /$regexA/ } readdir(DIR);
        closedir(DIR);

        foreach my $curA (@afiles) {
                $self->debug(  "          Checking [%s]", $curA);
                my($curFileA) = sprintf("%s/%s", $deviceDir, $curA);

                my($curFileB) = $curFileA;
                $curFileB =~ s/_a/_b/;

                if (! -e $curFileB) { # TODO: Add size Check
                        my($curB)  = $curA; $curB =~ s/_a/_b/;
                        my($curIndex) = substr($curA, 21, 4); $curIndex =~ s/^0*//;
                        $self->debug(  "            Recreating file B [%s] -- Index [%d]", $curB, $curIndex);

                        my($replyCode, $status1, $status2, $totalSigns, $dailySigns, $date, $time, $sign, $sn, $closure) = $self->PROTO_ReadSignEntry($curIndex);
                        my($fullSign) = sprintf("%s %04d %08d %s%s %s", $sign, $dailySigns, $totalSigns, $self->UTIL_date6ToHost($date), substr($time, 0, 4), $self->{SN});

                        open(FB, ">",  $curFileB) || croak "Error: $!";
                        print(FB $fullSign); 
                        close(FB);
                }
        }

        return;
}

sub _validateFilesC {
        my($self) = shift @_;

        my($reply, $status1, $status2, $lastZ, $total, $daily, $signBlock, $remainDaily) = $self->PROTO_ReadSummary();
        if ($reply != 0) { return $reply };

        my($curClosure, $curFileC, $matched);

        my($regexC) = sprintf("%s.*_c.txt", $self->{SN}, $lastZ + 1);
        $self->debug(  "    Validating C Files for, total of [%d]", $lastZ);
        my($deviceDir) = sprintf("%s/%s", $self->{DIR}, $self->{SN});

        opendir(DIR, $deviceDir) || croak "can't opendir $deviceDir: $!";
        my(@cfiles) = grep { /$regexC/ } readdir(DIR);
        closedir(DIR);

        for ($curClosure = 1; $curClosure <= $lastZ;  $curClosure++) {
                $self->debug(  "      Searching for [%d]", $curClosure);

                $matched = 0;
                foreach (@cfiles) {
                        if (/${curClosure}_c\.txt$/) { 
                                $curFileC = $_;
                                $matched = 1;
                                last;
                        }
                }

                if ($matched) { 
                        $self->debug(  "          Keeping file C    [%s] -- Index [%d]", $curFileC, $curClosure);
                } else {
                        my($replyCode, $status1, $status2, $totalSigns, $dailySigns, $date, $time, $z, $sn, $closure) = $self->PROTO_ReadClosure($curClosure);
                        my($fnC) = sprintf("%s%s%s%04d_c.txt", $sn, $date, $time, $curClosure);
                        $self->debug(  "          Recreating file C [%s] -- Index [%d]", $fnC, $curClosure);

                        open(FC, ">", $deviceDir . "/" . $fnC) || croak "Error: $!";
                        print(FC $z); 
                        close(FC);
                }
        }
}


sub DESTROY {
        my($self) = shift;
        #printfv("Destroying %s %s",  $self, $self->name );
}

=head2 debug

This is our handy debuging function 

=cut

sub debug {
	my($self)  = shift;
	my($flag);

	if (ref $self && defined $self->{ _DEBUG }) {
		$flag = $self->{ _DEBUG };
	} else {
		# go looking for package variable
		no strict 'refs';
		$self = ref $self || $self;
		$flag = ${"$self\::DEBUG"};
	}

	return unless $flag;

	printf(STDERR "[%s] %s\n", $self->id, sprintf(shift @_, @_));
}


# Preloaded methods go here.

1;
__END__


=head1 VERSION

This is version 0.80.

=head1 AUTHOR

Hasiotis Nikos, E<lt>hasiotis@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Hasiotis Nikos

This library is free software; you can redistribute it and/or modify
it under the terms of the LGPL or the same terms as Perl itself,
either Perl version 5.8.8 or, at your option, any later version of
Perl 5 you may have available.

=cut
