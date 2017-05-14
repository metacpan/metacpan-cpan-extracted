#================================= Msg.pm ====================================
# Filename:  	       Msg.pm
# Description:         Internal message encapsulation class.
# Original Author:     Dale M. Amon
# Revised by:          $Author: amon $ 
# Date:                $Date: 2008-08-28 23:20:19 $ 
# Version:             $Revision: 1.8 $
# License:	       LGPL 2.1, Perl Artistic or BSD
#
#=============================================================================
use strict;
use POSIX;

package Fault::Msg;
use vars qw{@ISA};
@ISA = qw( UNIVERSAL );

my $DFT_MSG     = "<No message argument>";
my $DFT_TYPE    = 'BUG';
my $DFT_PRI     = 'err';
my $DFT_PROCESS = "UnspecifiedProcess";
my $DFT_PREFIX  = "";
my $DFT_TAG     = "";

#=============================================================================
#                          INTERNAL OPS                                    
#=============================================================================
#                           CLASS METHODS
#-----------------------------------------------------------------------------

sub _timestamp   ($) {
    my @t = (gmtime)[5,4,3,2,1,0]; $t[0] += 1900; $t[1]++;
    return sprintf "%04d%02d%02d%02d%02d%02d", @t;
}

#-----------------------------------------------------------------------------

sub _processname ($) {(defined $::PROCESS_NAME) ? 
			 $::PROCESS_NAME : $DFT_PROCESS;}

#-----------------------------------------------------------------------------
#                         INSTANCE METHODS
#-----------------------------------------------------------------------------
# Test line without \n as Posix will complain other wise.

sub _validate_msg ($;$) {
    my ($s,$m) = @_;

    if    (!defined $m)        {$m = undef;}

    elsif (ref $m)             {push @{$s->{'err'}}, 
				("Message cannot be a pointer.");
				$m = $DFT_MSG; }

    else {
      chomp $m;
      if (!POSIX::isprint $m)  {push @{$s->{'err'}}, 
				  ("Message contains POSIX non-printable char: " .
				   "\'$m\'.");
				$m = $DFT_MSG;
			       }
    }
    return $m;
}

#-----------------------------------------------------------------------------

sub _validate_type ($;$) {
    my ($s,$t) = @_;

    if    (!defined $t)        {$t = undef;}

    elsif (ref $t)             {push @{$s->{'err'}}, 
				("Type cannot be a pointer.");
				$t = $DFT_TYPE; }

    elsif (!POSIX::isalpha $t) {push @{$s->{'err'}}, 
				("Type contains char other than [a-zA-Z]: " .
				 "\'$t\'.");
				$t = $DFT_TYPE; }

    else			{$t = uc $t;}
    return $t;
}

#-----------------------------------------------------------------------------

my %valid_priority = 
    ('emerg'   => 1,
     'alert'   => 1,
     'crit'    => 1,
     'err'     => 1,
     'warning' => 1,
     'notice'  => 1,
     'info'    => 1,
     'debug'   => 1 );

sub _validate_priority ($;$) {
    my ($s,$p) = @_;

    if    (!defined $p)        {$p = undef;}

    elsif (ref $p)             {push @{$s->{'err'}}, 
				("Priority cannot be a pointer.");
				$p = $DFT_PRI; }

    elsif (!exists $valid_priority{lc $p}) {push @{$s->{'err'}}, 
				("Priority is not a syslog priority:: " .
				 "\'$p\'.");
				$p = $DFT_PRI; }

    else			{$p = lc $p;}

    return $p;
}

#-----------------------------------------------------------------------------

sub _validate_prefix ($;$) {
    my ($s,$prefix) = @_;

    if    (!defined $prefix)        {$prefix = $DFT_PREFIX;}

    elsif (ref $prefix)             {push @{$s->{'err'}}, 
				     ("Prefix cannot be a pointer.");
				     $prefix = $DFT_PREFIX; }

    elsif (!POSIX::isprint $prefix) {push @{$s->{'err'}}, 
				     ("Prefix contains non-printable char: " .
				      "\'$prefix\'.");
				     $prefix = $DFT_PREFIX; }

    else			     {$prefix = "[$prefix]: ";}

    return $prefix;
}

