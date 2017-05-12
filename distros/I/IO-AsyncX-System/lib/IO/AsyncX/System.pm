package IO::AsyncX::System;
# ABSTRACT: system() in background for IO::Async
use strict;
use warnings;

use parent qw(IO::Async::Notifier);

our $VERSION = '0.003';

=head1 NAME

IO::AsyncX::System - fork+exec, capturing STDOUT/STDERR

=head1 VERSION

version 0.003

=head1 SYNOPSIS

 use feature qw(say);
 use IO::Async::Loop;
 use IO::AsyncX::System;
 my $loop = IO::Async::Loop->new;
 $loop->add(
  my $system = IO::AsyncX::System->new
 );
 my ($code, $stdout, $stderr) = $system->run([qw(ls)])->get;
 say for @$stdout;

=head1 DESCRIPTION

Intended as a replacement for L</system> in L<IO::Async>-using code.
Provides a single L</run> method which will fork+exec (via L<IO::Async::Process>),
capturing STDOUT/STDERR, and returning a L<Future> holding the exit code and output.

=cut

use curry;
use Future;
use Encode qw(decode_utf8);
use IO::Async::Process;

=head1 METHODS

=cut

=head2 run

Takes a single parameter defining the command to run:

 $system->run(['ls']);

plus optional named parameters:

=over 4

=item * utf8 - interprets all input/output as UTF-8, so STDOUT/STDERR will be returned as arrayrefs containing Perl strings rather than raw bytes

=item * binary - the reverse of utf8 (and the default)

=item * stdin - an arrayref of data to pass as STDIN

=item * timeout - kill the process if it doesn't complete within this many seconds

=back

Returns a L<Future> which resolves to the exit code, STDOUT and STDERR arrayrefs:

 $system->run([...]) ==> ($exitcode, $stdout_arrayref, $stderr_arrayref)

STDIN/STDOUT/STDERR are arrayrefs split by line. In binary mode, they will hold a single element each.

=cut

sub run {
	my ($self, $cmd, %args) = @_;
	my $stdout = [];
	my $stderr = [];
	my $stdin = [];
	my $stdin_def = {
		(
			# Allow both ['x','y'] and "x\ny" as input, although we only document the former
			defined($args{stdin})
			? (from => ref($args{stdin}) ? join "\n", @{delete $args{stdin}} : $args{stdin})
			: (from => '')
		),
	};
	my $stdout_def = {
		on_read => (
			$args{utf8}
			? $self->curry::read_utf8($stdout)
			: $self->curry::read_binary($stdout)
		),
	};
	my $stderr_def = {
		on_read => (
			$args{utf8}
			? $self->curry::read_utf8($stderr)
			: $self->curry::read_binary($stderr)
		),
	};
	my $f = $self->loop->new_future;
	my $proc = IO::Async::Process->new(
		command => $cmd,
		stdin => $stdin_def,
		stdout => $stdout_def,
		stderr => $stderr_def,
		on_finish => sub { $f->done($_[1], $stdout, $stderr) unless $f->is_ready },
		on_exception => sub { $f->fail($_[1]) unless $f->is_ready },
	);
	$self->add_child($proc);
	$f->on_ready(sub { $self->remove_child($proc) });
	return $f unless $args{timeout};
	Future->wait_any(
		$f,
		$self->loop->timeout_future(after => $args{timeout})->on_fail(
			sub { $proc->kill(9) if $proc->is_running }
		)
	)->on_cancel(sub { $f->cancel unless $f->is_ready });
}

sub read_binary {
	my ($self, $target, $stream, $buf, $eof) = @_;
	push @$target, '' unless @$target;
	$target->[0] .= $$buf;
	$$buf = '';
	0
}

sub read_utf8 {
	my ($self, $target, $stream, $buf, $eof) = @_;
	push @$target, decode_utf8($1) while $$buf =~ s/^(.*)\n//;
	return 0 unless length $$buf;
	push @$target, decode_utf8($$buf) if $eof;
	0
}

1;

__END__

=head1 SEE ALSO

=over 4

=item * L<IO::Async::Process>

=item * L<system>

=item * L<Capture::Tiny>

=item * L<IPC::Run>

=back

=head1 AUTHOR

Tom Molesworth <cpan@perlsite.co.uk>

=head1 LICENSE

Copyright Tom Molesworth 2015. Licensed under the same terms as Perl itself.
