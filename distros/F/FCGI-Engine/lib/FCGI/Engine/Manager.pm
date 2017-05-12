package FCGI::Engine::Manager;
use Moose;

use Class::Load ();
use FCGI::Engine::Types;
use FCGI::Engine::Manager::Server;

use Config::Any;

our $VERSION   = '0.22';
our $AUTHORITY = 'cpan:STEVAN';

with 'MooseX::Getopt';

has 'conf' => (
    is       => 'ro',
    isa      => 'Path::Class::File',
    coerce   => 1,
    required => 1,
);

has '_config' => (
    is       => 'ro',
    isa      => 'FCGI::Engine::Manager::Config',
    lazy     => 1,
    default  => sub {
        my $self   = shift;
        my $file   = $self->conf->stringify;
        my $config = Config::Any->load_files({
            files   => [ $file ],
            use_ext => 1
        })->[0]->{$file};
        #use Data::Dumper;
        #warn Dumper $config;
        return $config;
    }
);

has '_servers' => (
    reader    => 'servers',
    isa       => 'ArrayRef[FCGI::Engine::Manager::Server]',
    lazy      => 1,
    default   => sub {
        my $self = shift;
        return [
            map {
                $_->{server_class} ||= "FCGI::Engine::Manager::Server";
                Class::Load::load_class($_->{server_class});
                $_->{server_class}->new(%$_);
            } @{$self->_config}
        ];
    },
);

sub log { shift; print @_, "\n" }

sub start {
    my $self = shift;

    local $| = 1;

    $self->log("Starting up the FCGI servers ...");

    my @servers = (@_ && defined $_[0]) ? $self->_find_server_by_name( @_ ) : @{ $self->servers };

    foreach my $server ( @servers ) {

        if (-e $server->pidfile) {
            my $pid = $server->pid_obj;
            if ($pid->is_running) {
                $self->log("Pid " . $pid->pid . " is already running");
                return;
            }
            $server->remove_pid_obj;
        }

        my @cli = $server->construct_command_line();
        $self->log("Running @cli");

        unless (system(@cli) == 0) {
            $self->log("Could not execute command (@cli) exited with status $?");
            return;
        }

        my $count = 1;
        until (-e $server->pidfile) {
            $self->log("pidfile (" . $server->pidfile . ") does not exist yet ... (trying $count times)");
            sleep 2;
            $count++;
        }

        my $pid = $server->pid_obj;

        while (!$pid->is_running) {
            $self->log("pid (" . $pid->pid . ") with pid_file (" . $server->pidfile . ") is not running yet, sleeping ...");
            sleep 2;
        }

        $self->log("Pid " . $pid->pid . " is running");

    }

    $self->log("... FCGI servers have been started");
}

sub status {
    my $self = shift;

    my @servers = (@_ && defined $_[0]) ? $self->_find_server_by_name( @_ ) : @{ $self->servers };

    my $status = '';
    foreach my $server ( @servers ) {

        $status .= $server->name;

        if (! -f $server->pidfile ) {
            $status .= " is not running\n";
            next;
        }

        my $pid = $server->pid_obj;

        $status .= $pid->is_running ? " is running\n" : " is not running\n"
    }

    return $status;
}

sub stop {
    my $self = shift;

    local $| = 1;

    $self->log("Killing the FCGI servers ...");

    my @servers = (@_ && defined $_[0]) ? $self->_find_server_by_name( @_ ) : @{ $self->servers };

    foreach my $server ( @servers ) {

        if (-f $server->pidfile) {

            my $pid = $server->pid_obj;

            $self->log("Killing PID " . $pid->pid . " from $$ ");
            kill TERM => $pid->pid;

            while ($pid->is_running) {
                $self->log("pid (" . $server->pidfile . ") is still running, sleeping ...");
                sleep 1;
            }

            $server->pid_obj->remove;
            $server->remove_pid_obj;
        }

        if (-e $server->socket) {
            unlink($server->socket);
        }

    }

    $self->log("... FCGI servers have been killed");
}

