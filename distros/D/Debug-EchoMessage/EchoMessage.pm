package Debug::EchoMessage;

use warnings;
use Carp;
use IO::File;
use POSIX qw(strftime);

# require Exporter;
@ISA = qw(Exporter);
our @EXPORT = qw(echoMSG debug disp_param);
our @EXPORT_OK = qw(debug echoMSG disp_param start_log end_log
    );
our %EXPORT_TAGS = (
  all      => [@EXPORT_OK],
  echo_msg => [qw(debug echoMSG disp_param)],
  log      => [qw(start_log end_log)], 
);
$Debug::EchoMessage::VERSION = 1.03;

=head1 NAME

Debug::EchoMessage - Display debug messages based on levels

=head1 SYNOPSIS

    my $self = bless {}, "main";
    use Debug::EchoMessage;
    $self->debug(2);   # set debug level to 2
    # The level 3 message will not be displayed
    $self->echoMSG("This is level 1 message.", 1);
    $self->echoMSG("This is level 2 message.", 2);
    $self->echoMSG("This is level 3 message.", 3);  

=head1 DESCRIPTION

The package contains the modules can be used for debuging or displaying
contents of your runtime state. You would first define the level of 
each message in your program, then define a debug level that you would
like to see in your runtime.

{  # Encapsulated class data
   _debug      =>0,  # debug level
}

=head2 debug($n)

Input variables:

  $n   - a number between 0 and 100. It specifies the
         level of messages that you would like to
         display. The higher the number, the more
         detailed messages that you will get.

Variables used or routines called: None.

How to use:

  $self->debug(2);     # set the message level to 2
  print $self->debug;  # print current message level

Return: the debug level or set the debug level.

=cut

sub debug {
    # my ($c_pkg,$c_fn,$c_ln) = caller;
    # my $s =  ref($_[0])?shift:(bless {}, $c_pkg);
    my $s =  shift;
    croak "ERR: Too many args to debug." if @_ > 1;
    @_ ? ($s->{_debug}=shift) : return $s->{_debug};
}

=head2 echoMSG($msg, $lvl, $fh)

Input variables:

  $msg - the message to be displayed. No newline
         is needed in the end of the message. It
         will add the newline code at the end of
         the message.
  $lvl - the message level is assigned to the message.
         If it is higher than the debug level, then
         the message will not be displayed.
  $fh  - file handler, or set the file hanlder in this parameter
         $ENV{FH_DEBUG_LOG}

Variables used or routines called:

  debug - get debug level.