#-----------------------------------------------------------------------------

sub _validate_tag ($;$) {
    my ($s,$tag) = @_;

    if    (!defined $tag)        {$tag = $DFT_TAG;}
    
    elsif (ref $tag)             {push @{$s->{'err'}}, 
				  ("Tag cannot be a pointer.");
				  $tag = "Invalid tag (Pointer)";}

    elsif (!POSIX::isprint $tag) {push @{$s->{'err'}}, 
				  ("Tag contains non-printable char: " .
				   "\'$tag\'.");
				  $tag = "Invalid tag (Not printable)";}
    return $tag;
}

#------------------------------------------------------------------------------

my %default_priority =
    ('BUG'  => 'err',
     'DATA' => 'warning',
     'SRV'  => 'warning',
     'NET'  => 'warning',
     'NOTE' => 'info' );

sub _handle_defaulting ($;$$$) {
    my ($c,$m,$t,$p) = @_;
    my $blankflg     = (!defined $m);

    if (!defined $m) {$m = $DFT_MSG;}
    if (!defined $t) {$t = $DFT_TYPE;}

    if (!defined $p) {
	$p = (exists $default_priority{$t}) ? 
	    $default_priority{$t} : $DFT_PRI;
    }
    return ($m,$t,$p,$blankflg);
}

#=============================================================================
#                          CLASS METHODS                                    
#=============================================================================

sub new ($;$$$) {
  my ($c,$m,$t,$p) = @_;
  my $flg;
  my $stamp        = $c->_timestamp;
  my $self         = bless {}, $c;
  $self->{'err'}   = ();
  $m               = $self->_validate_msg      ($m);
  $t               = $self->_validate_type     ($t);
  $p               = $self->_validate_priority ($p);
  ($m,$t,$p,$flg)  = $self->_handle_defaulting ($m,$t,$p);

  @$self{'timestamp','date','time',
	 'process',
	 'msg','type','priority',
	 'blankflg','prefix','tag'} = 
      ($stamp,substr($stamp,0,8),substr($stamp,8,6),
       $c->_processname,
       $m,$t,$p,
       $flg,
       $DFT_PREFIX,
       $DFT_TAG,
       );

  return $self;
}

#=============================================================================
#                          INSTANCE METHODS                                 
#=============================================================================

sub set_msg ($;$) {
    my ($s,$m)       = @_;
    $m               = $s->_validate_msg($m);
    $s->{'blankflg'} = (!defined $m);
    $s->{'msg'}      = (defined $m) ? $m : $DFT_MSG;
    return $m;
}

#-----------------------------------------------------------------------------

sub set_type ($;$) {
    my ($s,$t)        = @_;
    defined $t || ($t = $DFT_TYPE);
    $t                = $s->validate_type($t);
    $s->{'type'}      = $t;
    return $t;
}

#-----------------------------------------------------------------------------

sub set_priority ($;$) {
    my ($s,$p)        = @_;
    defined $p || ($p = $DFT_PRI);
    $p                = $s->validate_priority($p);
    $s->{'priority'}  = $p;
    return $p;
}

#-----------------------------------------------------------------------------

sub set_prefix ($;$) {
    my ($s,$prefix)  = @_;
    $s->{'prefix'}   = $s->_validate_prefix($prefix);
    return $s->{'prefix'};
}

#-----------------------------------------------------------------------------

sub set_tag ($;$) {
    my ($s,$tag)  = @_;
    $s->{'tag'}   = $s->_validate_tag($tag);
    return $s->{'tag'};
}

#-----------------------------------------------------------------------------

sub get ($) {my $s   = shift; 
	     my $m = $s->{'prefix'} . $s->{'msg'};
	     (@$s{'timestamp','priority','type','process'}, $m);}

sub msg         ($) {my $s   = shift; $s->{'tag'} . $s->{'msg'};}

