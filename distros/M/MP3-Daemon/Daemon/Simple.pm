package MP3::Daemon::Simple;

use strict;
use MP3::Info;
use MP3::Daemon;
use Getopt::Std;
use File::Basename;

use vars qw(@ISA $VERSION);
@ISA     = qw(MP3::Daemon);
$VERSION = 0.11;

# constructor that does NOT daemonize itself
#_______________________________________
sub new {
    my $class = shift;
    my $self  = $class->SUPER::new(@_);

    $self->{playlist} = [ ];    # list of mp3s
    $self->{n}        = undef;  # index into playlist
    $self->{random}   = 0;      # play random songs? or not.
    $self->{loop}     = "all";  # looping behaviour (off|single|all)

    return $self;
}


# valid requests
#_______________________________________
*_play  = \&play;
*_next  = \&next;
*_prev  = \&prev;
*_pause = \&pause;
*_stop  = \&stop;
*_loop  = \&loop;
*_jump  = \&jump;
*_ff    = \&ff;
*_rw    = \&rw;
*_add   = \&add;
*_del   = \&del;
*_ls    = \&ls;
*_info  = \&info;
*_time  = \&time;
*_rand  = \&rand;
*_quit  = \&quit;

# playlist entry indices
#_______________________________________
use constant URL   => 0;
use constant TITLE => 1;
use constant TIME  => 2;

# Audio::Play::MPG123 states
#_______________________________________
use constant STOPPED => 0;
use constant PAUSED  => 1;
use constant PLAYING => 2;

# |>
#_______________________________________
sub play {
    my $self = shift;
    my $x    = shift;
    my $pl   = $self->{playlist};
    my $n    = $self->{n};

    if (defined $x) {
        if ($x =~ /^[-+]?\d+$/) {
            my $end = scalar(@$pl) - 1;
            $x = ($x < 0)    ? $end+1 + $x : $x;
            $x = ($x > $end) ? $end        : $x;
            $self->{n} = $n = $x;
        } else {
            $self->add($x);
            $self->{n} = $n = scalar(@$pl) - 1;
        }
    } else {
        $self->{n} = $n = 0 unless defined($n);
    }
    my $mp3 = $pl->[$n][URL];
    $self->{player}->load($mp3);
    $self->{player}->statfreq(1 / $self->{player}->tpf());
}

# >>
#_______________________________________
sub next {
    my $self = shift;
    if ($self->{random}) { $self->random(); return }
    my $pl   = $self->{playlist};
    my $end  = scalar(@$pl) - 1;
    my $n    = $self->{n};

    my $client = $self->{client};

    if (scalar @$pl) {
	my $loop = $self->{loop};
	if (($loop ne "single") || 
	    ($loop eq "single" && $self->{player}->state == PLAYING))
	{
	    if (not defined $n) {
		$n = 0;
	    } elsif ($n >= $end) {
		$n = 0;
	    } else {
		$n++;
	    }
	}
        $self->{n} = $n;
	if ($loop eq "off") {
	    $self->stop();
	} else {
	    $self->{player}->load($pl->[$n][URL]);
	}
    }
}

# <<
#_______________________________________
sub prev {
    my $self = shift;
    my $pl   = $self->{playlist};
    my $end  = scalar(@$pl) - 1;
    my $n    = $self->{n};

    my $client = $self->{client};

    if (scalar @$pl) {
        if (not defined $n) {
            $n = 0;
        } elsif ($n <= 0) {
            $n = $end;
        } else {
            $n--
        }
        $self->{n} = $n;
        $self->{player}->load($pl->[$n][URL]);
    }
}

# ==
#_______________________________________
sub pause {
    my $self   = shift;
    my $player = $self->{player};
    $player->pause() unless $player->state() == STOPPED;
}

# []
#_______________________________________
sub stop {
    my $self   = shift;
    my $player = $self->{player};
    $player->stop() unless $player->state == STOPPED;
}

# 69
#_______________________________________
sub loop {
    my $self   = shift;
    my $opt    = shift;
    my $client = $self->{client};
    if ($opt) {
	unless (grep { /^$opt$/ } qw(all single off)) {
	    print $client "mp3 loop [all|single|off]\n";
	    return;
	}
	$self->{loop} = $opt;
    }
    print $client "loop $self->{loop}\n";
}

# !!
#_______________________________________
sub jump {
    my $self   = shift;
    my $sec    = shift;
    my $player = $self->{player};
    my $tpf    = $player->tpf;

    $player->jump($sec / $tpf);
}

