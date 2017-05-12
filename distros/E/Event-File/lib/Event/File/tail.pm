=head1 NAME

  Event::File::tail - 'an tail [CB]<-f>' implementation using Event

=head1 SYNOPSIS

  use Event::File;
  Event::File->tail(
		    file => '/var/log/messages',
		    cb   => \&my_read_callback_function
		   );
  Event::loop;

=head1 DESCRIPTION

Event::FileTail is an attempt to reproduce the behaviour of the
'tail -f' using Event as the backend.

The main difference between this module and other modules that tries
to implement it is that it leaves room for parallel processing using 
Event.

=cut

package Event::File::tail;
use strict;
use vars qw($VERSION $ID);

$VERSION = "0.1.1";

#our internal id
$ID = 0;

#We use Event::File to register
'Event::File'->register;

#our startup 
sub new {
  my $class = shift;
  my %arg = @_;
  
  $ID++;

  #  No allocate (at least for now)
  #  my $o = allocate($class, delete $arg{attach_to} || {});
  my $o={
	 #We keep our "shared" data here
	 _arg => {},

	 #Here goes our internal data  stuff
	 _data => {

                   #our internal id
                   id => $ID,

		   #flag to tell if the processing file is the same as before
		   # 0 => no
		   # 1 => yes
		   file_ok => 0,

		   #internal count to keep track of how 
		   #many lines have we writen yet 
		   #our hardcoded limit is 10
		   file_count => 0,

		   #here we keep the beggining of the file for
		   #footprinting in case the file changes
		   file_footprint => [],

		   #counter to keep track of the file if it gets too quite
		   #(it might be rotated, and we didn't notice)
		   timer_count => 0,
		   
		   #Does the file exist?
		   #0 => no
		   #1 => yes
		   file_exist => 0,
		  },

	 #we keep a reference to our internal watchers
	 #remember that we have to undefine it in the 
	 #DESTROY sub
	 _watchers => {
		       timer => undef,
		       read  => undef,
		      },
	};

  bless $o;  

  #Event initioalization stuff
  #  $o->init(\%arg);

  #our initialization
  $o->_init(\%arg);

  $o->_prepare();
  $o;
}

=head2 Supported attributes

=over

=item file

file gives the file name to watch, with either a absolute or relative path.
The file has to exist during initialization.  After it, it can be unlinked and
recreated.

=item position

where to start reading from the file, in bytes.  As the file is read, it 
will be updated with the last position read.

=item footprint

footprint, if defined, ia an array reference of n elements.  Each element correspond
to a line from the beggining of the file. If any line does not match in the file,
C<position> will be ignored and started in the beggining.

=item cb

cb is the standard callback. It will receive a code reference that will
be called after every line read from the C<file>. The newline from the line
will be C<chomp>ed before passed.
The Event::File::tail object will be passed as the first argument.
The read line will be passed as the second argument.

=item timeout

A timeout starts to calculate after the file read gets to the end.
If a new line is added to the file the timer count is reseted.
Its main use is to catch a situation when the C<file> is rotated
and it was not catched.
The file will be closed and reopened.  If the file stills the same
it will continue from the place it was before closing it.  If the 
file has really changed, it will start reading it from the beggining.
If not specified it defaults to 60s.

=item timeout_cb

This is the callback to call when a timeout occur.
The timeout callback will be only called if the reopened file
results in the same file. 

=item endfile_cb

This callback will be called every time when the file read gets
to the end.  So if you need to do something after reading the
file (instead of during each read line).

=item desc

Description of the watcher.

=back

=head1 METHODS

This are the methods available for use with the tail watcher.

=cut