sub timestamp   ($) {shift->{'timestamp'};}
sub time        ($) {shift->{'time'};}
sub date        ($) {shift->{'date'};}
sub processname ($) {shift->{'process'};}
sub priority    ($) {shift->{'priority'};}
sub type        ($) {shift->{'type'};}
sub is_blank    ($) {shift->{'blankflg'};}
sub prefix      ($) {shift->{'prefix'};}
sub tag         ($) {shift->{'tag'};}

#-----------------------------------------------------------------------------

sub stamped_log_line ($) {
    my $s = shift;
    my ($d,$t,$p,$type,$priority,$m,$prefix,$tag) = 
	@$s{'date','time','process','type','priority','msg','prefix','tag'};
    return "$d $t UTC> $p: $type($priority): ${prefix}${tag}${m}";
}

#-----------------------------------------------------------------------------

sub unstamped_log_line ($) {
    my $s = shift;
    my ($p,$type,$priority,$m,$prefix,$tag) = 
	@$s{'process','type','priority','msg','prefix','tag'};
    return "$p: $type($priority): ${prefix}${tag}${m}";
}

#=============================================================================
#                          POD DOCUMENTATION                                
#=============================================================================
# You may extract and format the documention section with the 'perldoc' cmd.

=head1 NAME

 Fault::Msg - Internal message encapsulation class.

=head1 SYNOPSIS

 use Fault::Msg;
 $self   = Fault::Msg->new     ($m,$t,$p);
 $m      = $self->set_msg      ($m);
 $t      = $self->set_type     ($t);
 $p      = $self->set_priority ($p);
 $prefix = $self->set_prefix   ($prefix);
 $tag    = $self->set_tag      ($tag);

 ($stamp,$p,$t,$process,$taggedmsg) = $self->get;

 $taggedmsg   = $self->msg;
 $stamp       = $self->timestamp;
 $time        = $self->time;
 $date        = $self->date;
 $processname = $self->processname;
 $p           = $self->priority;
 $t           = $self->type;
 $prefix      = $self->prefix;
 $tag         = $self->tag;
 $bool        = $self->is_blank;
 $line        = $self->stamped_log_line;
 $line        = $self->unstamped_log_line;

=head1 Inheritance

 UNIVERSAL
  Fault::Msg

=head1 Description

A Fault::Msg is an object internal to the Fault::Logger system. It encapsultes
all the required information about a message that will be used for a fault or
log report. It makes certain that all required values are present and correct
so that other internal classes do not have to do so.

The message text itself is stored in three parts: prefix, tag and msg. The
prefix is used only in printed log lines. A tag, if present, is included as
if it were part of the message text.

=head1 Examples

 None.

=head1 Class Variables

 None.

=head1 Instance Variables

  timestamp    The time and date stamp at the time of creation of Msg.
  date         The date portion of the timestamp string.
  time         The time portion of the timestamp string.
  process      $::PROCESS_NAME or a default value.
  msg          The base message text.
  type         The message type.
  priority     The syslog priority type.
  blankflg     True if the base message is a default.
  prefix       A special prefix text that is not 'part' of the message.
  tag          A prefix that when set is alway included with the base
               message.

=head1 Class Methods

=over 4

=item B<$self = Fault::Msg-E<gt>new ($m,$t,$p)>

=item B<$self = Fault::Msg-E<gt>new ($m,$t)>

=item B<$self = Fault::Msg-E<gt>new ($m)>

=item B<$self = Fault::Msg-E<gt>new>

Create an instance of $Fault::Msg for the message, type
and priority specified. If values are undef, defaults will
be used for the missing values.

If the message ends with a newline, it is removed. If there
are embedded format chars the line will be rejected by 
POSIX::printable.

=head1 Instance Methods

=over 4

=item B<$date = $self-E<gt>date>

Return the date string, yyyymmdd.

=item B<($stamp,$p,$t,$process,$taggedmsg) = $self-E<gt>get>

Return the basic list of items used in a log message. Taggedmsg does
not include the prefix as prefix's are for log printing. 

