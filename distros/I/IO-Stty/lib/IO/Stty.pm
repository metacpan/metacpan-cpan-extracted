package IO::Stty;

use strict;
use warnings;

use POSIX;

our $VERSION='0.04';

=head1 NAME

IO::Stty - Change and print terminal line settings

=head1 SYNOPSIS

    # calling the script directly
    stty.pl [setting...]
    stty.pl {-a,-g,-v,--version}
    
    # Calling Stty module
    use IO::Stty;
    IO::Stty::stty(\*TTYHANDLE, @modes);

     use IO::Stty;
     $old_mode=IO::Stty::stty(\*STDIN,'-g');

     # Turn off echoing.
     IO::Stty::stty(\*STDIN,'-echo');

     # Do whatever.. grab input maybe?
     $read_password = <>;

     # Now restore the old mode.
     IO::Stty::stty(\*STDIN,$old_mode);

     # What settings do we have anyway?
     print IO::Stty::stty(\*STDIN,'-a');

=head1 DESCRIPTION

This is the PERL POSIX compliant stty. 

=head1 INTRO

This has not been tailored to the IO::File stuff but will work with it as
indicated. Before you go futzing with term parameters it's a good idea to grab
the current settings and restore them when you finish.

stty accepts the following non-option arguments that change aspects of the
terminal line operation. A `[-]' before a capability means that it can be
turned off by preceding it with a `-'. 

=head1 stty parameters

=head2 Control settings

=over 4

=item [-]parenb

Generate parity bit in output and expect parity bit in input.

=item [-]parodd