#our internal init method
sub _init{
  my ($me, $arg) = @_;

  die "You must provide a 'file' argument to tail\n" if (!defined($arg->{file}));
  $me->{_arg}->{file} = $arg->{file};

  #sets the position
  $me->{_arg}->{position} = 0;
  $me->{_arg}->{position} = $arg->{position} if (defined($arg->{position}));

  #the read callback
  $me->{_arg}->{cb} = sub {};
  $me->{_arg}->{cb} = $arg->{cb} if (defined($arg->{cb}));

  #timeout value
  $me->{_arg}->{timeout} = 60;
  $me->{_arg}->{timeout} = $arg->{timeout} if (defined($arg->{timeout}));

  #the timeout callback
  $me->{_arg}->{timeout_cb} = sub {};
  $me->{_arg}->{timeout_cb} = $arg->{timeout_cb} if (defined($arg->{timeout_cb}));

  #the end of file callback
  $me->{_arg}->{endfile_cb} = sub{};
  $me->{_arg}->{endfile_cb} = $arg->{endfile_cb} if (defined($arg->{endfile_cb}));

  #check for description
  $me->{_arg}->{desc} = "Event::File->tail watcher. ID: " . $me->{_data}->{id};
  $me->{_arg}->{desc} = $arg->{desc} if (defined($arg->{desc}));

  #file foot print
  $me->{_data}->{file_footprint} = [];
  $me->{_data}->{file_footprint} = $arg->{footprint} if (defined($arg->{footprint}));
}

#prepare the real watchers
sub _prepare{
  my ($me) = @_;

  #opens the file (parked)
  $me->_open_file(1);

  #checks wether the faile still the same
  $me->_file_check_sanity();

  #adjusts the file
  $me->{fd}->seek($me->{_arg}->{position}, 0);

  # The helper timer
  $me->{_watchers}->{timer} = Event->timer(
					   cb       => [$me, '_file_timer'],
					   desc     => 'helper watcher for Event::File->tail ID:' . $me->{_data}->{id},
					   interval => 1,
					   prio     => 6,
					   parked   => 1,
					  );

  #now we start the read timer
  $me->{_watchers}->{read}->start;
}

#this is the timer callback 
sub _file_read{
  my ($me, $event)=@_;
  my ($position, $handler);

  $handler = $event->w->fd;

  #There is nothing to read in the file
  if (eof($handler)){

    #saves the file position
    #Attention:
    #if using sys{read,write,seek} family,
    #would have to use 'sysseek($handler, 0, 1)' instead of tell
    $position = tell($handler);

    #if the file has changed
    if ($me->{_arg}->{position} != $position){

      $me->{_arg}->{position} = $position;
      
      #reset the counter
      $me->{_data}->{timer_count} = 0;

      #end of file callback
      &{$me->{_arg}->{endfile_cb}}($me);
    }

    #stops this watcher
    #there is nothing to read
    $event->w->stop;

    #starts the timer
    $me->{_watchers}->{timer}->again;

    return;
  }

  $_ = <$handler>;
  chomp;


  #save the first lines from the from file
  #right now 10 is a harcoded limit
  if (( $me->{_data}->{file_count} < 10) && ( $me->{_data}->{file_ok} == 0)){
    push ( @{$me->{_data}->{file_footprint}}, $_);
    $me->{_data}->{file_count}++;
  }

  #this is the default callback
  &{$me->{_arg}->{cb}}($me, $_);
  
  $me->{_data}->{timer_count} = 0;
}


