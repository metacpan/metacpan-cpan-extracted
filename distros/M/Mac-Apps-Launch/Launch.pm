package Mac::Apps::Launch;
require 5.004;
use Exporter;
use strict;
use vars qw($VERSION @ISA @EXPORT);
use Mac::Processes;
use Mac::MoreFiles;
use Mac::AppleEvents;
#-----------------------------------------------------------------
$VERSION = '1.93';
@ISA     = 'Exporter';
@EXPORT  = qw(
    LaunchSpecs LaunchApps QuitApps QuitAllApps IsRunning
    Show Hide SetFront
);
#-----------------------------------------------------------------
sub _showhide {
    my($tf, $app, $bool) = @_;
    my $err = 0;
    if (!$bool) {
        foreach my $psn (keys %Process) {
            if ($Process{$psn}->processSignature eq $app) {
                $app = $Process{$psn}->processName;
                last;
            }
        }
    }

    my $e = AEBuildAppleEvent(qw/core setd sign MACS/, 0, 0,
        q"'----': obj {form:prop, want:type(prop), seld:type(pvis), from:" .
        q"obj {form:name, want:type(pcap), seld:TEXT(@), from:'null'()}}," .
        "data:'$tf'", $app);
    $err ||= $^E unless $e;

    my $r = AESend($e, kAEWaitReply);
    $err ||= $^E unless $r;

    if ($r && (my $error = AEGetParamDesc($r, 'errn'))) {
        $err ||= $error->get;
        AEDisposeDesc $error;
    }
    AEDisposeDesc $e if $e;
    AEDisposeDesc $r if $r;
    $^E = $err;
    return !$err;
}
#-----------------------------------------------------------------
sub Show { _showhide('true', @_) }
sub Hide { _showhide('fals', @_) }
#-----------------------------------------------------------------
sub SetFront {
	my($address, $is_path) = _get_address(@_);
	for my $psn (keys %Process) {
		unless ($Process{$psn}) {
#			warn "$address:$is_path:$psn";
			next;
		}
		next unless $is_path
			? $Process{$psn}->processAppSpec =~ /^\Q$address\E/
			: $Process{$psn}->processSignature eq $address;
		SetFrontProcess($psn);
		return 1;
	}
	return;
}
#-----------------------------------------------------------------
sub QuitAllApps {
	my $keepapps;
	$keepapps = 'McPL' if $^O eq 'MacOS';
	for (@_) { $keepapps .= "|\Q$_\E" }
	my $APPL = unpack 'L*', 'APPL';

	my @apps;
	for my $psn (keys %Process) {
		my $proc = $Process{$psn};
		next unless $proc;
		my $sig = $proc->processSignature;
		next if $sig =~ /$keepapps/; # apps to keep running
		push @apps, $sig if $proc->processType == $APPL;
	}

	QuitApps(@apps);
}
#-----------------------------------------------------------------
sub QuitApps {
	my @apps = @_;
	my $err = 0;
	foreach (@apps) {
		my $e = AEBuildAppleEvent(
			'aevt', 'quit', typeApplSignature, $_,
			kAutoGenerateReturnID, kAnyTransactionID, ''
		);
		$err ||= $^E unless $e;

		my $r = AESend($e, kAEWaitReply);
		$err ||= $^E unless $r;

		AEDisposeDesc $e if $e;
		AEDisposeDesc $r if $r;
	}
	$^E = $err;
	return !$err;
}
#-----------------------------------------------------------------
sub LaunchApps {
	my $err = 0;
	my @apps = ref $_[0] eq 'ARRAY' ? @{$_[0]} : $_[0];
	my($switch, $specs, %open);

	$specs = 1 if (caller(1))[3] &&
		(caller(1))[3] eq __PACKAGE__ . "::LaunchSpecs";

	if ($_[1] && $_[1] == 1) {
		$switch = launchContinue | launchNoFileFlags;
	} else {
		$switch = launchContinue | launchNoFileFlags | launchDontSwitch;
	}

	for my $n (keys %Process) {
		my $i = $Process{$n};
		next unless $i;
		$open{$i->processSignature} = $i->processAppSpec;
	}

	foreach (@apps) {
		if ($specs) {
			_launch($_, $switch) or $err ||= $^E;
		} elsif ($Application{$_}) {
			my $app_spec = exists $open{$_} ? $open{$_} : $Application{$_};
			_launch($app_spec, $switch) or $err ||= $^E;
		} else {
			$err ||= -5012;  # "missing comment/APPL entry"
		}
	}
	$^E = $err;
	return !$err;
}
#-----------------------------------------------------------------
sub LaunchSpecs { LaunchApps(@_) }
#-----------------------------------------------------------------
sub _launch {
	my($app_spec, $switch) = @_;
	return unless -e $app_spec;
	my $Launch = new LaunchParam(
		launchControlFlags => $switch,
		launchAppSpec      => $app_spec,
	);
	LaunchApplication($Launch);
}
#-----------------------------------------------------------------
sub IsRunning {
	my($address, $is_path) = _get_address(@_);
	for my $psn (keys %Process) {
		unless ($Process{$psn}) {
#			warn "$address:$is_path:$psn";
			next;
		}
		return $psn if $is_path
			? $Process{$psn}->processAppSpec =~ /^\Q$address\E/
			: $Process{$psn}->processSignature eq $address;
	}
	return;
}
#-----------------------------------------------------------------
sub _get_address {
	my($address, $is_path) = @_;
	unless ($is_path) {
		if (length($address) == 4) {
			$is_path = 0;
		} elsif ($address =~ /^(?:\S+\.)+\S+$/) {
			# try to assume is bundle ID
			my $path = LSFindApplicationForInfo('', $address);
			$address = $path if $path;
			$is_path = 1;
		} else { # fall back to path ...
			$is_path = 1;
		}
	}

	return($address, $is_path);
}

