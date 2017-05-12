package Mac::AppleEvents::Simple;
require 5.004;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION $SWITCH
	$CLASSREC $ENUMREC %AE_GET %DESCS $DESCCOUNT $WARN $DEBUG $REVISION);

use Carp;
use Exporter;
use Mac::AppleEvents 1.30;
use Mac::Apps::Launch 1.90;
use Mac::Processes 1.04;
use Mac::Files;
use Mac::Types;
use Mac::Errors qw(%MacErrors $MacError);
use Time::Epoch 'epoch2perl';

#-----------------------------------------------------------------

@ISA = qw(Exporter Mac::AppleEvents);
@EXPORT = qw(
	do_event build_event handle_event
	pack_ppc pack_eppc pack_eppc_x pack_psn pack_pid
);
@EXPORT_OK = (@EXPORT, @Mac::AppleEvents::EXPORT);
%EXPORT_TAGS = (all => [@EXPORT, @EXPORT_OK]);

$REVISION = '$Id: Simple.pm,v 1.26 2006/07/07 06:44:37 pudge Exp $';
$VERSION  = '1.18';
$DEBUG	||= 0;
$SWITCH ||= 0;
$WARN	||= 0;

# some users won't have Carp::cluck ...
sub cluck;
*cluck = *Carp::cluck{CODE} || sub { warn Carp::longmess @_ };

#-----------------------------------------------------------------
# Main public methods and functions
#-----------------------------------------------------------------

sub do_event {
	my $self = bless _construct(@_), __PACKAGE__;
	$self->_build_event and return $self->_warn;
	$self->_send_event  and return $self->_warn;
	$self->_sending     and return $self->_warn;
	$self;
}

#-----------------------------------------------------------------

sub build_event {
	my $self = bless _construct(@_), __PACKAGE__;
	$self->_build_event       and return $self->_warn;
#	$self->_print_desc('EVT') and return $self->_warn;
	$self;
}

#-----------------------------------------------------------------

sub handle_event {
	my($class, $event, $code, $sys) = @_;
	my $hash = $sys ? \%SysAppleEvent : \%AppleEvent;
	my $handler = bless [$hash, $class, $event],
		__PACKAGE__ . '::Handler';

	$hash->{$class, $event} = sub {
		my($evt, $rep, $key) = @_;
		# make 'em backward!
		my $obj = bless {
			REP => $evt,
			EVT => $rep,
			HANDLER => $handler
		}, __PACKAGE__;
		$code->($obj, split /$;/, $key);
		0;
	};

	return;
}

#-----------------------------------------------------------------

sub send_event {
	my $self = shift;
	$self->_send_event(@_) and return $self->_warn;
	$self->_sending        and return $self->_warn;
	$self;
}

#-----------------------------------------------------------------

sub type {
	my($self, $key) = @_;
	my($d, $desc);
	$d = ref $self eq __PACKAGE__ ? $self->{REP} : $self;
	return unless ref $d eq 'AEDesc';
	return unless
		defined($desc = AEGetParamDesc($d, $key || keyDirectObject));

	my $type = $desc->type;
	AEDisposeDesc($desc);
	return $type;
}

#-----------------------------------------------------------------

sub data {
	my($self, $key) = @_;
	my($d, $desc, $num, @ret);

	$d = ref $self eq __PACKAGE__ ? $self->{REP} : $self;
	return unless ref $d eq 'AEDesc';
	return unless
		defined($desc = AEGetParamDesc($d, $key || keyDirectObject));

	# special-case typeAERecord here, too?
	if ($num = AECountItems($desc)) {
		for (1 .. $num) {
			my $d = AEGetNthDesc($desc, $_);
			push @ret, $d;
		}
		return wantarray ? @ret : $ret[0];
	} else {
		return $desc;
	}
}

#-----------------------------------------------------------------

