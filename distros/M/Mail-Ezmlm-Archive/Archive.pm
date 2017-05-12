# ===========================================================================
# Mail::Ezmlm::Archive
#
# Object methods for ezmlm-idx archives
#
# Copyright (C) 2003-2005, Alessandro Ranellucci, All Rights Reserved.
# Please send bug reports and comments to <aar@cpan.org>
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met: 
#
# Redistributions of source code must retain the above copyright notice,
# this list of conditions and the following disclaimer.
#
# Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.
#
# Neither name Alessandro Ranellucci nor the names of any contributors
# may be used to endorse or promote products derived from this software
# without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS ``AS
# IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
# THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
# PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
#
# ==========================================================================
# POD is at the end of this file. Search for '=head' to find it

package Mail::Ezmlm::Archive;

use strict;
use vars qw($VERSION *MONTHS);
require 5.002;

$VERSION = '0.16';

%MONTHS = ( Jan => 1, Feb => 2, Mar => 3, Apr => 4, May => 5, Jun => 6,
			Jul => 7, Aug => 8, Sep => 9, Oct => 10, Nov => 11, Dec => 12 );

sub new { 
	my ($class, $list) = @_;
	my $self = {};
	bless $self, ref $class || $class || 'Mail::Ezmlm::Archive';
	$self->{CACHE} = 1;
	$self->{CACHED} = {};
	$self->setlist($list) || return undef;
	return $self;
}

sub setlist {
	my ($self, $list) = @_;
	return undef if (!-e "$list/lock" || !-e "$list/archived" || !-e "$list/indexed");
	return ($self->{LIST_PATH} = $list);
}

sub cache {
	my $self = shift;
	$self->{CACHE} = 0;
}

sub nocache {
	my $self = shift;
	$self->{CACHE} = 1;
}

sub getmonths {
	my $self = shift;
	opendir(THREADS, $self->{LIST_PATH} . '/archive/threads');
	my @months = grep /^\d{6}$/, readdir(THREADS);
	closedir(THREADS);
	return sort(@months);
}

sub getthreads {
	my ($self, $month) = @_;
	my @threadlist = $self->_get_file($self->{LIST_PATH} . "/archive/threads/$month");
	my $threads = [];
	foreach my $thread (@threadlist) {
		$thread =~ m/^(\d+):(\w+) \[(\d+)\] (.*)$/;
		push (@{$threads}, {
			subject => $4,
			count => $3,
			offset => $1,
			id => $2,
			date => $self->_get_date($1)
		});
	}
	return $threads;
}

sub getthread {
	my ($self, $thread) = @_;
	my ($a, $b) = (substr($thread,0,2), substr($thread,2));
	my @messages = $self->_get_file($self->{LIST_PATH} . "/archive/subjects/$a/$b");
	my $subject = shift(@messages);
	chop($subject);
	$subject =~ s/^\w+ //;
	my $messages = [];
	foreach my $message (@messages) {
		$message =~ m/^(\d+):(\d+):(\w+) (.*)$/ || next;
		push (@{$messages}, {
			id => $1,
			month => $2,
			authorid => $3,
			author => $4
		});
	}
	return {
		subject => $subject,
		messages => $messages
	};
}

sub getmessage {
	my ($self, $message) = @_;
	$message = sprintf("%03u", $message);
	$message =~ m/^(\d+)(\d{2})$/;
	my ($a, $b) = ($1, $2);
	return undef unless (-e $self->{LIST_PATH} . "/archive/$a/$b");
	my @lines = $self->_get_file($self->{LIST_PATH} . "/archive/$a/$b");
	my $date = $self->_get_date(1*$message);
	$date =~ m/\s([A-Z][a-z]{2})\s(\d{4})/;
	return {
		month => $2 . sprintf("%02u", $MONTHS{$1}),
		text => join("", @lines)
	};
}

sub getcount {
	my $self = shift;
	open(FILE, $self->{LIST_PATH} . "/num");
	<FILE> =~ m/^(\d+):/;
 	my $count = $1;
	close(FILE);
	return $count;
}