Set odd parity (even with `-').

=item cs5 cs6 cs7 cs8

Set character size to 5, 6, 7, or 8 bits.

=item [-]hupcl [-]hup

Send a hangup signal when the last process closes the tty.

=item [-]cstopb

Use two stop bits per character (one with `-').

=item [-]cread

Allow input to be received.

=item [-]clocal

Disable modem control signals.

=back

=head2 Input settings

=over 4

=item [-]ignbrk

Ignore break characters.

=item [-]brkint

Breaks cause an interrupt signal.

=item [-]ignpar

Ignore characters with parity errors.

=item [-]parmrk

Mark parity errors (with a 255-0-character sequence).

=item [-]inpck

Enable input parity checking.

=item [-]istrip

Clear high (8th) bit of input characters.

=item [-]inlcr

Translate newline to carriage return.

=item [-]igncr

Ignore carriage return.

=item [-]icrnl

Translate carriage return to newline.

=item [-]ixon

Enable XON/XOFF flow control.

=item [-]ixoff

Enable sending of stop character when the system
input buffer is almost full, and start character
when it becomes almost empty again.

=back 

=head2 Output settings

=over 4

=item [-]opost

Postprocess output.

=back

=head2 Local settings

=over 4

=item [-]isig

Enable interrupt, quit, and suspend special characters.

=item [-]icanon

Enable erase, kill, werase, and rprnt special characters.

=item [-]echo

Echo input characters.

=item [-]echoe, [-]crterase

Echo erase characters as backspace-space-backspace.

=item [-]echok

Echo a newline after a kill character.

=item [-]echonl

Echo newline even if not echoing other characters.

=item [-]noflsh

Disable flushing after interrupt and quit special characters.

* Though this claims non-posixhood it is supported by the perl POSIX.pm.

=item [-]tostop (np)

Stop background jobs that try to write to the terminal.

=back

=head2 Combination settings

=over 4

=item ek

Reset the erase and kill special characters to their default values.

=item sane

Same as:

    cread -ignbrk brkint -inlcr -igncr icrnl -ixoff opost 
    isig icanon echo echoe echok -echonl -noflsh -tostop 

also sets all special characters to their default
values.

=item [-]cooked

Same as:

    brkint ignpar istrip icrnl ixon opost isig icanon

plus sets the eof and eol characters to their default values 
if they are the same as the min and time characters.
With `-', same as raw.

=item [-]raw

Same as:

    -ignbrk -brkint -ignpar -parmrk -inpck -istrip -inlcr -igncr
    -icrnl -ixon -ixoff -opost -isig -icanon min 1 time 0

With `-', same as cooked.

=item [-]pass8

Same as:

    -parenb -istrip cs8

With  `-',  same  as parenb istrip cs7.

=item dec

Same as:

    echoe echoctl echoke -ixany

Also sets the interrupt special character to Ctrl-C, erase to
Del, and kill to Ctrl-U.

=back

=head2 Special characters

The special characters' default values vary from system to
system. They are set with the syntax `name value', where
the names are listed below and the value can be given
either literally, in hat notation (`^c'), or as an integer
which may start with `0x' to indicate hexadecimal, `0' to
indicate octal, or any other digit to indicate decimal.
Giving a value of `^-' or `undef' disables that special
character.

=over 4

=item intr

Send an interrupt signal.

=item quit

Send a quit signal.

=item erase

Erase the last character typed.

=item kill

Erase the current line.

=item eof

Send an end of file (terminate the input).

=item eol

End the line.

=item start

Restart the output after stopping it.

=item stop

Stop the output.

=item susp

Send a terminal stop signal.

=back

=head2 Special settings

=over 4

=item min N

Set the minimum number of characters that will satisfy a read 
until the time value has expired,  when <E>-icanon<E> is set.

=item time N

Set the number of tenths of a second before reads
time out if the min number of characters  have  not
been read, when -icanon is set.

=item N

Set the input and output speeds to N.  N can be one
of: 0 50 75 110 134 134.5 150 200 300 600 1200 1800
2400 4800 9600 19200 38400 exta extb.  exta is  the
same  as 19200; extb is the same as 38400.  0 hangs
up the line if -clocal is set.

=back

=head2 OPTIONS

=over 4

=item -a

Print all current settings in human-readable  form.

=item -g

Print all current settings in a form  that  can  be
used  as  an  argument  to  another stty command to
restore the current settings.

=item -v,--version

Print version info.

=back

=head1 Direct Subroutines

=over 4

=item B<stty()>

    IO::Stty::stty(\*STDIN, @params);

From comments:

    I'm not feeling very inspired about this. Terminal parameters are obscure
    and boring. Basically what this will do is get the current setting,
    take the parameters, modify the setting and write it back. Zzzz.
    This is not especially efficent and probably not too fast. Assuming the POSIX
    spec has been implemented properly it should mostly work.

=cut

sub stty {
  my $tty_handle = shift; # This should be a \*HANDLE

  @_ or die("No parameters passed to stty");

  # Notice fileno() instead of handle->fileno(). I want it to work with 
  # normal fhs.
  my ($file_num) = fileno($tty_handle);
  # Is it a terminal?
  return undef unless isatty($file_num);
  my($tty_name) = ttyname($file_num);
  # make a terminal object.
  my($termios)= POSIX::Termios->new();
  $termios->getattr($file_num) || warn "Couldn't get terminal parameters for '$tty_name', fine num ($file_num)";
  my($c_cflag) = $termios->getcflag;
  my($c_iflag) = $termios->getiflag;
  my($ispeed)  = $termios->getispeed;
  my($c_lflag) = $termios->getlflag;
  my($c_oflag) = $termios->getoflag;
  my($ospeed) = $termios->getospeed;
  my(%control_chars);
  $control_chars{'INTR'}=$termios->getcc(VINTR);
  $control_chars{'QUIT'}=$termios->getcc(VQUIT);
  $control_chars{'ERASE'}=$termios->getcc(VERASE);
  $control_chars{'KILL'}=$termios->getcc(VKILL);
  $control_chars{'EOF'}=$termios->getcc(VEOF);
  $control_chars{'TIME'}=$termios->getcc(VTIME);
  $control_chars{'MIN'}=$termios->getcc(VMIN);
  $control_chars{'START'}=$termios->getcc(VSTART);
  $control_chars{'STOP'}=$termios->getcc(VSTOP);
  $control_chars{'SUSP'}=$termios->getcc(VSUSP);
  $control_chars{'EOL'}=$termios->getcc(VEOL);
  # OK.. we have our crap.

  my @parameters;
  my $parameter_with_value_rx = qr/^()$/;

  if(@_ == 1) {
    # handle the one-arg cases specifically
    # Version info
    if ($_[0] =~ /^(-v|version)$/ ) {
      return $IO::Stty::VERSION."\n";
    }
    elsif($_[0] =~ /^\d+$/) {
      push (@parameters,'ispeed',$_[0],'ospeed',$_[0]);
    }
  # Do we want to know what the crap is?
    elsif($_[0] eq '-a') {
    return show_me_the_crap ($c_cflag,$c_iflag,$ispeed,$c_lflag,$c_oflag,
      $ospeed,\%control_chars);
    }
  # did we get the '-g' flag?
    if($_[0] eq '-g') {
    return "$c_cflag:$c_iflag:$ispeed:$c_lflag:$c_oflag:$ospeed:".
      $control_chars{'INTR'}.":".
      $control_chars{'QUIT'}.":".
      $control_chars{'ERASE'}.":".
      $control_chars{'KILL'}.":".
      $control_chars{'EOF'}.":".
      $control_chars{'TIME'}.":".
      $control_chars{'MIN'}.":".
      $control_chars{'START'}.":".
      $control_chars{'STOP'}.":".
      $control_chars{'SUSP'}.":".
      $control_chars{'EOL'};
    } else {
  # Or the converse.. -g used before and we're getting the return.
  # Note that this uses the functionality of stty -g, not any specific
  # method. Don't take the output here and feed it to the OS stty.

  # This will make  perl -w happy.
      my(@g_params) = split(':',$_[0]);
      if (@g_params == 17) {
#   print "Feeding back...\n";
        ($c_cflag,$c_iflag,$ispeed,$c_lflag,$c_oflag,$ospeed)=(@g_params);
        $control_chars{'INTR'}=$g_params[6];
        $control_chars{'QUIT'}=$g_params[7];
        $control_chars{'ERASE'}=$g_params[8];
        $control_chars{'KILL'}=$g_params[9];
        $control_chars{'EOF'}=$g_params[10];
        $control_chars{'TIME'}=$g_params[11];
        $control_chars{'MIN'}=$g_params[12];
        $control_chars{'START'}=$g_params[13];
        $control_chars{'STOP'}=$g_params[14];
        $control_chars{'SUSP'}=$g_params[15];
        $control_chars{'EOL'}=$g_params[16];
        # leave parameters empty
      } else {
        # a simple single option
        @parameters = @_;
      }
    }
  } else {
    @parameters = @_;
  }

  # So.. what shall we set?
  my($set_value);
  local($_);
  while (defined ($_ = shift(@parameters))) {
#    print "Param:$_:\n";
    # Build the 'this really means this' cases.
    if($_ eq 'ek') {
      unshift(@parameters,'erase',8,'kill',21);
      next;
    }
    if($_ eq 'sane') {
      unshift(@parameters,'cread','-ignbrk','brkint','-inlcr','-igncr','icrnl',
        '-ixoff','opost','isig','icanon','iexten','echo','echoe','echok',
        '-echonl','-noflsh','-tostop','echok','intr',3,'quit',28,'erase',
        8,'kill',21,'eof',4,'eol',0,'stop',19,'start',17,'susp',26,
        'time',0,'min',0 );
      next;
    # Ugh.
    }
    if($_ eq 'cooked' || $_ eq '-raw') {
      # Is this right?
      unshift(@parameters,'brkint','ignpar','istrip','icrnl','ixon','opost',
        'isig','icanon',
        'intr',3,'quit',28,'erase',8,'kill',21,'eof',
        4,'eol',0,'stop',19,'start',17,'susp',26,'time',0,'min',0);
      next; 
    }
    if($_ eq 'raw' || $_ eq '-cooked') {
      unshift(@parameters,'-ignbrk','-brkint','-ignpar','-parmrk','-inpck',
        '-istrip','-inlcr','-igncr','-icrnl','-ixon','-ixoff',
        '-opost','-isig','-icanon','min',1,'time',0 );
      next;
    }
    if($_ eq 'pass8') {
      unshift(@parameters,'-parenb','-istrip','cs8');
      next;
    }
    if($_ eq '-pass8') {
      unshift(@parameters,'parenb','istrip','cs7');
      next;
    }
    if($_ eq 'crt') {
      unshift(@parameters,'echoe','echok');
      next;
    }
    if($_ eq 'dec') {
      # 127 == delete, no?
      unshift(@parameters,'echoe','echok','intr',3,'erase', 127,'kill',21);
      next; 
    }
    $set_value = 1; # On by default...
    # unset if starts w/ -, as in  -crtscts
    $set_value = 0 if s/^\-//;
    # Now the fun part.
    
    # c_cc field crap.
    if ($_ eq 'intr') { $control_chars{'INTR'} = shift @parameters; next;}
    if ($_ eq 'quit') { $control_chars{'QUIT'} = shift @parameters; next;}
    if ($_ eq 'erase') { $control_chars{'ERASE'} = shift @parameters; next;}
    if ($_ eq 'kill') { $control_chars{'KILL'} = shift @parameters; next;}
    if ($_ eq 'eof') { $control_chars{'EOF'} = shift @parameters; next;}
    if ($_ eq 'eol') { $control_chars{'EOL'} = shift @parameters; next;}
    if ($_ eq 'start') { $control_chars{'START'} = shift @parameters; next;}
    if ($_ eq 'stop') { $control_chars{'STOP'} = shift @parameters; next;}
    if ($_ eq 'susp') { $control_chars{'SUSP'} = shift @parameters; next;}
    if ($_ eq 'min') { $control_chars{'MIN'} = shift @parameters; next;}
    if ($_ eq 'time') { $control_chars{'TIME'} = shift @parameters; next;}

    # c_cflag crap
    if ($_ eq 'clocal') { $c_cflag = ($set_value ? ($c_cflag | CLOCAL) : ($c_cflag & (~CLOCAL))); next; } 
    if ($_ eq 'cread') { $c_cflag = ($set_value ? ($c_cflag | CREAD) : ($c_cflag & (~CREAD))); next; } 
    # As best I can tell, doing |~CS8 will clear the bits.. under solaris
    # anyway, where CS5 = 0, CS6 = 0x20, CS7= 0x40, CS8=0x60
    if ($_ eq 'cs5') { $c_cflag = (($c_cflag & ~CS8 )| CS5); next; } 
    if ($_ eq 'cs6') { $c_cflag = (($c_cflag & ~CS8 )| CS6); next; } 
    if ($_ eq 'cs7') { $c_cflag = (($c_cflag & ~CS8 )| CS7); next; } 
    if ($_ eq 'cs8') { $c_cflag = ($c_cflag | CS8); next; } 
    if ($_ eq 'cstopb') { $c_cflag = ($set_value ? ($c_cflag | CSTOPB) : ($c_cflag & (~CSTOPB))); next; } 
    if ($_ eq 'hupcl' || $_ eq 'hup') { $c_cflag = ($set_value ? ($c_cflag | HUPCL) : ($c_cflag & (~HUPCL))); next; } 
    if ($_ eq 'parenb') { $c_cflag = ($set_value ? ($c_cflag | PARENB) : ($c_cflag & (~PARENB))); next; } 
    if ($_ eq 'parodd') { $c_cflag = ($set_value ? ($c_cflag | PARODD) : ($c_cflag & (~PARODD))); next; } 

    # That was fun. Still awake? c_iflag time.
    if ($_ eq 'brkint') { $c_iflag = (($set_value ? ($c_iflag | BRKINT) : ($c_iflag & (~BRKINT)))); next; }
    if ($_ eq 'icrnl') { $c_iflag = (($set_value ? ($c_iflag | ICRNL) : ($c_iflag & (~ICRNL)))); next; }
    if ($_ eq 'ignbrk') { $c_iflag = (($set_value ? ($c_iflag | IGNBRK) : ($c_iflag & (~IGNBRK)))); next; }
    if ($_ eq 'igncr') { $c_iflag = (($set_value ? ($c_iflag | IGNCR) : ($c_iflag & (~IGNCR)))); next; }
    if ($_ eq 'ignpar') { $c_iflag = (($set_value ? ($c_iflag | IGNPAR) : ($c_iflag & (~IGNPAR)))); next; }
    if ($_ eq 'inlcr') { $c_iflag = (($set_value ? ($c_iflag | INLCR) : ($c_iflag & (~INLCR)))); next; }
    if ($_ eq 'inpck') { $c_iflag = (($set_value ? ($c_iflag | INPCK) : ($c_iflag & (~INPCK)))); next; }
    if ($_ eq 'istrip') { $c_iflag = (($set_value ? ($c_iflag | ISTRIP) : ($c_iflag & (~ISTRIP)))); next; }
    if ($_ eq 'ixoff') { $c_iflag = (($set_value ? ($c_iflag | IXOFF) : ($c_iflag & (~IXOFF)))); next; }
    if ($_ eq 'ixon') { $c_iflag = (($set_value ? ($c_iflag | IXON) : ($c_iflag & (~IXON)))); next; }
    if ($_ eq 'parmrk') { $c_iflag = (($set_value ? ($c_iflag | PARMRK) : ($c_iflag & (~PARMRK)))); next; }
    
    # Are we there yet? No. Are we there yet? No. Are we there yet...
#    print "Values: $c_lflag,".($c_lflag | ECHO)." ".($c_lflag & (~ECHO))."\n";
    if ($_ eq 'echo') { $c_lflag = (($set_value ? ($c_lflag | ECHO) : ($c_lflag & (~ECHO)))); next; }
    if ($_ eq 'echoe') { $c_lflag = (($set_value ? ($c_lflag | ECHOE) : ($c_lflag & (~ECHOE)))); next; }
    if ($_ eq 'echok') { $c_lflag = (($set_value ? ($c_lflag | ECHOK) : ($c_lflag & (~ECHOK)))); next; }
    if ($_ eq 'echonl') { $c_lflag = (($set_value ? ($c_lflag | ECHONL) : ($c_lflag & (~ECHONL)))); next; }
    if ($_ eq 'icanon') { $c_lflag = (($set_value ? ($c_lflag | ICANON) : ($c_lflag & (~ICANON)))); next; }
    if ($_ eq 'iexten') { $c_lflag = (($set_value ? ($c_lflag | IEXTEN) : ($c_lflag & (~IEXTEN)))); next; }
    if ($_ eq 'isig') { $c_lflag = (($set_value ? ($c_lflag | ISIG) : ($c_lflag & (~ISIG)))); next; }
    if ($_ eq 'noflsh') { $c_lflag = (($set_value ? ($c_lflag | NOFLSH) : ($c_lflag & (~NOFLSH)))); next; }
    if ($_ eq 'tostop') { $c_lflag = (($set_value ? ($c_lflag | TOSTOP) : ($c_lflag & (~TOSTOP)))); next; }

    # Make it stop! Make it stop!
    # c_oflag crap.
    if ($_ eq 'opost') { $c_oflag = (($set_value ? ($c_oflag | OPOST) : ($c_oflag & (~OPOST)))); next; }
  
    # Speed?
    if ($_ eq 'ospeed') { $ospeed = &{"POSIX::B".shift(@parameters)}; next; }
    if ($_ eq 'ispeed') { $ispeed = &{"POSIX::B".shift(@parameters)}; next; }
  # Default.. parameter hasn't matched anything
#    print "char:".sprintf("%lo",ord($_))."\n";
    warn "IO::Stty::stty passed invalid parameter '$_'\n";
  }

  # What a pain in the ass! Ok.. let's write the crap back.
  $termios->setcflag($c_cflag);
  $termios->setiflag($c_iflag);
  $termios->setispeed($ispeed);
  $termios->setlflag($c_lflag);
  $termios->setoflag($c_oflag);
  $termios->setospeed($ospeed);
  $termios->setcc(VINTR,$control_chars{'INTR'});
  $termios->setcc(VQUIT,$control_chars{'QUIT'});
  $termios->setcc(VERASE,$control_chars{'ERASE'});
  $termios->setcc(VKILL,$control_chars{'KILL'});
  $termios->setcc(VEOF,$control_chars{'EOF'});
  $termios->setcc(VTIME,$control_chars{'TIME'});
  $termios->setcc(VMIN,$control_chars{'MIN'});
  $termios->setcc(VSTART,$control_chars{'START'});
  $termios->setcc(VSTOP,$control_chars{'STOP'});
  $termios->setcc(VSUSP,$control_chars{'SUSP'});
  $termios->setcc(VEOL,$control_chars{'EOL'});
  $termios->setattr($file_num,TCSANOW); # TCSANOW = do immediately. don't unbuffer first.
  # OK.. that sucked.
}

=item B<show_me_the_crap()>

Needs documentation

=cut

sub show_me_the_crap {
  my ($c_cflag,$c_iflag,$ispeed,$c_lflag,$c_oflag,
    $ospeed,$control_chars) = @_;
  my(%cc) = %$control_chars;
  # rs = return string
  my($rs)='';
  $rs .= 'speed ';
  if ($ospeed == B0) { $rs .= 0; }
  if ($ospeed == B50) { $rs .= 50; }
  if ($ospeed == B75) { $rs .= 75; }
  if ($ospeed == B110) { $rs .= 110; }
  if ($ospeed == B134) { $rs .= 134; }
  if ($ospeed == B150) { $rs .= 150; }
  if ($ospeed == B200) { $rs .= 200; }
  if ($ospeed == B300) { $rs .= 300; }
  if ($ospeed == B600) { $rs .= 600; }
  if ($ospeed == B1200) { $rs .= 1200; }
  if ($ospeed == B1800) { $rs .= 1800; }
  if ($ospeed == B2400) { $rs .= 2400; }
  if ($ospeed == B4800) { $rs .= 4800; }
  if ($ospeed == B9600) { $rs .= 9600; }
  if ($ospeed == B19200) { $rs .= 19200; }
  if ($ospeed == B38400) { $rs .= 38400; }
  $rs .= " baud\n";
  $rs .= <<EOM;
intr = $cc{'INTR'}; quit = $cc{'QUIT'}; erase = $cc{'ERASE'}; kill = $cc{'KILL'};
eof = $cc{'EOF'}; eol = $cc{'EOL'}; start = $cc{'START'}; stop = $cc{'STOP'}; susp = $cc{'SUSP'};
EOM
;
  # c flags.
  $rs .= (($c_cflag & CLOCAL) ? '' : '-' ).'clocal '; 
  $rs .= (($c_cflag & CREAD) ? '' : '-' ).'cread '; 
  $rs .= (($c_cflag & CSTOPB) ? '' : '-' ).'cstopb '; 
  $rs .= (($c_cflag & HUPCL) ? '' : '-' ).'hupcl '; 
  $rs .= (($c_cflag & PARENB) ? '' : '-' ).'parenb '; 
  $rs .= (($c_cflag & PARODD) ? '' : '-' ).'parodd '; 
  $c_cflag = $c_cflag & CS8; 
  if ($c_cflag == CS8) {
    $rs .= "cs8\n";
  } elsif ($c_cflag == CS7) {
    $rs .= "cs7\n";
  } elsif ($c_cflag == CS6) {
    $rs .= "cs6\n";
  } else {
    $rs .= "cs5\n";
  }
  # l flags.
  $rs .= (($c_lflag & ECHO) ? '' : '-' ).'echo ';
  $rs .= (($c_lflag & ECHOE) ? '' : '-' ).'echoe ';
  $rs .= (($c_lflag & ECHOK) ? '' : '-' ).'echok ';
  $rs .= (($c_lflag & ECHONL) ? '' : '-' ).'echonl ';
  $rs .= (($c_lflag & ICANON) ? '' : '-' ).'icanon ';
  $rs .= (($c_lflag & ISIG) ? '' : '-' ).'isig ';
  $rs .= (($c_lflag & NOFLSH) ? '' : '-' ).'noflsh ';
  $rs .= (($c_lflag & TOSTOP) ? '' : '-' ).'tostop ';
  $rs .= (($c_lflag & IEXTEN) ? '' : '-' ).'iexten ';
  # o flag. jam it after the l flags so it looks more compact.
  $rs .= (($c_oflag & OPOST) ? '' : '-' )."opost\n";
  #  i flags.
  $rs .= (($c_iflag & BRKINT) ? '' : '-' ).'brkint ';
  $rs .= (($c_iflag & IGNBRK) ? '' : '-' ).'ignbrk ';
  $rs .= (($c_iflag & IGNPAR) ? '' : '-' ).'ignpar ';
  $rs .= (($c_iflag & PARMRK) ? '' : '-' ).'parmrk ';
  $rs .= (($c_iflag & INPCK) ? '' : '-' ).'inpck ';
  $rs .= (($c_iflag & ISTRIP) ? '' : '-' ).'istrip ';
  $rs .= (($c_iflag & INLCR) ? '' : '-' ).'inlcr ';
  $rs .= (($c_iflag & ICRNL) ? '' : '-' ).'icrnl ';
  $rs .= (($c_iflag & IXON) ? '' : '-' ).'ixon ';
  $rs .= (($c_iflag & IXOFF) ? '' : '-' )."ixoff\n";
  return $rs;
}
  
=back

=head1 AUTHOR

Austin Schutz <auschutz@cpan.org> (Initial version and maintenance)

Todd Rinaldo <toddr@cpan.org> (Maintenance)

=head1 BUGS

This is use at your own risk software. Do anything you want with it except
blame me for it blowing up your machine because it's full of bugs.

See above for what functions are supported. It's mostly standard POSIX
stuff. If any of the settings are wrong and you actually know what some of
these extremely arcane settings (like what 'sane' should be in POSIX land)
really should be, please open an RT ticket.

=head1 ACKNOWLEDGEMENTS

None

=head1 COPYRIGHT & LICENSE

Copyright 1997 Austin Schutz, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

  
1;
