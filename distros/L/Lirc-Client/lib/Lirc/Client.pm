package Lirc::Client;

# ABSTRACT: A client library for the Linux Infrared Remote Control

use strict;
use warnings;
use Moo;
use Carp;
use IO::Socket;
use File::Path::Expand;

our $VERSION = '2.02';

has prog => ( is => 'ro', required => 1 );   # the program name from lircrc file
has rcfile => ( is => 'ro', default => sub { "$ENV{HOME}/.lircrc" } );
has dev => ( is => 'ro', default => sub { '/dev/lircd' } );    # lircd device
has debug => ( is => 'ro', default => sub { 0 } );    # instance debug flag
has fake  => ( is => 'ro', default => sub { 0 } );    # fake the lirc connection
has sock          => ( is => 'rw' );                          # the lircd socket
has mode          => ( is => 'rw', default => sub { '' } );
has _in_block     => ( is => 'rw', default => sub { 0 } );
has _commands     => ( is => 'rw', default => sub { {} } );
has _startup_mode => ( is => 'rw' );
has _buf          => ( is => 'rw', default => sub { '' } );

sub BUILD {
    my $self = shift;

    if ( $self->fake ) {
        $self->sock( \*STDIN );
    } else {
        $self->sock(
            IO::Socket->new(
                Domain => &AF_UNIX,
                Type   => SOCK_STREAM,
                Peer   => $self->dev,
            ) ) or croak "couldn't connect to $self->dev: $!";
    }

    $self->_parse_lircrc( $self->rcfile );
    $self->mode( $self->_startup_mode ) if defined $self->_startup_mode;
    return 1;
}

sub BUILDARGS {
    my ( $class, @args ) = @_;

    my $cfg       = {};
    my @arg_names = qw{prog rcfile dev debug fake};    # get any passed by order

    carp
      "positional parameters for constructor is depreciated and will be removed from a future version"
      if @args and ref $args[0] ne 'HASH';

    while ( @args and ref $args[0] ne 'HASH' ) {
        my $arg_name = shift @arg_names;
        my $arg_val  = shift @args;
        $cfg->{$arg_name} = $arg_val if defined $arg_val;
    }

    if ( ref $args[0] eq 'HASH' ) {
        $cfg = { %$cfg, %{ shift @args } };    # Merge the two hashes
    }

    croak "new expects list of args or hash ref of named args" if @args;
    return $cfg;
}

sub clean_up {
    my $self = shift;

    if ( defined $self->sock ) {
        close $self->sock unless $self->fake;
    }

    return;
}