=item B<$bool = $self-E<gt>is_blank>

Return true if the base message text is empty and has been replaced
by a default.

=item B<$taggedmsg = $self-E<gt>msg>

Return a concatenated string consisting of the tag and the base message.

=item B<$p = $self-E<gt>priority>

Return the priority.

=item B<$prefix = $self-E<gt>prefix>

Return the message prefix.

=item B<$processname = $self-E<gt>processname>

Return the messages originating process name.

=item B<$m = $self-E<gt>set_msg ($m)>

Set the base message string. An undefined value will set the blank
message flag and set the base message to an informative default message.

If the message ends with a newline, it is removed. If there
are embedded format chars the line will be rejected by 
POSIX::printable.

=item B<$p = $self-E<gt>set_priority ($p)>

Set the syslog priority string. An undefined $p will set the priority to
a default value compatible with the current string type setting. 
[See Fault::Logger for more information on defaulting.]

=item B<$prefix = $self-E<gt>set_prefix ($prefix)>

Set the prefix string. A prefix will appear before a message and
tag in the format '[$prefix] '. A prefix will only appear in strings
generated via stamped_log_line and unstamped_log_line.

An undefined $prefix will set prefix to the default value: "".

=item B<$tag = $self-E<gt>set_tag ($tag)>

Set a message tag. A tag will be prepended to the message when ever
it is used. A undefined $tag will set tag to the default value: "".

=item B<$t = $self-E<gt>set_type ($t)>

Set the type of the message. An undefined type string will set type
to the default value: 'BUG'.

=item B<$line = $self-E<gt>stamped_log_line>

Return a line formatted for use in a private log format or printing
format:

    "$date $time UTC> $process: $type($priority): ${prefix}${tag}${msg}"

=item B<$tag  = $self-E<gt>tag>

Return the tag string.

=item B<$time = $self-E<gt>time>

Return a time string. A time is formatted: hhmmss.

=item B<$stamp = $self-E<gt>timestamp>

Return the message timestamp. A timestamp is formatted: yyyymmddhhmmss.

=item B<$t = $self-E<gt>type>

Return the message type string.

=item B<$line = $self-E<gt>unstamped_log_line>

Return a line formatted for use in a syslog format:

    "$process: $type($priority): ${prefix}${tag}${msg}"

=back 4

=head1 Private Class Method

 None.

=head1 Private Instance Methods

 None.

=head1 Errors and Warnings

 None.

=head1 KNOWN BUGS

POSIX::isprint is used to filter whether a message is junk or not.
It should probably make an effort to sanitize the string of format
characters rather than reject a potentially good message.

See TODO.

=head1 Errors and Warnings

 None.

=head1 SEE ALSO

 None.

=head1 AUTHOR

Dale Amon <amon@vnl.com>

=cut

#=============================================================================
#                                CVS HISTORY
#=============================================================================
# $Log: Msg.pm,v $
# Revision 1.8  2008-08-28 23:20:19  amon
# perldoc section regularization.
#
# Revision 1.7  2008-08-17 21:56:37  amon
# Make all titles fit CPAN standard.
#
# Revision 1.6  2008-07-24 21:17:24  amon
# Moved all todo notes to elsewhere; made Stderr the default delegate instead of Stdout.
#
# Revision 1.5  2008-07-24 19:11:29  amon
# Notepad now uses Fault::Msg class which moves all the timestamp and 
# digitalsig issues to Msg.
#
# Revision 1.4  2008-07-23 22:56:30  amon
# I forgot chomp does not return the chomped string. Fixed the code 
# accordingly.
#
# Revision 1.3  2008-07-23 22:32:51  amon
# chomp line ends in Msg class rather than fail unconditionally due to 
# POSIX::isprint.
#
# Revision 1.2  2008-05-07 18:38:20  amon
# Documentation fixes.
#
# Revision 1.1  2008-05-07 17:45:35  amon
# Put most of the message handling into this class.
#
# $DATE   Dale Amon <amon@vnl.com>
#	  Created.
1;
