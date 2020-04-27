package MPV::Simple::JSON;

use strict;
use warnings;
use IO::Handle;
use IO::Socket::UNIX;
use JSON;
use File::Temp qw(tempdir);


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

# Avoid zombies
$SIG{CHLD} = 'IGNORE';

sub new {
    my ($class,%opts) = @_;
    
    my ($reader, $writer,$evreader, $evwriter);
    pipe $reader, $writer;
    pipe $evreader, $evwriter;
    $writer->autoflush(1);
    $evwriter->autoflush(1);
    #$reader->blocking(0);
    $evreader->blocking(0);
    
    my $tmp = tempdir(CLEANUP => 1);
    my $SOCK_PATH = "$tmp/mpv.sock";
    
    my $pid = fork();
    
    # MPV starts the server
    if ($pid == 0) {
        system("mpv --idle --terminal=no --input-ipc-server=$SOCK_PATH");
        print "Exiting MPV\n";
        unlink $SOCK_PATH;
        exit 0;
    }
    
    # Main
    # Wait until server is started
    sleep 0.1 until (-e $SOCK_PATH);
    
    # Create the client
    my $client = IO::Socket::UNIX->new(
            Type => SOCK_STREAM(),
            Peer => $SOCK_PATH,
    ) or die "Could not open connection: $@\n";
    
    
    # Event Loop retrieving events and results
    my $pid2 = fork();
    if ($pid2 == 0) {
        close $evreader;
        close $reader;
        mpv($client,$writer, $evwriter);
    }
    
    my $obj ={};
    $obj->{client} = $client;
    $obj->{pid} = $pid;
    $obj->{pid2} = $pid2;
    
    close $evwriter;
    close $writer;
    $obj->{reader} = $reader;
    $obj->{evreader} = $evreader;
    
    
    bless $obj;
    return $obj;
}

sub set_property_string {
    my ($obj,$name,$value) = @_;
    my $hash = {
            'command' => ['set_property_string', $name, $value]
    };
    my $json =to_json($hash);
    my  $client = $obj->{client};
    print $client $json."\n";
    
    my $reader = $obj->{reader};
    my $ret = <$reader>;
    $ret = from_json($ret);
    return $ret;
}

sub get_property_string {
    my ($obj,$name) = @_;
    my $hash = {
            'command' => ['get_property_string', $name]
    };
    my $json =to_json($hash);
    my  $client = $obj->{client};
    print $client $json."\n";
    
    my $reader = $obj->{reader};
    my $ret = <$reader>;
    $ret = from_json($ret);
    return $ret;
}

sub observe_property_string {
    my ($obj,$id, $name) = @_;
    my $hash = {
            'command' => ['observe_property_string', $id, $name]
    };
    my $json =to_json($hash);
    my  $client = $obj->{client};
    print $client $json."\n";
    
    my $reader = $obj->{reader};
    my $ret = <$reader>;
    $ret = from_json($ret);
    return $ret;
}

sub unobserve_property {
    my ($obj,$id) = @_;
    my $hash = {
            'command' => ['observe_property_string', $id]
    };
    my $json =to_json($hash);
    my  $client = $obj->{client};
    print $client $json."\n";
    
    my $reader = $obj->{reader};
    my $ret = <$reader>;
    $ret = from_json($ret);
    return $ret;
}

sub command {
    my ($obj,@args) = @_;
    my $hash = {
            'command' => [@args]
    };
    my $json =to_json($hash);
    my  $client = $obj->{client};
    print $client $json."\n";
    my $reader = $obj->{reader};
    my $ret = <$reader>;
    $ret = from_json($ret);
    return $ret;
}

sub terminate_destroy {
    my ($obj) = @_;
    my $hash = {
            'command' => ['quit']
    };
    my $json =to_json($hash);
    my  $client = $obj->{client};
    print $client $json."\n";
    
    #my $reader = $obj->{reader};
    #my $ret = <$reader>;
    #$ret = from_json($ret);
    #return $ret;
    
}

sub mpv {
    my ($client,$writer, $evwriter) = @_;
    
    while (1) {
        while (my $line = <$client>) {
            my $perl_scalar = from_json($line);
            
            if ( $perl_scalar->{event} ) {
                print $evwriter $line;
            }
            else {
                print $writer $line;
            }
        }
        close $evwriter;
        close $writer;
        exit 0;
    }
}

sub get_events {
    my ($self) = @_;
    my $evreader = $self->{evreader};
    my $line = <$evreader>;
    return undef unless ($line);
    my $ret = from_json($line);
    return $ret;
    
}

DESTROY {
    my ($self) = @_;
    if ( my $pid=$self->{pid} ) {
            close $self->{reader};
            close $self->{evreader};
            kill(9,$pid);
    }
    if ( my $pid=$self->{pid2} ) {
            kill(9,$pid);
    }
}