sub get {
	my($self, $key) = @_;
	my($d, $desc, $num);

	$d = ref $self eq __PACKAGE__ ? $self->{REP} : $self;
	return unless ref $d eq 'AEDesc';
	return unless
		defined($desc = AEGetParamDesc($d, $key || keyDirectObject));

	if ($num = AECountItems($desc)) {
		if ($desc->type eq typeAEList) {
			my @ret;
			for (1..$num) {
				push @ret, _getdata(AEGetNthDesc($desc, $_));
			}
			# if scalar context, return ref instead?
			AEDisposeDesc($desc);
			return wantarray ? @ret : $ret[0];

		} elsif ($desc->type eq typeAERecord) {
			my %ret;
			for (1..$num) {
				my @d = AEGetNthDesc($desc, $_);
				$ret{$d[1]} = _getdata($d[0]);
			}
			AEDisposeDesc($desc);
			# if scalar context, return ref instead?
			return %ret;
		}
	}
	return _getdata($desc);
}

#-----------------------------------------------------------------

sub pack_psn {
	my($psn) = @_;
	return pack 'll', 0, $psn;
}

#-----------------------------------------------------------------

sub pack_pid {
	my($pid) = @_;
	return pack 'l', $pid;
}

#-----------------------------------------------------------------

sub pack_eppc_x {
	my($name, $server, $uid, $pid, $user, $pass) = @_;

	my $info;
	$info = $user if defined $user;
	$info .= ':' . $pass if defined $user && defined $pass;

	my @query;
	push @query, uid => $uid if $uid;
	push @query, pid => $pid if $pid;

	require URI;
	my $uri = new URI;
	$uri->scheme('http');
	$uri->path($name);
	$uri->host($server);
	$uri->query_form(@query) if @query;
	$uri->userinfo($info) if defined $info;
	$uri =~ s/http/eppc/;

	return $uri;
}

#-----------------------------------------------------------------

sub pack_ppc  { _pack_ppc('ppc',  @_) }
sub pack_eppc { _pack_ppc('eppc', @_) }

sub _pack_ppc {
	my($type, $id, $name, $server, $zone) = @_;
	my %TargetID;

	$TargetID{sess} = ['l', 0];			# long sessionID
	$TargetID{name} = ['sca33sca33',		# PPCPortRec name
		0,						# ScriptCode nameScript
		length($name), $name,				# Str32Field name
		2,						# PPCPortKinds ppcByString
		length($id . 'ep01'), $id . 'ep01',		# Str32 portTypeStr
		# why ep01? dick karpinski suggests it might be
		# "Ethernet port 01", so maybe we need to find out
		# the port automatically ... ick.
	];

	if ($type eq 'ppc') {
		my $atype = 'PPCToolbox';
		$zone ||= '*';
		$TargetID{loca} = ['sca33ca33ca33',	# LocationNameRec location
			1,				# PPCLocationKind ppcNBPLocation
							# EntityName
			length($server), $server,		# Str32Field objStr
			length($atype), $atype,			# Str32Field typeStr
			length($zone), $zone,			# Str32Field zoneStr
		];
	} elsif ($type eq 'eppc') {
		$TargetID{loca} = ['ssssa*',		# LocationNameRec location
			3,				# PPCLocationKind 
							#	  ppcXTIAddrLocation
							# PPCAddrRec xtiType
			0,					# UInt8 Reserved (0)
			2 + length($server),			# UInt8 xtiAddrLen
								# PPCXTIAddress xtiAddr
			42,						# PPCXTIAddressType
									#	  kDNSAddrType
			$server						# UInt8 fAddress[96]
		];
	} else {
		carp "Type $type not recognized\n";
	}

	my($format, @args, $targ);
	for (qw[sess name loca]) {
		my @foo = @{$TargetID{$_}};
		$format .= shift @foo;
		push @args, @foo;
	}
	$targ  = pack $format, @args;

	printf("> %s\n< %s\n\n", $targ, join("|", unpack $format, $targ))
		if $DEBUG > 1;
	return $targ;
}

#-----------------------------------------------------------------
# Private methods
#-----------------------------------------------------------------

