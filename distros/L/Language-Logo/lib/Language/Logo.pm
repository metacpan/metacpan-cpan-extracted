#
#  Language::Logo.pm
#
#  An implementation of the Logo programming language which allows
#  multiple clients to connect simultaneously.
#
#  Written January 2007, by John C. Norton
#  Presented at Boston Perlmongers on January 16th, 2007
#  Last update -- 1/30/2007  22:12
#


# Package header
package Logo;
our $VERSION = '1.000';              # Current version


# Strict
use strict;
use warnings;


# Libraries
use Data::Dumper;
use IO::Select;
use IO::Socket;
use Sys::Hostname;


#################
### Variables ###
#################
use constant PI => (4 * atan2(1, 1));

# User-defined
my $iam           = "Language::Logo";     # Module identifier
my $d_title       = "$iam version $VERSION";

my $max_connect   = 16;         # Maximum client connections
my $retry_timeout = 10;         # Client connection timeout after N seconds

# Defaults
my $d_port       = "8220";       # Default socket port
my $d_update     = 10;           # Default gui update rate
my $d_bg         = "black";      # Default canvas background color
my $d_width      = 512;          # Default canvas width
my $d_height     = 512;          # Default canvas height
my $d_color      = 'white';      # Default pen/turtle color
my $d_psize      = '1';          # default pen size (thickness)
my $d_txdim      = '6';          # Default turtle x-dimension
my $d_tydim      = '9';          # Default turtle y-dimension

my @switches     = qw( verbose name title bg width height update host port );
my %switches     = map { $_ => 1 } @switches;

# Global (server-specific) variables
my $pserver_vars  = [qw( nticks verbose count total )];

# Client-specific top-level variables (with initial values)
my $pclient_vars = {
    'debug' => 0,
    'step'  => 0,
};

# Turtle state info passed back from server to client
my $pinfo = [qw( x y angle pen color size show wrap )];

# Command aliases and descriptions
my $palias = {
    'fd' => [ 'forward',     'Moves forward the given number of pixels' ],
    'bk' => [ 'backward',    'Moves backward the given number of pixels' ],
    'rt' => [ 'right',       'Rotates clockwise the given angle' ],
    'lt' => [ 'left',        'Rotates counter-clockwise the given angle' ],
    'sh' => [ 'seth',        'Sets the turtle heading to the given angle' ],
    'pu' => [ 'penup',       'Stops drawing' ],
    'pd' => [ 'pendown',     'Starts drawing' ],
    'ps' => [ 'pensize',     'Specifies the line width to draw with' ],
    'co' => [ 'color',       'Specifies the color to draw with' ],
    'cs' => [ 'clear',       'Clears the screen' ],
    'hm' => [ 'home',        'Homes the turtle to the starting position' ],
    'sx' => [ 'setx',        'Sets the x-coordinate' ],
    'sy' => [ 'sety',        'Sets the y-coordinate' ],
    'xy' => [ 'setxy',       'Sets the x and y coordinates' ],
    'ht' => [ 'hideturtle',  'Makes the turtle invisible' ],
    'st' => [ 'showturtle',  'Makes the turtle visible' ],
    'w'  => [ 'width',       'Specifies the width of the screen (global)' ],
    'h'  => [ 'height',      'Specifies the height of the screen (global)' ],
    'bg' => [ 'background',  'Sets the screen background color (global)' ],
    'ud' => [ 'update',      'Changes the Tk update interval (global)' ],
    'wr' => [ 'wrap',        'Sets wrap (0=normal, 1=torus, 2=reflective)' ],
};


my $pmethods = {
    'forward'    => 'move_turtle', 
    'backward'   => 'move_turtle',
    'right'      => 'turn_turtle',
    'left'       => 'turn_turtle',
    'seth'       => 'turn_turtle',
    'penup'      => 'change_pen_state',
    'pendown'    => 'change_pen_state',
    'pensize'    => 'change_pen_size',
    'color'      => 'change_color',
    'clear'      => 'modify_canvas',
    'width'      => 'modify_canvas',
    'height'     => 'modify_canvas',
    'background' => 'modify_canvas',
    'home'       => 'reset_turtle',
    'setx'       => 'move_turtle',
    'sety'       => 'move_turtle',
    'setxy'      => 'move_turtle',
    'hideturtle' => 'show_turtle',
    'showturtle' => 'show_turtle',
    'update'     => 'change_update',
    'wrap'       => 'set_wrap_value',
};


###################
### Subroutines ###
###################

#===================
#=== Client code ===
#===================
sub new {
    my ($class, @args) = @_;
    (ref $class) and $class = ref $class;

    # Create blessed reference
    my $self = { };
    bless $self, $class;

    # Parse optional arguments
    while (@args) {
        my $arg = shift @args;
        if ($arg =~ /^sig(.+)$/) {
            # Trap specified signals
            my $sig = uc $1;
            $SIG{$sig} = shift @args;
        } elsif (defined($switches{$arg}) and @args > 0) {
            # Assign all valid parameters
            $self->{$arg} = shift @args;
        }
    }

    # Startup a new server locally if 'host' was not defined.
    if (!defined($self->{'host'})) {
        $self->fork_server();
    }

    # Connect to the server
    $self->connect_to_server();

    # Return the object
    return $self;
}


sub disconnect {
    my ($self, $msg) = @_;
    if ($msg || 0) {
        print "$msg";
        <STDIN>;
    }
    my $sock = $self->{'socket'};
    if ($sock || 0) {
        close($sock);
    }
}


sub connect_to_server {
    my ($self) = @_;

    # Return if socket is already connected
    my $sock = $self->{'socket'};
    ($sock || 0) and return $sock;

    # If hostname is ':', use local host
    my $host = $self->{'host'} || ':';
    ($host eq ':') and $host = hostname();

    my $port = $self->{'port'} || $d_port;
    my %params = (
        'PeerAddr'  => $host,
        'PeerPort'  => $port,
        'Proto'     => 'tcp',
        'ReuseAddr' => 0,
    );

    # Keep retrying until $retry_timeout is exceeded
    my $start = time;
    while (1) {
        ($sock = new IO::Socket::INET(%params)) and last;   # Success!
        if (time - $start > $retry_timeout) {
            die "$iam:  Failed client socket connection\n";
        }
        select(undef, undef, undef, 0.1);
    }

    # Save socket
    $self->{'socket'} = $sock;
    my $name = $self->{'name'}   || "";
    print $sock ":$name\n";
    chomp(my $ans = <$sock>);
    if ($ans !~ /^(\d+):(.+)$/) {
        die "$iam:  expected 'id:name', got '$ans'\n";
    }
    my ($id, $newname) = ($1, $2);
    $self->{'id'}   = $id;
    $self->{'name'} = $newname;
    $self->{'host'} = $host;
    return $sock;
}