1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

MPV::Simple::JSON

=head1 SYNOPSIS

        use strict;
    use warnings;
    use utf8;
    use MPV::Simple::JSON;
    use Tcl::Tk;
    
    # IMPORTANT: Because the mpv process is in MPV::Simple::JSON multithreaded
    # you MUST create the MPV::Simple::Object before creating the TCL interpreter
    # and before doing any GUI work!!!
    my $mpv = MPV::Simple::JSON->new(event_handling => 1);
    my $int = Tcl::Tk->new();
    
    my $mw = $int->mainwindow();
    $mw->title("MPV::Simple example");  
    
    # Create the video frame
    my $f = $mw->Frame(-width => 640, -height => 480)->pack(-expand =>1,-fill => "both");
    
    # Until the video frame is mapped, we set up the MPV Player in this video frame
    $f->bind('<Map>' => sub {
        $f->bind('<Map>' => sub {});
        
        # The video shall start paused here
        $mpv->set_property_string("pause","yes");
        
        # With the MPV property "wid" you can embed MPV in a foreign window
        # (therefore it was important, that $f is already mapped!)
        $mpv->set_property_string("wid",$f->id());
        
        # Load a video file
        $mpv->command("loadfile", "path_to_video.ogg");
    });
    
    # For handling events you must repeatly call a event handler.
    # A good value for the timeout is 200-1000ms (I think 500ms is enough)
    # Another aproach would be, that the Tcl::Tk loop coexists with the 
    # MPV loop (see MPV::Simple::Pipe for an example)
    $int->call('after',1000,\&handle_events);
    
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
    $int->MainLoop;
    
    # Event handler
    # If you set $opt{event_handling} to a true value in the constructor
    # the events are sent through a non-blocking pipe ($mpv->{evreader}) you can access 
    # by the method $mpv->get_events(); which returns a hashref of the event
    # The event_ids can be translated to the event names with the global array 
    # $MPV::Simple::event_names[$id]
    sub handle_events {
        while ( my $event = $mpv->get_events() ) {
            if ($event->{event} eq "property-change") {
                    print "prop ".$event->{name}." changed to ".$event->{data}." %\n";
            }
            else {
                    print $event->{event}."\n";
            }
        }
    
    # Don't forget to call the event handler repeatly
    $int->call('after',1000,\&handle_events);
    }
    
=head1 DESCRIPTION

With this pure perl module you can use the mpv media player through the JSON IPC interface (see L<https://mpv.io/manual/stable/#json-ipc>). This is useful to integrate mpv in a foreign event loop, especially to interact with GUI toolkits. The module give access to the same methods as L<MPV::Simple>. Furthermore, if the option $opt{event_handling} is passed to a true value, events are passed trough a pipe ($mpv->{evreader}) which can be accessed by $mpv->get_events(). In this case you can and must handle the events by a repeatly call of a subroutine. See the example above.

=head2 Methods

The following methods exist. See L<MPV::Simple> for a detailled description. MPV::Simple::JSON orientates itself as far as possible to the original JSON IPC interface. Thererfore there are some differences to MPV::Simple and MPV::Simple::Pipe which are described hereafter. Furthermore you don't have to initialize the mpv player (and apart from that cannot).

=item * my $mpv = MPV::Simple->new()
IMPORTANT: Because the mpv process is in MPV::Simple::JSON multithreaded you MUST create the MPV::Simple::Object before creating the TCL interpreter and before doing any GUI work!!!

=item * $mpv->set_property_string('name','value');

=item * my $ret = $mpv->get_property_string('name');
IMPORTANT: the return value is contrary to MPV::Simple or MPV::Simple::Pipe a hashref. You can access the returned value with C<$ret->{data}.

=item * $mpv->observe_property_string(id,'name');
IMPORTANT: As Contrary to MPV::Simple  and MPV::Simple::Pipe the order of the arguments is inverted, first id, then the name of the property.

=item * $mpv->unobserve_property(registered_id);

=item * $mpv->command($command, @args);

=item * $mpv->terminate_destroy()
Note: After terminating you cannot use the MPV object anymore. Instead you have to create a new MPV object.

=head2 Error handling

Every MPV method will send back a hashref as a reply indicating whether the command was run correctly, and an additional field holding the command-specific return data (it can also be null). The error key can be accessed with C<$return->{error}> and is "success" if everything went well. See L<https://mpv.io/manual/stable/#json-ipc> for details of the protocoll.

=head1 SEE ALSO

See also the manual of the mpv media player in L<http://mpv.io> and especially the description of the JSON IPC at L<https://mpv.io/manual/stable/#json-ipc>. 