sub _getdata {
	my($desc) = @_;
	my $type = $desc->type;
	my($ret, $keep);

	if ($type eq typeEnumerated && $ENUMREC && defined &$ENUMREC) {
		$ret = $ENUMREC->($desc->get);
	}

	if (!$ret && !exists $AE_GET{$type} && !exists $MacUnpack{$type} && defined &$CLASSREC) {
		if ($CLASSREC->($type)) {
			my $tmp = AECoerceDesc($desc, typeAERecord); # or die "Type [$type]: $MacError\n";
			if ($tmp) {
				AEDisposeDesc $desc;
				$desc = $tmp;
				$type = typeAERecord;
			}
		}
	}

	if (!$ret) {
		($ret, $keep) = exists($AE_GET{$type})
			? $AE_GET{$type}->($desc)
			: $desc->get;
	}

	AEDisposeDesc $desc unless $keep;
	return $ret;
}

#-----------------------------------------------------------------

sub _sending {
	my $self = shift;
#	$self->_print_desc('EVT');
#	$self->_print_desc('REP');
	$self->_event_error;
}

#-----------------------------------------------------------------

sub _construct {
	my $self = {};
	$self->{CLASS} = shift or croak 'Not enough parameters in AE build';
	$self->{EVNT} =  shift or croak 'Not enough parameters in AE build';
	$self->{APP} =   shift or croak 'Not enough parameters in AE build';

	if (ref $self->{APP} eq 'HASH') {
		for (keys %{$self->{APP}}) {
			$self->{ADDTYPE} = $_;
			$self->{ADDRESS} = $self->{APP}{$_};
			next;
		}
	} else {
		$self->{ADDTYPE} = typeApplSignature;
		$self->{ADDRESS} = $self->{APP};
	}

	$self->{DESC} = shift || '';
	$self->{PARAMS} = [@_];
	$self;
}

#-----------------------------------------------------------------

sub _print_desc {
	my $self = shift;
	my %what = (EVT => 'EVENT', REP => 'REPLY');
	$self->{$what{$_[0]}} = AEPrint $self->{$_[0]};
}

#-----------------------------------------------------------------

sub _build_event {
	my $self = shift;
	$self->{TRNS_ID} ||= kAnyTransactionID;
	$self->{EVT} = AEBuildAppleEvent(
		$self->{CLASS}, $self->{EVNT}, $self->{ADDTYPE},
		$self->{ADDRESS}, kAutoGenerateReturnID, $self->{TRNS_ID},
		$self->{DESC}, @{$self->{PARAMS}}
	);
	$self->{ERRNO} = $^E+0;
	$self->{ERROR} = $MacError;
	return $self->{ERRNO};
}

#-----------------------------------------------------------------

sub _send_event {
	my $self   = $_[0];
	my $launch = $_[4];

	if ($self->{ADDTYPE} eq typeApplSignature) {
		if (! IsRunning($self->{ADDRESS})) { # $launch
			LaunchApps($self->{ADDRESS}, $SWITCH) or
				warn "Can't launch '$self->{ADDRESS}': $MacError";
		} elsif ($SWITCH) {
			SetFront($self->{ADDRESS});
		}

	} elsif ($self->{ADDTYPE} eq typeApplicationBundleID) {
		my $path = $self->{PATH} || LSFindApplicationForInfo('', $self->{ADDRESS});
		if (! IsRunning($path, 1)) { # $launch
			LaunchSpecs($path, $SWITCH) or
				warn "Can't launch '$self->{ADDRESS}': $MacError";
		} elsif ($SWITCH) {
			SetFront($path, 1);
		}
	}

	$self->{R} = defined $_[1] ? $_[1] : $self->{GETREPLY} || kAEWaitReply;
	$self->{P} = defined $_[2] ? $_[2] : $self->{PRIORITY} || kAENormalPriority;
	$self->{T} = defined $_[3] ? $_[3] : $self->{TIMEOUT}  || kNoTimeOut;

	$self->{REP} = AESend(@{$self}{'EVT', 'R', 'P', 'T'});
	$self->{ERRNO} = $^E+0;
	$self->{ERROR} = $MacError;

#	if (!$launch && $self->{ERRNO} == -600) { #$MacErrors{connectionInvalid}->number) {
#		$self->_send_event(@_[1..3], 1);
#	}

	return $self->{ERRNO};
}