How to use:

  # default msg level to 0
  $self->echoMSG('This is a test");
  # set the msg level to 2
  $self->echoMSG('This is a test", 2);

Return: None.

This method will display message or a hash array based on I<debug>
level. If I<debug> is set to '0', no message or array will be
displayed. If I<debug> is set to '2', it will only display the message
level ($lvl) is less than or equal to '2'. If you call this
method without providing a message level, the message level ($lvl) is
default to '0'.  Of course, if no message is provided to the method,
it will be quietly returned.

This is how you can call I<echoMSG>:

  my $df = DataFax->new;
     $df->echoMSG("This is a test");   # default the msg to level 0
     $df->echoMSG("This is a test",1); # assign the msg as level 1 msg
     $df->echoMSG("Test again",2);     # assign the msg as level 2 msg
     $df->echoMSG($hrf,1);             # assign $hrf as level 1 msg
     $df->echoMSG($hrf,2);             # assign $hrf as level 2 msg

If I<debug> is set to '1', all the messages with default message level,
i.e., 0, and '1' will be displayed. The higher level messages
will not be displayed.

This method displays or writes the message based on debug level.
The filehandler is provided through $fh or $ENV{FH_DEBUG_LOG}, and
the outputs are written to the file.

=cut

sub echoMSG {
    # my ($c_pkg,$c_fn,$c_ln) = caller;
    # my $self = ref($_[0])?shift:(bless {},$c_pkg);
    my $self = shift;
    my ($msg,$lvl, $fh) = @_;
    $fh = (exists $ENV{FH_DEBUG_LOG})?$ENV{FH_DEBUG_LOG}:"";
    $fh = "" if !$fh || ($fh && ref($fh) !~ /(IO::File|GLOB)/);  
    if (!defined($msg)) { return; }      # return if no msg
    if (!defined($lvl)) { $lvl = 0; }    # default level to 0
    my $class = ref($self)||$self;       # get class name
    my $dbg = $self->debug;              # get debug level
    if (!$dbg) { return; }               # return if not debug
    my $ref = ref($msg);
    if ($ref eq $class) {
        if ($lvl <= $dbg) { $self->disp_param($msg); }
    } else {
        $msg = "<h2>$msg</h2>" if exists $ENV{QUERY_STRING} && 
            $msg =~ /^\s*\d+\.\s+\w+/; 
        $msg = "$msg\n";
        $msg =~ s/\n/<br>\n/gm if exists $ENV{QUERY_STRING};
        if ($lvl <= $dbg) { 
            if ($fh) { print $fh $msg; } else { print $msg; }
        }
    }
}

=head2 disp_param($arf,$lzp, $fh)

Input variables:

  $arf - array reference
  $lzp - number of blank space indented in left
  $fh  - file handler

Variables used or routines called:

  echoMSG - print debug messages
  debug   - set debug level
  disp_param - recusively called

How to use:

  use Debug::EchoMessage qw(:echo_msg);
  my $self= bless {}, "main";
  $self->disp_param($arf);

Return: Display the content of the array.

This method recursively displays the contents of an array. If a
filehandler is provided through $fh or $ENV{FH_DEBUG_LOG}, the outputs
are written to the file.

=cut

sub disp_param {
    my ($self, $hrf, $lzp, $fh) = @_;
    $self->echoMSG(" -- displaying parameters...");
    $fh = (exists $ENV{FH_DEBUG_LOG})?$ENV{FH_DEBUG_LOG}:"";
    $fh = "" if !$fh || ($fh && ref($fh) !~ /(IO::File|GLOB)/);  
    if (!$lzp) { $lzp = 15; } else { $lzp +=4; }
    my $fmt;
    if (exists $ENV{QUERY_STRING}) {
        $fmt = "%${lzp}s = %-30s<br>\n";
    } else {
        $fmt = "%${lzp}s = %-30s\n";
    }
    if (!$hrf) {
        print "Please specify an array ref.\n";
        return;
    }
    # print join "|", $self, "HRF", $hrf, ref($hrf), "\n";
    my ($v);
    if (ref($hrf) eq 'HASH'|| $hrf =~ /.*=HASH/) {
        foreach my $k (sort keys %{$hrf}) {
            if (!defined(${$hrf}{$k})) { $v = "";
            } else { $v = ${$hrf}{$k}; }
            if ($v =~ /([-\w_]+)\/(\w+)\@(\w+)/) {
                $v =~ s{(\w+)/(\w+)\@}{$1/\*\*\*\@};
            }
            if ($fh) { printf $fh $fmt, $k, $v;
            } else   { printf $fmt, $k, $v; }
            if (ref($v) =~ /^(HASH|ARRAY)$/ ||
                $v =~ /.*=(HASH|ARRAY)/) {
                my $db1 = $self->debug;
                $self->debug(0);
                # print "$k = ${$hrf}{$k}: @{${$hrf}{$k}}\n";
                $self->disp_param(${$hrf}{$k},$lzp);
                $self->debug($db1);
                if ($fh) { print $fh "\n"; } else { print "\n"; }
            }
        }
    } elsif (ref($hrf) eq 'ARRAY' || $hrf =~ /.*=ARRAY/) {
        foreach my $i (0..$#{$hrf}) {
            if (!defined(${$hrf}[$i])) { $v = "";
            } else { $v = ${$hrf}[$i]; }
            if ($v =~ /([-\w_]+)\/(\w+)\@(\w+)/) {
                $v =~ s{(\w+)/(\w+)\@}{$1/\*\*\*\@};
            }
            if ($fh) { printf $fh $fmt, $i, $v;
            } else   { printf $fmt, $i, $v; }
            if (ref($v) =~ /^(HASH|ARRAY)$/ ||
                $v =~ /.*=(HASH|ARRAY)/) {
                my $db1 = $self->debug;
                $self->debug(0);
                $self->disp_param(${$hrf}[$i],$lzp);
                $self->debug($db1);
                if ($fh) { print $fh "\n"; } else { print "\n"; }
            }
        }
    }
}

=head2 start_log($dtl, $brf, $cns)

Input variables:

  $dtl - file name for detailed log
  $brf - file name for brief log
  $cns - a list of fields which are stored in brief log
  $arg - command line arguments

Variables used or routines called:

  echoMSG - print debug messages

How to use:

  use Debug::EchoMessage qw(:log);
  my $self= bless {}, "main";
  my $ar = $self->start_log('details.log','brief.log',
    'start_time,end_time,elapsed_time,file_tranferred,status');

Return: a hash array containing the fields in $cns.

This method creates log files if they do not exist and prepare a
hash array to store needed fields for end_log. The hash array has
the following elements:

  cns    - a list of field names separated by commas
  fld    - a hash array containing the field defined in cns.
  fn_brf - file name for brief log
  fh_brf - file handler for brief log
  fn_dtl - file name for detail log
  fh_dtl - file handler for detail log

If the I<cns> is not specifed, then it defaults to 
start_time,end_time,elapsed_time,user,args,result. 

=cut

sub start_log {
    my $s = shift;
    my ($dtl, $brf, $cns,$arg) = @_;
    my $ar = bless {}, ref($s);
    return $ar if ! $dtl; 

    $s->echoMSG(" -- start logging in $dtl...");
    $cns='start_time,end_time,elapsed_time,user,args,result' if !$cns;
    foreach my $k (split /,/, $cns) { 
        $k = lc $k; ${$ar}{fld}{$k} = ""; 
    } 
    ${$ar}{user} = `whoami`; 
    ${$ar}{args} = (exists $ENV{QUERY_STRING})?
                   $ENV{QUERY_STRING}:$arg;  
    my ($tx1, $txt, $cn1); 
    my $fh_dtl = new IO::File ">> $dtl"; 
    croak "ERR: could not write to $dtl: $!\n" if !defined($fh_dtl);
    ${$ar}{start_time} = time;
    $ENV{FH_DEBUG_LOG} = $fh_dtl; 
    ${$ar}{cns}    = $cns; 
    ${$ar}{fn_dtl} = $dtl; 
    ${$ar}{fh_dtl} = $fh_dtl;
    my $stm = strftime "%a %b %e %H:%M:%S %Y", 
        localtime(${$ar}{start_time});
    $tx1 = "# File Name: $dtl\n# Start at $stm\n"; 
    print $fh_dtl $tx1;
    return $ar if ! $brf;

    my ($pkg, $fn, $line, $subroutine, $hasargs, $wantarray, 
       $evaltext, $is_require, $hints, $bitmask) = caller(3);
    $tx1  = "# File Name: $brf\n# Generated By: $subroutine\n";
    $tx1 .= "# Fields: (elapsed times are in seconds)\n";
    $cn1 = $cns; $cn1 =~ s/,/\|/g;
    $tx1 .= "# $cn1\n";
    $txt = $tx1 if ! -f $brf; 
    my $dbg = $s->debug;
    $s->debug(1)  if !$dbg;   # we at least log message at level 1
    my $fh_brf = new IO::File ">> $brf"; 
    print $fh_brf "$txt"     if $txt;
    ${$ar}{fn_brf} = $brf;
    ${$ar}{fh_brf} = $fh_brf; 
    return $ar;
}

=head2 end_log($ar)

Input variables:

  $ar  - array ref returned from start_log. The elements can
         be populated in before end_log.

Variables used or routines called:

  strftime - time formater from POSIX
  disp_param - display parameters

How to use:

  use Debug::EchoMessage qw(:log);
  my $self= bless {}, "main";
  my $ar = $self->start_log('details.log','brief.log');
  $self->end_log($ar);

Return: none.

=cut

sub end_log {
    my $s = shift;
    my ($ar) = @_;

    my %b   = %{${$ar}{fld}}; 
    my $f   = "%a %b %e %H:%M:%S %Y"; 
    my $fh1 = ${$ar}{fh_brf}; 
    my $fh2 = ${$ar}{fh_dtl}; 
    my $cns = ${$ar}{cns}; 

    $b{end_time}     = time;
    $b{elapsed_time} = $b{end_time} - $b{start_time};
    $b{start_time}   = strftime $f, localtime($b{start_time});
    $b{end_time}     = strftime $f, localtime($b{end_time});
    $b{result}       = 'OK'; 
  
    my ($txt) = ("");
    foreach my $k (split /,/, $cns) { $txt .= "$b{$k}|"; }
    $txt =~ s/\|$//; 

    $self->disp_param(\%b); 
    print $fh1 $txt;  
    print $fh2 "# End at $b{end_time} $b{result}\n"; 
    undef $fh1;   # close breif  file hanlder
    undef $fh2;   # close detail file handler
}

=head1 CODING HISTORY

=over 4

=item * Version 0.01

04/15/2000 (htu) - Initial coding

=item * Version 0.02

04/16/2001 (htu) - finished debug and echoMSG

=item * Version 0.03

05/19/2001 (htu) - added disp_param 

=item * Version 1.00

06/25/2002 (htu) - added HTML format in disp_param 

=item * Version 1.01

04/25/2005 (htu) - fixed the NAME title

=item * Version 1.02

05/06/2005 (htu) - added file handler parameter so that messages can
be logged. The file handler can be passed through $ENV{FH_DEBUG_LOG}.

=item * Version 1.03

This version adds the start_log and end_log routines. 

=back

=head1 FUTURE IMPLEMENTATION

=over 4

=item * no plan yet 

=back

=head1 AUTHOR

Copyright (c) 2004 Hanming Tu.  All rights reserved.

This package is free software and is provided "as is" without express
or implied warranty.  It may be used, redistributed and/or modified
under the terms of the Perl Artistic License (see
http://www.perl.com/perl/misc/Artistic.html)

=cut

