# -*- perl -*-

#
# Author: Slaven Rezic
#
# Copyright (C) 2017,2018 Slaven Rezic. All rights reserved.
# This package is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Mail: slaven@rezic.de
# WWW:  http://www.rezic.de/eserte/
#

package Doit::Docker;

use strict;
use warnings;
our $VERSION = '0.012';

sub new { bless {}, shift }
sub functions { qw(docker_connect) }

sub docker_connect {
    my($self, %opts) = @_;
    my $docker_connection = Doit::Docker::RPC->do_connect(dry_run => $self->is_dry_run, components => $self->{components}, %opts);
    $docker_connection;
}

{
    package Doit::Docker::RPC;

    our @ISA = ('Doit::_AnyRPCImpl');

    use Doit::Log;

    my $socket_count = 0;

    sub do_connect {
	my($class, %opts) = @_;
	my $container = delete $opts{container};
	if (!defined $container) { error "The container option is mandatory" }
	my $dry_run = delete $opts{dry_run};
	my $debug = delete $opts{debug};
	my @components = @{ delete $opts{components} || [] };
	my $perl = delete $opts{perl} || 'perl';
	error "Unhandled options: " . join(" ", %opts) if %opts;

	my $self = bless { }, $class;

	require File::Basename;
	require IPC::Open2;
	require FindBin;

	my $copy_to_container = sub ($$) {
	    my($src, $dest) = @_;
	    my @docker_cmd = (qw(docker exec -i), $container, qw(sh -c), "cat > $dest"); # XXX use simply docker cp if docker is new enough (>=1.8 or so)
	    info "Copying '$src' to docker container '$container' as '$dest'" if $debug;
	    open my $ifh, '<', $src
		or error "Error opening $src: $!";
	    open my $ofh, '|-', @docker_cmd # XXX shell quoting! XXX
		or error "Error running @docker_cmd: $!";
	    local $/ = \4096;
	    while(<$ifh>) {
		print $ofh $_;
	    }
	    close $ofh
		or error "Error running @docker_cmd: $!";
	};

	my $exec_in_container = sub {
	    my @cmd = @_;
	    my @docker_cmd = (qw(docker exec), $container, @cmd);
	    info "Running '@cmd' in docker container '$container'" if $debug;
	    system @docker_cmd;
	    if ($? != 0) {
		error "Error running '@cmd' in docker container '$container'";
	    }
	};

	# XXX too much duplication with Doit::SSH
	{
	    my $remote_cmd = "if [ ! -d .doit/lib ] ; then mkdir -p .doit/lib; fi";
	    $exec_in_container->('sh', '-c', $remote_cmd);
	}
	if ($FindBin::RealScript ne '-e') {
	    no warnings 'once';
	    $copy_to_container->("$FindBin::RealBin/$FindBin::RealScript", ".doit/$FindBin::RealScript");
	}
	$copy_to_container->($INC{"Doit.pm"}, ".doit/lib/Doit.pm");
	{
	    my %seen_dir;
	    for my $component (@components) {
		my $from = $component->{path};
		my $to = $component->{relpath};
		my $full_target = ".doit/lib/$to";
		my $target_dir = File::Basename::dirname($full_target);
		if (!$seen_dir{$target_dir}) {
		    $exec_in_container->('sh', '-c', "if [ ! -d $target_dir ] ; then mkdir -p $target_dir; fi");
		    $seen_dir{$target_dir} = 1;
		}
		$copy_to_container->($from, $full_target);
	    }
	}

	# Socket pathname, make it possible to find out
	# old outdated sockets easily by including a
	# timestamp. Also need to maintain a $socket_count,
	# if the same script opens multiple sockets quickly.
	my $sock_path = do {
	    require POSIX;
	    "/tmp/." . join(".", "doit", "docker", POSIX::strftime("%Y%m%d_%H%M%S", gmtime), $<, $$, (++$socket_count)) . ".sock";
	};

	# On linux use Linux Abstract Namespace Sockets ---
	# invisible and automatically cleaned up. See man 7 unix.
	my $LANS_PREFIX = $class->_can_LANS;

	# Run the server
	my @cmd_worker =
	    (
	     $perl, "-I.doit", "-I.doit/lib", "-e",
	     Doit::_ScriptTools::self_require($FindBin::RealScript) .
	     q{my $d = Doit->init; } .
	     Doit::_ScriptTools::add_components(@components) .
	     q<sub _server_cleanup { unlink "> . $sock_path . q<" }> .
	     q<$SIG{PIPE} = \&_server_cleanup; > .
	     q<END { _server_cleanup() } > .
	     q{Doit::RPC::Server->new($d, "} . $sock_path . q{", excl => 1, debug => } . ($debug?1:0).q{)->run();},
	     "--", ($dry_run? "--dry-run" : ())
	    );
	my $worker_pid = fork;
	if (!defined $worker_pid) {
	    error "fork failed: $!";
	} elsif ($worker_pid == 0) {
	    $exec_in_container->(@cmd_worker);
	    if ($? != 0) {
		warning "Failed to run '@cmd_worker'"; # XXX actually an error(), but I want to use CORE::exit
		CORE::exit(1); # XXX necessary to use CORE::exit?
	    } else {
		CORE::exit(0); # XXX necessary to use CORE::exit?
	    }
	}
	$self->{worker_pid} = $worker_pid;

	my @cmd_comm =
	    (
	     $perl, "-I.doit/lib", "-MDoit", "-e",
	     q{Doit::Comm->comm_to_sock("} . $sock_path . q{", debug => shift);},
	     !!$debug,
	    );

	info "comm perl cmd: @cmd_comm\n" if $debug;
	my($out, $in);
	my $comm_pid = IPC::Open2::open2($out, $in,
					 'docker', 'exec', '-i', $container, @cmd_comm,
					);
	$self->{comm_pid} = $comm_pid;
	$self->{rpc} = Doit::RPC::Client->new($out, $in, label => "docker:$container", debug => $debug);

	$self;
    }

    sub DESTROY {
	my $self = shift;
	kill 9 => $self->{comm_pid}    if $self->{comm_pid};
	kill 9 => $self->{worker_pid}  if $self->{worker_pid};
	waitpid $self->{comm_pid}, 0   if $self->{comm_pid};
	waitpid $self->{worker_pid}, 0 if $self->{worker_pid};
    }

}

1;

__END__
