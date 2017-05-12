#!perl -w
package Mac::Comm::OT_PPP;
require 5.00201;
use vars qw($VERSION @ISA @EXPORT $AUTOLOAD);
use strict;
use AutoLoader;
use Exporter;
use Carp;
use Mac::AppleEvents;
@ISA = qw(Exporter);
@EXPORT = ();
$VERSION = sprintf("%d.%02d", q$Revision: 1.20 $ =~ /(\d+)\.(\d+)/);

#=================================================================
# Stuff
#=================================================================
sub new {
	my $self = shift;
	return bless{}, $self;
}
#-----------------------------------------------------------------
sub PPPconnect {
	my($self,$user,$pass,$adrs,$diag,$be,$rp,$at);
	$self = shift;
	$user = shift || croak "username left blank\n";
	$pass = shift || croak "password left blank\n";
	$adrs = shift || croak "phone # left blank\n";
	$be = AEBuildAppleEvent('netw','RAco',typeApplSignature,'MACS',0,0,'') || croak $^E;
	AEPutParam($be,'RAun','TEXT',$user);
	AEPutParam($be,'RApw','TEXT',$pass);
	AEPutParam($be,'RAad','TEXT',$adrs);
	$rp = AESend($be, kAEWaitReply) || croak $^E;
	$at = AEGetParamDesc($rp,'errn');
	AEDisposeDesc $be;
	AEDisposeDesc $rp;
	return AEPrint($at) if ($at);
}
#-----------------------------------------------------------------
sub PPPdisconnect {
	my($be,$rp,$at);
	$be = AEBuildAppleEvent('netw','RAdc',typeApplSignature,'MACS',0,0,'') || croak $^E;
	$rp = AESend($be, kAEWaitReply) || croak $^E;
	$at = AEGetParamDesc($rp,'errn');
	AEDisposeDesc $be;
	AEDisposeDesc $rp;
	return AEPrint($at) if ($at);
}
#-----------------------------------------------------------------
sub PPPstatus {
	my($be,$rp,$aq,$at,@ar,$ar,%ar);
	$be = AEBuildAppleEvent('netw','RAst',typeApplSignature,'MACS',0,0,'') || croak $^E;
	$rp = AESend($be, kAEWaitReply) || croak $^E;
	$at = AEGetParamDesc($rp,'errn');
	return AEPrint($at) if ($at);

	$aq = AEGetParamDesc($rp,'----');
	@ar = qw(RAsb RAsc RAun RAsn RAms RAsp RAbm RAbi RAbo RAsr);
	foreach $ar(@ar) {
		if ($at = AEGetParamDesc($aq,$ar)) {
			($ar{$ar} = AEPrint($at)) =~ s/^Ò(.*)Ó$/$1/s;
			delete $ar{$ar} if ($ar{$ar} eq q{'TEXT'()});
		}
	}

	AEDisposeDesc $be;
	AEDisposeDesc $rp;
	return AEPrint($ar{'errn'}) if ($ar{'errn'});
	return \%ar;
}
#-----------------------------------------------------------------
sub PPPsavelog {
	my($self,$file,$be,$rp,$at);
	$self = shift;
	$file = shift || croak "filename left blank\n";
	$be = AEBuildAppleEvent('netw','RAsl',typeApplSignature,'MACS',0,0,'') || croak $^E;
	AEPutParam($be,'RAlf','TEXT',$file) if ($file);
	$rp = AESend($be, kAEWaitReply) || croak $^E;
	$at = AEGetParamDesc($rp,'errn');
	AEDisposeDesc $be;
	AEDisposeDesc $rp;
	return AEPrint($at) if ($at);
}
#-----------------------------------------------------------------#

__END__


=head1 NAME

Mac::Comm::OT_PPP - Interface to Open Transport PPP

=head1 SYNOPSIS

	use Mac::Comm::OT_PPP;
	$ppp = new Mac::Comm::OT_PPP;

=head1 DESCRIPTION

This module allows you to do basic operations with OT/PPP, the PPP connection software from Apple Computer designed for use with their Open Transport networking architecture.  For more information on Open Transport or OT/PPP, see the Open Transport web site.

=over 4

=item PPPconnect

	$ppp->PPPconnect(USER,PASS,ADRS);

Connect to phone number ADRS as user USER with password PASS.

=item PPPdisconnect

	$ppp->PPPdisconnect();

Disconnect.

=item PPPstatus

	$hash = $ppp->PPPstatus();
	foreach $key (keys %{$hash}) {
		print "$key: $$hash{$key}\n";
	}

Return status:

=over 8

=item RAsb

State of connection

=item RAsc

Seconds connected

=item RAsr

Seconds remaining

=item RAun

User name

=item RAsn

Server name

=item RAms

Most recent message for connection

=item RAbm

Baud rate of connection

=item RAbi

Bytes in/received

=item RAbo

Bytes out/sent

=item RAsp

Connection type (?)

=back

=item PPPsavelog

	$ppp->PPPsavelog(FILE);

Save log to file of filepath FILE.  Operation can take a minute or two if the log is big, and might freeze up your computer while working.  Be patient.

=back

=head1 VERSION NOTES

=over 4

=item v.1.2 January 3, 1998

General cleanup.

=item v.1.1 October 13, 1997

Took some code and threw it in a module.

=item v.1.0 May 4, 1997

Took some code and threw it in a module.

=back

=head1 SEE ALSO

=over

=item Open Transport Home Page

http://tuvix.apple.com/dev/opentransport

=back

=head1 AUTHOR

Chris Nandor F<E<lt>pudge@pobox.comE<gt>>
http://pudge.net/

Copyright (c) 1998 Chris Nandor.  All rights reserved.  This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.  Please see the Perl Artistic License.

=head1 VERSION

Version 1.20 (03 January 1998)

=cut
