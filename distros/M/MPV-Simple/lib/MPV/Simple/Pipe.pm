package MPV::Simple::Pipe;

use strict;
use warnings;
use IO::Handle;
use MPV::Simple;
use Storable qw(freeze thaw);
use Time::HiRes qw(usleep);
use threads;
use threads::shared;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use MPV::Simple ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);


# Wake event loop up, when a command is passed to the mpv process
#our $wakeup;
our $wakeup :shared;

# Avoid zombies
$SIG{CHLD} = 'IGNORE';

sub new {
    my ($class,%opts) = @_;
    
    my ($reader, $writer,$reader2, $writer2,$evreader, $evwriter);
    
    
    # Fork
    pipe $reader, $writer;
    pipe $reader2, $writer2;
    pipe $evreader, $evwriter;
    $writer->autoflush(1);
    $writer2->autoflush(1);
    $evwriter->autoflush(1);
    $reader->blocking(0);
    $evreader->blocking(0);
    
    
    # Kommando Schnittstelle
    my $pid = fork();
    die "Cannot fork: $!\n" unless (defined $pid);
   
    # Main
    my $obj ={};
    if ($pid != 0) {
        close $writer2;
        close $reader;
        $obj->{reader} = $reader2;
        $obj->{writer} = $writer;
        $obj->{pid} = $pid;
        
        close $evwriter;
        $obj->{evreader} = $evreader;
        $obj->{event_handling} = $opts{event_handling} || 0;
        bless $obj, $class;
        usleep(100);
        return $obj;
    }
    # Event Handler
    else {
        close $reader2;
        close $writer;
        close $evreader;
        mpv($reader,$writer2,$evwriter,%opts);
        exit 0;
    }
    
    
}

sub terminate_destroy {
    my ($obj,@args) = @_;
    my $args = join('###',@args);
    my $line = "terminate_destroy###$args\n";
    my $writer = $obj->{writer};
    print $writer $line;
}

sub AUTOLOAD {
    my ($obj,@args) = @_;
    our $AUTOLOAD;
    
    # trim package name
    my $func = $AUTOLOAD; 
    $func =~ s/.*:://;
    
    my $args = join('###',@args);
    my $line = "$func###$args\n";
    
    my $writer = $obj->{writer};
    print $writer $line;
    
    my $reader = $obj->{reader};
    my $ret = <$reader>;
    chomp $ret;
    return $ret;
}

sub mpv {
    my ($reader,$writer2,$evwriter,%opts) = @_;
    
    my $ctx = MPV::Simple->new() or die "Could not create MPV instance: $!\n";
    
    #New implementation: use mpv_set_wakeup_callback
    $ctx->set_wakeup_callback('MPV::Simple::Pipe::wakeup');
    
    #old implementation:
    #$ctx->setup_event_notification();
    
    while (1) {
        
        while ( defined(my $line = <$reader>) ) {
            last unless ($line);
            _process_command($ctx,$line,$writer2);
        }
        
        #old implementation
        #my $wakeup = $ctx->has_events;
        
        while ($wakeup) {
            $wakeup = 0;
            
            while (my $event = $ctx->wait_event(0)) {
                        my $id = $event->{id};
                        last if ($id == 0);
                        my $name = $event->{name} || '';
                        my $data = $event->{data} || '';
                        my $event_name = $MPV::Simple::event_names[$id];
                        print $evwriter "$id###$name###$data###$event_name\n" if ($opts{event_handling} && $id != 0);
                    }
            }
            
        # We have to add a little sleep to save CPU!    
        usleep(100);
            
    }
    close $writer2;
    close $evwriter;
    close $reader;
    exit 0;
}

sub wakeup {
    $wakeup = 1;
}

sub _process_command {
    my ($ctx,$line,$writer2) = @_;
    my $return;
    chomp $line;
    my ($command, @args) = split('###',$line);
    if ($command eq "terminate_destroy") {
        
        $ctx->terminate_destroy();
    }
    elsif ($command eq "get_property_string") {
        $return = $ctx->get_property_string(@args);
        # Don't forget \n at the end!!!
        print $writer2 "$return\n";
    }
    else {
        
        eval{
            $return = $ctx->$command(@args);
        };
        if ($@) {
                print "FEHLER:$@\n";
        }
        
        print $writer2  "$return\n";
    }
    
}

sub get_events {
    my ($self) = @_;
    my $evreader = $self->{evreader};
    
    my $line = <$evreader>;
    return undef unless ($line);
    chomp $line;
    
    #my $event = thaw($line);
    #return $event;
    
    my ($event_id,$name,$data,$event_name) = split('###',$line);
    return {
        event_id => $event_id,
        event => $event_name,
        name => $name,
        data => $data,
    };
}

