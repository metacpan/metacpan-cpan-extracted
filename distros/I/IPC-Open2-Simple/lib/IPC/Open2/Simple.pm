package IPC::Open2::Simple;

use strict;
use warnings;
use IO::Handle;
use IPC::Open2;
use Exporter 'import';
use Carp;

our $VERSION = '0.01';
our @EXPORT_OK = qw(open2s);

sub open2s {
	my ($out, $in, @cmd) = @_;

	# Sanity checks
	for my $arg ($out, $in) {
		unless (ref($arg) eq 'SCALAR') {
			carp "open2s: \$out and \$in both must be a scalarref";
			return undef;
		}
	}
	unless (@cmd) {
		carp "open2s: empty command line";
		return undef;
	}

	my ($fh_out, $fh_in) = (IO::Handle->new, IO::Handle->new);

	my $pid = open2($fh_out, $fh_in, @cmd);
	# open2() will die if it cannot fork, so we
	# do not need to check $pid here.

	# Pass the input
	$fh_in->print($$in);
	$fh_in->close;

	# Read the output
	{
		local $/;
		until ($fh_out->eof) {
			$$out .= $fh_out->getline;
		}
	}

	# Wait for the child's tragic death
	waitpid $pid, 0;

	return $? >> 8;
}

1;

__END__

=encoding utf8

=head1 NAME

IPC::Open2::Simple - The simplest way to read and write to a fork

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

  use IPC::Open2::Simple 'open2s'

  my $input = "IPC::Open2 is too hard!\n";

  my $ret = open2s(\my $output, \$input, '/bin/cat');

  warn "status: $ret\n";  # 0

  print $output;  # "IPC::Open2 is too hard!"

=head1 DESCRIPTION

L<IPC::Open2::Simple> allows you to pipe data to a child process and read
its ouput (C<STDOUT>), all in one line! Contrary to L<IPC::Open2>, you do not
need to use file handles to communicate with the child process, which makes
things a lot easier.

B<WARNING> This module only works for simple use cases like the one in the
synopsis, where the program called receives only 1 input and will print the
output to C<STDOUT> immediately and exit. C<STDERR> is ignored and there is no
timeout, so you should only use this module with programs and data you trust,
or else your program  might get stuck.

While this module has much less features than L<IPC::Run>, it does not suffer
from all its bugs and memory leaks, which make IPC::Run unusable in servers.
L<IPC::Open2::Simple> is also much more lightweight and has no non-core
dependencies.

=head1 FUNCTIONS

=head2 open2s

  $ret = open2s(\$output, \$input, @command)

Calls C<@command> with the content of C<$input> as C<STDIN> and copies C<STDOUT>
into C<$output>. C<STDERR> is ignored. Returns the exit status of C<@command>.
Note that C<$output> and C<$input> must be scalar references.

=head1 BUGS

Please report any bugs or feature requests to C<bug-ipc-open2-simple at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=IPC-Open2-Simple>.
I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 COPYRIGHT AND LICENSE

Copyright 2014 Olivier Duclos

This library is free software; you may redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<IPC::Open2>, L<IPC::Run>

=cut