#######################################
# from_file_timer:
#    timer callback
#######################
sub _file_timer{
  my ($me, $event)=@_;
  my ($pid);

  #update the counter
  $me->{_data}->{timer_count}++;

  #first we check if the file still there
  if (! -f $me->{_arg}->{file}){
    #no, the file isn't there (oh oh)
    
    if ($me->{_data}->{file_exist} == 1){
      #we probably just got the file being rotate

      #flag to tell that 
      $me->{_data}->{file_exist} = 0;
 
      #note that we keep timer on, until the file is back
      #if we were lucky, we got every entry before it was rotate
      #otherwise we probably lost the lasts entrys
      #For all effects, we behave like we never lost it (since
      # we can't guess :\ )
      
      #supose you are watching procmail's log file
      #if the user rotates the from file from the procfile,
      #he has to make sure that he rotates the file before delivering mail,
      #as procmail is called when receives a mail
      #otherwise we will lost that entry for sure. (sad!)
      #and we will only note that after that mbox is opened.

      #reset the counter
      $me->{_data}->{timer_count} = 0;

      #close the file and cancels the watcher
      $me->_close_file();
    }
    return;
  }
  
  #was it trucated/rotated and we already noticed it before?
  if ($me->{_data}->{file_exist} == 0){
    #now the file is back, we need to reopen it again
    
    #we need to get this data back..
    $me->{_data}->{file_count} = 0;
    $me->{_data}->{file_footprint} = [];
    
    #we can stop the timer for now
    $me->{_watchers}->{timer}->stop;
    
    #reset the counter
    $me->{_data}->{timer_count} = 0;
      
    #open it again
    $me->_open_file();

    return;
  }

  #checks if we got to the limit
  if ($me->{_data}->{timer_count} == $me->{_arg}->{timeout}){

    $me->{_data}->{timer_count} = 0;

    #The file might have being rotated and we didn't notice it
    $me->_close_file();
    $me->_open_file(1);

    #there is a great chance that the file is the same as before,
    #so we need to check it again    
    if ($me->_file_check_sanity() == 0){

      #reset our counters
      $me->{_data}->{file_count} = 0;
      $me->{_data}->{file_footprint} = [];
    }
    else{
      #The timout callback
      &{$me->{_arg}->{timeout_cb}}($me);
    }
    
    #we can stop the timer for now
    $me->{_watchers}->{timer}->stop;
    $me->{_watchers}->{read}->again;

    return;
  }


  #default behaviour
  
  $me->{_watchers}->{timer}->stop;
  $me->{_watchers}->{read}->again;
}




######################################
# _close_file
#     Closes the file and cancels the
#     watcher
###################################
sub _close_file{
  my ($me) = @_;

  #cancel the watcher and make sure we don't hold any reference to it
  $me->{_watchers}->{read}->cancel;
  undef $me->{_watchers}->{read};
  
  #close the FH
  $me->{fd}->close();
  undef $me->{fd};
}


###########################################
#  _open_file:
#       Open the file and start the watcher to it
###############
sub _open_file{
  my ($me, $parked) =@_;

  if (!defined($parked)){
    $parked = 0;
  }

  #open it
  $me->{fd} = new IO::File $me->{_arg}->{file}, "r"
    or die "Error!! Could not open file: ". $me->{_arg}->{file} ."\nReason: $!\n";
    
  #it exists
  $me->{_data}->{file_exist} = 1;

  #the file read watcher
  $me->{_watchers}->{read} = Event->io(
				       fd     => $me->{fd},
				       cb     => [$me, "_file_read"],
				       poll   => 'r',
				       desc   => 'Helper watcher for Event::File->tail ID:' . $me->{_data}->{id},
				       parked => $parked,
				      );
}

##################################################
#  _file_check_sanity:
#     Checks if the from file still the same 
#     as before.
#     If it is in sync, it will update the 
#     position to where we left off.
#     It returns:
#     0 => file out of sync (start from the beggining)
#     1 => file in sync
################################
sub _file_check_sanity{
  my ($me) = @_;
  my ($size, $line, $file_line, $old_position, $handler, $file_ok);
  
  $size          = (stat($me->{_arg}->{file}))[7];
  $old_position  = $me->{_arg}->{position};
  $handler       = $me->{fd};

  #Check if it is possible to be the same file
  if ( $size >= $old_position ){

    #checks each line
    #note that this will not block because of the size check above
    #if the file shrinks, we better start all over because it would be impossible
    #to know what exaclty happened
    $file_ok = 1;
  SANITY_CHECK:
    foreach $line (@{$me->{_data}->{file_footprint}}){

      #read it
      $file_line = <$handler>;
      chomp ($file_line);
      
      if ($file_line ne $line){
	#out of sync!
	$file_ok = 0;
	last SANITY_CHECK;
      }
    }
    #put the file in the desired position
    if ($file_ok){
      $handler->seek($old_position, 0);
    }else{
      $handler->seek(0, 0);
    }
  }
  
  #We don't trust a file if it is less than it was before
  else{
    $file_ok = 0;
  }

  $me->{_data}->{file_ok} = $file_ok;

  #returns the result
  return $file_ok;
}