sub _parse_lircrc {    ## no critic
    my ( $self, $rcfilename ) = @_;

    open( my $rcfile, '<', $rcfilename )
      or croak "couldn't open lircrc file ($rcfilename): $!";

    my $in_block = 0;
    my $cur_mode = '';
    my $ops      = {};

    while (<$rcfile>) {
        s/^\s*#.*$//g;    # remove commented lines
        chomp;
        print "> ($rcfilename) ($cur_mode) $_\n" if $self->debug;

        ## begin block
        /^\s*begin\s*$/i && do {
            $in_block && croak "Found begin inside a block in line: $_\n";
            $in_block = 1;
            next;
        };

        ## end block
        /^\s*end\s*$/i && do {
            croak "found end outside of a block in line: $_\n" unless $in_block;

            if ( defined $ops->{flags} && $ops->{flags} =~ /\bstartup_mode\b/ )
            {
                croak "startup_mode flag given without a mode line"
                  unless defined $ops->{mode};
                $self->_startup_mode( $ops->{mode} );
                next;
            }

            croak "end of block found without a prog code at line: $_\n"
              unless defined $ops->{prog};
            $ops->{remote} ||= '*';
            my $key = join '-', $ops->{remote}, $ops->{button}, $cur_mode;
            my $val = $ops;

            $in_block = 0;
            $ops      = {};

            next unless $val->{prog} eq $self->prog;

            $self->_commands->{$key} = $val;

            next;
        };

        ## token = arg
        /^\s*([\w-]+)\s*=\s*(.*?)\s*$/ && do {
            my ( $tok, $act ) = ( $1, $2 );
            croak "unknown token found in rc file: $_\n"
              unless $tok =~ /^(prog|remote|button|repeat|config|mode|flags)$/i;
            $ops->{$tok} = $act;

            next;
        };

        ## begin mode
        /^\s*begin\s*([\w-]+)\s*$/i && do {
            croak "found embedded mode line: $_\n" if $1 && $cur_mode;
            $self->_startup_mode($1) if $1 eq $self->prog;
            $cur_mode = $1;
            next;
        };

        ## end mode
        /^\s*end\s*([\w-]+)\s*$/i && do {
            croak "end $1: found inside a begin/end block" if $in_block;
            croak "end $1: found without associated begin mode"
              unless $cur_mode eq $1;

            $cur_mode = '';
            next;
        };

        ## include file
        /^include\s+(.*)\s*$/ && do {
            my $file = $1;
            $file =~ s/^["<]|[">]$//g;
            $file = eval { expand_filename($file) };
            croak "error parsing include statement: $_\n" if $@;
            croak "could not find file ($file) in include: $_\n"
              unless -r $file;
            $self->_parse_lircrc($file);
            next;
        };

        ## blank lines
        /^\s*$/ && next;

        ## unrecognized
        croak sprintf "Couldn't parse lircrc file (%s) error in line: %s\n",
          $self->rcfile, $_;
    }
    close $rcfile;

    return;
}

sub recognized_commands {
    my $self = shift;

    return $self->_commands;
}

