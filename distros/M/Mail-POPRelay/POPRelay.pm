package Mail::POPRelay;

use strict;
use Mail::Object;
use vars qw[$VERSION @ISA ];

use constant PRESERVE_MESSAGE => "# Above configuration will be preserved by POPRelay.\n";

$VERSION = '2.1.1';
@ISA     = qw[Mail::Object ];

$Mail::POPRelay::DEBUG = 0;


# check any given hash for existence of certain keys
# ---------
sub __initTest {
	my $self   = shift;
	my %qaTest = %{; shift};

	foreach (keys %qaTest) {
		die sprintf "%s was not specified.\n", $qaTest{$_} unless defined $self->{$_};
	}
	return $self;
}


# ---------
sub initWithConfigFile {
	my $configFileName = splice(@_, 1, 1);

	die "Missing argument config-file." unless $configFileName;
	die "$configFileName: No such file exists." unless -f $configFileName;

	# slurp config file
	undef $/;
	open CONFIG, $configFileName or die "Unable to open config-file $configFileName: $!";
	my $configFile = <CONFIG>;
	close CONFIG;
	$/ = "\n"; # disable slurp mode
	
	# create a hash from the config file
	my $options;
	$configFile =~ s,(.*?=)([\s\t]*)(.*),$1>$2'$3'\,,g;
	eval "\$options = { $configFile };";
	die "Corrupted config-file $configFileName: $@" if $@;

	# store config file used
	$_[0]->addAttributeWithValue('configFile', $configFileName) 
		unless $_[0]->respondsTo('configFile');
	
	# initialize a POPRelay subclass w/ config file hash
	return Mail::POPRelay::init(@_, $options);
}


# ---------
sub init {
	# call proper init if necessary
	return Mail::POPRelay::initWithConfigFile(@_) unless ref $_[1];

	my $myDefaults = {
		mailLogFile               => '/var/log/maillog',
		mailProgram               => 'sendmail',
		mailProgramRestart        => 0,
		mailProgramRestartCommand => '/etc/init.d/%m restart',
		mailRelayIsDatabase       => 0,
		mailRelayDatabaseCommand  => '/usr/sbin/makemap hash %r < %r',
		mailRelayDirectory        => '/var/spool/poprelay',
	};
	splice(@_, 2, 0, splice(@_, 1, 1, $myDefaults));
	my $self = Mail::Object::init(@_);
	
	my %qualityAssurance = (
		mailLogFile         => 'Mail log file',
		mailProgram         => 'Mail program',
		mailRelayDirectory  => 'Mail relay directory',
		mailRelayFile       => 'Mail relay file',
		mailRelayPeriod     => 'Mail relay period',
		mailRelayFileFormat => 'Mail relay file format',
	);
	$self->__initTest(\%qualityAssurance);

	$self->addAttribute('relayPreserve') unless
		$self->respondsTo('relayPreserve');

	# parse special option variables
	foreach ($self->{'mailRelayFileFormat'}, $self->{'mailProgramRestartCommand'}, $self->{'mailRelayDatabaseCommand'}) {
		s,%m,$self->{'mailProgram'},gi;
		s,%r,$self->{'mailRelayFile'},gi;
	}

	$self->__createRelayDirectory()
		unless (-d $self->{'mailRelayDirectory'});

	return $self;
}


# ---------
sub restartMailProgram {
	my $self = shift;

	$self->{'mailProgramRestartCommand'} =~ s,%m,$self->{'mailProgram'},ig;

	print "o Restarting mail program: $self->{'mailProgramRestartCommand'}" 
		if $Mail::POPRelay::DEBUG;
	return `$self->{'mailProgramRestartCommand'}`;
}