# ->
#_______________________________________
sub ff {
    my $self   = shift;
    my $sec    = shift;
    my $player = $self->{player};
    my $tpf    = $player->tpf;

    $player->jump("+" . $sec / $tpf);
}

# <-
#_______________________________________
sub rw {
    my $self   = shift;
    my $sec    = shift;
    my $player = $self->{player};
    my $tpf    = $player->tpf;

    $player->jump(-$sec / $tpf);
}

# ++
#_______________________________________
sub add {
    my $self   = shift;
    my $pl     = $self->{playlist};
    my $client = $self->{client};

    foreach (@_) {
        my $tag;
        my $info = get_mp3info($_);
        if (m|^http://|) {
            $info->{TIME} = "00:00";
            $tag->{TITLE} = (fileparse($_, '\..*$'))[0];
        }
        if ($info) {
            $tag ||= get_mp3tag($_);
            $tag->{TITLE} ||= (fileparse($_, '\..*$'))[0];
            my $entry = [
                $_,                     # URL
                $tag->{TITLE},          # TITLE
                $info->{TIME},          # TIME
            ];
            push(@$pl, $entry);
        } else {
            print $client qq("$_" does not seem to be an mp3.\n);
        }
    }
}

# --
#_______________________________________
sub del {
    my $self = shift;
    my $pl   = $self->{playlist};
    my $end  = scalar(@$pl) - 1;
    my $n    = $self->{n};
    my $x    = $n;

    # no parameter deletes current item from list
    push(@_, $n) unless (scalar(@_));

    # delete 1 or more from list
    my @new_playlist;
    my $adjust = 0;
    my %kill = 
        map  { $adjust++ if $_ < $n; $_ => 1 }      # create set
        grep { $_ <= $end }                         # check range
        map  { ($_ < 0) ? $_ = $end+1 + $_ : $_ }   # normalize
        grep { /^[-+]?\d+$/ } @_;                   # integers only
    return unless (scalar keys %kill);
    for (my $i = 0; $i <= $end; $i++) {
        push(@new_playlist, $pl->[$i]) unless ($kill{$i});
    }

    # assign new list and prepare to reindex if necessary
    $self->{playlist} = $pl = \@new_playlist;
    $end = scalar(@$pl) - 1;
    my $player = $self->{player};

    # nothing left?
    if ($end < 0) { 
        $self->{n} = 0; 
        $player->stop if $player->state;
        return; 
    }

    # before current track
    if ($adjust) { $n -= $adjust; $self->{n} = $n; }

    # at and after current track
    if (defined $kill{$x}) {
        $n = 0 if ($n > $end);
        $self->{n} = $n;
        $self->{player}->load($pl->[$n][URL]);
    }
}

#_______________________________________
sub ls_short_entry_factory {
    my $attr = shift;
    return sub {
        my $i     = shift;
        my $entry = shift;
        return sprintf('%5s %s', $i, qq("$entry->[$attr]"));
    }
}

#_______________________________________
sub ls_long_entry {
    my $i     = shift;
    my $entry = shift;
    return sprintf(
        '%5s %5s %-30s "%s"',
        $i, $entry->[TIME], qq("$entry->[TITLE]"), $entry->[URL]
    );
}

# @
#_______________________________________
sub ls {
    my $self   = shift;
    my $client = $self->{client};
    my $pl     = $self->{playlist};

    my %opt;
    local @ARGV = @_;
    getopts('lf', \%opt);
    my $re = shift(@ARGV);

    my $attr = defined($opt{f}) ? URL : TITLE;
    my $i;
    my $n = $self->{n};
    my $l = defined($opt{l}) 
        ? \&ls_long_entry
        :  &ls_short_entry_factory($attr);
    for ($i = 0 ; $i < scalar(@$pl); $i++) {
        defined($re) && do { $pl->[$i][TITLE] =~ /$re/ || next };
        if ($i == $n) {
            $_ = $l->($i, $pl->[$i]);
            s/^ />/;
            print $client "$_\n";
        } else {
            print $client $l->($i, $pl->[$i]), "\n";
        }
    }
}

# i
#_______________________________________
sub info {
    my $self   = shift;
    my $player = $self->{player};
    my $client = $self->{client};
    my $mp3_attribute;
    my @method = qw( 
        artist album title year genre url 
        type layer bitrate samplerate channels mode mode_extension bpf
        copyrighted error_protected
    );

    my $format = "%-15s | \%s\n";
    foreach $mp3_attribute (@method) {
        printf $client (
            $format, $mp3_attribute, $player->$mp3_attribute()
        );
    }
    printf $client ($format, "state", 
        (qw(stopped paused playing))[$player->state()]);
    printf $client ($format, "random", $self->{random});
    printf $client ($format, "loop", $self->{loop});
    $self->time;
}

