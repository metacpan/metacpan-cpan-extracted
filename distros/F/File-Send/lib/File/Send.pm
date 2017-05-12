package File::Send;
{
  $File::Send::VERSION = '0.002';
}
use strict;
use warnings;
use Carp;
use Errno 'EAGAIN';

use Sub::Exporter::Progressive -setup => { exports => ['sendfile'], groups => { default => ['sendfile'] } };

use Fcntl 'SEEK_CUR';
sub _systell {
	return sysseek $_[0], 0, SEEK_CUR;
}

my $backend = eval { require Sys::Sendfile; 'Sys::Sendfile' } || eval { require File::Map; 'File::Map' } || '';

if ($backend eq 'Sys::Sendfile') {
	*sendfile = sub {
		my $ret = Sys::Sendfile::sendfile(@_);
		croak "Couldn't sendfile: $!" if not defined $ret and $! != EAGAIN;
		return $ret;
	}
}
elsif ($backend eq 'File::Map') {
	*sendfile = sub {
		my ($out, $in, $length) = @_;
		my $offset = _systell $in;
		$length ||= (-s $in) - $offset;
		File::Map::map_handle(my $map, $in, '<', $offset, $length);
		my $ret = syswrite $out, $map;
		croak "Couldn't sendfile: $!" if not defined $ret and $! != EAGAIN;
		return $ret;
	}
}
else {
	croak 'No backend for File::Send installed';
}

1;

=pod

=head1 NAME

File::Send - Sending files over a socket efficiently and cross-platform

=head1 VERSION

version 0.002

=head1 SYNOPSIS

=head1 DESCRIPTION

File::Send provides access to your operating system's C<sendfile> facility, or if that is not available uses L<File::Map> and C<syswrite> to achieve a similarly efficient io function. It allows you to efficiently transfer data from one filehandle to another. Typically the source is a file on disk and the sink is a socket, and some operating systems may not even support other usage.

=head1 FUNCTIONS

=head2 sendfile $out, $in, $count

This function sends up to C<$count> B<bytes> from C<$in> to C<$out>. If $count isn't given, it will send all remaining bytes in $in. C<$in> and C<$out> can be a bareword, constant, scalar expression, typeglob, or a reference to a typeglob. It returns the number of bytes actually sent. On error it throws an exception describing the problem. This function is exported by default.

=encoding utf8

=head1 FUNCTIONS

=head1 AUTHOR

Leon Timmermans <leont@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

#ABSTRACT: Sending files over a socket efficiently and cross-platform