sub restart {
    my $self = shift;
    $self->stop( @_ );
    sleep( 2 ); # give stop() some time
    $self->start( @_ );
}


sub graceful {
    my $self = shift;
    my @servers = (@_ && defined $_[0]) ? $self->_find_server_by_name( @_ ) : @{ $self->servers };
    my @pids;
    foreach my $server ( @servers ) {
        push @pids, $server->pid_obj->pid;
        unlink($server->pidfile);
        $server->remove_pid_obj;
    }
    $self->start( @_ );
    foreach my $pid ( @pids ) {
        $self->log("... Killing old fcgi process $pid");
        kill TERM => $pid;
    }
    foreach my $server ( @servers ) {
        while (-f $server->pidfile) {
            $self->log("pid (" . $server->pidfile . ") has not been removed, sleeping ...");
            sleep 1;
        }
        $server->pid_obj->write;
    }
}

sub _find_server_by_name {
    my( $self, @names ) = @_;

    my %wanted = map { $_ => 1 } @names;
    my @servers = grep { exists $wanted{ $_->name } } @{ $self->servers };

    return @servers;
}

1;

__END__


=pod

=head1 NAME

FCGI::Engine::Manager - Manage multiple FCGI::Engine instances

=head1 SYNOPSIS

  #!/usr/bin/perl

  my $m = FCGI::Engine::Manager->new(
      conf => 'conf/my_app_conf.yml'
  );

  my ($command, $server_name) = @ARGV;

  $m->start($server_name)        if $command eq 'start';
  $m->stop($server_name)         if $command eq 'stop';
  $m->restart($server_name)      if $command eq 'restart';
  $m->graceful($server_name)     if $command eq 'graceful';
  print $m->status($server_name) if $command eq 'status';

  # on the command line

  perl all_my_fcgi_backends.pl start
  perl all_my_fcgi_backends.pl stop
  perl all_my_fcgi_backends.pl restart foo.server
  # etc ...

=head1 DESCRIPTION

This module handles multiple L<FCGI::Engine> instances for you, it can
start, stop and provide basic status info. It is configurable using
L<Config::Any>, but only really the YAML format has been tested.

=head2 Use with Catalyst

Since L<FCGI::Engine> is pretty much compatible with
L<Catalyst::Engine::FastCGI>, this module can also be used to manage
your L<Catalyst::Engine::FastCGI> based apps as well as your
L<FCGI::Engine> based apps.

=head2 Use with Plack

L<Plack> support is provided via the L<FCGI::Engine::Manager::Server::Plackup>
module. All that is required is setting the C<server_class> parameter
in the configuarion and it will Just Work.

=head1 EXAMPLE CONFIGURATION

Here is an example configuration in YAML, it should be noted that
the options for each server are basically the constructor params to
L<FCGI::Engine::Manager::Server> and are passed verbatim to it.
This means that if you subclass L<FCGI::Engine::Manager::Server>
and set the C<server_class:> option appropriately, it should pass
any new options you added to your subclass automatically. The third
server in the list shows exactly how this is used with a L<Plack>
application.

  ---
  - name:            "foo.server"
    server_class:    "FCGI::Engine::Manager::Server"
    scriptname:      "t/scripts/foo.pl"
    nproc:            1
    pidfile:         "/tmp/foo.pid"
    socket:          "/tmp/foo.socket"
    additional_args: [ "-I", "lib/" ]
  - name:       "bar.server"
    scriptname: "t/scripts/bar.pl"
    nproc:       1
    pidfile:    "/tmp/bar.pid"
    socket:     "/tmp/bar.socket"
  - name:            "baz.server"
    server_class:    "FCGI::Engine::Manager::Server::Plackup"
    scriptname:      "t/scripts/baz.psgi" # the .psgi file
    nproc:            1
    pidfile:         "/tmp/baz.pid"
    socket:          "/tmp/baz.socket"
    additional_args: [ "-E", "production" ] # plackup specific option

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Stevan Little E<lt>stevan@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2007-2010 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut




