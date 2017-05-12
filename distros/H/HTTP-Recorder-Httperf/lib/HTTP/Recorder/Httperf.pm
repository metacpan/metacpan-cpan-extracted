package HTTP::Recorder::Httperf;
use base 'HTTP::Recorder';
use strict;
use warnings;
use HTTP::Recorder::Httperf::Logger;
use File::Temp ();

$HTTP::Recorder::Httperf::VERSION = 0.02;
=pod

=head1 NAME 

HTTP::Recorder::Httperf - An HTTP::Recorder subclass to record user actions as input for httperf for load testing

=head1 SYNOPSIS

Use it almost exactly like you would use L<HTTP::Recorder>. In fact, this synopsis comes almost
exactly 'as is' from the L<HTTP::Recorder> documentation only changing 'HTTP::Recorder' to 'HTTP::Recorder::Httperf'.

	#!/usr/bin/perl
	
	use HTTP::Proxy;
	use HTTP::Recorder::Httperf;
	
	my $proxy = HTTP::Proxy->new();
	
	# create a new HTTP::Recorder::Httperf object
	my $agent = new HTTP::Recorder::Httperf;
	
	# set the log file (optional)
	$agent->file("/tmp/myfile");
	
	# set HTTP::Recorder as the agent for the proxy
	$proxy->agent( $agent );
	
	# start the proxy
	$proxy->start();
	
	1;

Now let's look at our 'file' (I</tmp/myfile>) and it might look something like this...

	#new session definition
	/foo.html think=2.0
	    /pict1.gif
	    /pict2.gif
	/foo2.html method=POST contents=’Post data’
	    /pict3.gif
	    /pict4.gif
		
	#new session definition
	/foo3.html method=POST contents="Multiline\ndata"
	/foo4.html method=HEAD

This sample httperf session file comes straight from the httperf manpage. If you would like
more information on the specific syntax of this file or how to edit it then please see the
httperf documentation. 

Then you can run httperf to load test your recorded session with something like this

	httperf --server 192.168.1.2 --wsesslog 100,2,/tmp/myfile --max-piped-calls=5 --rate 10


=head1 DESCRIPTION

This module is a subclass of L<HTTP::Recorder> but instead of recording the user's actions
as a L<WWW::Mechanize> script they are instead recorded into a session file to be used by
httperf, a load testing engine for testing websevers (L<http://www.hpl.hp.com/personal/David_Mosberger/httperf.html>).

It's use is almost exactly the same as L<HTTP::Recorder>. Some methods have been added for convenience
for httperf specific functionality. Please be familiar with L<HTTP::Recorder> and it's documentation
before proceeding to use this module as it will probably answer most of your questions.

=head1 METHODS

=head2 new([%args])

This is the constuctor method. Any arguments passed into this method will passed directly to
L<HTTP::Recorder::new()> except for the 'logger' argument which will be overridden with a new L<HTTP::Recorder::Httperf::Logger>
object.

In addition to the name-value pairs that L<HTTP::Recorder::new> takes, this method will also accept the
following arguments.

=over 8

=item default_think

This value set's the default 'think' value (time in seconds) for each request in this
session (see httperf documentation). If this value isn't set (or undef) then HTTP::Recorder::Httperf will
try and estimate the think time looking at the user's actual browsing. By default it is 'undef'

=item burst_threshold

This value set's the time in seconds between requests where they would be considered a part of
a burst. If this is not set then it defaults to 1 sec.

=item temp_file

HTTP::Recorder::Httperf uses a temporary file to store data about the time of requests. By default
this is named '.httperf_recorder_time'. You can change it as you see fit.

=back

=head2 default_think([$value])

This accessor/mutator method will return the current value for the 'default_think' time in seconds between
requests in this session. If $value is given it will set the current 'default_think' first to $value and
then return it. If it hasn't been set, it will return undef.

=head2 burst_threshold([$value])
                                                                                                                                             
This accessor/mutator method will return the current value for the 'burst_threshold' time in seconds. 
See L<new()>. If $value is given it will set the current 'burst_threshold' first to $value and
then return it.

=head2 temp_file([$value])
                                                                                                                                             
This accessor/mutator method will return the current name of the 'temp_file'.
See L<new()>. If $value is given it will set the current 'temp_file' first to $value and
then return it.

=head1 CAVEATS

=over 8
 
=item *

HTTP::Recorder::Httperf will try and create files (the session log and temp files) in the current directory
so the user running the proxy script must have appropriate permissions for the current working directory.

=back

=head1 AUTHOR

Michael Peters <mpeters@plusthree.com>

=head1 SEE ALSO

httperf L<http://www.hpl.hp.com/personal/David_Mosberger/httperf.html>,
L<HTTP::Recorder>, L<LWP::UserAgent>, L<HTTP::Proxy>

=cut
sub new
{
  my ($class, %args) = @_;

  my $default_think = $args{default_think};
  delete($args{default_think});
  my $temp_file = $args{temp_file};
  delete($args{temp_file});
  my $burst_threshold = $args{burst_threshold}; 
  delete($args{burst_threshold});

  my $self = $class->SUPER::new(%args);
  bless $self, $class;
  $self->{default_think} = $default_think || undef;
  $self->{temp_file} = $temp_file || '.httperf_recorder_time';
  $self->{burst_threshold} = $burst_threshold || 1;

  #create a new HTTP::Recorder::httper::Logger object and store it as my 'logger'
  $self->logger(HTTP::Recorder::Httperf::Logger->new(file => $args{file}));
  return $self;
}


#this is where the fun stuff of logging the httperf session file takes place
sub modify_request
{ 
  my ($self, $request) = @_;
  my ($think, $indent) = ($self->{default_think}, 0);
 
  #if we don't have the default_think time then go and get it
  if(!defined($think))
  {
    #get the current time
    my $cur_time = time();
    #get the last time a request was run
    my $last_time = $self->_get_temp_time();
    #now set think and indent
    $think = $last_time ? $cur_time - $last_time: $last_time;
    $self->_set_temp_time(time());
    #it can only be indented if it isn't the first (ie, there was a last time)
    $indent = $think <= $self->{burst_threshold} if($last_time);
  } 

  #get the uri of the request
  my $uri = $request->uri->path();
  $uri = '/' if(!$uri); #add an empty '/' if there is no path
  $uri .= '?' . $request->uri->query if($request->uri->query);
  #now log this line
  my $content = $request->content();
  if($content)
  {
    $content =~ s/\r?\n/\\<CR>/g;
    $content =~ s/"/\\"/g;
  }
  my $line = $indent ? '    ' : '';
  $line .= "$uri method=" . $request->method();
  $line .= " contents=\"$content\"" if($content);
  $line .= " think=$think" if($think && !$indent);
  $line .= "\n";
  $self->{logger}->Log($line);

  return $request;
}


sub _get_temp_time
{
  my $self = shift;
  my $line = 0;
  #open up the temp file
  if( -e $self->{temp_file})
  {
    open(FILE, $self->{temp_file}) or 
      die "Couldn't open " . $self->{temp_file} . ": $!";
    #get the time from the first line
    $line = <FILE> || 0;
    close(FILE) or die "Couldn't close " . $self->{temp_file} . ": $!";
    chomp($line) if($line);
  }
  return $line;
}


sub _set_temp_time
{
  my ($self, $time) = @_;
  #now write the time
  my $fh = File::Temp->new(TEMPLATE => '/tmp/httperf_recorder_XXXX', UNLINK => 0);
  print $fh $time;
  rename($fh->filename(), $self->{temp_file}) or 
    die "Couln't rename " . $self->{temp_file} . ": $!";
}



#just a blank method so that the response isn't modified, so just return the response
sub modify_response
{ return $_[1] }

#accessor/mutators
sub default_think 
{
  my ($self, $value) = @_;
  $self->{default_think} = $value if(defined $value);
  return $self->{default_think};
}

sub temp_file 
{
  my ($self, $value) = @_;
  $self->{temp_file} = $value if(defined $value);
  return $self->{temp_file};
}

sub burst_threshold 
{
  my ($self, $value) = @_;
  $self->{burst_threshold} = $value if(defined $value);
  return $self->{burst_threshold};
}





1;

