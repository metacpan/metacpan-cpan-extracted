use strict;
use warnings;

use ExtUtils::MakeMaker;
use IO::Handle ();

my $is_windows = ($^O eq 'MSWin32')? 1: 0;

my %WriteMakefileArgs = (
  'ABSTRACT_FROM' => 'lib/Device/Modem.pm',
  'AUTHOR' => 'Cosimo Streppone <cosimo@cpan.org>',
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "Device-Modem",
  "LICENSE" => "perl",
  'META_MERGE'    => {
    resources => {
      repository => 'git://github.com/cosimo/perl5-device-modem.git',
      bugtracker => 'mailto:bug-device-modem@rt.cpan.org',
      license    => 'http://dev.perl.org/licenses/',
    },
  },
  "MIN_PERL_VERSION" => "5.006",
  "NAME" => "Device::Modem",
  "PREREQ_PM" => {
    "Carp" => 0,
    "Exporter" => 0,
    "File::Basename" => 0,
    "File::Path" => 0,
    "IO::Handle" => 0,
    "Sys::Syslog" => 0,
    "base" => 0,
    "constant" => 0,
    "overload" => 0,
    "strict" => 0,
  },
  "TEST_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0,
    "File::Spec" => 0,
    "Test::More" => "0",
    "warnings" => 0,
  },
  'VERSION_FROM'    => 'lib/Device/Modem.pm',
  "test" => {
    "TESTS" => "t/*.t"
  }
);

my %FallbackPrereqs = (
  "Carp" => 0,
  "Exporter" => 0,
  "ExtUtils::MakeMaker" => 0,
  "File::Basename" => 0,
  "File::Path" => 0,
  "IO::Handle" => 0,
  "Sys::Syslog" => 0,
  "Test::More" => "0.88",
  "Tie::Handle" => 0,
  "base" => 0,
  "constant" => 0,
  "strict" => 0,
  "overload" => 0,
  "warnings" => 0
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

if ( $is_windows ) {
    $WriteMakefileArgs{PREREQ_PM}{'Win32::SerialPort'} = '0';
}
else {
    $WriteMakefileArgs{PREREQ_PM}{'Device::SerialPort'} = '0';
}

WriteMakefile(%WriteMakefileArgs);

#print "\n\n", '-' x 60, "\n", ' ' x 20, 'Device::Modem setup', "\n", '-' x 60, "\n\n";
#
# my %config = configure();
#
sub configure {
    # Modem setup
    my $default = 'n'; # default = no modem
    my $port;
    my %conf;

    do {

        print <<HELP;

* Modem configuration

  Do you have a modem connected to one of your serial ports ?
  Please choose one:

  n) no modem. Tests will not access serial port    *DEFAULT*
HELP

        print "  0) (zero). Modem is connected to [/dev/ttyS0]\n" unless ($is_windows);

        for( 1 .. 4 ) {
            print "  $_) Modem is connected to ", $is_windows ? 'COM' : '/dev/ttyS', $_, "\n";
        }

        print "  m) Modem is connected to [/dev/modem]\n" unless ($is_windows);

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
        $conf{'port'} = $is_windows ? 'COM%d' : '/dev/ttyS%d';
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
    open my $cnf, '>', '.config.pm' or return %conf;

    print {$cnf} "# Device::Modem setup parameters\n# \$Id: Makefile.PL,v 1.6 2005-04-30 21:45:47 cosimo Exp $\n\n";
    for my $key (sort keys %conf) {
        print {$cnf} "\$Device::Modem::$_ = '$conf{$_}';\n";
    }
    print {$cnf} "\n1;\n\n";
    return %conf;
}