#-----------------------------------------------------------------

sub _event_error {
	my($self) = @_;
	my($event, $error);

	delete $self->{ERRNO};
	$event = $self->{REP};
	return unless $event;

	{
		local $^E;
		if (my $errn = AEGetParamDesc($event, keyErrorNumber)) {
			$self->{ERRNO} = $errn->get;
			AEDisposeDesc($errn);
		}

		if (my $errs = AEGetParamDesc($event, keyErrorString)) {
			$self->{ERROR} = $errs->get;
			AEDisposeDesc($errs);
		}
	}

	$self->{ERRNO} ||= $^E+0;
	$self->{ERROR} ||= $MacError;
	return $self->{ERRNO};
}

#-----------------------------------------------------------------

sub _warn {
	my $self = $_[0];
	if ($WARN) {
		my $warn = $WARN > 1 ? \&cluck : \&carp;
		if ($self->{ERROR}) {
			$warn->($self->{ERROR});
		} elsif ($self->{ERRNO}) {
			local $^E = $self->{ERRNO};
			$self->{ERROR} = $MacError;
			$warn->("Error $self->{ERRNO}: $self->{ERROR}");
		}
	}
	$self;
}

#-----------------------------------------------------------------

sub Mac::AppleEvents::Simple::Handler::DESTROY {
	my $self = shift;
	delete $self->[0]{$self->[1], $self->[2]};
}

#-----------------------------------------------------------------

DESTROY {
	my $self = shift;
	local $^E;	# save $^E
	unless ($self->{HANDLER}) {
		AEDisposeDesc $self->{EVT} if $self->{EVT};
		AEDisposeDesc $self->{REP} if $self->{REP};
	}
}

#-----------------------------------------------------------------

END {
	foreach my $desc (keys %DESCS) {
		print "Destroying $desc\n" if $DEBUG;
		if ($desc) {
			eval { print "\t", AEPrint($DESCS{$desc}), "\n" } if $DEBUG;
			AEDisposeDesc $DESCS{$desc} or warn "Can't dispose $desc: $MacError";
		}
	}
}

#-----------------------------------------------------------------

BEGIN {
	%AE_GET = (
		typeComp()			=> sub {
			return _get_coerce($_[0], typeFloat);
		},

		typeAlias()			=> sub {
			my $alis = $_[0]->data;
			my $return = ResolveAlias($alis) or die "Can't resolve alias: $MacError";
			$alis->dispose;
			return $return;
		},

		typeObjectSpecifier()		=> sub {
			$DESCS{ $_[0] } = $_[0];
			return($_[0], 1);
		},

		typeAEList()			=> sub {
			my $list = $_[0];
			my @data;
			for (1 .. AECountItems($list)) {
				my $d = AEGetNthDesc($list, $_) or die "Can't get desc: $MacError";
				push @data, _getdata($d);
			}
			return \@data;
		},

		typeAERecord()			=> sub {
			my $reco = $_[0];
			my %data;
			for (1 .. AECountItems($reco)) {
				my @d = AEGetNthDesc($reco, $_) or die "Can't get desc: $MacError";
				$data{$d[1]} = _getdata($d[0]);
			}
			return \%data;
		},

		typeProcessSerialNumber() 	=> sub {
			my $handle = $_[0]->data;
			my $num = $handle->get;
			$handle->dispose;
			my $psn = join '', unpack 'LL', $num;
			$psn =~ s/^0+//;
			return $psn;
		},

		typeLongDateTime() 		=> sub {
			my $handle = $_[0]->data;
			my $num = $handle->get;
			$handle->dispose;
			# typeLongDateTime is 64 bits, and the grep tosses out
			# the high bits, which will be good for as long
			# as the Unix 32-bit epoch lasts, which is good
			# enoguh for now; but this is not 64-bit safe, at all;
			# for that, we will use unpack 'Q' probably
			my($ldt) = grep $_, unpack 'LL', $num;
			return $^O eq 'MacOS' ? $ldt : epoch2perl($ldt, 'macos');
		},

		typeStyledText()		=> sub {
			return _get_coerce($_[0], typeChar);
		},

		typeQDPoint()			=> sub {
			my $handle = $_[0]->data;
			my $point = $handle->get;
			$handle->dispose;
			return [reverse unpack "s4s4", $point];
		},

		typeQDRectangle()		=> sub {
			return [ ($_[0]->get)[1,0,3,2] ];
		},

	);

	%AE_GET = (%AE_GET,
		typeUnicodeText()	=> $AE_GET{typeStyledText()},
		typeIntlText()		=> $AE_GET{typeStyledText()},
		typeAEText()		=> $AE_GET{typeStyledText()},
#		  UREC => sub {
#			  $AE_GET{typeAERecord()}->(AECoerceDesc(shift, typeAERecord));
#		  },
	);

}