# purge all relay address files in spool
# ---------
sub wipeRelayDirectory {
	my $self = shift;

	print "o Wiping relay directory\n" if $Mail::POPRelay::DEBUG;
	my $mailRelayDirectory = $self->{'mailRelayDirectory'};
	foreach (<$mailRelayDirectory/*>) {
		unlink($_) or die "Unable to remove $_: $!";
	}
	return $self;
}


# purge only expired relay address files in spool
# ---------
sub cleanRelayDirectory {
	my $self = shift;

	print "o Cleaning relay directory\n" if $Mail::POPRelay::DEBUG;
	my($mailRelayDirectory, @purgeCount) = ($self->{'mailRelayDirectory'}, 0);
	foreach (<$mailRelayDirectory/*>) {
		chomp();
		my $modifyTime = (stat("$_"))[8] or die "Unable to stat $_: $!";

		if (time > ($modifyTime + $self->{'mailRelayPeriod'})) {
			printf "\t`- removing %s (%d - %d < %d)\n", $_, time, ($modifyTime + $self->{'mailRelayDirectory'}, $self->{'mailRelayPeriod'}) if $Mail::POPRelay::DEBUG;
			unlink($_) or die "Unable to unlink $_: $!";
			push @purgeCount, $_;
		}
	}
	return wantarray ? @purgeCount : scalar @purgeCount;
}


# add relay address file to spool
# ---------
sub addRelayAddress {
	my $self          = shift;
	my $userName      = shift;
	my $userIpAddress = shift;

	if (!-e "$self->{'mailRelayDirectory'}/$userIpAddress") {
		open(OUT, ">$self->{'mailRelayDirectory'}/$userIpAddress") or die "Unable to open $self->{'mailRelayDirectory'}/$userIpAddress: $!";
		print OUT $userName;
		close(OUT);
		return $self;
	}

	return 0;
}


# ---------
sub __generatePreserveList {
	my $self = shift;

	my @preserveList;
	my $mailRelayFile = $self->{'mailRelayFile'};
	open(PACCESS, "<$mailRelayFile") or die "Unable to open $mailRelayFile: $!";
	while (<PACCESS>) {
		last if $_ eq PRESERVE_MESSAGE;
		push @preserveList, $_;
	}
	close(PACCESS);
	return join('', @preserveList);
}


# ---------
sub __createRelayDirectory {
	my $self = shift;

	die "Unable to create mail relay directory: $!" unless
		mkdir($self->{'mailRelayDirectory'}, 0027);

	return $self;
}


# write out entire relaying file
# ---------
sub generateRelayFile {
	my $self = shift;

	my @relayArray;
	my $mailRelayDirectory = $self->{'mailRelayDirectory'};
	
	$self->__createRelayDirectory()
		unless (-d $self->{'mailRelayDirectory'});

	# build relay list
	my $entry;
	print "o Building the relay file\n" if $Mail::POPRelay::DEBUG;
	foreach (<$mailRelayDirectory/*>) {
		s,.*/([\d\.]+)$,$1,;
		print "\t`- adding $_\n" if $Mail::POPRelay::DEBUG;
		$entry = $self->{'mailRelayFileFormat'};
		$entry =~ s,%i,$_,g;
		push @relayArray, $entry;
	}

	# recreate preserve list incase of change
	$self->{'relayPreserve'} = $self->__generatePreserveList();

	my $mailRelayFile = $self->{'mailRelayFile'};
	open(RACCESS, ">$mailRelayFile") or die "Unable to open $mailRelayFile: $!";
	print RACCESS $self->{'relayPreserve'}, PRESERVE_MESSAGE, join("\n", @relayArray);
	close RACCESS;

	# generate relay database if needed
	if ($self->{'mailRelayIsDatabase'}) {
		print "o Generating relay database\n" if $Mail::POPRelay::DEBUG;
		warn "Error generating relay database with command: $self->{'mailRelayDatabaseCommand'}\n" if
			system($self->{'mailRelayDatabaseCommand'});
	}

	# restart mail server if needed 
	if ($self->{'mailProgramRestart'}) {
		sleep(3);
		print "o Restarting mail daemon\n" if $Mail::POPRelay::DEBUG;
		$self->restartMailProgram();
	}
	return $self;
}


1337;


__END__

=cut

=head1 NAME

Mail::POPRelay - Dynamic Relay Access Control


=head1 DESCRIPTION

Mail::POPRelay is designed as a framework to support
relaying through many different types of POP and email
servers. This software is useful for mobile users and is fully
compatible with virtual domains.

One of the main differences between this software and others is that
neither modification of the POP server or mail program is needed.
Mail::POPRelay should integrate seamlessly with any server given the 
correct agent and configuration are used.

Agents are executables that provide support for various POP servers.  
Each agent possesses the ability to call functions from the Mail::POPRelay 
framework, load configuration files and do whatever else is necessary to support
dynamic relaying.

Configuration files allow the user (you) to specify options that are read by
an agent.  These options inform the agent how to work with a server's configuration.
Following is a list of available options and their descriptions:



=over 8

=item mailLogFile           

Absolute location of the mail log file to watch for incoming logins.
Defaulted to '/var/log/maillog'.

=item mailProgram

Set to the mail program service name.  This option's value will be replaced with the
special %m variable that can be used where specified.
Defaulted to 'sendmail'.

=item mailProgramRestart

Set to '1' if the mail server must be restarted after modifying the relay file.
This shouldn't be necessary if using an access database style relay file.
Defaulted to '0'.

=item mailProgramRestartCommand

Set to the command required for restarting your email server.  
Special variables %m and %r can be used in this string.
Defaulted to '/etc/init.d/%m restart'.

=item mailRelayIsDatabase

Set accordingly if your mail relay file is a database.
Defaulted to '0'.

=item makemapLocation

Usage is deprecated.  Reference mailRelayDatabaseCommand.

=item mailRelayDatabaseType

Usage is deprecated.  Reference mailRelayDatabaseCommand.

=item mailRelayDatabaseCommand

Set to the command required for creating the relay database.
Special variables %m and %r can be used in this string.
Defaulted to '/usr/sbin/makemap hash %r < %r'.