sub host {
    my ($self) = @_;
    return $self->{'host'};
}


sub interact {
    my ($self) = @_;

    print "Type '?' for help\n";
    while (1) {
        print "$iam> ";
        my $cmd = <STDIN>;
        defined($cmd) or return;
        chomp $cmd;
        $cmd =~ s/^\s*(.*)\s*$/$1/;     # Trim whitespace
        next if ($cmd eq "");

        if ($cmd eq 'quit' or $cmd eq 'bye' or $cmd eq 'exit') {
            # Exit interactive mode
            return 0;
        }

        if ($cmd eq "?") {
            $self->interactive_help();
        } else {
            $self->interactive_command($cmd);
        }
    }
}


sub interactive_help {
    printf "    Command Abbr  Description\n";
    print  "-" x 79, "\n";
    my @keys = keys %$palias;
    my @sort = sort { $palias->{$a}->[0] cmp $palias->{$b}->[0] } @keys;
    foreach my $alias (@sort) {
        my $pcmd = $palias->{$alias};
        my ($full, $desc) = @$pcmd;
        printf  " %10.10s  %3.3s  %s\n", $full, $alias, $desc;
    }
}


sub interactive_command {
    my ($self, $cmd) = @_;

    # Send a Logo command
    my $preply = $self->command($cmd);
    my $err = $preply->{'error'};
    if (defined($err)) {
        print "ERROR:  $err\n";
    } else {
        my $text = "";
        foreach my $param (@$pinfo) {
            my $val = $preply->{$param};
            $text and $text .= ",";
            $text .= "$param=$val";
        }
        print "[$text]\n";
    }
}


sub query {
    my ($self, @params) = @_;
    my $sock = $self->connect_to_server();
    my $preply = $self->client_send($sock, "?");
    defined($preply->{'error'}) and return $preply;
    my @values = ( );
    foreach my $param (@params) {
        if (!defined($preply->{$param})) {
            $preply->{'error'} = "Server parameter '$param' undefined";
            return $preply;
        }
        my $value = $preply->{$param};
        push @values, $value;
    }
    return wantarray? (@values): $values[0];
}


sub command {
    my ($self, $cmdstr) = @_;
    my $sock = $self->connect_to_server();
    $sock or return 0;
    my @commands = split(';', $cmdstr);
    my $preply = { };
    foreach my $cmd (@commands) {
        $cmd =~ s/^\s*//;    # Trim leading whitespace
        $cmd =~ s/\s*$//;    # Trim trailing whitespace
        $preply = $self->client_send($sock, "=$cmd");
        defined($preply->{'error'}) and return $preply;
    }
    return $preply;
}


sub cmd {
    my $self = shift;
    return $self->command(@_);
}


sub client_send {
    my ($self, $sock, $text) = @_;
    print $sock $text, "\n";
    my $answer = <$sock>;
    $answer or die "$iam:  server socket went away\n";
    chomp $answer;
    my $preply = { };
    if ($answer =~ s/^!//) {
        $preply->{'error'} = $answer;
        return $preply;
    }
    $answer =~ s/^(.)//;
    my @params = split(',', $answer);
    foreach my $param (@params) {
        my ($param, $val) = ($param =~ /^(.*)=(.*)$/);
        $preply->{$param} = $val;
    }
    return $preply;
}


#===================
#=== Server code ===
#===================
sub fork_server {
    my ($self) = @_;

    my $verbose = $self->{'verbose'} || 0;
    my $title   = $self->{'title'}   || $d_title;
    my $w       = $self->{'width'}   || $d_width;
    my $h       = $self->{'height'}  || $d_height;
    my $bg      = $self->{'bg'}      || $d_bg;
    my $update  = $self->{'update'}  || $d_update;
    my $host    = $self->{'host'}    || hostname();
    my $port    = $self->{'port'}    || $d_port;
   
    my $fork = fork();
    defined($fork) or die "$iam:  failed to fork server\n";
    $fork and return;
    Logo->server_init($verbose, $title, $w, $h, $bg, $update, $host, $port);
}


sub server_init {
    my ($class, $verbose, $title, $w, $h, $bg, $update, $host, $port) = @_;

    # Create a blessed object
    my $self = {
        'nticks'   => 0,        # Tracks number of GUI updates
        'verbose'  => $verbose, # Verbose flag
        'count'    => 0,        # Current number of connections
        'total'    => 0,        # Total number of connections
        'clients'  => { },      # The client hash
        'names'    => { },      # The clients by name
    };
    bless $self, $class;

    # Open a socket connection at the desired port
    my %params = (
        'LocalHost' => $host,
        'LocalPort' => $port,
        'Proto'     => 'tcp',
        'Listen'    => $max_connect,
        'ReuseAddr' => 0,
    );

    # Create socket object
    my $sock = new IO::Socket::INET(%params);
    if (!$sock) {
        # Port is already in use -- client will connect to it instead
        $verbose and print "[Port $port already in use]\n";
        exit;
    }
    $self->{'socket'} = $sock;

    # Create select set for reading
    $self->{'select'} = new IO::Select($sock);

    # Create the GUI
    require Tk;
    $verbose and print "[Logo server v$VERSION on '$host']\n";
    my $mw = Tk::MainWindow->new(-title => $title);
    $self->{'mw'} = $mw;

    # Allow easy dismissal of the GUI
    $mw->bind("<Escape>" => sub { $self->server_exit });

    # Create a new canvas
    $self->clear_screen($w, $h, $bg);

    # Manage the GUI
    $self->{'repid'} = $self->set_update($update);
    Tk::MainLoop();
}


sub server_exit {
    my ($self) = @_;
    my $mw = $self->{'mw'};

    my $sel      = $self->{'select'};
    my $sock     = $self->{'socket'};
    my $pclients = $self->{'clients'};
    my $pnames   = $self->{'names'};

    close $sock;

    foreach my $name (keys %$pnames) {
        my $pclient = $pnames->{$name};
        my $fh = $pclient->{'fh'};
        $self->server_remove_client($pclients, $sel, $fh);
    }

    # Shouldn't ever get here, since when the last client exited,
    # the server should have already gone away. But just in case ...
    #
    $mw->destroy();
    exit;
}


sub set_update {
    my ($self, $update) = @_;
    ($update < 1)    and $update = 1;
    ($update > 1000) and $update = 1000;
    $self->{'update'} = $update;
    my $mw = $self->{'mw'};
    my $id = $mw->repeat($update => sub { $self->server_loop() });
    return $id;
}


sub server_loop {
    my ($self) = @_;

    # Increment tick count
    ++$self->{'nticks'};

    # Get data from the object
    my $sel      = $self->{'select'};
    my $sock     = $self->{'socket'};
    my $pclients = $self->{'clients'};

    # Handle each pending socket
    my @readable = $sel->can_read(0);
    foreach my $rh (@readable) {
        if ($rh == $sock) {
            # The main socket means a new incoming connection.
            $self->server_add_client($rh, $pclients);
        } else {
            # Service the socket
            my $text = <$rh>;

            if (defined($text)) {
                # Process command
                chomp $text;
                my $pc = $pclients->{$rh};
                if ($text eq '?') {
                    $self->server_query($pc);
                } elsif ($text =~ s/^=//) {
                    $self->server_command($pc, $text);
                }
            } else {
                # Socket was closed -- remove the client
                $self->server_remove_client($pclients, $sel, $rh);
            }
        }
    }
}


sub server_add_client {
    my ($self, $rh, $pclients) = @_;

    # Accept the client connect and add the new socket
    my $sel = $self->{'select'};
    my $ns  = $rh->accept();
    $sel->add($ns);

    my $verbose = $self->{'verbose'};
    my $peer = getpeername($ns);
    my ($port, $iaddr) = unpack_sockaddr_in($peer);
    my $remote = inet_ntoa($iaddr);

    # Get the client handshake, and send back its unique ID
    chomp(my $text = <$ns>);
    ($text =~ /^:(.*)$/) or die "Bad header, expected ':[name]', got '$text'";
    my $name = $1 || "";

    my $id = $self->{'total'} + 1;
    $name ||= "CLIENT$id";
    print $ns "$id:$name\n";

    my $pc = $pclients->{$ns} = {
        'id'      => $id,
        'fh'      => $ns,
        'name'    => $name,
        'remote'  => $remote,
    };

    # Assign defaults to client-specific variables
    map { $pc->{$_} = $pclient_vars->{$_} } (keys %$pclient_vars);

    # Create the 'turtle' object
    $self->create_turtle($pc);

    # Increment the number of connections and the total connection count
    ++$self->{'count'};
    ++$self->{'total'};

    # Add the client's name
    $verbose and print "[Added socket $id => '$name']\n";
    $self->{'names'}->{$name} = $pclients->{$ns};
}


sub server_remove_client {
    my ($self, $pclients, $sel, $fh) = @_;;
    my $verbose = $self->{'verbose'};
    my $pc = $pclients->{$fh};
    my $name = $pc->{'name'};
    my $id   = $pc->{'id'};
    $sel->remove($fh);
    close($fh);
    delete $pclients->{$fh};

    # Remove the client's name
    my $pnames = $self->{'names'};
    delete $pnames->{$name};

    # Remove the client's turtle
    my $cv    = $self->{'canvas'};
    my $ptids = $pc->{'turtle'}->{'tids'};
    ($ptids || 0) and map { $cv->delete($_) } @$ptids;

    # Decrement the global client count
    --$self->{'count'};
    $verbose and print "[Closed socket $id '$name']\n";

    # Exit the server if this is the last connection
    if (0 == $self->{'count'} and $self->{'total'} > 0) {
        $verbose and print "[Final client closed -- exiting]\n";
        $self->{'mw'}->destroy();
        exit;
    }
}


sub server_query {
    my ($self, $pc) = @_;
    my $text = "";
    foreach my $param (@$pserver_vars) {
        $text and $text .= ",";
        my $val = $self->{$param};
        $text .= "$param=$val";
    }
    my $fh = $pc->{'fh'};
    printf $fh "?$text\n";
}


sub server_command {
    my ($self, $pc, $cmdstr) = @_;
    my $id = $pc->{'id'};
    $pc->{'lastcmd'} = $cmdstr;

    my $debug = $pc->{'debug'};
    $debug and print "Command<$id>: '$cmdstr'\n";

    my @args = split(/\s+/, $cmdstr);
    my $cmd = shift @args;

    # Allow "noop" command to just query current client parameters
    if ($cmdstr eq 'noop') {
        return $self->server_reply($pc);
    }

    # Resolve any command alias
    while (defined($palias->{$cmd})) {
        my $pcmd = $palias->{$cmd};
        my $newcmd = $pcmd->[0];
        $cmd = $newcmd;
    }
    unshift @args, $cmd;

    # Execute one command if single-stepping is on
    if ($pc->{'step'}) {
        my $go = $self->server_single_step($pc, $cmd, [ @args ]);
        $go or return $self->server_reply($pc);
    }

    # Client variables
    if (defined($pclient_vars->{$cmd})) {
        return $self->server_set_variable($pc, @args);
    }

    # Find command in dispatch table
    my $method = $pmethods->{$cmd};
    defined($method) and return $self->$method($pc, @args);

    # Return acknowledgment
    $self->server_error($pc, "Unknown command '$cmd'");
}


sub server_set_variable {
    my ($self, $pc, $param, $val) = @_;
    $pc->{$param} = $val || 0;
    $pc->{'debug'} and print "Variable '$param' set to '$val'\n";
    $self->server_reply($pc);
}


sub server_single_step {
    my ($self, $pc, $cmd, $pargs) = @_;
    my $cmdstr = join(" ", @$pargs);
    print "Step>  [$cmdstr]  Execute {y|n|c}? [y]";
    chomp(my $ans = <STDIN>);
    ($ans =~ /^[cC]/) and $pc->{'step'} = 0;
    return ($ans =~ /^[nN]/)? 0: 1;
}


sub server_reply {
    my ($self, $pc) = @_;
    my $fh = $pc->{'fh'};
    my $turtle = $pc->{'turtle'};
    my $text = "";
    foreach my $param (@$pinfo) {
        my $val = $turtle->{$param};
        $text and $text .= ",";
        $text .= "$param=$val";
    }
    printf $fh "=$text\n";
}


sub server_error {
    my ($self, $pc, $msg) = @_;
    my $fh = $pc->{'fh'};
    $msg ||= "";
    print $fh "!$msg\n";
}


sub create_turtle {
    my ($self, $pc, $from) = @_;

    my $turtle = {
        'pen'    => 0,          # Pen state:  0 = 'up', 1 = 'down'
        'color'  => $d_color,   # Pen color (also turtle color)
        'size'   => $d_psize,   # Pen size (thickness)
        'xdim'   => $d_txdim,   # Turtle x-dimension
        'ydim'   => $d_tydim,   # Turtle y-dimension
        'dist'   => 0,          # Last distance traveled (used as default)
        'show'   => 1,          # Turtle starts out visible
        'wrap'   => 0,          # Normal wrap (= no wrap)
    };

    # Use old turtle as a reference
    if ($from || 0) {
        map { $turtle->{$_} = $from->{$_} } (keys %$from);
    }

    $self->home_turtle($pc, $turtle);
    $self->draw_turtle($pc, $turtle);
}


sub home_turtle {
    my ($self, $pc, $turtle) = @_;
    my $cv     = $self->{'canvas'};
    my $width  = $cv->cget(-width);
    my $height = $cv->cget(-height);

    my $x = int($width  / 2);
    my $y = int($height / 2);

    $turtle->{'x'}     = $x;
    $turtle->{'y'}     = $y;
    $turtle->{'angle'} = 0;
}