=head2 $watcher->desc;

Returns the description of the watcher.

=cut

sub desc{
  my ($me) = @_;
  return $me->{_arg}->{desc};
}

=head2 $watcher->id;

Returns the internal watcher id number.

=cut

sub id{
  my ($me) = @_;
  return $me->{_data}->{id};
}

=head2 $position = $watcher->position;

Returns the current file position

=cut

#WARNING: the file position is updated only when it gets to the end of the
#file
sub position{
  my ($me) = @_;
  return $me->{_arg}->{position};
}

=head2 $array_ref = $watcher->footprint;

This will return an array reference of the file's footprint.
This is handy if you need to quit your application and after restarting it the
file can be checked whether it is the same or not.

=cut

sub footprint{
  my ($me) = @_;
  return $me->{_data}->{file_footprint};
}

=head2 $result = $watcher->loop($timeout);

loop is a wrapper to C<Event::loop> in case that no other Event's watcher is in use.  
You have to call it somewhere to let Event watch the
file for you.
C<$result> will return from the C<$result> value passed by an C<unloop> method (see below).
Please refer to the loop function in the Event pod page for more info.

=cut

#'loop wrapper
sub loop{
  my ($me, $timeout) = @_;
  return Event::loop($timeout);
}

=head2 $watcher->unloop($result);

A wrapper to C<Event::unloop>.  This will cancel an active Event::loop, e.g.
when called from a callback.
C<$result> will be passed to the C<loop> caller.
Please refer to Event::unloop for more info.

=cut

#unloop wrapper
sub unloop{
  my ($me, $result) = @_;
  Event::unloop($result);
}

=head2 $watcher->sweep;

A wrapper around C<Event::sweep>. 
C<sweep> will call any event pending and return.
Please refer to C<Event::sweep> for mor info.

=cut

#Sweep wrapper
sub sweep{
  my ($me, $prio) = @_;
  Event::sweep($prio);
}

=head2 $watcher->stop;

This will stop the watcher until a C<again> or C<start> method is called.

=cut

sub stop{
  my ($me) = @_;
  $me->{_watchers}->{read}->stop;
  $me->{_watchers}->{timer}->stop; 
}

=head2 $watcher->start;

This method will restart the watcher

=cut

sub start{
  my ($me) = @_;
  $me->{_watchers}->{read}->stop;
  $me->{_watchers}->{timer}->start;
}

=head2 $watcher->again;

The same as C<start>

=cut

sub again{
  my ($me) = @_;
  $me->start;
}

=head2 $watcher->cancel

This will destroy the watcher.
Note that if t there is a reference to this watcher outside this package,
the memory won't be freed.

=cut

#'
sub cancel{
  my ($me) = @_;
  $me->{_watchers}->{read}->cancel;
  $me->{_watchers}->{timer}->cancel;
  undef $me;
}


1;

__END__

=pod

=head1 loop vs sweep

When do you have to use C<loop> or C<sweep>?

Well, that depends.  If you are not familiar with Event, the quick
and dirty answer is C<loop> will BLOCK and C<sweep> no.

C<loop> will be keeping calling the callback functions whenever they are
ready and will just return when a callback calls for C<unloop> or a timeout
happens.

On the other hand, if you are not using Event for anything else in your program,
this might not be a desired situation.
C<sweep> can be called them to check if some event has happened or not.
If it has it will execute all the pending callbacks and then return (as opposed
from C<loop>). So, long loops might be a good place to use it.

=head1 IMPLEMENTATION

Event::File::tail is a fake watcher in the Event point of view.  On the other hand, it
does use two helper watchers for each Event::File::tail, a read io and a timer watchers.
In case you are debugging and need to findout about them, every tail watcher has an unique
id during the program execution (use C<$watcher->id) to retrive it).  Each helper watcher
does have the id number on its description (desc).

=head1 SEE ALSO

Event(3), Tutorial.pdf, cmc

=head1 AUTHOR

Raul Dias <raul@dias.com.br>