sub _get_coerce {
	my $data = AECoerceDesc(@_) or die $^E+0;
	return $data->get;
}

1;

__END__

=head1 NAME

Mac::AppleEvents::Simple - Simple access to Mac::AppleEvents

=head1 SYNOPSIS

	#!perl -w
	use Mac::AppleEvents::Simple;
	use Mac::Files;  # for NewAliasMinimal
	$alias = NewAliasMinimal(scalar MacPerl::Volumes);
	do_event(qw/aevt odoc MACS/, "'----':alis(\@\@)", $alias);

	# [...]
	use Mac::Errors '$MacError';
	use Mac::AppleEvents;  # for kAENoReply
	$evt = build_event(qw/aevt odoc MACS/, "'----':alis(\@\@)", $alias);
	die "There was a problem: $MacError" if $^E;
	$evt->send_event(kAENoReply);
	die "There was a problem: $MacError" if $^E;


=head1 DESCRIPTION

=head2 Requirements

For MacPerl 5.2.0r4, you should have the latest cpan-mac distribution:

	http://sourceforge.net/projects/cpan-mac/

For MacPerl 5.6.1 and up, everything you need is included.

For Mac OS X, you should have the latest Mac::Carbon:

	http://sourceforge.net/projects/macperl/

Also note the differences between MacPerl and perl on Mac OS X listed
in Mac::Carbon, especially regarding C<$^E>.

=head2 Overview

This is just a simple way to do Apple Events.  The example above was 
previously done as:

	#!perl -w
	use Mac::AppleEvents;
	use Mac::Files;
	$alias = NewAliasMinimal(scalar MacPerl::Volumes);
	$evt = AEBuildAppleEvent(qw/aevt odoc sign MACS 0 0/,
		"'----':alis(\@\@)", $alias) or die $MacError;
	$rep = AESend($evt, kAEWaitReply) or die $MacError;
	AEDisposeDesc($rep);
	AEDisposeDesc($evt);

The building, sending, and disposing is done automatically.  The function 
returns an object containing the parameters.  (Previously, the C<AEPrint> 
results of C<AEBuildAppleEvent> and C<AESend> would be in C<$event-E<gt>{EVENT}> 
C<$event-E<gt>{REPLY}>, but this was wasting way too much memory, as some of
these things got big; you can call C<AEPrint($event-E<gt>{REP})> yourself).

Also, the Mac::AppleEvents::Simple method will launch the application for
you, whereas the Mac::AppleEvents method requires the program to be running
already (or launched via Mac::Processes or Mac::Apps::Launch).  Launching
works only when the target is an app signature or bundle ID.

The raw AEDesc forms are in C<$event-E<gt>{EVT}> and C<$event-E<gt>{REP}>.
So if I also C<use>'d the Mac::AppleEvents module (or got the symbols via
C<use Mac::AppleEvents::Simple ':all'>), I could extract the direct
object from the reply like this:

	$dobj = AEPrint(AEGetParamDesc($event->{REP}, keyDirectObject));

An easier way to get the direct object data, though, is with the C<get>
method, described below.

The sending of the event uses as its defaults (C<kAEWaitReply>,
C<kAENormalPriority>, C<kNoTimeout>).  To use different parameters, use
C<build_event> with C<send_event>.

Setting C<$Mac::AppleEvents::Simple::SWITCH = 1> forces the target app to
go to the front on sending an event to it.  This works only when
the target is an app signature or bundle ID.

Sending an event with C<send_event> or C<do_event> will check for errors
automatically, and if there is an error and C<$Mac::AppleEvents::Simple::WARN>
is true, a warning will be sent to C<STDERR>.  You can also check C<$^E>
after each call, or check the values of C<$event-E<gt>{ERRNO}> and
C<$event-E<gt>{ERROR}>.

If the event reply itself contains a C<errn> or C<errs> parameter, these
will also be placed in C<$event-E<gt>{ERRNO}> and C<$event-E<gt>{ERROR}>
and C<$^E> as appropriate.

You may decide to roll your own error catching system, too.  In this
example, the error is returned in the direct object parameter.

	my $event = do_event( ... );
	die $MacError if $^E;  # catch execution errors
	my_warn_for_this_app($event);  # catch AE reply errors

	sub my_warn_for_this_app {
		my $event = shift;
		my $error = AEGetParamDesc($event->{REP}, keyDirectObject);
		if ($error) {
			my $err = $error->get;
			if ($err =~ /^-\d+$/ && $^W) {
				warn "Application error: $err";
			}
			AEDisposeDesc($error);
		}
	}


=head1 FUNCTIONS

=over 4

=item [$EVENT =] do_event(CLASSID, EVENTID, TARGET, FORMAT, PARAMETERS ...)

The first three parameters are required.  The FORMAT and PARAMETERS
are documented elsewhere; see L<Mac::AppleEvents> and L<macperlcat>.

TARGET may be a four-character app ID or a hashref containing ADDRESSTYPE
and ADDRESS.  Examples:

	{ typeApplSignature()       => '...'            }  # default
	{ typeTargetID()            => pack_ppc(...)    }  # Mac OS only
	{ typeTargetID()            => pack_eppc(...)   }  # Mac OS only
	{ typeApplicationURL()      => pack_eppc_x(...) }  # Mac OS X
	{ typeProcessSerialNumber() => pack_psn(...)    }
	{ typeKernelProcessID()     => pack_pid(...)    }  # Mac OS X only
	{ typeBundleID()            => '...'            }  # Mac OS X only

See the pack functions below for details.


=item $EVENT = build_event(CLASSID, EVENTID, TARGET, FORMAT, PARAMETERS ...)

This is for delayed execution of the event, or to build an event that will be 
sent specially with C<send_event>.  Build it with C<build_event>, and then 
send it with C<send_event> method.  The parameters are the same as
C<do_event>.


=item $EVENT->send_event([GETREPLY, PRIORITY, TIMEOUT]);

For sending events differently than the defaults, which are C<kAEWaitReply>,
C<kAENormalPriority>, and C<kNoTimeout>, or for re-sending an event.  The
parameters are sticky for a given event, so:

	$evt->send_event(kAENoReply);
	$evt->send_event;  # kAENoReply is still used


=item $EVENT->handle_event(CLASSID, EVENTID, CODE [, SYS]);

B<Note>: Untested under Mac OS X.  Testing and patches welcome.

Sets up an event handler by passing CLASSID and EVENTID of the event
to be handled.  If SYS is true, then it sets up a system-wide event handler,
instead of an application-wide event handler.

CODE is a code reference that will be passed three parameters:
a Mac::AppleEvents::Simple object, the CLASSID, and the EVENTID.
The object will work similarly to a regular object.  The REP and EVT
parameters are switched (that is, you get the event in the REP parameter,
and the reply to be sent is in the EVT parameter).  This is so the other
methods will work just fine, and since you will only be using actual methods
on the object and not accessing its data directly, it shouldn't matter, right?

