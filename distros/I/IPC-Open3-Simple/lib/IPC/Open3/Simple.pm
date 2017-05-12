#################################################################
#
#   IPC::Open3::Simple - A simple alternative to IPC::Open3
#
#   $Id: Simple.pm,v 1.7 2006/07/20 13:30:02 erwan Exp $
#
#   060714 erwan Created
#
#################################################################

use strict;
use warnings;

package IPC::Open3::Simple;

use Carp qw(croak confess);
use IPC::Open3;
use IO::Select;
use IO::Handle;
use Data::Dumper;

our $VERSION = '0.04';

#-----------------------------------------------------------------
#
#   new - constructor. takes a hash where keys are in, out and err 
#         and values are closures/coderefs
#

sub new {
    my($pkg,%args) = @_;
    $pkg = ref $pkg || $pkg;
    my $self = bless({},$pkg);

    foreach my $type ('in','out','err') {
	if (exists $args{$type}) {
	    croak "".__PACKAGE__."::new expects coderefs" if (ref $args{$type} ne 'CODE');
	    $self->{$type} = $args{$type};
	}
    }
    
    return $self;
}

#-----------------------------------------------------------------
#
#   run - execute a list of shell commands in a separate process
#         and redirect input/output to the closures provided to new()
#

sub run {
    my($self,@args) = @_;
    
    # note: in theory, it should work to write:
    #     my $pid = open3($child_in, $child_out, $child_err, @arguments)
    # but that does not work (bug?). $child_err is then undefined
    # (in perldoc for open2, the explanation is that stderr=stdout if $child_out == $child_err, which they do when they are both undefined)

    # TODO: support interactive ipc with child process?
    
    my $pid = open3(\*CHILD_IN, \*CHILD_OUT, \*CHILD_ERR, @args)
 	or confess "ERROR: failed to execute command [".join(" ",@args)."]";

    my $reader = IO::Select->new();

    my $child_in = \*CHILD_IN;
    my $child_out = \*CHILD_OUT;
    my $child_err = \*CHILD_ERR;
#    $child_in->autoflush; IPC::Open3 does it already
    $child_out->autoflush;
    $child_err->autoflush;

    # listen to stdout and stderr, or close them
    if (exists $self->{out}) {
	$reader->add($child_out);
    } else {
	$child_out->close();
    }

    if (exists $self->{err}) {
	$reader->add($child_err);
    } else {
	$child_err->close();
    }

    # forward stdin to provided function, or close it
    if (exists $self->{in}) { 
	&{$self->{in}}($child_in);
    } else {
	$child_in->close();
    }

    # parse output of cvs command
    if ($reader->handles) {
	while (my @ready = $reader->can_read()) {
	    foreach my $fh (@ready) {
		my $line = <$fh>;
		if (!defined $line) { 
                    # reached EOF on this filehandle
		    $reader->remove($fh);
		    $fh->close();
		} else {
		    chomp $line;
		    if ($child_out->opened && fileno($fh) == fileno(\*CHILD_OUT)) {
			&{$self->{out}}($line);
		    } elsif ($child_err->opened && fileno($fh) == fileno(\*CHILD_ERR)) {
			&{$self->{err}}($line);
		    } else {
			confess "BUG: got an unexpected filehandle:".Dumper($fh);
		    }
		}
	    }
	}
    }

    # wait for child process to die
    waitpid($pid, 0);

    return $self;
}

1;

__END__

=head1 NAME

IPC::Open3::Simple - A simple alternative to IPC::Open3

=head1 VERSION

$Id: Simple.pm,v 1.7 2006/07/20 13:30:02 erwan Exp $

=head1 SYNOPSIS

To run 'ls' in a few directories and put the returned lines in a list:

    my @files;
    my $ipc = IPC::Open3::Simple->new(out => sub { push @files, $_[0]; })
    $ipc->run('ls /etc/');
    $ipc->run('ls /home/erwan/');

To run a 'cvs up' and do different stuff with what cvs writes to stdout
and stderr:

    IPC::Open3::Simple->new(out => \&parse_cvs_stdout, err => \&parse_cvs_stderr)->run('cvs up');

=head1 DESCRIPTION

IPC::Open3::Simple aims at making it very easy to start a shell command, eventually
feed its stdin with some data, then retrieve its stdout and stderr separately.

When you want to run a shell command and parse its stdout/stderr or feed its
stdin, you often end up using IPC::Run, IPC::Cmd or IPC::Open3 with your
own parsing code, and end up writing more code than you intended.
IPC::Open3::Simple is about removing this overhead and making IPC::Open3 
easier to use.

IPC::Open3::Simple calls IPC::Open3 and redirects stdin, stdout
and stderr to some function references passed in argument to the constructor.
It does a select on the input/output filehandles returned by IPC::Open3
and dispatches their content to and from those functions.

=head1 INTERFACE

=over

=item my $runner = IPC::Open3::Simple->B<new>(in => \&sub_in, out => \&sub_out, err => \&sub_err)

Return an object that run commands. Takes no arguments or a hash containing one or
more of the keys 'in', 'out' and 'err'. The values of those keys are function
references (see method I<run> for details).

=item $runner->B<run>(@cmds)

Execute the shell commands I<@cmds>. I<@cmds> follows the same syntax as the command
arguments of I<open3> from IPC::Open3.

I<run> creates a process that executes thoses commands, and connects the process's
stdin, stdout and stderr to the functions passed in the constructor:

If I<out> was defined in I<new>, every line coming from the process's stdout is passed
as first argument to the function reference I<sub_out>. The line is chomped.

If I<err> was defined, the same applies, with lines from the process's stderr being
passed to I<sub_err>.

If I<in> was defined, I<sub_in> is called with a filehandle as first argument. 
Everything written to this filehandle will be sent forward to the process's stdin.
I<sub_in> is responsible for calling I<close>() on the filehandle.

I<run> returns only when the command has finished to run.

=back

=head1 DIAGNOSTICS

=over

=item "IPC::Open3::Simple::new expects coderefs" 

You called I<new> with 'in', 'err' or 'out' arguments that are not function references.

=item "ERROR: failed to execute command..."

Open3 failed to run the command passed in I<@cmds> to I<run>.

=back

=head1 BUGS AND LIMITATIONS

No bugs so far.

Limitation: IPC::Open3::Simple is not designed for interactive interprocess communication.
Do not use it to steer the process opened by I<open3> via stdin/stdout/stderr, use fork and pipes
or some appropriate IPC module for that. IPC::Open3::Simple's scope is to easily run a command,
eventually with some stdin input, and get its stdout and stderr along the way, not to interactively
communicate with the command.

=head1 SEE ALSO

See IPC::Open3, IPC::Run, IPC::Cmd.

=head1 COPYRIGHT AND LICENSE

Copyright (C) by Erwan Lemonnier C<< <erwan@cpan.org> >>

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut





