package File::Open::NoCache::ReadOnly;

# Author Nigel Horne: njh@bandsman.co.uk

# Usage is subject to licence terms.
# The licence terms of this software are as follows:
# Personal single user, single computer use: GPL2
# All other users (including Commercial, Charity, Educational, Government)
#	must apply in writing for a licence for use from Nigel Horne at the
#	above e-mail.

use strict;
use warnings;
use Carp;
use IO::AIO;
use Params::Get;
use Scalar::Util;

=head1 NAME

File::Open::NoCache::ReadOnly - Open a file and flush from memory on closing

=head1 VERSION

Version 0.06

=cut

our $VERSION = '0.06';

=head1 DESCRIPTION

The C<File::Open::NoCache::ReadOnly> module is designed to open files for sequential,
read-only access while optimizing memory usage by minimizing filesystem caching.
This is particularly useful for processing large data files that only need to be read once,
such as during database population or bulk data imports.
The C<new> method facilitates opening files with options to specify file paths directly or via a parameter hash,
and it can enforce fatal errors on failure if desired.
The module uses L<IO::AIO::fadvise> to signal the operating system to avoid retaining file data in cache,
improving memory efficiency.
The module provides a C<fd> method to retrieve the file descriptor and a C<close> method for explicit resource cleanup.
The destructor also ensures file closure when the object is destroyed,
with safeguards to prevent redundant closure attempts.

=head1 SUBROUTINES/METHODS

=head2 new

Open a file that will be read once sequentially and not again,
optimising the filesystem cache accordingly.
One use case is building a large database from smaller files that are
only read in once,
once the file has been used it's a waste of RAM to keep it in cache.

    use File::Open::NoCache::ReadOnly;
    my $fh = File::Open::NoCache::ReadOnly->new('/etc/passwd');
    my $fh2 = File::Open::NoCache::ReadOnly->new(filename => '/etc/group', fatal => 1);

=cut

sub new {
	my $class = shift;

	# Handle hash or hashref arguments
	my $params = Params::Get::get_params('filename', @_);

	if(!defined($class)) {
		if((scalar keys %{$params}) > 0) {
			# Using File::Open::NoCache::ReadOnly:new(), not File::Open::NoCache::ReadOnly->new()
			carp(__PACKAGE__, ' use ->new() not ::new() to instantiate');
			return;
		}

		# FIXME: this only works when no arguments are given
		$class = __PACKAGE__;
	} elsif(Scalar::Util::blessed($class)) {
		# If $class is an object, clone it with new arguments
		return bless { %{$class}, %{$params} }, ref($class);
	}

	# Open file if filename is provided
	if(my $filename = $params->{'filename'}) {
		if(open(my $fd, '<', $filename)) {
			IO::AIO::fadvise($fd, 0, 0, IO::AIO::FADV_SEQUENTIAL|IO::AIO::FADV_NOREUSE|IO::AIO::FADV_DONTNEED);
			return bless { filename => $filename, fd => $fd }, $class;
		}
		if($params->{'fatal'}) {
			Carp::croak("$filename: $!");
		}
		Carp::carp("$filename: $!");
	} else {
		Carp::carp('Usage: ', __PACKAGE__, '->new(filename => $filename)');
	}

	return;	# Return undef if unsuccessful
}

=head2	fd

Returns the file descriptor of the file

    my $fd = $fh->fd();
    my $line = <$fd>;

=cut

sub fd {
	my $self = shift;

	return $self->{'fd'};
}

=head2 readline

Read a line from the file

=cut

sub readline {
	my $self = shift;
	my $fd = $self->{'fd'};

	return <$fd>
}

=head2	close

Shouldn't be needed as close happens automatically when the variable goes out of scope.
However Perl isn't as good at reaping as it'd have you believe, so this is here to force it when you
know you're finished with the object.

=cut

sub close {
	my $self = shift;

	if(my $fd = delete $self->{'fd'}) {
		# my @statb = stat($fd);
		# IO::AIO::fadvise($fd, 0, $statb[7] - 1, IO::AIO::FADV_DONTNEED);
		IO::AIO::fadvise($fd, 0, 0, IO::AIO::FADV_DONTNEED);

		close $fd;
	} else {
		Carp::carp('Attempt to close object twice');
	}
}

sub DESTROY {
	if(defined($^V) && ($^V ge 'v5.14.0')) {
		return if ${^GLOBAL_PHASE} eq 'DESTRUCT';	# >= 5.14.0 only
	}
	my $self = shift;

	if($self->{'fd'}) {
		$self->close();
	}
}

=head1 AUTHOR

Nigel Horne, C<< <njh at bandsman.co.uk> >>

=head1 SUPPORT

This module is provided as-is without any warranty.

Please report any bugs or feature requests to
C<bug-file-Open-NoCache-ReadOnly at rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=File-Open-NoCache-ReadOnly>.
I will be notified, and then you'll
automatically be notified of the progress on your bug as I make changes.

You can find documentation for this module with the perldoc command.

    perldoc File::Open::NoCache::ReadOnly

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=File-Open-NoCache-ReadOnly>

=item * Search CPAN

L<http://search.cpan.org/dist/File-Open-NoCache-ReadOnly/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2019-2025 Nigel Horne.

Usage is subject to licence terms.

The licence terms of this software are as follows:

=over 4

=item * Personal single user, single computer use: GPL2

=item * All other users (including Commercial, Charity, Educational, Government)
  must apply in writing for a licence for use from Nigel Horne at the
  above e-mail.

=back

=cut

1;
