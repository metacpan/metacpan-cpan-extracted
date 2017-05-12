use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

my @SERIALS;

# Scan for argument we know about
my @passargs;
if (@ARGV) {
	foreach my $arg (@ARGV) {
		my ($key,$value)=split /=/, $arg, 2;
		if ($key eq "TESTPORT") {
			push(@SERIALS,$value);
		}
		else {
			push(@passargs,$arg);
		}
	}
}
@ARGV=@passargs;


# First, we need to figure out a default serial port to use for
# testing.
if (scalar(@SERIALS)>0 && $SERIALS[0] eq "auto") {
	print "Trying to find a serial port for testing...\n";
	@SERIALS=( "/dev/ttyS1", "/dev/cua01", "/dev/cua/b", "/dev/tty1",
		   "/dev/tty.modem" );
	print "(use 'perl Makefile.PL TESTPORT=<DEVICE>' to override this search)\n";
}

if (scalar(@SERIALS)<1) {
	print "To enable serial port tests, use:\n";
	print "\tperl Makefile.PL TESTPORT=<DEVICE>\n";
	print "where <DEVICE> is a specific port or 'auto' to autodetect.\n";
	unlink("t/DefaultPort.pm");
}
else {
  my $file=undef;
  my $test;
  foreach $test (@SERIALS) {
    print "\tchecking '$test' ... ";
    lstat($test);
    if (-e _) {
        if (-l _) {
	    my $sunserial=readlink($test);
	    $sunserial="/dev/$sunserial" unless ($sunserial =~ m#^/#);
	    stat($sunserial);
	    if (-c _) {
	        print "link to character device\n";
	        if ($sunserial =~ m#/devices/#) {
	            # this is a sun serial device, check the type
	            my @paths=split('/',$sunserial);
		    my $serialtype="";
		    foreach my $part (@paths) {
	                if ($part =~ /^(zs|se)\@/) {
		            $serialtype=$1;
			    last;
                        }
                    }
		    if ($serialtype =~ /^zs/) {
		        &CheckEtcSystem("zs:default_dtrlow");
		    }
		    elsif ($serialtype =~ /^se/) {
		        warn "\nMake sure you have patch 105924-09 or better ".
		             "to handle your 'se' serial port.\n";
		        &CheckEtcSystem("se:se_default_dtrlow");
		    }
		    else {
		        warn "\nFound what seems to be a Sun serial device.\n".
		             "Its path is '$sunserial',\n".
		   	     "but is not a 'zs' or 'se' style serial device.\n".
			     "continuing anyway...\n";
		    }
		    $file=$test;
		    last;
	        }
	    }
	}
	# if we get here, it's either not a link, or not a link to a sun dev
	stat($test);
	if (-c _) {
	    print "character device\n";
	    $file=$test;
	    last;
	}
    }
    print "nope\n";
  }
  if (!defined($file)) {
    die "Could not find a serial port to use for testing.\n".
        "Please specify one on the 'perl Makefile.PL' command line, like so:\n".
	"\tperl Makefile.PL /dev/ttyS0\n";
  }
  my $dfile = "t/DefaultPort.pm";
  open (DEFAULT, "> $dfile") or die "Can't create $dfile: $!\n";
  print DEFAULT <<EOF;
package SerialJunk;
# Created by Makefile.PL

\$Makefile_Test_Port = "$file";
EOF

  close DEFAULT;

  print "\n";
  print "PLEASE NOTE:\n";
  print "If you run 'make test', you must make sure that nothing is plugged\n";
  print "into '$file'!\n";
}

# I may end up needing this to hint the configure script?
#use Config;
# 
#my $compiler = "$Config{'cc'} $Config{'ccflags'}";
#print "built by '$compiler'\n";

my %mm_args=(
    'NAME'          => 'Device::SerialPort',
    'VERSION_FROM'  => 'SerialPort.pm', # finds $VERSION
    'PREREQ_PM'     => {
				'Test::More' => 0,
			}, # e.g., Module::Name => 1.1
    'ABSTRACT_FROM' => 'SerialPort.pm', # retrieve abstract from module
    'AUTHOR'        => 'Kees Cook <kees@outflux.net>',
    'LIBS'          => [''], # e.g., '-lm'
    'EXE_FILES'     => ['modemtest'],
    'DEFINE'        => '', # e.g., '-DHAVE_SOMETHING'
    'INC'           => '-I.', # e.g., '-I. -I/usr/include/other'
    'clean'         => { 'FILES' => "config.h t/DefaultPort.pm *.cfg t/*.cfg" },
    'realclean'     => { 'FILES' => "config.h config.log config.status" },
);

# Prepare config.h
print "Running ./configure ...\n";
system("./configure");
if ($? != 0) {
        die <<EOM;
The 'configure' script didn't like something.  It should have told you
what went wrong, but you can check 'config.log' for more details.
EOM
}

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(%mm_args);

print "\nYou're ready to run 'make' now...\n";

sub CheckEtcSystem {
    my $setting=shift;

    if (! -f "/etc/system") {
	warn "Hey, where is your '/etc/system' file?  We need to check\n".
	     "and make sure your '$setting' settings are correct\n".
	     "since it looks like you have a Sun serial port\n";
	return;
    }

    open(SYSTEM,"</etc/system") || die "Ack!  Can't read '/etc/system': $!\n";
    my @lines=<SYSTEM>;
    close(SYSTEM);

    my $found=0;
    foreach my $line (@lines) {
	chomp($line);
	next if ($line !~ /^set/);
	next if ($line !~ /$setting/);

	my @parts=split(/\s*=\s*/,$line,2);
	my $value=$parts[1];
	$value=~s/\s*$//;
	if ($value != 0) {
	    warn "\nYour '$setting' in '/etc/system' is not '0'.  This will\n".
		 "break several of the Device::SerialPort tests, and cause\n".
		 "longer delays when working with the DTR functions.\n";
	}
	else {
	    $found=1;
	}
    }
    if ($found != 1) {
	warn "\n***** WARNING *****\n".
             "You don't have a '$setting' line in '/etc/system'.\n".
	     "you might need to add:\n".
	     "\tset $setting = 0\n".
             "to '/etc/system', or else Device::SerialPort's DTR functions\n".
	     "will not work properly.\n".
	     "\nHopefully, you'll be lucky (PCI? fully patched Solaris 8?)".
	     "\nand you won't need to make this change.  See what 'make test' says.\n".
	     "\n*** Please read the 'SOLARIS TROUBLE' section of the README\n";
    }
    else {
        print "\tOh good, your '/etc/system' contains '$setting = 0'!\n";
    }
}