# $
#_______________________________________
sub time {
    my $self   = shift;
    my $player = $self->{player};
    my $client = $self->{client};
    my $format = "%-15s | \%s\n";

    my $f = $player->{frame};
    printf $client ($format, "elapsed", $f->[2] . " seconds");
    printf $client ($format, "remaining", $f->[3] . " seconds");
    printf $client ($format, "total", $f->[2] + $f->[3] . " seconds");
    printf $client ($format, "track", $self->{n});
}

# ?
#_______________________________________
sub rand {
    my $self    = shift;
    my $client  = $self->{client};
    my $setting = shift || ("on", "off")[$self->{random}];

    if ($setting eq "off") {
        $self->{random} = 0;
        *_next = \&next;
        *_prev = \&prev;
        print $client "random play off\n";
    } elsif ($setting eq "on") {
        $self->{random} = 1;
        *_next = \&random;
        *_prev = \&random;
        print $client "random play on\n";
    } else {
        print $client qq("$setting" is not a valid random state.\n);
    }
}

# *
#_______________________________________
sub random {
    my $self = shift;
    my $pl   = $self->{playlist};
    my $len  = scalar @$pl;
    my $n;

    if ($len) {

        # prevent an mp3 from being played twice in a row
	if ($len == 1) { 
	    $n = 0; 
	} else {
	    do { $n = int(rand($len)) } until ($n != $self->{n});
	}
        $self->{n} = $n;
        $self->{player}->load($pl->[$n][URL]);
    }
}

# __
#_______________________________________
sub quit { 
    my $self = shift;
    unlink($self->{socket_path});
    exit 0; 
}

1;

__END__

=head1 NAME

MP3::Daemon::Simple - the daemon for the mp3(1p) client

=head1 SYNOPSIS

Fork a daemon

    MP3::Daemon::Simple->spawn($socket_path);

Start a server, but don't fork into background

    my $mp3d = MP3::Daemon::Simple->new($socket_path);
    $mp3d->main;

You're a client wanting a socket to talk to the daemon

    my $client = MP3::Daemon::Simple->client($socket_path);
    print $client @command;

=head1 REQUIRES

=over 4

=item File::Basename

This is used to give titles to songs when the mp3 leaves
the title undefined.

=item Getopt::Std

Some methods need to pretend they're command line utilities.

=item MP3::Daemon

This is the base class.  It provides the daemonization and
event loop.

=item MP3::Info

This is for getting information out of mp3s.

=back

=head1 DESCRIPTION

MP3::Daemon::Simple provides a server that controls mpg123.  Clients
such as mp3(1p) may connect to it and request the server to
manipulate its internal playlists.

=head1 METHODS

=head2 Server-related Methods

MP3::Daemon::Simple relies on unix domain sockets to communicate.  The
socket requires a place in the file system which is referred to
as C<$socket_path> in the following descriptions.

    $socket_path = "$ENV{HOME}/.mp3/mp3_socket";

=over 4

=item new (socket_path => $socket_path, at_exit => $code_ref)

This instantiates a new MP3::Daemon.  The parameter, C<socket_path> is
mandatory, but C<at_exit> is optional.

    my $mp3d = MP3::Daemon::Simple->new (
        socket_path => "$ENV{HOME}/.mp3/mp3_socket"
        at_exit     => sub { print "farewell\n" },
    );

=item main

This starts the event loop.  This will be listening to the socket
for client requests while polling mpg123 in times of idleness.  This
method will never return.

    $mp3d->main;

=item spawn (socket_path => $socket_path, at_exit => $code_ref)

This combines C<new()> and C<main()> while also forking itself into
the background.  The spawn method will return immediately to the
parent process while the child process becomes an MP3::Daemon that is
waiting for client requests.

    MP3::Daemon::Simple->spawn (
        socket_path => "$ENV{HOME}/.mp3/mp3_socket"
        at_exit     => sub { print "farewell\n" },
    );

=item client $socket_path 

This is a factory method for use by clients who want a socket to
communicate with a previously instantiated MP3::Daemon::Simple.

    my $client = MP3::Daemon::Simple->client($socket_path);

=item idle $code_ref