sub reset_turtle {
    my ($self, $pc, $cmd) = @_;
    my $turtle = $pc->{'turtle'};
    $self->home_turtle($pc, $turtle);
    $self->draw_turtle($pc, $turtle);
    $self->server_reply($pc);
}


sub draw_turtle {
    my ($self, $pc, $turtle) = @_;

    # Erase old turtle if one exists
    my $cv    = $self->{'canvas'};
    my $ptids = $pc->{'turtle'}->{'tids'};
    if ($ptids || 0) {
        map { $cv->delete($_) } @$ptids;
        $pc->{'turtle'}->{'tids'} = 0;
    }

    # Create turtle parameters
    my $cvbg   = $cv->cget(-bg);
    my $x      = $turtle->{'x'};
    my $y      = $turtle->{'y'};
    my $angle  = $turtle->{'angle'};
    my $color  = $turtle->{'color'};
    my $show   = $turtle->{'show'};
    my $xdim   = $turtle->{'xdim'};
    my $ydim   = $turtle->{'ydim'};

    if ($turtle->{'show'}) {
        # Assign points, rotate them, and plot the turtle
        my $ppts = [ $x, $y, $x-$xdim, $y, $x, $y-2*$ydim, $x+$xdim, $y ];
        $ppts = $self->rotate($x, $y, $angle, $ppts);
        my @args = (-fill => $cvbg, -outline => $color);
        my $tid = $cv->createPolygon(@$ppts, @args);
        $turtle->{'tids'} = [ $tid ];
        $pc->{'turtle'} = $turtle;

        # If the pen is down, draw a circle around the current point
        $ppts = [ ];
        if ($turtle->{'pen'}) {
            $ppts = [ $x-3, $y-3, $x+3, $y+3 ];
            $tid = $cv->createOval(@$ppts, -outline => $color);
            push @{$turtle->{'tids'}}, $tid;
        }
    }

    # Save the turtle to this client's data
    $pc->{'turtle'} = $turtle;
}


sub change_update {
    my ($self, $pc, $cmd, $update) = @_;
    my $repid = $self->{'repid'};
    ($repid || 0) and $repid->cancel();
    $self->{'repid'} = $self->set_update($update);
    $self->server_reply($pc);
}


sub set_wrap_value {
    my ($self, $pc, $cmd, $wrap) = @_;
    defined($wrap) or return $self->syntax_error($pc);
    $wrap = int($wrap);
    if ($wrap < 0 || $wrap > 2) {
        return $self->server_error($pc, "Invalid wrap value '$wrap'");
    }
    my $turtle = $pc->{'turtle'};
    $turtle->{'wrap'} = $wrap;
    $self->server_reply($pc);
}


sub modify_canvas {
    my ($self, $pc, $cmd, $val) = @_;

    my $cv = $self->{'canvas'};
    ($cmd eq 'clear')      and $self->clear_screen();
    ($cmd eq 'width')      and eval {$cv->configure('-wi', $val || $d_width)};
    ($cmd eq 'height')     and eval {$cv->configure('-he', $val || $d_height)};
    ($cmd eq 'background') and eval {$cv->configure('-bg', $val || $d_bg)};

    my $pnames = $self->{'names'};
    foreach my $name (keys %$pnames) {
        my $pclient = $pnames->{$name};
        my $turtle = $pclient->{'turtle'};
        if ($cmd eq 'w' or $cmd eq 'h') {
            # Have to recreate the turtle
            $self->create_turtle($pclient);
        } elsif ($cmd eq 'bg') {
            # Have to redraw the turtle
            $self->draw_turtle($pclient, $turtle);
        }
    }

    $self->server_reply($pc);
}


sub clear_screen {
    my ($self, $width, $height, $bg) = @_;

    # Clear any old canvas
    my $oldcv = $self->{'canvas'};
    if ($oldcv || 0) {
        $width  ||= $oldcv->cget(-width);
        $height ||= $oldcv->cget(-height);
        $bg     ||= $oldcv->cget(-bg);
        $oldcv->packForget();
    }
    
    # Create a new canvas
    $width  ||= $d_width;
    $height ||= $d_height;
    $bg     ||= $d_bg;
    my $mw = $self->{'mw'};
    my @opts = (-bg => $bg, -width => $width, -height => $height);
    my $cv = $mw->Canvas(@opts);
    $cv->pack(-expand => 1, -fill => 'both');
    $self->{'canvas'} = $cv;

    # For each client, draw its turtle
    my $pclients = $self->{'clients'} || { };
    foreach my $pc (values %$pclients) {
        my $turtle = $pc->{'turtle'};
        $self->create_turtle($pc, $turtle);
    }
}


sub rotate {
    my ($self, $x, $y, $angle, $ppoints) = @_;
    for (my $i = 0; $i < @$ppoints; $i += 2) {
        $ppoints->[$i]   -= $x;
        $ppoints->[$i+1] -= $y;
    }
    my $ppolar = $self->rect_to_polar($ppoints);
    for (my $i = 1; $i <= @$ppolar; $i += 2) {
        $ppolar->[$i] = ($ppolar->[$i] + $angle) % 360;
    }
    $ppoints = $self->polar_to_rect($ppolar);
    for (my $i = 0; $i < @$ppoints; $i += 2) {
        $ppoints->[$i]   += $x;
        $ppoints->[$i+1] += $y;
    }
    return $ppoints;
}


sub calculate_endpoint {
    my ($self, $x, $y, $angle, $dist) = @_;
    my $prect = $self->polar_to_rect([ $dist, $angle ]);
    my ($x1, $y1) = @$prect;
    $x1 += $x;
    $y1 += $y;
    return ($x1, $y1);
}


sub rect_to_polar {
    my ($self, $ppoints) = @_;
    my $ppolar = ( );
    while (@$ppoints > 1) {
        my $x = shift @$ppoints;
        my $y = shift @$ppoints;
        my $r = sqrt($x ** 2 + $y ** 2);
        my $t = $self->rad_to_deg(atan2($y, $x));
        push @$ppolar, $r, $t;
    }
    return $ppolar;
}


sub polar_to_rect {
    my ($self, $ppoints) = @_;
    my $prect = [ ];
    while (@$ppoints > 1) {
        my $r = shift @$ppoints;
        my $t = $self->deg_to_rad(shift @$ppoints);
        my $x = $r * cos($t);
        my $y = $r * sin($t);
        push @$prect, $x, $y;
    }
    return $prect;
}


sub deg_to_rad {
    my ($self, $degrees) = @_;
    my $radians = $degrees * PI / 180;
    ($radians < 0) and $radians += 6.283185307;
    return $radians;
}


sub rad_to_deg {
    my ($self, $radians) = @_;
    my $degrees = $radians * 180 / PI;
    ($degrees < 0) and $degrees += 360;
    return $degrees;
}