DESTROY {
    my ($self) = @_;
    if ( my $pid=$self->{pid} ) {
            close $self->{reader};
            close $self->{evreader};
            close $self->{writer};
            kill(9,$pid);
    }
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

MPV::Simple::Pipe

=head1 SYNOPSIS

    use strict;
    use warnings;
    use utf8;
    use MPV::Simple::Pipe;
    use Tcl::Tk;
    use Time::HiRes qw(usleep);
    
    # 1) It is recommended to to create the MPV::Simple::Pipe object before TCL
    # interpreter because this forks and copies the perl environment
    # 2) If you want to handle events you have to pass a true value to the 
    # option event_handling 
    my $mpv = MPV::Simple::Pipe->new(event_handling => 1);
    
    my $int = Tcl::Tk->new();
    my $mw = $int->mainwindow();
    $mw->title("MPV::Simple example");  
    
    # Create the video frame
    my $f = $mw->Frame(-width => 640, -height => 480)->pack(-expand =>1,-fill => "both");
    
    # Until the video frame is mapped, we set up the MPV Player in this video frame
    $f->bind('<Map>' => sub {
        $f->bind('<Map>' => sub {});
        
        $mpv->initialize();
        
        # The video shall start paused here
        $mpv->set_property_string("pause","yes");
        
        # With the MPV property "wid" you can embed MPV in a foreign window
        # (therefore it was important, that $f is already mapped!)
        $mpv->set_property_string("wid",$f->id());
        
        # Load a video file
        $mpv->command("loadfile", "path_to_video.ogg");
    });
    
    my $b1 = $mw->Button(
        -text   =>  "Play",
        -command => sub {$mpv->set_property_string('pause','no')}
    )->pack(-side => 'left');
    my $b2 = $mw->Button(
        -text   =>  "Pause",
        -command => sub {$mpv->set_property_string('pause','yes')}
    )->pack(-side => 'left');
    my $b3 = $mw->Button(
        -text   =>  "Backward",
        -command => sub {$mpv->command('seek',-5)}
    )->pack(-side => 'left');
    my $b4 = $mw->Button(
        -text   =>  "Forward",
        -command => sub {$mpv->command('seek',5)}
    )->pack(-side => 'left');
    my $b5 = $mw->Button(
        -text   =>  "Close",
        # I recommend to destroy first the Tcl::Tk main window, and
        # then the mpv instance
        -command => sub {$mw->destroy();$mpv->terminate_destroy();}
    )->pack(-side => 'left');
    
    # In this example the Tcl loop coexists with the MPV loop
    # see L<https://docstore.mik.ua/orelly/perl3/tk/ch15_09.htm>
    # Another approach (especially if coexisting loops are not possible) 
    # would be using a timer, see MPV::Simple:JSON for an example
    loop($int);
    
    sub loop {
        my $int = shift;
        while ($int->Eval("info commands .")) { 
            while (my $stat = $int->DoOneEvent(Tcl::DONT_WAIT) ) {}
            while (my $event = $mpv->get_events() ){handle_event($event);}
            
            # Important: We add a little sleep to save CPU!
            usleep(100);
        }
        print "Shuting down..\n";
        $mpv->terminate_destroy();
    }
    
    # Event handler
    # If you set $opt{event_handling} to a true value in the constructor
    # the events are sent through a non-blocking pipe ($mpv->{evreader}) you can access 
    # events by the method $mpv->get_events(); which returns a hashref of the event
    # The event_ids can be translated to the event names with the global array 
    # $MPV::Simple::event_names[$id]
    sub handle_event {
        my $event = shift;
        if ($event->{event} eq "property-change") {
            print "prop ".$event->{name}." changed to ".$event->{data}." %\n";
        }
        else {
            print $event->{event}."\n";
        }
    }
    
=head1 DESCRIPTION

Using MPV::Simple as a seperate process to integrate it in a foreign event loop, especially to interact with GUI toolkits. The module give access to the same methods as L<MPV::Simple>. Furthermore, if the option $opt{event_handling} is passed to a true value, events are passed trough a pipe ($mpv->{evreader}) which can be accessed by $mpv->get_events(). In this case you can and must handle the events by a repeatly call of a subroutine. See the example above.

=head2 Methods

The following methods exist. See L<MPV::Simple> for a detailled description.

=item * my $mpv = MPV::Simple->new()

=item * $mpv->initialize()

=item * $mpv->set_property_string('name','value');

=item * $mpv->get_property_string('name');

=item * $mpv->observe_property_string('name', id);

=item * $mpv->unobserve_property(registered_id);

=item * $mpv->command($command, @args);

=item * $mpv->terminate_destroy()
Note: After terminating you cannot use the MPV object anymore. Instead you have to create a new MPV object.

=head2 Error handling

You can use MPV::Simple::error_names(), MPV::Simple::check_error() and MPV::Simple::warn_error() to handle errors. See L<MPV::Simple> for details.

=head1 SEE ALSO

See the doxygen documentation at L<https://github.com/mpv-player/mpv/blob/master/libmpv/client.h> and the manual of the mpv media player in L<http://mpv.io>.