sub _get_lines {
    my $self = shift;

    # what is in the buffer now?
    printf "buffer1=%s\n", $self->_buf if $self->debug;

    # read anything in the pipe
    my $buf;
    my $status = sysread( $self->sock, $buf, 512 );
    ( carp "bad status from read" and return ) unless defined $status;

    # what is in the buffer after the read?
    $self->{_buf} .= $buf;
    print "buffer2=%s\n", $self->_buf if $self->debug;

    # separate the lines, leaving partial lines on _buf
    my @lines;
    push @lines, $1 while ( $self->{_buf} =~ s/^(.+)\n// );    ## no critic
           # while() tests that s/// matched

    return @lines;
}

sub nextcodes {
    return shift->next_codes();
}

sub next_codes {
    my $self = shift;

    my @lines = $self->_get_lines;
    print "==", join( ", ", map { defined $_ ? $_ : "undef" } @lines ), "\n"
      if $self->debug;
    return () unless scalar @lines;
    my @commands = ();
    for my $line (@lines) {
        chomp $line;
        print "Line: $line\n" if $self->debug;
        my $command = $self->parse_line($line);
        print "Command: ", ( defined $command ? $command : "undef" ), "\n"
          if $self->debug;
        push @commands, $command if defined $command;
    }
    return @commands;
}

sub nextcode {
    return shift->next_code();
}

sub next_code {
    my $self = shift;

    my $fh = $self->sock;
    while ( defined( my $line = <$fh> ) ) {
        chomp $line;
        print "Line: $line\n" if $self->debug;
        my $command = $self->parse_line($line);
        print "Command: ", ( defined $command ? $command : "undef" ), "\n"
          if $self->debug;
        return $command if defined $command;
    }
    return;    # no command found and lirc exited?
}

sub parse_line {    ## parse a line read from lircd
    my $self = shift;
    $_ = shift;

    printf "> (%s) %s\n", $self->_in_block, $_ if $self->debug;

    # Take care of response blocks
    ## Right Lirc::Client doesn't support LIST or VERSION, so we can ignore
    ## Responses that come inside a block
    if (/^\s*BEGIN\s*$/) {
        croak "got BEGIN inside a block from lircd: $_" if $self->_in_block;
        $self->_in_block(1);
        return;
    }
    if (/^\s*END\s*$/) {
        croak "got END outside a block from lircd: $_" if !$self->_in_block;
        $self->_in_block(0);
        return;
    }
    return if $self->_in_block;

    # Decipher IR Command
    # http://www.lirc.org/html/technical.html#applications
    # <hexcode> <repeat count> <button name> <remote name>
    my ( $hex, $repeat, $button, $remote ) = split /\s+/;
    defined $button and length $button or do {
        carp "Unable to decode.\n";
        return;
    };

    my $commands = $self->_commands;
    my $cur_mode = $self->mode;
    my $command =
         $commands->{"$remote-$button-$cur_mode"}
      || $commands->{"*-$button-$cur_mode"}
      || $commands->{"$remote-*-$cur_mode"};
    defined $command or return;

    my $rep_count =
      $command->{repeat};    # default repeat count is 0 (ignore repeated keys)
    return if $rep_count ? hex($repeat) % $rep_count : hex $repeat;

    if ( defined $command->{flags} && $command->{flags} =~ /\bmode\b/ ) {
        $self->mode('');
    }
    if ( defined $command->{mode} ) { $self->mode( $command->{mode} ); }

    return unless defined $command->{config};
    printf ">> %s accepted --> %s\n", $button, $command->{config}
      if $self->debug;
    return $command->{config};
}

sub DEMOLISH {
    my $self = shift;
    print __PACKAGE__, ": DEMOLISH\n" if $self->debug;

    $self->clean_up;
    return;
}

1;

__END__


=pod

=head1 NAME

Lirc::Client - A client library for the Linux Infrared Remote Control

=head1 VERSION

version 2.02

=head1 SYNOPSIS

  use Lirc::Client;

  my $lirc = Lirc::Client->new({ prog => 'progname' });
  while( my $code = $lirc->next_code ){  # wait for a new ir code
    print "Lirc> $code\n";
    process( $code );          # do whatever you want with the code
  }

=head1 DESCRIPTION

This module provides a simple interface to the Linux Infrared Remote
Control (Lirc). The module encapsulates parsing the Lirc config file (.lircrc),
opening a connection to the Lirc device, and retrieving events from the 
device.

=head1 METHODS

=head2 new( program, \%options )

  my $lirc = Lirc::Client->new( {    
               prog    => 'progname',           # required
               rcfile  => "$ENV{HOME}/.lircrc", # optional
               dev     => "/dev/lircd",         # optional
               debug   => 0,                    # optional
               fake    => 1,                    # optional
        } );

  # Depreciated positional syntax; don't use
  my $lirc = Lirc::Client->new( 'progname',    # required
               "$ENV{HOME}/.lircrc",           # optional
               '/dev/lircd', 0, 0 );           # optional

The constructor accepts two calling forms: an ordered list (for backwards
compatibility), and a hash ref of configuration options. The two forms
can be combined as long as the hash ref is last.

=over 4

=item prog    => 'progname'

Required parameter identifying the program token for Lirc.

=item rcfile  => "$ENV{HOME}/.lircrc"

Path to the C<.lircrc> configuration file. Optional.

=item dev     => "/dev/lircd"

The path to the Lirc device. Optional.

=item debug   => 0

Flag to turn on debugging output. Optional.

=item fake    => 1

Will cause Lirc::Client to read from STDIN rather than the lircd device. 
This is meant to facilitate debugging and testing. Optional.

=back

When called the constructor defines the program token used in the Lirc
config file, opens and parses the Lirc config file (B<rcfile> defaults to
~/.lircrc if none specified), connects to the Lirc device (B<dev> defaults to
/dev/lircd if none specified), and returns the Lirc::Client object.

=head2 recognized_commands()

  my @list = $lirc->recognized_commands;

Returns a list of all the recognized commands for this application (as
defined in C<prog> parameter to the call to B<new>).

=head2 next_code()

=head2 nextcode()

  my $code = $lirc->next_code;

Retrieves the next IR command associated with the B<progname> as defined in
B<new()>, blocking if none is available. B<next_code> uses the stdio read
commands which are buffered. Use B<next_codes> if you are also using select.

=head2 next_codes()

=head2 nextcodes()

  my @codes = $lirc->next_codes;

Retrieves any IR commands associated with the B<progname> as defined in the 
B<new()> constructor, blocking if none are available. B<next_codes> uses
sysread so it is compatible with B<select> driven event loops. This is 
the most efficient method to accomplish a non-blocking read.

Due to the mechanics of B<sysread> and B<select>, this version may
return multiple IR codes so the return value is an array.

Here is an example using IO::Select:

    use IO::Select;
    ....
    my $select = IO::Select->new();
    $select->add( $lirc->sock );
    while(1){
        # do your own stuff, if you want
        if( my @ready = $select->can_read(0) ){ 
            # an ir event has been received (if you are tracking other
            # filehandles, you need to make sure it is lirc)
            my @codes = $lirc->next_codes;    # should not block
            for my $code (@codes){
                process( $code );
            }
        }
    }

This is much more efficient than looping over B<next_code> in non-blocking
mode. See the B<select.t> test for the complete example. Also, checkout the
B<Event> module on CPAN for a nice way to handle your event loops.

=head2 sock()

  my $sock = $lirc->sock;

Returns (or sets if an argument is passed) the socket from which to read
lirc commands. This can be used to work Lirc::Client into you own event 
loop. 

=head2 parse_line()

  my $code = $lirc->parse_line( $line );

Takes a full line as read from the lirc device and returns code on the 
B<config> line of the lircrc file for that button. This can be used in 
combination with B<sock> to take more of the event loop control out of
Lirc::Client.

=head2 clean_up()

  $lirc->clean_up;

Closes the Lirc device pipe, etc. B<clean_up> will be called when the lirc
object goes out of scope, so this is not necessary.

=head2 debug()

  $lirc->debug;

Return the debug status for the lirc object.

=head1 TODO

Features that are outlined in the C<.lircrc> specification which have not yet
been implemented include:

=over 4

=item * The mode should be independent of the prog token

=item * Implement the C<once> flag

=item * Implement the C<quit> flag and executing multiple entries

=item * Support for multiple C<config> entries

=item * Implement the C<delay> token

=item * Supprot non-printable charaters in the C<config> command

=item * Support key sequenses (multiple C<remote>, C<button> entries per block)

=item * Support VERSION and LIST commands

=item * Watch for signals from lircd to re-read rc file (C<SIGHUP>)

=item * Add C<SEND_*> support

=back

Features that have been recently implemented include:

=over 4

=item * Support for C<mode>s

=item * Recognizing the C<startup_mode> flag and automatically starting in 
a mode that is identical to the program name

=item * The C<include> directive

=item * Support wild card C<*> entries for C<remote> or C<button>, and blocks
that lack a C<remote>

=back

If anyone has need of one or more of these features, please let me know
(via http://rt.cpan.org if possible).

=head1 SEE ALSO

=over 4

=item L<The Lirc Project|http://www.lirc.org>

=back

=head1 THANKS

Parts of this package were inspired by a project by michael@engsoc.org and
Perl LIRC Client (plircc) by Matti Airas (mairas@iki.fi).
See http://www.lirc.org/html/technical.html for specs. Thanks!

=head1 BUGS

There are a few features that a .lircrc file is supposed to support
(according to http://www.lirc.org/html/configure.html#lircrc_format) that 
have not yet been implemented. See TODO for a list.

See http://rt.cpan.org to view and report bugs

=head1 AUTHOR

Mark Grimes E<lt>mgrimes@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Mark Grimes E<lt>mgrimes@cpan.orgE<gt>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
