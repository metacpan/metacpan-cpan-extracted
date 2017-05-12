package Device::CableModem::SURFboard;
use strict;
#use warnings; # testing

BEGIN {
    use Exporter ();
    use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
    $VERSION     = '0.04';
    @ISA         = qw(Exporter);
    @EXPORT      = qw();
    @EXPORT_OK   = qw(&errstr);
    %EXPORT_TAGS = ();
}

# Device::CableModem::SURFboard - Motorola 'SURFboard' modem status
# (models: SB4100, SB4200, SB5100, SB5100E, SB5101, SBV5120E)

# See the bottom of this file for the POD documentation.  Search for
# the string '=head'.

# You can run this file through either pod2man or pod2html to produce
# pretty documentation in manual or html file format (these utilities
# are part of the Perl 5 distribution).

# copyright(C) 2007 Scott Mazur <scott.AT.littlefish.ca>

# requires:
#     Socket;
#     Scalar::Util;

use Socket;
use Scalar::Util;

use constant SB5100_PATH => '/signaldata.html';
use constant SB5101_PATH => '/RgSignal.asp';
use constant SBV5120E_PATH => '/cmSignalData.htm';

my $errstr = '';
my $errfatal = 0;

sub new
{
    my ($class, %parameters) = @_;

	my $self = {
		dnPowerMax => 16,
		dnPowerMin => -16,
		upPowerMax => 54,
		upPowerMin => 36,
		SNRatioMax => 100, # FIXME reasonable value?
		SNRatioMin => 0,   # FIXME reasonable value?
		modemIP => '192.168.100.1',
		loginUsername => 'admin',
		loginPassword => 'motorola',
		%parameters,
	};

	# to prevent trying more page paths if the ip can't connect
	$errfatal = 0;

	# get the modem status page
	my $page_ref = pageRef($self, SB5100_PATH, 'SB5100')
		|| pageRef($self, SB5101_PATH, 'SB5101')
		|| pageRef($self, SBV5120E_PATH, 'SBV5120E')
		|| return undef;

	# The SBV5120E uses a login page.
	# Because of this the first page request sent to the modem
	# is completely ignored and the first response returned
	# is the login page.  A second page request (or more) is
	# required to complete the login and get the signal page,
	# after which the modem will remain 'logged in' for some period
	# of time.
	if ($self->{modelGroup} eq 'SBV5120E'
		and $$page_ref =~ m/loginUsername/i) {
		my $path = '/loginData.htm' .
			'?loginUsername=' . $self->{loginUsername} .
			'&loginPassword=' . $self->{loginPassword} .
			'&LOGIN_BUTTON=Login';
		my $tries = 4;
		while (--$tries and $$page_ref =~ m/loginUsername/i) {
			$page_ref = pageRef($self, $path)
				or return undef;
		}
		if (!$tries) {
			$errstr = "Failed to pass login page!";
			return undef;
		}
		# now get the try the signal page again
		$page_ref = pageRef($self, SBV5120E_PATH)
	}

	# clean up the html a bit for parsing
	$$page_ref =~ s/\n//g;     # drop new lines
	$$page_ref =~ s!</?t[dr]>! !ig; # strip table tags
	$$page_ref =~ s/&nbsp;/ /ig; # replace hard spaces
	$$page_ref =~ s/\s\s+/ /g; # reduce double spaces

	# check that the page has what we expect
	if ($$page_ref =~ m{
			Frequency \s (\d+)\s (Hz) \s (Locked\s)?
			Signal \s To \s Noise \s Ratio \s ([\d.]+)\s (dB) \s
			.*?  # non-greedy extra stuff for SBV5120E
			Power \s Level \s ([\d.-]+)\s (dBmV)
			}xi) {
		# fill in the signal strength values
		$self->{dnFreq} = $1;
		$self->{dnFreqUnit} = $2;
		$self->{SNRatio} = $4;
		$self->{SNRatioUnit} = $5;
		$self->{dnPower} = $6;
		$self->{dnPowerUnit} = $7;
	}
	else {
		$errstr = "Failed to parse content!";
		return undef;
	}

	# get the upstream values
	if ($$page_ref =~ m{
				ID \s (\d+) \s
				Frequency \s (\d+)\s (Hz)(\s Ranged)? \s
				.*?  # non-greedy extra stuff for SBV5120E
				Power(\s Level)?\s ([\d.-]+)\s (dBmV)
			}xi) {
		$self->{channel} = $1;
		$self->{upFreq} = $2;
		$self->{upFreqUnit} = $3;
		$self->{upPower} = $6;
		$self->{upPowerUnit} = $7;
	}
	else {
		# default
		$self->{channel} = 0;
		$self->{upFreq} = 0;
		$self->{upFreqUnit} = 'Hz';
		$self->{upPower} = 0;
		$self->{upPowerUnit} = 'dBmV';
	}

	# $errstr should be blank by now
	$self->{errstr} = $errstr;
	return bless($self, ref ($class) || $class);
}

sub errstr {
	my $self = shift;
	return $self->{errstr} if Scalar::Util::blessed $self;
	return $errstr;
}