sub show_turtle {
    my ($self, $pc, $cmd) = @_;
    my $b_show = ($cmd eq 'st')? 1: 0;
    my $turtle = $pc->{'turtle'};
    $turtle->{'show'} = $b_show;
    $self->draw_turtle($pc, $turtle);
    $self->server_reply($pc);
}


sub change_color {
    my ($self, $pc, $cmd, $color) = @_;
    defined($color) or return $self->syntax_error($pc);

    # Allow a random color
    if (($color || "") eq 'random') {
        $color = sprintf "#%02x%02x%02x", rand 256, rand 256, rand 256;
    }

    my $turtle = $pc->{'turtle'};
    $turtle->{'color'} = $color;
    $self->draw_turtle($pc, $turtle);
    $self->server_reply($pc);
}


sub change_pen_state {
    my ($self, $pc, $cmd) = @_;
    my $state = ($cmd eq 'pendown')? 1: 0;
    my $turtle = $pc->{'turtle'};
    $turtle->{'pen'} = $state;
    $self->draw_turtle($pc, $turtle);
    $self->server_reply($pc);
}


sub change_pen_size {
    my ($self, $pc, $cmd, $size, @args) = @_;
    my $turtle = $pc->{'turtle'};

    # Allow a random pen size
    if (($size || "") eq "random") {
        my $min = $args[0];
        my $max = $args[1];
        defined($min) or return $self->syntax_error($pc);
        defined($max) or return $self->syntax_error($pc);
        $size = $min + rand($max - $min);
    }

    $size ||= $d_psize;
    $turtle->{'size'} = $size;
    $self->server_reply($pc);
}


sub syntax_error {
    my ($self, $pc) = @_;
    my $cmd = $pc->{'lastcmd'};
    $self->server_error($pc, "Syntax error in '$cmd'");
}


sub turn_turtle {
    my ($self, $pc, $cmd, $newang, $arg0, $arg1) = @_;

    my $turtle = $pc->{'turtle'};
    my $angle  = $turtle->{'angle'};

    # Allow a random angle of turn
    if (($newang || "") eq 'random') {
        defined($arg0) or return $self->syntax_error($pc);
        defined($arg1) or return $self->syntax_error($pc);
        $newang = $arg0 + rand($arg1 - $arg0);
    }

    # Make angles default to right angles
    defined($newang) or $newang = 90;

    # Assign the angle
    ($cmd eq 'left')  and $angle = $angle - $newang;
    ($cmd eq 'right') and $angle = $angle + $newang;
    ($cmd eq 'seth')  and $angle = $newang;

    # Normalize the angle
    while ($angle < 0)   { $angle += 360 }
    while ($angle > 360) { $angle -= 360 }

    $turtle->{'angle'} = $angle;
    $self->draw_turtle($pc, $turtle);
    $self->server_reply($pc);
}


sub move_turtle {
    my ($self, $pc, $cmd, $dist, $arg0, $arg1) = @_;
    my $turtle = $pc->{'turtle'};
    my $angle  = $turtle->{'angle'};
    my $wrap   = $turtle->{'wrap'};

    # Allow a random distance
    if (($dist || "") eq 'random') {
        defined($arg0) or return $self->syntax_error($pc);
        defined($arg1) or return $self->syntax_error($pc);
        $dist = $arg0 + rand($arg1 - $arg0);
    }

    $dist ||= $turtle->{'dist'};
    (0 == $dist) and return $self->syntax_error($pc);
    $turtle->{'dist'} = $dist;
    ($cmd eq 'forward')  and $angle = ($angle + 270) % 360;
    ($cmd eq 'backward') and $angle = ($angle + 90)  % 360;
    my ($x0, $y0) = ($turtle->{'x'}, $turtle->{'y'});
    my ($x1, $y1);
    if ($cmd eq 'setx' or $cmd eq 'sety' or $cmd eq 'setxy') {
        if ($cmd eq 'setxy') {
            defined($dist) or return $self->syntax_error($pc);
            defined($arg0) or return $self->syntax_error($pc);
            ($x1, $y1) = ($dist, $arg0);
        } else {
            defined($dist) or return $self->syntax_error($pc);
            ($x1, $y1) = ($x0, $y0);
            ($x1, $y1) = ($cmd eq 'setx')? ($dist, $y0): ($x0, $dist);
        }
    } else {
        ($x1, $y1) = $self->calculate_endpoint($x0, $y0, $angle, $dist);
    }

    my @args = ($pc, $x0, $y0, $x1, $y1);
    return $self->move_turtle_reflect(@args) if (2 == $wrap);
    return $self->move_turtle_torus(@args)   if (1 == $wrap);
    return $self->move_turtle_normal(@args); # Assume wrap == 0
}


sub move_turtle_normal {
    my ($self, $pc, $x0, $y0, $x1, $y1) = @_;
    my $turtle = $pc->{'turtle'};
    my $pen    = $turtle->{'pen'};
    my $size   = $turtle->{'size'};
    my $color  = $turtle->{'color'};

    $self->line($pen, $x0, $y0, $x1, $y1, $color, $size);
    $self->move($pc, $x1, $y1);
    $self->server_reply($pc);
}


sub move_turtle_torus {
    my ($self, $pc, $x0, $y0, $x1, $y1) = @_;
    my $turtle = $pc->{'turtle'};
    my $pen    = $turtle->{'pen'};
    my $size   = $turtle->{'size'};
    my $color  = $turtle->{'color'};

    # Calculate (dx, dy), which don't change for torus behavior
    my ($dx, $dy) = ($x1 - $x0, $y1 - $y0);

    while (!$self->contained($x1, $y1)) {
        my $height = $self->{'height'};
        my $width  = $self->{'width'};
        if (abs($dx) < 0.0000001) {
            # Vertical line
            my $yb = ($y1 < $y0)? 0: $height;
            $self->line($pen, $x0, $y0, $x0, $yb, $color, $size);
            ($y0, $y1) = $yb? (0, $y1-$height): ($height, $y1+$height);
            $self->move($pc, $x0, $y0);
        } elsif (abs($dy) < 0.0000001) {
            # Horizontal line
            my $xb = ($x1 < $x0)? 0: $width;
            $self->line($pen, $x0, $y0, $xb, $y0, $color, $size);
            ($x0, $x1) = $xb? (0, $x1-$width): ($width, $x1+$width);
            $self->move($pc, $x0, $y0);
        } else {
            # Diagonal line
            my $m = $dy / $dx;
            my $b = $y1 - ($m * $x1);
            my $xb = ($y1 > $y0)? (($height - $b) / $m): (-$b / $m);
            my $yb = ($x1 > $x0)? (($m * $width) + $b):  $b;
            my ($xn, $yn) = ($xb, $yb);
            my $crossx = ($xb > 0 and $xb < $width)?  1: 0;
            my $crossy = ($yb > 0 and $yb < $height)? 1: 0;
            if ($crossx and !$crossy) {
                # Line intercepts x-axis
                $yb = ($y1 > $y0)? $height: 0;
                $yn = $height - $yb;
                $y1 = ($y1 > $y0)? $y1 - $height: $y1 + $height;
            } elsif ($crossy and !$crossx) {
                # Line intercepts y-axis
                $xb = ($x1 > $x0)? $width: 0;
                $xn = $width - $xb;
                $x1 = ($x1 > $x0)? $x1 - $width: $x1 + $width;
            } else {
                # Line intercepts both axes
                $xb = ($x1 > $x0)? $width:  0;
                $yb = ($y1 > $y0)? $height: 0;
                ($xn, $yn) = ($width - $xb, $height - $yb);
                $x1 = ($x1 > $x0)? $x1 - $width:  $x1 + $width;
                $y1 = ($y1 > $y0)? $y1 - $height: $y1 + $height;
            }

            $self->line($pen, $x0, $y0, $xb, $yb, $color, $size);
            ($x0, $y0) = ($xn, $yn);
            $self->move($pc, $x0, $y0);
        }
    }

    # Back within canvas
    return $self->move_turtle_normal($pc, $x0, $y0, $x1, $y1);
}


