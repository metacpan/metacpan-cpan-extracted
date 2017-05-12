# $Id: Makefile.PL,v 1.6 2005-04-30 21:45:47 cosimo Exp $
use ExtUtils::MakeMaker;

#print "\n\n", '-' x 60, "\n", ' ' x 20, 'Device::Modem setup', "\n", '-' x 60, "\n\n";

my $is_windoze = index($^O, 'Win') >= 0;

#
# my %config = configure();
#

WriteMakefile(
	'AUTHOR'        => 'Cosimo Streppone <cosimo@cpan.org>',
	'ABSTRACT_FROM' => 'lib/Device/Modem.pm',
	'NAME'	        => 'Device::Modem',
	'VERSION_FROM'	=> 'lib/Device/Modem.pm',
	'PREREQ_PM'		=> $is_windoze
                       ? { 'Win32::SerialPort'   => 0 }
                       : { 'Device::SerialPort'  => 0 },
	'META_MERGE'    => {
		resources => {
			repository => 'git://github.com/cosimo/perl5-device-modem.git',
			bugtracker => 'mailto:bug-device-modem@rt.cpan.org',
			license    => 'http://dev.perl.org/licenses/',
		},
	},
);

sub configure {

	my $default;

	#
	# Modem setup
	#

	my $port;
	$default = 'n';   # default = no modem

	do {

		print <<HELP;

* Modem configuration

  Do you have a modem connected to one of your serial ports ?
  Please choose one:

  n) no modem. Tests will not access serial port    *DEFAULT*
HELP

		if( ! $is_windoze ) {
			print "  0) (zero). Modem is connected to [/dev/ttyS0]\n";
		}

		for( 1 .. 4 ) {
			print "  $_) Modem is connected to ", $is_windoze ? 'COM' : '/dev/ttyS', $_, "\n";
		}

		if( ! $is_windoze ) {
			print "  m) Modem is connected to [/dev/modem]\n";
		}

		print "\n? ";

		$port = <STDIN>;
		chomp $port;
		$port = lc substr $port, 0, 1;

		$port = $default unless defined $port;

	} until( index( '01234nm', $port ) != -1 );

	if( $port eq 'n' ) {
		$conf{'port'} = 'NONE';
	} elsif( $port eq 'm' ) {
		$conf{'port'} = '/dev/modem';
	} else {
		$conf{'port'} = $is_windoze ? 'COM%d' : '/dev/ttyS%d';
		$conf{'port'} = sprintf $conf{'port'}, $port;
	}

	$conf{'port'} = 'COM1' if $conf{'port'} eq 'COM0';

	#
	# Baud rate configuration
	#

	my $baud;
	$default = 4;   # default = 19200

	do {

		print <<HELP;

* Serial link speed

  Please choose one:

  1) 2400 baud
  2) 4800 baud
  3) 9600 baud
  4) 19200 baud    *DEFAULT*
  5) 38400 baud

HELP

		print "? ";
		$baud = <STDIN>; chomp $baud; $baud =~ s/\D//g;
		$baud ||= $default;

	} until( $baud >= 1 and $baud <= 5 );

	$conf{'baudrate'} = 2400 << ($baud - 1);

	print "\n- Selected $conf{'baudrate'} speed\n";


	# Write configuration file
	if( open CONF, '>.config.pm' ) {

		print CONF "# Device::Modem setup parameters\n# \$Id: Makefile.PL,v 1.6 2005-04-30 21:45:47 cosimo Exp $\n\n";

		foreach( sort keys %conf ) {
			print CONF "\$Device::Modem::$_ = '$conf{$_}';\n";
		}

		print CONF "\n1;\n\n";
		close CONF;

	}

	return %conf;

}


