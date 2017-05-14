# $Id: Topics.pm,v 1.5 1996/01/04 20:45:38 willijar Exp $

=head1 NAME

Log::Topics - control flow of logging messages

=head1 SYNOPSIS

  use Log::Topics qw(add_topic log_topic topics);
  add_topic $topic_name,$filehandle,$overload
  add_topic $topic_name,$filename,$overload
  log_topic $topic_name,@messages
  @topicslist=topics();

=head1 DESCRIPTION

This package provides services for controlling the output of logging
messages from an application. Log messages are identified by named
topics, and the messages for each topic can be directed or redirected
to file handles or files.

The add_topic() function can be used to associate a named topic with a
particular file handle. If a value of 0 then logging of that
particular topic is switched off. If the file handle is not connected
to a file then it will be created and connected to a file of the same
name. add_topic() returns the name of the file handle. The third
$overload parameter, if specified and false will only set the file
handle if the specified topic is not already associated with a file
handle.

Log messages are written using the log_topic() function which takes
the topic name, and if that particular topic is enabled will print its
remaining arguments to the associated file handle. It is an error to
use a topic name that has not been declared using add_topic() first.

The topics() function returns a list of all the current registered
topics.

This package can usefully be used for controlling all the output of a
program, not just debugging and logging messages.

If you have Getopt::Regex package then the following lines of code
allow the user to control the log messages from the command
line using either '-Lname=FILE' or '-Lname FILE' syntaxes.

 use Log::Topics qw(add_topic log_topic);
 use Getopt::Regex qw(GetOptions);
 GetOptions(\@ARGV,
  ['-L(.+)=(.+)',sub { add_topic $1,$2; }    ,0],
  ['-L(.+)',     sub { add_topic $1; $_[0]; },1]);

=head1 HISTORY

 $Log: Topics.pm,v $
 Revision 1.5  1996/01/04 20:45:38  willijar
 Renamed module to Log::Topics, and renamed functions to more
 accurately reflect modules operation.
 Added topics() function to obtain list of available topics and removed
 internal hash variable from export list.
 Reduced to one the hash dereference in log_topic for slight efficiency
 gain.

 Revision 1.4  1995/12/17 17:16:31  willijar
 Fixed bug that crept in in non-overloading case of diagnose

 Revision 1.3  1995/12/16 11:59:19  willijar
 Removed function for reading arguments from commandline -
 use Getopt::Regex instead.
 Added ability to open files for undefined filehandles.
 Improvements to documentation
 Changed name to be closer to module guidlines.

 Revision 1.2  1995/09/20  19:11:44  willijar
 Added pod documentation and RCS control

=head1 TO DO

Could perhaps have the idea of groups of related topics which could be
set and changed together. Would this be useful?

=head1 BUGS

Please let me know of any bugs.
Suggestions for improvements gladly received.

=head1 AUTHOR

John A.R. Williams, <J.A.R.Williams@aston.ac.uk>

Thanks to Tim Bunce <Tim.Bunce@ig.co.uk> for helpful suggestions and comments.

=cut

require Exporter;
package Log::Topics;
@ISA=qw(Exporter);
@EXPORT_OK=qw(add_topic log_topic topics);
use Carp;

%topics={};

sub add_topic {
  my ($d,$fhandle,$overload)=@_;
  if (!defined $overload) { $overload=1; }
  if (defined $fhandle and ($overload or !exists($topics{$d}))) {
    if (!$fhandle) { $topics{$d}=0; }
    else {
      if ($fhandle==1) { $fhandle=STDERR; }
      if (!defined(fileno($fhandle))) { open $fhandle,">$fhandle"; }
      $topics{$d}=$fhandle;
    }
  }
  return $topics{$d};
}

sub log_topic {
  my $d=shift;
  my $fhandle=$topics{$d};
  if (defined($fhandle)) {
    if ($fhandle) { print {$fhandle} @_; }
  }
  else {
    carp "Undefined Log topic $d used\n";
  }
}

sub topics { return keys(%topics); }

1;

