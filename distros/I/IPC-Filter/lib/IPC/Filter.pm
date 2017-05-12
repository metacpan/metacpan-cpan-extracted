=head1 NAME

IPC::Filter - filter data through an external process

=head1 SYNOPSIS

	use IPC::Filter qw(filter);

	$compressed_data = filter($data, "bzip2");

=head1 DESCRIPTION

The C<filter> function provided by this module passes data through an
external command, thus providing filtering in non-pipeline situations.

=cut

package IPC::Filter;

{ use 5.006; }
use warnings;
use strict;

use Errno 1.00 qw(EPIPE);
use IPC::Open3 1.01 qw(open3);
use IPC::Signal 1.00 qw(sig_name);
use IO::Handle 1.12;
use IO::Poll 0.01 qw(POLLIN POLLOUT POLLERR POLLHUP);
use POSIX qw(_exit);
use Symbol qw(gensym);

our $VERSION = "0.004";

use parent "Exporter";
our @EXPORT_OK = qw(filter);

=head1 FUNCTIONS

=over

=item filter(DATA, SHELL_COMMAND)

=item filter(DATA, PROGRAM, ARGS ...)

The SHELL_COMMAND, or the PROGRAM with ARGS if more arguments are
supplied, is executed as a separate process.  (The arguments other
than DATA are ultimately passed to C<exec>; see L<perlfunc(1)/exec>
for explanation of the choice between the two forms.)  The DATA (which
must be either a simple string or a reference to a string) is supplied
to the process on its standard input, and the process's standard output
is captured and returned (as a simple string).

If the process exits with a non-zero exit code or on a signal, the
function will C<die>.  In the case of a non-zero exit code, the C<die>
message will duplicate the process's standard error output; in any other
case, the error output is discarded.

=cut

my $chunksize = 4096;

sub filter($@) {
	my $data = \shift(@_);
	if(@_ == 0 || $_[0] eq "-") {
		die "filter: invalid command\n";
	}
	if(ref($data) eq "REF") {
		$data = $$data;
	}
	my $stdin = gensym;
	my $stdout = gensym;
	my $stderr = gensym;
	# Note: perl bug (bug in IPC::Open3 version 1.0106, bug ID
	# #32198): if the exec fails in the subprocess created by open3(),
	# it uses die() to emit its error message and terminate.  If an
	# exception handler is installed using eval {}, execution in the
	# subprocess continues there instead of the process terminating.
	# We avoid nastiness by catching the exception ourselves and
	# doing the right thing.
	my $parent_pid = $$;
	my $child_pid = eval { local $SIG{__DIE__};
		open3($stdin, $stdout, $stderr, @_);
	};
	if($@ ne "") {
		my $err = $@;
		die $err if $$ == $parent_pid;
		print STDERR $err;
		_exit 255;
	}
	local $SIG{PIPE} = "IGNORE";
	my $poll = IO::Poll->new;
	my $datalen = length($$data);
	if($datalen == 0) {
		$stdin->close;
	} else {
		$poll->mask($stdin => POLLOUT | POLLERR | POLLHUP);
	}
	$poll->mask($stdout => POLLIN | POLLERR | POLLHUP);
	$poll->mask($stderr => POLLIN | POLLERR | POLLHUP);
	my $datapos = 0;
	my @out;
	my @err;
	while($poll->handles) {
		$poll->poll;
		if($datapos != $datalen && $poll->events($stdin)) {
			my $n = $stdin->syswrite($$data, $chunksize, $datapos);
			if(defined $n) {
				$datapos += $n;
			} elsif($! == EPIPE) {
				$datapos = $datalen;
			} else {
				die "filter: stdin: $!\n";
			}
			if($datapos == $datalen) {
				$poll->remove($stdin);
				$stdin->close;
			}
		}
		if($poll->events($stdout)) {
			my $output;
			unless(defined $stdout->sysread($output, $chunksize)) {
				die "filter: stdout: $!\n";
			}
			if($output eq "") {
				$poll->remove($stdout);
			} else {
				push @out, $output;
			}
		}
		if($poll->events($stderr)) {
			my $output;
			unless(defined $stderr->sysread($output, $chunksize)) {
				die "filter: stderr: $!\n";
			}
			if($output eq "") {
				$poll->remove($stderr);
			} else {
				push @err, $output;
			}
		}
	}
	waitpid $child_pid, 0;
	my $status = $?;
	if($status == 0) {
		return join("", @out);
	}
	if($status & 127) {
		die "filter: process died on SIG".sig_name($status & 127)."\n";
	} else {
		die join("", "filter: process exited with status ",
			$status >> 8, "\n", @err);
	}
}

=back

=head1 SEE ALSO

L<IPC::Open2>

=head1 AUTHOR

Andrew Main (Zefram) <zefram@fysh.org>

=head1 COPYRIGHT

Copyright (C) 2004, 2007, 2010, 2011
Andrew Main (Zefram) <zefram@fysh.org>

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
