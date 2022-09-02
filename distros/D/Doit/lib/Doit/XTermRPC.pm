# -*- perl -*-

#
# Author: Slaven Rezic
#
# Copyright (C) 2018 Slaven Rezic. All rights reserved.
# This package is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Mail: slaven@rezic.de
# WWW:  http://www.rezic.de/eserte/
#

package Doit::XTermRPC;

use strict;
use warnings;
our $VERSION = '0.01';

our @ISA = ('Doit::_AnyRPCImpl');

use Doit::Log;

my $socket_count = 0;

sub do_connect {
    my($class, %opts) = @_;
    my $term_prog  =    delete $opts{term_prog} || 'xterm';
    my @term_opts  = @{ delete $opts{term_opts} || [] };
    my @term_run   = @{ delete $opts{term_run}  || ['-e', \"prog_and_args"] };
    my $dry_run    =    delete $opts{dry_run};
    my $debug      =    delete $opts{debug};
    my @components = @{ delete $opts{components} || [] };
    my $perl       =    delete $opts{perl} || $^X;
    error "Unhandled options: " . join(" ", %opts) if %opts;

    my $self = bless { }, $class;

    require File::Basename;
    require File::Spec;
    require IPC::Open2;
    require POSIX;

    # Socket pathname, make it possible to find out
    # old outdated sockets easily by including a
    # timestamp. Also need to maintain a $socket_count,
    # if the same script opens multiple sockets quickly.
    my $sock_path = "/tmp/." . join(".", "doit", "xterm", POSIX::strftime("%Y%m%d_%H%M%S", gmtime), $<, $$, (++$socket_count)) . ".sock";

    # On linux use Linux Abstract Namespace Sockets ---
    # invisible and automatically cleaned up. See man 7 unix.
    my $LANS_PREFIX = $class->_can_LANS ? '\0' : '';

    # Run the server
    my @cmd_worker =
	(
	 $perl, "-I".File::Spec->rel2abs(File::Basename::dirname(__FILE__)."/.."), "-I".File::Spec->rel2abs(File::Basename::dirname($0)), "-e",
	 Doit::_ScriptTools::self_require() .
	 q{my $d = Doit->init; } .
	 Doit::_ScriptTools::add_components(@components) .
	 q{Doit::RPC::Server->new($d, "} . $LANS_PREFIX . $sock_path . q{", excl => 1, debug => } . ($debug?1:0) . q{)->run();} .
	 ($LANS_PREFIX ? '' : q<END { unlink "> . $sock_path . q<" }>), # cleanup socket file, except if Linux Abstract Namespace Sockets are used
	 "--", ($dry_run? "--dry-run" : ())
	);
    my @full_cmd_worker = ($term_prog, @term_opts);
    for my $arg (@term_run) {
	if (ref $arg) {
	    if ($$arg eq 'prog_and_args') {
		push @full_cmd_worker, @cmd_worker;
	    } else {
		error "Invalid reference $arg";
	    }
	} else {
	    push @full_cmd_worker, $arg;
	}
    }

    my $worker_pid = fork;
    if (!defined $worker_pid) {
	error "fork failed: $!";
    } elsif ($worker_pid == 0) {
	info "worker perl cmd: @full_cmd_worker\n" if $debug;
	no warnings qw(syntax exec); # "Statement unlikely to be reached", different warning categories in different perls
	exec @full_cmd_worker;
	error "Failed to run '@full_cmd_worker': $!";
    }

    # Run the client
    my($in, $out);
    my @cmd_comm = ($perl, "-I".File::Spec->rel2abs(File::Basename::dirname(__FILE__)."/.."), "-MDoit", "-e",
		    q{Doit::Comm->comm_to_sock("} . $LANS_PREFIX . $sock_path . q{", debug => shift)}, !!$debug);
    warn "comm perl cmd: @cmd_comm\n" if $debug;
    my $comm_pid = IPC::Open2::open2($out, $in, @cmd_comm);
    $self->{rpc} = Doit::RPC::Client->new($out, $in, label => "xterm:", debug => $debug);

    $self;
}

sub DESTROY { }

1;

__END__