sub _get_file {
	my ($self, $file) = @_;
	if ($self->{CACHED}->{$file}) {
		return @{$self->{CACHED}->{$file}};
	}
	open(FH, "<$file");
	my @lines = <FH>;
	close(FH);
	if ($self->{CACHE} == 1) {
		$self->{CACHED}->{$file} = [ @lines ];
	}
	return @lines;
}

sub _get_date {
	my ($self, $message) = @_;
	my $msg = sprintf("%03u", $message);
	$msg =~ m/^(\d+)(\d{2})$/;
	my ($a, $b) = ($1, $2);
	my @index = $self->_get_file($self->{LIST_PATH} . "/archive/$a/index");
	my $found;
	foreach my $line (@index) {
		if ($found) {
			$line =~ m/^\s([^;]+);/;
			return $1;
		}
		$found = 1 if ($line =~ /^$message:/);
	}
}

1;
__END__

=head1 NAME

Mail::Ezmlm::Archive - Object Methods for Ezmlm-Idx Archives

=head1 SYNOPSIS

 use Mail::Ezmlm::Archive;
 $archive = Mail::Ezmlm::Archive->new('/path/to/list/folder');
 
 $message_count = $archive->getcount;
 @available_months = $archive->getmonths;
 $threads = $archive->getthreads('200304');

=head1 ABSTRACT

Mail::Ezmlm::Archive is designed to provide an object interface to the message 
archives maintained by the ezmlm-idx software. See the ezmlm web page for a 
complete description of that software: <http://www.ezmlm.org>.

This version is designed to work with ezmlm 0.53 and ezmlm-idx 0.40.

=head1 DESCRIPTION

=head2 Setting up a new Archive object

	use Mail::Ezmlm::Archive;
	$archive = Mail::Ezmlm::Archive->new('/path/to/list/folder');

=head2 Changing which list the Archive object points at

	$archive->setlist('/full/path/to/other/list');

=head2 Getting count of archived messages

	$message_count = $archive->getcount;

Actually the getcount methods reads message count from DIR/num file, so we'd 
better consider the result as count of distributed messages instead of archived.

=head2 Getting a list of months

	@available_months = $archive->getmonths;

This returns an array of strings in the 'YYYYMM' format, such as '200304', which 
represent months for which we have archived messages.

=head2 Getting a list of threads in a given month

	$threads = $archive->getthreads('200304');

This method returns a reference to an array, whose elements are hashes with these 
keys:

=item subject

The subject of the thread, as archived in DIR/archived/threads/$month

=item count

Count of messages in the thread

=item offset

Id of first message in the thread

=item id

Thread Id.

=item date

The date of last message in the thread, as archived in DIR/archived/threads/$month

=head2 Getting list of messages in a given thread

	$messages = $archive->getthread('nknmgklhcgijmbonmbkk');

This method returns a reference to a hash, which has two keys: 'subject' and 'messages'.
The former contains the subject of the first message in the thread. The latter is a 
reference to an array, whose elements are hashes with these keys:

=item id

Message Id for retrieving.

=item month

Month of the message, in 'YYYYMM' format

=item authorid

Author Id

=item author

Full value of the 'From:' line

=head2 Retrieving a message

	$message = $archive->getmessage('52');

This method returns a reference to a hash with two keys: text and month. The first
contains the full raw message, and the message contains the month in YYYYMM format.
It returns undef if the message doesn't exist.

=head1 CACHING

All opened files are cached by default, so that we do not need to overload the 
filesystem for doing normal listing and browsing operations. However, caching 
can be disabled to reduce memory usage:

	$archive->nocache;

Then, to enable it again:

	$archive->cache;

=head1 BUGS AND LIMITATIONS

=over 4

=item *

No methods for author-based browsing.

=item *

Not enough object oriented, maybe? :-)

=head1 AVAILABILITY

You can download the latest version from CPAN ( http://search.cpan.org ). 
You are very welcome to write mail to the author (aar@cpan.org) with 
your comments, suggestions, bug reports and complaints.

=head1 SEE ALSO

L<Mail::Ezmlm>: object methods to manage Ezmlm lists by Guy Antony Halse

=head1 COPYRIGHT

Copyright (C) Alessandro Ranellucci. All rights reserved.

This library is free software; you can redistribute it and/or modify it under 
the same terms as Perl itself.

=head1 AUTHOR

 Alessandro Ranellucci <aar@cpan.org>

=cut