sub move_turtle_reflect {
    my ($self, $pc, $x0, $y0, $x1, $y1) = @_;
    my $turtle = $pc->{'turtle'};
    my $angle  = $turtle->{'angle'};
    my $pen    = $turtle->{'pen'};
    my $size   = $turtle->{'size'};
    my $color  = $turtle->{'color'};

    while (!$self->contained($x1, $y1)) {
        # Calculate (dx, dy), which change for reflection behavior
        my ($dx, $dy) = ($x1 - $x0, $y1 - $y0);

        my $height = $self->{'height'};
        my $width  = $self->{'width'};
        if (abs($dx) < 0.0000001) {
            # Vertical line
            my $yb = ($y1 < $y0)? 0: $height;
            $self->line($pen, $x0, $y0, $x0, $yb, $color, $size);
            $y0 = $yb;
            $y1 = ($y1 < $y0)? (- $y1): (2 * $height) - $y1;
            $self->move($pc, $x0, $y0);
            $angle = $self->adjust_angle($pc, 180 - $angle);
        } elsif (abs($dy) < 0.0000001) {
            # Horizontal line
            my $xb = ($x1 < $x0)? 0: $width;
            $self->line($pen, $x0, $y0, $xb, $y0, $color, $size);
            $x0 = $xb;
            $x1 = ($x1 < $x0)? (- $x1): (2 * $width) - $x1;
            $self->move($pc, $x0, $y0);
            $angle = $self->adjust_angle($pc, 360 - $angle);
        } else {
            # Diagonal line
            my $m = $dy / $dx;
            my $b = $y1 - ($m * $x1);
            my $xb = ($y1 > $y0)? (($height - $b) / $m): (-$b / $m);
            my $yb = ($x1 > $x0)? (($m * $width) + $b):  $b;
            my $crossx = ($xb > 0 and $xb < $width)?  1: 0;
            my $crossy = ($yb > 0 and $yb < $height)? 1: 0;
            if ($crossx and !$crossy) {
                # Line intercepts x-axis
                $yb = ($y1 > $y0)? $height: 0;
                $y1 = ($y1 > $y0)? (2 * $height - $y1): (- $y1);
            } elsif ($crossy and !$crossx) {
                # Line intercepts y-axis
                $xb = ($x1 > $x0)? $width: 0;
                $x1 = ($x1 > $x0)? (2 * $width - $x1): (- $x1);
            } else {
                # Line intercepts both axes
                $xb = ($x1 > $x0)? $width:  0;
                $yb = ($y1 > $y0)? $height: 0;
                $x1 = ($x1 > $x0)? (2 * $width  - $x1): (- $x1);
                $y1 = ($y1 > $y0)? (2 * $height - $y1): (- $y1);
            }

            $self->line($pen, $x0, $y0, $xb, $yb, $color, $size);
            ($x0, $y0) = ($xb, $yb);
            $self->move($pc, $x0, $y0);
            $angle = $self->adjust_angle($pc, 180 - $angle);
        }
    }

    # Back within canvas
    return $self->move_turtle_normal($pc, $x0, $y0, $x1, $y1);
}


sub adjust_angle {
    my ($self, $pc, $newang) = @_;
    my $turtle = $pc->{'turtle'};
    while ($newang >= 360) {
        $newang -= 360;
    }
    while ($newang < 0) {
        $newang += 360;
    }
    $turtle->{'angle'} = $newang;
    $self->draw_turtle($pc, $turtle);
    return $newang;
}


sub line {
    my ($self, $pen, $x0, $y0, $x1, $y1, $color, $size) = @_;

    # Pen is up; no need to draw
    return unless $pen;

    # Get canvas and draw line
    my $cv = $self->{'canvas'};
    my @points = ($x0, $y0, $x1, $y1, -fill => $color, -width => $size);
    $cv->createLine(@points);
}


sub move {
    my ($self, $pc, $x, $y) = @_;

    # Set new turtle coordinates and redraw turtle
    my $turtle = $pc->{'turtle'};
    $turtle->{'x'} = $x;
    $turtle->{'y'} = $y;
    $self->draw_turtle($pc, $turtle);
}


sub contained {
    my ($self, $x1, $y1) = @_;

    my $cv     = $self->{'canvas'};
    my $width  = $cv->cget(-width);
    my $height = $cv->cget(-height);

    $self->{'width'}  = $width;
    $self->{'height'} = $height;

    return ($x1 < 0 or $x1 > $width or $y1 < 0 or $y1 > $height)? 0: 1;
}


1;

__END__

=head1 NAME

Language::Logo - An implementation of the Logo programming language

=head1 SYNOPSIS

    use Language::Logo;

    my $lo = new Logo(update => 20);

    $lo->command("setxy 250 256");
    $lo->command("color yellow");
    $lo->command("pendown");

    # Draw a circle
    for (my $i = 0; $i < 360; $i += 10) {
        $lo->command("forward 10; right 10");
    }

    $lo->disconnect("Finished...")


=head1 DESCRIPTION

This module provides an implementation of the Logo programming language, with
all of the necessary drawing primitives in a Tk Canvas.  The Canvas object is
also referred to as the "screen".

The first construction of a Language::Logo object causes a server to be
created in a separate process; this server then creates a Tk GUI with a
Tk::Canvas for use by the client's "turtle", and responds to all requests
from the client's commands.  In this way, multiple clients may be constructed
simultaneously -- each one with its own "turtle".