This method has 2 purposes.  When called with a parameter that is a
code reference, the purpose of this method is to specify a code reference
to execute during times of idleness.  When called with no parameters,
the specified code reference will be invoked w/ an MP3::Daemon object
passed to it as its only parameter.  This method will be invoked
at regular intervals while main() runs.

B<Example>:  Go to the next song when there are 8 or fewer seconds left
in the current mp3.

    $mp3d->idle (
        sub {
            my $self   = shift;             # M:D:Simple
            my $player = $self->{player};   # A:P:MPG123
            my $f      = $player->{frame};  # hashref w/ time info

            $self->next() if ($f->[2] <= 8);
        }
    );

This is a flexible mechanism for adding additional behaviours during
playback.

=item atExit $code_ref

This mimics the C function atexit().  It allows one to give an MP3::Daemon
some CODEREFs to execute when the destructor is called.  Like the C version,
the CODEREFs will be called in the reverse order of their registration.
Unlike the C version, C<$self> will be given as a parameter to each CODEREF.

    $mp3d->atExit( sub { unlink("$ENV{HOME}/.mp3/mp3.pid") } );

=back

=head2 Client Protocol

These methods are usually not invoked directly.  They are invoked when
a client makes a request.  The protocol is very simple.  The first
line is the name of the method.  Each argument to the method is
specified on successive lines.  A final blank line signifies the end
of the request.

    0   method name
    1   $arg[0]
    .   ...
    n-1 $arg[n-2]
    n   /^$/

Example:

    print $client <<REQUEST;
    play
    5

    REQUEST

This plays $self->{playlist}[5].

=over 8

=item add

This adds mp3s to the playlist.  Multiple files may be specified.

=item del

This deletes items from the playlist by index.  More than one
index may be specified.  If no index is specified, the current mp3
in the playlist is removed.  Indices may also be negative in
which case they count from the end of the playlist.

=item play

This plays the current mp3 if no other parameters are given.  This
command also takes an optional parameter where the index of an mp3
in the playlist may be given.

=item next

This loads the next mp3 in the playlist.

=item prev

This loads the previous mp3 in the playlist.

=item pause

This pauses the currently playing mp3.  If the mp3 was already
paused, this will unpause it.  Note that using the play command
on a paused mp3 makes it start over from the beginning.

=item rw

This rewinds an mp3 by the specified amount of seconds.

=item ff

This fastforwards an mp3 by the specified amount of seconds.

=item jump

This will go directly to a part of an mp3 specified by
seconds from the beginning of the track.  If the number of
seconds is prefixed with either a "-" or a "+", a relative
jump will be made.  This is another way to rewind or
fastforward.

=item stop

This stops the player.

=item time

This sends back the index of the current track, the amount of time
that has elapsed, the amount of time that is left, and the total
amount of time.  All times are reported in seconds.

=item info

This sends back information about the current track.

=item ls [-fl] [REGEX]

First, a warning -- I'm beginning to realize how GNU/ls became so
bloated.  The C<ls> interface should not be considered stable.  I'm
still playing with it.

This sends back a list of the titles of all mp3s currently in the
playlist.  The current track is denoted by a line matching the regexp
/^>/.  

=over 8

=item -f

This makes C<ls> return a listing with index and filename.

=item -l

This makes C<ls> return a long listing that includes index,
title, and filename.

=item [REGEX]

This allows one to filter the playlist for only titles matching
this regex.  Of course, one may use grep, instead.

=back

=item rand

Calling this with no parameters toggles the random play feature.
Randomness can be set to be specifically "on" or "off" by
passing the scalar "on" or "off" to this method.

=item loop

This option controls the playlist's looping behaviour.  When called with
a parameter, loop can be set to "all", "single", or "off".  Calling this
with no parameters displays the current looping status.

=item quit

This unloads the MP3::Daemon::Simple that was automagically spawned
when you first invoked mp3.

=back

=head1 DIAGNOSTICS

I need to be able to report errors in the daemon better.
They currently go to /dev/null.  I need to learn how to
use syslog.

=head1 COPYLEFT

Copyleft (c) 2001 John BEPPU.  All rights reversed.  This program is
free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=head1 AUTHOR

John BEPPU <beppu@ax9.org>

=head1 SEE ALSO

mpg123(1), Audio::Play::MPG123(3pm), pimp(1p), mpg123sh(1p), mp3(1p)

=cut

# $Id: Simple.pm,v 1.14 2001/12/29 23:58:13 beppu Exp $