1;

__END__

=head1 NAME

Mac::Apps::Launch - Mac module to launch /quit applications

=head1 SYNOPSIS

    use Mac::Apps::Launch;
    my @apps = qw(R*ch Arch MPGP);
    my $path = "HD:System Folder:Finder";
    LaunchApps([@apps], 1) or warn $^E; # launch and switch to front
    LaunchApps([@apps])    or warn $^E; # launch and don't switch 
    LaunchApps($app, 1)    or warn $^E; # launch and switch to front
    LaunchSpecs($path, 1)  or warn $^E; # use path instead of app ID
    QuitApps(@apps)        or warn $^E; # quit all @apps
    QuitAllApps(@apps)     or warn $^E; # quit all except @apps
    IsRunning('MACS');                  # returns boolean for whether
                                        # given app ID is running
    SetFront('MACS')       or warn $^E; # set Finder to front
    Hide('MACS')           or warn $^E; # hide Finder
    Show('Finder', 1)      or warn $^E; # show Finder (1 == use name)

=head1 DESCRIPTION

Simply launch or quit applications by their creator ID.  The Finder can
be quit in this way, though it cannot be launched in this way.

This module is used by many other modules.

This module as written does not work with MacPerls prior to 5.1.4r4.

C<Hide> and C<Show> do not currently work on Mac OS X.

Apps that don't have signatures under Mac OS X currently aren't handled,
except with LaunchSpecs().

C<SetFront> and C<IsRunning> can take a four-char creator ID ('MACS'), a
bundle ID ('com.apple.Finder'), or a path
(F</System/Library/CoreServices/Finder.app>).  They both optionally take
a second parameter which affirms that the data is indeed a path (for
those rare cases where a path might possibly look like a creator ID
or bundle ID ... you never know).

C<IsRunning> will return the PSN of the application if it is running,
which you can then use for targetting the app, or converting to a PID
(with C<Mac::Processes::GetProcessPID()>), to send signals to it.

=head1 EXPORT

Exports functions C<QuitApps>, C<QuitAllApps>, and C<LaunchApps>,
C<IsRunning>, C<LaunchSpecs>, C<SetFront>, C<Hide>, C<Show>.

=head1 AUTHOR

Chris Nandor E<lt>pudge@pobox.comE<gt>, http://pudge.net/

Copyright (c) 1999-2005 Chris Nandor.  All rights reserved.  This program
is free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=cut