sub modelGroup { shift->{modelGroup} }

sub channel { shift->{channel} }

# up freq value + unit string
sub upFreqStr {
	my $self = shift;
	"$self->{upFreq} $self->{upFreqUnit}";
}
sub upFreq { shift->{upFreq} }

# down freq value + unit string
sub dnFreqStr {
	my $self = shift;
	"$self->{dnFreq} $self->{dnFreqUnit}";
}
sub dnFreq { shift->{dnFreq} }

# SNRatio value + unit string
sub SNRatioStr {
	my $self = shift;
	"$self->{SNRatio} $self->{SNRatioUnit}";
}
sub SNRatio { shift->{SNRatio} }

# compare SNRatio value with limits
sub SNRatioCheck { my $self = shift;
	my $level = $self->{SNRatio};
	return 'high' if $level > $self->{SNRatioMax};
	return 'low' if $level < $self->{SNRatioMin};
	return '';
}

# down power value + unit string
sub dnPowerStr {
	my $self = shift;
	"$self->{dnPower} $self->{dnPowerUnit}";
}
sub dnPower { shift->{dnPower} }

# compare downstream Power value with limits
sub dnPowerCheck { my $self = shift;
	my $level = $self->{dnPower};
	return 'high' if $level > $self->{dnPowerMax};
	return 'low' if $level < $self->{dnPowerMin};
	return '';
}

# up power value + unit string
sub upPowerStr {
	my $self = shift;
	"$self->{upPower} $self->{upPowerUnit}";
}
sub upPower { shift->{upPower} }

# compare upstream Power value with limits
sub upPowerCheck { my $self = shift;
	my $level = $self->{upPower};
	return 'high' if $level > $self->{upPowerMax};
	return 'low' if $level < $self->{upPowerMin};
	return '';
}

# connect to the modem and retrieve the page in $path
sub pageRef { my $self = shift;
	# if the ip connect failed once, there's no point trying again
	return undef if $errfatal;

	my $path = shift;
	if (!$path) {
		$errstr = 'No page path';
		return undef;
	}
	# remember model group (future enhancement)
	my $model_group = shift || $self->{modelGroup} || '';

	my $modem_ip = shift || $self->{modemIP};
	if (!$modem_ip) {
		$errstr = 'No modem IP';
		return undef;
	}

	my $buf;

	# open a tcp socket to the modem
	socket(MODEM, PF_INET, SOCK_STREAM, getprotobyname('tcp'));

	# connect with timeout
	my $timeout_failed = 1;
	eval {
		# set a signal to die if the timeout is reached
		local $SIG{ALRM} = sub { die "alarm\n" };
		# modem response should be quick!
		alarm 1; # 1 second
		connect(MODEM, sockaddr_in(80, inet_aton($modem_ip)))
			or $errfatal++;
		alarm 0;
		$errstr = "Couldn't connect to $modem_ip:80 : $!"
			if $errfatal;
		$timeout_failed = 0;
	};
	alarm 0; # prevent race condition

	# error in connect
	return undef if $errfatal;

	# connect timeout
	if ($timeout_failed) {
		close(MODEM);
		$errfatal++;
		$errstr = "Couldn't connect to $modem_ip:80 : Socket Timeout";
		return undef;
	}


	# enable command buffering (autoflush)
	select((select(MODEM), $| = 1)[0]);

	# send the page request with timeout
	$timeout_failed = 1;
	eval {
		local $SIG{ALRM} = sub { die "alarm\n" };
		alarm 1; # 1 second
		print MODEM join("\015\012",
							"GET $path HTTP/1.0",
#							"GET $path HTTP/1.1",
							"Host: $modem_ip",
							"User-Agent: ". __PACKAGE__ ."/$VERSION",
#							"User-Agent: Cable-Modem/$VERSION",
#							"From: root\@localhost",
							"", "");
		alarm 0;
		$timeout_failed = 0;
	};
	alarm 0; # prevent race condition
	if ($timeout_failed) {
		close(MODEM);
		$errstr = "Couldn't send to $modem_ip:80 : Socket Timeout";
		return undef;
	}

	# get the page results with timeout
	$timeout_failed = 1;
	eval {
		local $/; # slurp the page
		undef $/;
		# set a signal to die if the timeout is reached
		local $SIG{ALRM} = sub { die "alarm\n" };
		alarm 1; # 1 second
		$buf = <MODEM>;
		alarm 0;
		$timeout_failed = 0;
	};
	alarm 0; # prevent race condition
	if ($timeout_failed) {
		close(MODEM);
		$errstr = "Couldn't get from $modem_ip:80 : Socket Timeout";
		return undef;
	}

	if ($buf =~ m,^HTTP/\d+\.\d+\s+(\d+)[^\012]*\012,) {
		my $code = $1;

		# we don't handle redirects
		if ($code !~ /^2/) {
			$errstr = "Bad page code $code";
			return undef;
		}

		$errstr = ''; # clear the error message
		$buf =~ s/.+?\015?\012\015?\012//s;  # zap header
		$self->{modelGroup} = $model_group;
		return \$buf;
	}

	$errstr = "Unknown page response";
	return undef;
}