The other difference is that there is an additional data member in the object,
called HANDLER, which is for properly disposing of the handler when you are done
with it.  Your event handler should get disposed of for you in the background.

An example:

	my @data_out;
	handle_event('CLAS', 'EVNT', \&handler);
	sub handler {
		my($evt) = @_;
		my @data = $evt->get;
		push @data_out, [$data[0], $data[9]] if $data[0] && $data[9];
	}

	while (1) {
		if (my $data = shift @data_out) {
			print "woohoo: @$data\n";
		}	
	}


=item $EVENT->data([KEY])

=item $EVENT->get([KEY])

=item data(DESC[, KEY])

=item get(DESC[, KEY])

Similar to C<get> and C<data> from the Mac::AppleEvents module.
Get data from a Mac::AppleEvents::Simple object for a given key
(C<keyDirectObject> is the default).  Can also be called as a function,
where an AEDesc object is passed as the first parameter.

For C<data>, if the descriptor in KEY is an AE list, then a list
of the descriptors in the list will be returned.  In scalar context,
only the first element will be returned.

On the other hand, C<get> will return a nested data structure,
where all nested AE lists will be converted to perl array references,
and all nested AE records will be converted to perl hash references.
In scalar context, only the first element of the base list will be
returned for AE lists.

Also, C<get> will attempt to convert other data into a more usable form
(such as resolving aliases into paths).


=item pack_ppc(ID, NAME, SERVER[, ZONE])

B<Note>: Not implemented under Mac OS X.

Packs a PPC record suitable for using in C<build_event> and C<do_event>.
Accepts the 4-character ID of the target app, the name of the app as it
may appear in the PPC Chooser, and the server and zone it is on.  If
not supplied, zone is assumed to be '*'.

=item pack_eppc(ID, NAME, HOST)

B<Note>: Not implemented under Mac OS X (see L<pack_eppc_x>).

Packs an EPPC record suitable for using in C<build_event> and C<do_event>.
Accepts the 4-character ID of the target app, the name of the app as it
may appear in the PPC Chooser, and the hostname of the machine it is on.
Requires Mac OS 9.

=item pack_eppc_x(NAME, HOST [, UID, PID, USERNAME, PASSWORD])

B<Note>: Not implemented under Mac OS (see L<pack_eppc>).

Packs an EPPC record suitable for using in C<build_event> and C<do_event>
under Mac OS X.  Accepts the name of the app, the hostname of the machine
it is on, and, optionally, the uid of the owner of the app, the process ID
of the app, and the username/password to connect with.  Note that it is
normally preferable to allow the Keychain to handle the username/password
(enter it the first time it is asked for, and select "Add to Keychain?").
Requires Mac OS X.

B<Note>: the UID/PID stuff doesn't actually work for me, in my tests.  Huh.

B<Note>: the eppc port (for both Mac OS and Mac OS X) is 3031.

=item pack_psn(PSN)

Simply packs a PSN into a double long.

=item pack_pid(PID)

B<Note>: Mac OS X only.

Converts a PID into a PSN, then calls C<pack_psn>.

=back

=head1 EXPORT

Exports functions C<do_event>, C<build_event>, C<handle_event>,
C<pack_ppc>, C<pack_eppc>, C<pack_psn>, C<pack_pid>.  All the symbols from
Mac::AppleEvents are available in C<@EXPORT_OK> and through the
C<all> export tag.

=head1 AUTHOR

Chris Nandor E<lt>pudge@pobox.comE<gt>, http://pudge.net/

Copyright (c) 1998-2005 Chris Nandor.  All rights reserved.  This program
is free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=head1 SEE ALSO

Mac::AppleEvents, Mac::OSA, Mac::OSA::Simple, macperlcat, Inside Macintosh: 
Interapplication Communication.

	http://projects.pudge.net/