In this first release, not all of the Logo language is implemented.
Rather, the primary commands available are those which directly affect
the turtle, and are related to drawing on the screen.  The intent is to
use the Logo in conjunction with Perl as a sort of "hybrid" language;
Perl us used as the higher-level language layer through which all loop
constructs, conditionals, and data-manipulation is done.  This allows
for a substantial level of programming power.



=head2 Methods

=over 4

=item I<PACKAGE>->new([I<param> => I<value>, [I<param> => I<value>, ...]])

Returns a newly created C<Language::Logo> object.  No arguments are required,
but the following are allowed (each of which must be accompanied by a value):

=item verbose I<0 or 1>

a zero value turns verbose mode off (the default); a nonzero value turns
verbose mode on.  When verbose mode is on, certain server events cause
output to be displayed to the terminal, such as new client connections,
and client connections which have closed.

=item name I<client name>

the name of the current client.  (The default is a uniquely generated name;
this parameter is not currently used, but may be used in the future to force
synchronization between clients in a multiple-client scenario).

=item title I<main window title>

the title of the Tk window (the default is the name and current version
number of the module).

=item bg I<background color>

the starting background color of the screen (the default is black).

=item width I<screen width>

the starting width of the screen (the default is 512 pixels).

=item height I<screen height>

the starting height of the screen (the default is 512 pixels).

=item update I<update interval>

the starting update value for controlling the number of milliseconds to
delay before reentering Tk's idle loop.  The fastest is therefore a value
of 1 (which updates up to 1000 times per second).

=item host I<server address>

the host computer where the server is running (the default is to use the
server on the local machine).  If the host is on a remote machine, it is
assumed that the remote machine has already constructed at least one
Language::Logo object which is currently running its own local server.

=item port I<server port>

the port at which to connect to the server (the default is port 8220).

=back

=item I<$OBJ>->disconnect([I<message>])

=over 4

Disconnects from the server.  If a message is supplied, the user is
prompted with the message, and the program waits until a newline is
typed before disconnecting.  This is especially useful if the client
is the only one (or last one) connected; in which case the server will
also exit upon disconnect.

=item I<$OBJ>->interact()

Enters interactive mode, whereby the user can issue Logo commands
one-at-a-time.  Queries may also be used to retrieve various information
about the state of the current client's object.

=item I<$OBJ>->query([I<param>, I<param> ...])

Sends a Logo query command to the server, asking for the values of
the specified parameters (or all parameters, if none are listed).
A list containing the parameter names and their values is returned.

=item I<$OBJ>->command(I<command string>)

=item I<$OBJ>->cmd(I<command string>)

Sends a Logo command to the server.  Multiple commands may be sent at the
same time by inserting a semi-colon ';' between them.

Upon successful completion of a command, all of the turtle-related
parameters (eg. x and y coordinates, angle, pen state, etc.) are
returned in a hash, where the keys are the parameters, and the
corresponding values are the parameters' values.  If the key 'error'
is defined, its value is an error string indicating what was incorrect
with the command.

The following commands are available:

=over 4

=item "noop" (no arguments)

The "noop" command is simply a way to retrieve the parameter/value hash
without performing any other operation.

=item "background" or "bg" (1 argument)

Sets the background color of the screen.  Colors must be valid Tk colors,
specified either by name ("blue") or hex triplet ("#0000ff").  For example,
"background orange".

=item "backward" or "bk" (1 argument)

Moves the turtle backwards the specified number of pixels.  If the pen is
down, a line is drawn with the current color and pensize.  For example,
"backward 100".
[Contrast "forward"]

=item "clear" or "cs" (no arguments)

Clears the screen entirely.

=item "color" or "co" (1 argument)

Changes the current turtle color to the specified color.  Both the turtle
and any items drawn by the turtle (when the pen is down) will appear in this
color.  For example, "color white".

=item "forward" or "fd" (1 argument)

Moves the turtle forwards the specified number of pixels.  If the pen is down,
a line is drawn with the current color and pensize.  For example, "foreward
100".
[Contrast "backward"]

=item "height" or "h " (1 argument)

Changes the current screen height to the specified number of pixels.
Note that, as this change applies to the Tk Canvas, it affects all
clients which are connected to the server.  For example, "height 768".
[Contrast "width"]

=item "hideturtle" or "ht" (no arguments)

Makes the turtle invisible.  Note that this is unrelated to the current
state of the pen; lines will still be drawn or not, depending on whether
the pen is up or down.  [Contrast "showturtle"]

=item "home" or "hm" (no arguments)

Puts the turtle in its original location, at the center of the screen, with
a heading of due North (0 degrees).

=item "left" or "lt" (1 argument)

Rotates the turtle to the left by the specified angle, given in degrees.
Thus, an angle of 90 degrees will make an exact left turn; an angle of
180 degrees will make the turtle face the opposite direction.  For example,
"left 45".  [Contrast "right"]

=item "pendown" or "pd" (no arguments)

Changes the state of the turtle's "pen" so that subsequent movements of the
turtle will draw the corresponding lines on the screen.  As a visual cue,
the turtle will appear with a circle drawn around the current point.
[Contrast "penup"]

=item "pensize" or "ps" (1 argument)

Changes the width of the turtle's "pen" to the given number of pixels, so
that subsequent drawing will be done with the new line width.

=item "penup" or "pu" (no arguments)

Changes the state of the turtle's "pen" so that subsequent movements of the
turtle will no longer result in lines being drawn on the screen.  As a visual
cue, the turtle will appear -without- the circle drawn around the current
point.  [Contrast "pendown"]

=item "right" or "rt" (1 argument)

Rotates the turtle to the left by the specified angle, given in degrees.
Thus, an angle of 90 degrees will make an exact right turn; an angle of
180 degrees will make the turtle face the opposite direction.  For example,
"right 135".  [Contrast "left"]

=item "seth" or "sh" (1 argument)

Changes the turtle's heading to the specified angle.  The angle given is
an absolute angle, in degrees, representing the clockwise spin relative to
due North.  Thus, a value of 0 is due North, 90 is due East, 180 is due
South, and 270 is due West.  For example, "seth 225".

=item "setx" or "sx" (1 argument)

Changes the turtle's x-coordinate to the specified pixel location on the
screen, without changing the value of the current y-coordinate.  The value
given is an absolute location, not one related to the previous position.
If the pen is down, a line will be drawn from the old location to the new
one.  For example, "setx 128".  [Contrast "sety", "setxy" ]

=item "setxy" or "xy" (2 arguments)

Changes the turtle's x and y coordinates to the specified pixel locations
on the screen, without changing the value of the current x-coordinate.
The first argument is the new x-coordinate, the second the new y-coordinate.
The position of the new point represents an absolute location, not one related
to the previous position.  If the pen is down, a line will be drawn from the
old location to the new one.  For example, "setxy 10 40".  [Contrast "setx",
"sety" ]

=item "sety" or "sy" (1 argument)

Changes the turtle's y-coordinate to the specified pixel location on the
screen, without changing the value of the current x-coordinate.  The value
given is an absolute location, not one related to the previous position.
If the pen is down, a line will be drawn from the old location to the new
one.  For example, "sety 256".  [Contrast "setx", "setxy" ]

=item "showturtle" or "st" (no arguments)

Makes the turtle visible.  Note that this is unrelated to the current state
of the pen; lines will still be drawn or not, depending on whether the pen
is up or down.  [Contrast "hideturtle"]

=item "update" or "ud" (1 argument)

Changes the current update value which controls the number of milliseconds to
delay before reentering Tk's idle loop.  A value of 1000 is the slowest; it
will cause a delay of 1 second between updates.  A value of 1 is the fastest,
it will make the Tk window update up to 1000 times each second.

=item "width" or "w " (1 argument)

Changes the current screen width to the specified number of pixels.
Note that, as this change applies to the Tk Canvas, it affects all
clients which are connected to the server.  For example, "width 1024".
[Contrast "height"]

=item "wrap" (1 argument)

Changes the screen "wrap" type on a per-client basis, to the specified
argument, which must be a value of 0, 1 or 2.  See L<WRAP TYPES> below
for more detailed information.

=back

=back

=head1 RANDOM VALUES

  Some of the commands can take as an argument the word "random", possibly
  followed by more arguments which modify the random behavior.  For example,
  the command "color random" chooses a new random color for the pen, whereas
  "seth random 80 100" sets the turtle heading to a random angle between 80
  and 100 degrees.

  The number of arguments following "random" depend on the context:
 
      angles ........ 2 arguments (mininum angle, maximum angle)
      distances ..... 2 arguments (minimum distance, maximum distance)
      other ......... no arguments


=head1 WRAP TYPES

  The parameter 'wrap' defines the behavior that occurs when the
  turtle's destination point is outside of the display window.

  The allowable values for wrap are:

    0:  Normal "no-wrap" behavior
    1:  Toroidal "round-world" wrap
    2:  Reflective wrap

    Consider the following diagram:

                 +---------------o---------------+
                 |              /| (xb0,yb0)     |
                 |         <C> /                 |
                 |            /  |               |
                 |   (x2,y2) o                   |
                 | [wrap = 1]    |               |
                 |                               |
                 | [wrap = 2]    |               |
                 |   (x3,y3) o       @ (x0,y0)   |
                 |            \  |  /            |
                 |         <D> \   / <A>         |
                 |              \|/              |
                 +---------------o---------------+
                                / (xb1,yb1)
                           <B> /     
                              /  
                     (x1,y1) @ [wrap = 0]

    Point (x0,y0) represents the current location of the turtle, and
    (x1,y1) the destination point.  Since the destination is outside
    of the display window, the behavior of both the turtle and the
    drawn line will be governed by the value of the 'wrap' parameter.

    Since line segment <A> is in the visible window, it will be drawn
    in all cases.  Since line segment <B> is outside of the visible
    window, it will not be visible in all cases.

    When (wrap == 0), only line segment <A> will be visible, and the
    turtle, which ends up at point (x1,y1), will NOT.

    When (wrap == 1), the window behaves like a torus, so that line
    segment <B> "wraps" back into the window at the point (xb0,yb0).
    Thus line segments <A> and <C> are visible, and the turtle ends
    up at point (x2,y2).

    When (wrap == 2), the borders of the window are reflective, and
    line segment <B> "reflects" at the point (xb1,yb1).  Thus line
    segments <A> and <D> are visible, and the turtle ends up at the
    point (x3,y3).


=head1 EXAMPLES

The following programs show some of the various ways to use the
Language::Logo object.

    #################################
    ###  Randomly-colored designs ###
    #################################
    use Language::Logo;

    my $lo = new Logo(title => "Logo Demonstration");
    $lo->command("update 2; color random; pendown; hideturtle");

    for (my $i = 1; $i < 999; $i++) {
        my $distance = $i / 4;
        $lo->command("forward $distance; right 36.5");
        $lo->command("color random") if not ($i % 50);
    }

    $lo->disconnect("Type [RETURN] to finish...");


    ################################################
    ### Randomly placed "rings" of random widths ###
    ################################################
    use Language::Logo;

    my $lo = new Logo(title => "Random rings", update => 5);
    $lo->cmd("wrap 1");    # Toroidal wrap

    while (1) {
        $lo->cmd("pu; sx random 1 512; sy random 1 512; pd; co random");
        $lo->cmd("pensize random 1 32");
        my $dist = 5 + (rand(50));
        for (my $i = 0; $i <= 360; $i += $dist) {
            $lo->cmd("fd $dist; rt $dist");
        }
    }


    ###################################
    ### Fullscreen "frenetic Lines" ###
    ###################################
    use Language::Logo;

    my $lo = new Logo(width => 1024, height => 768, update => 3);

    # Change "1" to "2" for reflection instead of torus
    $lo->cmd("wrap 1");

    $lo->cmd("setx random 0 800");  # Choose random x-coordinate
    $lo->cmd("sety random 0 800");  # Choose random y-coordinate
    $lo->cmd("rt random 0 360");    # Make a random turn
    $lo->cmd("pd");                 # Pen down
    $lo->cmd("ht");                 # Hide turtle

    my $size = 1;  # Starting pen size

    while (1) {
        if (++$size > 48) {
            $size = 1;                  # Reset the size
            $lo->cmd("cs");             # Clear the screen
        }
        $lo->cmd("ps $size");           # Set the pensize
        $lo->cmd("color random");       # Random color
        $lo->cmd("fd 9999");            # Move the turtle
        $lo->cmd("rt random 29 31");    # Turn a random angle
    }


=head1 BUGS

The following items are not yet implemented, but are intended to be
addressed in a future version of the library:

=over 4

=item *

There is no provision for compiling "pure" Logo language code.  Such
capabilities as loops, conditionals, and subroutines must be handled
in the calling Perl program.

=item *

There is no way to change the processing speed on a per-client basis.

=item *

There is no way to synchronize multiple clients to wait for one another.

=item *

There are still some commands which do not support a "random" parameter
("setxy" and "background", for example).

=item *

There is currently no analog command to "setxy" ("offxy" ?) which changes
the position of the turtle's location I<relative> to the current point, as
opposed to setting it absolutely.

=item *

It would be nice to be able to draw things other than lines; for example
ovals, polygons, etc.  It would also be nice to be able fill these with
a given "fill" color.

=item *

There needs to be a way to save the current screen to a file (eg. as
PostScript).


=head1 AUTHOR

John C. Norton        jcnorton@charter.net

Copyright (c) 2007 John C. Norton. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 VERSION

Version 1.000  (January 2007)

=head1 REQUIREMENTS

The Tk module is required.

=head1 SEE ALSO

perl(1)

=cut