#################### main pod documentation begin ###################

=head1 NAME

Device::CableModem::SURFboard - Get info from a Motorola 'SURFboard'

=head1 SYNOPSYS

    use Device::CableModem::SURFboard;
    my $modem = Device::CableModem::SURFboard->new
        or die Device::CableModem::SURFboard->errstr;

    # print upstream power range check
    print $modem->upPowerStr . ' ' . $modem->upPowerCheck;

    # print downstream power range check
    print $modem->dnPowerStr . ' ' . $modem->dnPowerCheck;

    # print Signal/Noise range check
    print $modem->SNRatioStr . ' ' . $modem->SNRatioCheck;

=head1 DESCRIPTION

The Motorola 'SURFboard' cable modem includes a built in web interface
that contains useful information like signal to noise ratios and power
levels.  These values can be used to aid in trouble shooting modem
connection problems, or monitoring the health of the modem or cable
connection.

C<Device::CableModem::SURFboard> connects to several different models
of 'SURFboard' modems (currently confirmed: SB4100, SB4200, SB5100,
SB5100E, SB5101, SBV5120E), scraping the status page for the most
useful information regarding cable line condition.

=head2 CREATING A NEW MODEM OBJECT

    $modem = Device::CableModem::SURFboard->new();

This will create a new modem object using default values.  You can
also initialize the modem object from an associative array reference:

    $modem = Device::CableModem::SURFboard->new(
        dnPowerMax => 16,
        dnPowerMin => -16,
        upPowerMax => 54,
        upPowerMin => 36,
        SNRatioMax => 100,
        SNRatioMin => 0,
        modemIP => '192.168.100.1',
        loginUsername => 'admin',
        loginPassword => 'motorola');

The above example also demonstrates all of the configurable options
with their defaults.

=head1 METHODS

=over 2

=item errstr()

Returns the last error message (or empty).  Currently this isn't much
use as a method as only pageRef() (used internally) will generate
errors.  errstr() can also be called directly to determine why a
new() method failed.

=item modelGroup()

Returns the model group found.  Different models of SURFboard modems
have different URL/page layouts.  These can be grouped into similar
model groups that share the same basic layout.  When a new modem
object is created, modelGroup will be set according to the first
successful status page retrieved.

=item channel()

Returns the up stream channel id (number).

=item upFreq()

Returns the up stream frequency value (Hz) as a simple number.

=item upFreqStr()

Returns the up stream frequency value as a text string with the unit
description attached.  For example "25250000 Hz".

=item dnFreq()

Returns the down stream frequency value (Hz) as a simple number.

=item dnFreqStr()

Returns the down stream frequency value as a text string with the
unit description attached.  For example "477000000 Hz".

=item SNRatio()

Returns the down stream Signal to Noise ratio value (dB) as a simple
number.

=item SNRatioStr()

Returns the down stream Signal to Noise ratio value as a text string
with the unit description attached.  For example "40.5 dB".

=item SNRatioCheck()

Checks the current down stream Signal to Noise ratio against pre-
defined max/min limits and returns either "high", "low" or blank.
The pre-defined max/min (default 100/0) can be also be set with
the SNRatioMax/SNRatioMin parameters when the object is created.

=item dnPower()

Returns the down stream power value (dBmV) as a simple number.

=item dnPowerStr()

Returns the down stream power value as a text string with the
unit description attached.  For example "7.3 dBmV".

=item dnPowerCheck()

Checks the current down stream power against pre-defined max/min
limits and returns either "high", "low" or blank.  The pre-defined
max/min (default 16/-16) can be also be set with the
dnPowerMax/dnPowerMin parameters when the object is created.

=item upPower()

Returns the up stream power value (dBmV) as a simple number.

=item upPowerStr()

Returns the up stream power value as a text string with the
unit description attached.  For example "49.5 dBmV".

=item upPowerCheck()

Checks the current up stream power against pre-defined max/min
limits and returns either "high", "low" or blank.  The pre-defined
max/min (default 54/36) can be also be set with the
upPowerMax/upPowerMin parameters when the object is created.

=item pageRef()

Takes a URL path, optional modem group id and optional IP address to
read a page from the modem.  pageRef() is used internally to get the
signal information page.  It could also be used for grabbing other
information pages from modems.  A valid page request returns a reference
to a string containing the page contents.  A page request failure will
return undefined (call errstr() to find out why).

=back

=head1 SUPPORT

This script was developed and tested on a Motorla SURFboard cable modem.
(Models: SB4100, SB4200, SB5100, SB5100E, SB5101, SBV5120E).

It may work on other Motorla modems, but likely will not.  If you have
a different cable modem that works, or you would like to have work,
please let me know.

=head1 AUTHOR

    Scott Mazur
    CPAN ID: RUZAM
    littlefish.ca
    scott@littlefish.ca
    http://littlefish.ca

=head1 COPYRIGHT

copyright(C) 2007 Scott Mazur, all rights reserved.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

perl(1).

=cut

#################### main pod documentation end ###################


1;
# The preceding line will help the module return a true value