=item mailRelayDirectory

Absolute location of the spool directory used to create relay tracking files.
Defaulted to '/var/spool/poprelay'.

=item mailRelayFile

Absolute location of the mail access relay file.  This option's value will be replaced with the
special %r variable that can be used where specified.
No default value.

=item mailRelayFileFormat

Set to the format of your relay file.  Special variables %m, %r and %i may be used in this string.
%i is replaced with the current IP address allow relaying access.
Defaulted to '%i RELAY' if mail relay file is set to '1' or '%i' if not.

=item mailRelayPeriod

After a user successfully logs in we must set a period for
which he/she can relay mail.  Specify this value in seconds.
No default value.

=back

Use the SYNOPSIS to help create your own agents and configuration files.


=head1 FLOW

=item 1 An agent is executed with a configuration file

=item 2 The mailLogFile is monitored for instances of mailLogRegExp (loop)

=item 3 A "mailRelayDirectory/(authenticated IP)" file is created if an instance is found

=item 4 The mailRelayFile is updated based off the mailRelayDirectory spool

=item 5 The mailRelayDatabaseCommand is executed if the mailRelayIsDatabase option is set

=item 6 The mailProgramRestartCommand is executed if the mailProgramRestart option is set

	
Note:  The config-file is reloaded when the agent receives a HUP signal.
	

=head1 SYNOPSIS


=head2 Creating Custom Agents

=item o Create a file in the ./bin directory for your agent

=item o Copy this header into your agent file:

	----- BEGIN HEADER -----
	use strict;
	use Mail::POPRelay;
	use vars qw[@ISA ];

	# Mail::POPRelay is designed to be subclassed.
	@ISA = qw[Mail::POPRelay ];
	----- END HEADER -----

=over 8

=item o Create a regular expression 

This is done to match user authentication log entries for the POP server you're adding 
support and is necessary for dynamic relaying.  The regular expression must place the 
authenticating user name in $1 and IP address in $2.  Monitor the mailLogFile for
incoming user authentication entries if unsure about its format.

=back

=item o Use this conventional template to instantiate Mail::POPRelay

	----- BEGIN TEMPLATE -----
	my $popDaemon = new Mail::POPRelay::Daemon(
		$ARGV[0], # config-file to use
		{ mailLogRegExp    => 'a regular expression', 
		  overridingOption => 'a value',
		}
	};
	----- END TEMPLATE -----

=over 8

=item o Overriding options

Any options specified as parameters to Mail::POPRelay::Daemon will override those
in the config-file.

=item o Calling additional methods

It is possible to call other methods from the POPRelay class in your agent.
Reference the METHODS section below.

	

=head2 Creating Custom Configuration Files

=item o Create a file in the ./conf directory for your configuration

=item o Specify one option and value per line

Each line is in the format "optionName = value".  Comment lines begin with a # symbol.
Reference the DESCRIPTION section above for a complete list of options and their meanings.


=back


=head1 METHODS

=over 8

=item $popRelay->wipeRelayDirectory();

Remove all relay access files in the spool (mailRelayDirectory).

=item $popRelay->cleanRelayDirectory();

Remove expired access files in the spool (mailRelayDirectory).

=item $popRelay->generateRelayFile();

Create and write out a relay file based from the access files 
in the spool (mailRelayDirectory).  An attempt to create the spool 
directory will be made if it doesn't already exist.  This method now 
also handles restarting the mail program and/or creating the access 
database file if necessary.

=item $popRelay->restartMailProgram();

Use is deprecated.  Not absolutely necessary anymore.  Read above.

=item $popRelay->addRelayAddress('User Name', 'IP Address')

Adds a relay access file to the spool (mailRelayDirectory).

=back


=head1 DIAGNOSTICS

die().  Will write to syslog eventually.


=head1 CONTRIBUTIONS

=over 8

=item John Beppu <beppu@lbox.org>

Found a bug in the signal handlers.  Thanks for looking over my code ;)

=item Jefferson S. M <linuxman@trendservices.com.br>

Verified and tested the ipop3d_vpopd agent.

=item Dave Doeppel <dave@hyperburn.com>

Verified and tested integration with the Exim mailer.

=item Fuat Gozetepe <turk@lbox.org>

Verified and tested integration with Slackware.

=item Mike Polek <mike@pictage.com>

Found a race condition in Daemon.pm where relaying information could have
been lost.

=item Sven-Oliver Stietzel <dev@netshake.de>

Added a config file for Suse Linux and Qpopper agent.

=back

=head1 AUTHOR

Keith Hoerling <keith@hoerling.com>


=head1 SEE ALSO

Mail::POPRelay::Daemon(3pm), poprelay_cleanup(1p), poprelay_ipop3d(1p).

=cut

# $Id: POPRelay.pm,v 1.3 2002/08/20 01:26:35 keith Exp $
