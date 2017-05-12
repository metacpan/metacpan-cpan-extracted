# CVS: $Id: IO.pm,v 1.5 2002/04/20 07:29:23 michael Exp $

package Device::WS2000::IO;

require 5.005_62;
use strict;
use warnings;
use Carp;

require Exporter;
require DynaLoader;
use AutoLoader;

our @ISA = qw(Exporter DynaLoader);

our %EXPORT_TAGS = ( 'all' => [ qw(open_ws close_ws send_ws read_ws _called)	
 ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw( 
);

our $VERSION = '0.01';

bootstrap Device::WS2000::IO $VERSION;

my $DEBUG = 0;

# Preloaded methods go here.

sub _called(@) {
  return unless $DEBUG > 0;
  my $args = join(',',@_);
  printf ("%s(%s)\n", (caller(1))[3],$args);
}

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.  If a constant is not found then control is passed
    # to the AUTOLOAD in AutoLoader.
  _called(@_);

    my $constname;
    our $AUTOLOAD;

    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "& not defined" if $constname eq 'constant';
    my $val = constant($constname, @_ ? $_[0] : 0);
    if ($! != 0) {
	if ($! =~ /Invalid/ || $!{EINVAL}) {
	    $AutoLoader::AUTOLOAD = $AUTOLOAD;
	    goto &AutoLoader::AUTOLOAD;
	}
	else {
	    croak "Your vendor has not defined ws2000 macro $constname";
	}
    }
    {
	no strict 'refs';
	# Fixed between 5.005_53 and 5.005_61
	if ($] >= 5.00561) {
	    *$AUTOLOAD = sub () { $val };
	}
	else {
	    *$AUTOLOAD = sub { $val };
	}
    }
    goto &$AUTOLOAD;
}

my $fdescr;
our @buffer;

sub open_ws {
  _called(@_);
  my ($port) = @_;
  $fdescr = open_port($port);
  if ($fdescr != -1) {
    my ($buf,$nread) = ("",0);
    open(TTY, "<&=$fdescr");
# WS2000 needs  DTR change from Low to High
    clr_dtr($fdescr);
#    sleep(1);
    set_dtr($fdescr);
# WS2000 reponses with a ETX if ready
    sleep(1);
    $nread = sysread (TTY,$buf,1);
    print "Got $nread chars\n" if $DEBUG;
    if ($nread == 1 and ord($buf) == 3) {
      return 1;
    }
    else {
      close (TTY);
      close_port($fdescr);
    }
  }
  return 0;
}

# send_ws wrapper for the C-funktion
sub send_ws {
  _called(@_);
  my ($cmd,$par) = @_;
  send_command($fdescr,$cmd,$par);
}


sub read_ws {
  _called(@_);
  my ($len,$nread,$buffer,$buf,$length);
  $len = 255;
  $buffer=$buf="";
  $length=0;
  $nread = sysread (TTY,$buf,$len);
  while ($nread) {
    $length += $nread;
    $buffer.=$buf;
    $nread = sysread(TTY,$buf,$len);
  }

  $buffer.=$buf;
  print join(" ",unpack("C$length",$buffer)),"\n" if $DEBUG;
  my $tmp;
  $tmp = substr($buffer,0,1);
  return undef unless ord($tmp) == 2;
  $tmp = substr($buffer,length($buffer)-1);
  return undef unless ord($tmp) == 3;

  $buffer = substr($buffer,1,length($buffer)-2);

  print join(" ",unpack("C$length",$buffer)),"\n" if $DEBUG;
  $buffer=~s/\x05\x12/\x02/g;
  print join(" ",unpack("C$length",$buffer)),"\n" if $DEBUG;
  $buffer=~s/\x05\x13/\x03/g;
  print join(" ",unpack("C$length",$buffer)),"\n" if $DEBUG;
  $buffer=~s/\x05\x15/\x05/g;
  print join(" ",unpack("C$length",$buffer)),"\n" if $DEBUG;

  $len = ord(substr($buffer,0,1));
  $buffer = substr($buffer,1,length($buffer)-2);

  unless (length($buffer) == $len) {
    print STDERR "incorrect length ",length($buffer),"should be $len\n";
    return undef;
  }
  @buffer = unpack("C$len",$buffer);
  print join(" ",@buffer),"\n" if $DEBUG;
  print "END read_ws\n" if $DEBUG;
  return (@buffer);
}

sub close_ws {
  _called(@_);
  clr_dtr($fdescr);
  close (TTY);
  close_port($fdescr);
}


# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__


=head1 NAME

Device::WS2000::IO - Perl extension for reading data from the ELV Weatherstation WS2000 PC

=head1 SYNOPSIS

  use Device::WS2000::IO qw (:all);
  $ok=open_ws("ttyS0");
  send_ws($command,$parameter);
  @buffer = read_ws();
  close_ws();

=head1 DESCRIPTION

This module contains lowlevel-routines for the communication with the ELV Weatherstation
WS2000 PC connected to a serial port.

Following functions are implemented:

open_ws ($port)     opens the serial port and checks initial response, 
                    returns 1 on success, 0 on failure

send_ws ($cmd,$par) send a command to the WS2000
                    Legal commands are:
                    0  read DCF-Time
                    1  read one datablock
                    2  next datablock
                    3  nine sensors
                    4  16 sensors
                    5  get status
                    6  uses parameter: set poll interval 
                       1 - 60 minutes

read_ws             read response from WS2000
                    returns read buffer 
                            length is checked
                            envelope is removed 
                            checksum is not yet checked 
                            (blame on me)

close_ws            closes the serial port


=head2 EXPORT

None by default.

Tag :all
open_ws close_ws send_ws read_ws


=head1 SEE ALSO

perl(1).

=head1 Thanks

My thanks go out to Friedrich Zabel for the C-Code used for the low-level functions,
taken from his project wx2000 at http://wx2000.sourceforge.net/

To the opensource comunity in general which time and again show that
sharing / modifying code and returning it to all users actualy works.

=head1 AUTHOR

Michael Böker <mmbk@cpan.org>

=head1 Copyright

Copyright (c) 2002 by Michael Böker. All rights reserved. This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself. 

=cut
