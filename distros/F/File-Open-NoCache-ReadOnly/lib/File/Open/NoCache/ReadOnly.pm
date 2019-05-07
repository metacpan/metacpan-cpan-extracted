package File::Open::NoCache::ReadOnly;

# Author Nigel Horne: njh@bandsman.co.uk
# Copyright (C) 2019 Nigel Horne

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

=head1 NAME

File::Open::NoCache::ReadOnly - Open a file and clear the cache afterward

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SUBROUTINES/METHODS

=head2 new

Open a file and flush the cache afterwards.
One use case is building a large database from smaller files that are
only read in once.
Once the file has been used it's a waste of RAM to keep it in cache.

    use File::Open::NoCache::ReadOnly;
    my $fh = File::Open::NoCache::ReadOnly->new('/etc/passwd');

=cut

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;

	return unless(defined($class));

	my %params;
	if(ref($_[0]) eq 'HASH') {
		%params = %{$_[0]};
	} elsif(ref($_[0]) || !defined($_[0])) {
		Carp::croak('Usage: ', __PACKAGE__, '->new(%args)');
	} elsif(scalar(@_) % 2 == 0) {
		%params = @_;
	} else {
		$params{'filename'} = shift;
	}

	if(my $filename = $params{'filename'}) {
		if(open(my $fd, '<', $filename)) {
			return bless { fd => $fd }, $class
		}
		Carp::carp("$filename: $!");
		return;
	}
	Carp::carp('Usage: ', __PACKAGE__, '->new(filename => $filename)');
	return;
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

sub DESTROY {
	if(defined($^V) && ($^V ge 'v5.14.0')) {
		return if ${^GLOBAL_PHASE} eq 'DESTRUCT';	# >= 5.14.0 only
	}
	my $self = shift;

	if(my $fd = $self->{'fd'}) {
		# my @statb = stat($fd);
		# IO::AIO::fadvise($fd, 0, $statb[7] - 1, IO::AIO::FADV_DONTNEED);
		IO::AIO::fadvise($fd, 0, 0, IO::AIO::FADV_DONTNEED);

		close $self->{'fd'};

		delete $self->{'fd'};
	}
}

=head1 AUTHOR

Nigel Horne, C<< <njh at bandsman.co.uk> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-file-Open-NoCache-ReadOnly at rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=File-Open-NoCache-ReadOnly>.
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc File::Open::NoCache::ReadOnly

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=File-Open-NoCache-ReadOnly>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/File-Open-NoCache-ReadOnly>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/File-Open-NoCache-ReadOnly>

=item * Search CPAN

L<http://search.cpan.org/dist/File-Open-NoCache-ReadOnly/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2019 Nigel Horne.

Usage is subject to licence terms.

The licence terms of this software are as follows:

* Personal single user, single computer use: GPL2
* All other users (including Commercial, Charity, Educational, Government)
  must apply in writing for a licence for use from Nigel Horne at the
  above e-mail.

=cut

1;
