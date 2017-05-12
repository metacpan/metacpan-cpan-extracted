
package Logfile::Tail;

=head1 NAME

Logfile::Tail - read log files

=head1 SYNOPSIS

	use Logfile::Tail ();
	my $file = new Logfile::Tail('/var/log/messages');
	while (<$file>) {
		# process the line
	}

and later in different process

	my $file = new Logfile::Tail('/var/log/messages');

and continue reading where we've left out the last time. Also possible
is to explicitly save the current position:

	my $file = new Logfile::Tail('/var/log/messages',
		{ autocommit => 0 });
	my $line = $file->getline();
	$file->commit();

=cut

use strict;
use warnings FATAL => 'all';

our $VERSION = '0.7';

use Symbol ();
use IO::File ();
use Digest::SHA ();
use File::Spec ();
use Fcntl qw( O_RDWR O_CREAT );
use Cwd ();

sub new {
	my $class = shift;

	my $self = Symbol::gensym();
	bless $self, $class;
	tie *$self, $self;

	if (@_) {
		$self->open(@_) or return;
	}

	return $self;
}

my $STATUS_SUBDIR = '.logfile-tail-status';
my $CHECK_LENGTH = 512;
sub open {
	my $self = shift;

	my $filename = shift;
	if (@_ and ref $_[-1] eq 'HASH') {
		*$self->{opts} = pop @_;
	}
	if (not exists *$self->{opts}{autocommit}) {
		*$self->{opts}{autocommit} = 1;
	}

	my ($archive, $offset, $checksum) = $self->_load_data_from_status($filename);
	return unless defined $offset;

	my $need_commit = *$self->{opts}{autocommit};
	if (not defined $checksum) {
		$need_commit = 1;
	}

	my ($fh, $content) = $self->_open(defined $archive ? $filename . $archive : $filename, $offset);
	if (not defined $fh) {
		if (not defined $archive) {
			return;
		}
		my ($older_fh, $older_archive, $older_content) = $self->_get_archive($archive, 'older', $offset, $checksum);
		if (defined $older_fh) {
			$fh = $older_fh;
			$content = $older_content;
			$archive = $older_archive;
		} else {
			return;
		}
	} elsif (not defined $checksum) {
		$content = $self->_seek_to($fh, 0);
	} elsif (not defined $content
		or $checksum ne Digest::SHA::sha256_hex($content)) {
		my ($older_fh, $older_archive, $older_content) = $self->_get_archive($archive, 'older', $offset, $checksum);
		if (defined $older_fh) {
			$fh->close();
			$fh = $older_fh;
			$content = $older_content;
			$archive = $older_archive;
		} else {
			$content = $self->_seek_to($fh, 0);
		}
	}

	my $layers = $_[0];
	if (defined $layers and $layers =~ /<:/) {
		$layers =~ s!<:!<:scalar:!;
	} else {
		$layers = '<:scalar';
	}

	my $buffer = '';
	*$self->{int_buffer} = \$buffer;
	my $int_fh;
	eval { open $int_fh, $layers, *$self->{int_buffer} };
	if ($@) {
		warn "$@\n";
		return;
	};
	*$self->{int_fh} = $int_fh;

	*$self->{_fh} = $fh;
	*$self->{data_array} = [ $content ];
	*$self->{data_length} = length $content;
	*$self->{archive} = $archive;

	if ($need_commit) {
		$self->commit();
	}
	1;
}

sub _open {
	my ($self, $filename, $offset) = @_;
	my $fh = new IO::File or return;
	$fh->open($filename, '<:raw') or return;

	if ($offset > 0) {
		my $content = $self->_seek_to($fh, $offset);
		return ($fh, $content);
	}
	return ($fh, '');
}

sub _fh {
	*{$_[0]}->{_fh};
}

sub _seek_to {
	my ($self, $fh, $offset) = @_;

	my $offset_start = $offset - $CHECK_LENGTH;
	$offset_start = 0 if $offset_start < 0;

	# no point in checking the return value, seek will
	# go beyond the end of the file anyway
	$fh->seek($offset_start, 0);

	my $buffer = '';
	while ($offset - $offset_start > 0) {
		my $read = $fh->read($buffer, $offset - $offset_start, length($buffer));
		# $read is not defined for example when we try to read directory
		last if not defined $read or $read <= 0;
		$offset_start += $read;
	}
	if ($offset_start == $offset) {
		return $buffer;
	} else {
		return;
	}
}

sub _load_data_from_status {
	my ($self, $log_filename) = @_;
	my $abs_filename = Cwd::abs_path($log_filename);
	if (not defined $abs_filename) {
		# can we access the file at all?
		warn "Cannot access file [$log_filename]\n";
		return;
	}
	my @abs_stat = stat $abs_filename;
	if (defined $abs_stat[1] and (stat $log_filename)[1] == $abs_stat[1]) {
		$log_filename = $abs_filename;
	}

	*$self->{filename} = $log_filename;

	my $status_filename = *$self->{opts}{status_file};
	if (not defined $status_filename) {
		$status_filename = Digest::SHA::sha256_hex($log_filename);
	}
	my $status_dir = *$self->{opts}{status_dir};
	if (not defined $status_dir) {
		$status_dir = $STATUS_SUBDIR;
	} elsif ($status_dir eq '') {
		$status_dir = '.';
	}
	if (not -d $status_dir) {
		mkdir $status_dir, 0775;
	}
	my $status_path = File::Spec->catfile($status_dir, $status_filename);
	my $status_fh = new IO::File $status_path, O_RDWR | O_CREAT;
	if (not defined $status_fh) {
		warn "Error reading/creating status file [$status_path]\n";
		return;
	}
	*$self->{status_fh} = $status_fh;

	my $status_line = <$status_fh>;
	my ($offset, $checksum, $archive_filename) = (0, undef, undef);
	if (defined $status_line) {
		if (not $status_line =~ /^File \[(.+?)\] (?:archive \[(.+)\] )?offset \[(\d+)\] checksum \[([0-9a-z]+)\]\n/) {
			warn "Status file [$status_path] has bad format\n";
			return;
		}
		my $check_filename = $1;
		$archive_filename = $2;
		$offset = $3;
		$checksum = $4;
		if ($check_filename ne $log_filename) {
			warn "Status file [$status_path] is for file [$check_filename] while expected [$log_filename]\n";
			return;
		}
	}

	return ($archive_filename, $offset, $checksum);
}

sub _save_offset_to_status {
	my ($self, $offset) = @_;
	my $log_filename = *$self->{filename};
	my $status_fh = *$self->{status_fh};
	my $checksum = $self->_get_current_checksum();
	$status_fh->seek(0, 0);
	my $archive_text = defined *$self->{archive} ? " archive [@{[ *$self->{archive} ]}]" : '';
	$status_fh->printflush("File [$log_filename]$archive_text offset [$offset] checksum [$checksum]\n");
	$status_fh->truncate($status_fh->tell);
}

sub _push_to_data {
	my $self = shift;
	my $chunk = shift;
	if (length($chunk) >= $CHECK_LENGTH) {
		*$self->{data_array} = [ substr $chunk, -$CHECK_LENGTH ];
		*$self->{data_length} = $CHECK_LENGTH;
		return;
	}
	my $data = *$self->{data_array};
	my $data_length = *$self->{data_length};
	push @$data, $chunk;
	$data_length += length($chunk);
	while ($data_length - length($data->[0]) >= $CHECK_LENGTH) {
		$data_length -= length($data->[0]);
		shift @$data;
	}
	*$self->{data_length} = $data_length;
}

sub _get_current_checksum {
	my $self = shift;
	my $data_length = *$self->{data_length};
	my $data = *$self->{data_array};
	my $i = 0;
	my $digest = new Digest::SHA('sha256');
	if ($data_length > $CHECK_LENGTH) {
		$digest->add(substr($data->[0], $data_length - $CHECK_LENGTH));
		$i++;
	}
	for (; $i <= $#$data; $i++) {
		$digest->add($data->[$i]);
	}
	return $digest->hexdigest();
}

sub _get_archive {
	my ($self, $start, $older_newer, $offset, $checksum) = @_;
	my @types = ( '-', '.' );
	my $start_num;
	if (defined $start) {
		@types = substr($start, 0, 1);
		$start_num = substr($start, 1);
	}
	my $filename = *$self->{filename};
	for my $t (@types) {
		my $srt;
		if ($t eq '.') {
			if ($older_newer eq 'newer') {
				$srt = sub { $_[1] <=> $_[0] };
			} else {
				$srt = sub { $_[0] <=> $_[1] };
			}
		} else {
			if ($older_newer eq 'newer') {
				$srt = sub { $_[0] cmp $_[1] };
			} else {
				$srt = sub { $_[1] cmp $_[0] };
			}
		}
		my @archives = map { "$t$_" }			# make it a suffix
			sort { $srt->($a, $b) }			# sort properly
			grep { not defined $start_num or $srt->($_, $start_num) == 1}		# only newer / older
			grep { /^[0-9]+$/ }			# only numerical suffixes
			map { substr($_, length($filename) + 1) }	# only get the numerical suffixes
			glob "$filename$t*";			# we look at file.1, file.2 or file-20091231, ...
		if ($older_newer eq 'newer' and -f $filename) {
			push @archives, '';
		}
		for my $a (@archives) {
			my ($fh, $content) = $self->_open($filename . $a, ($offset || 0));
			if (not defined $fh) {
				next;
			}
			if (defined $checksum) {
				if (defined $content
					and $checksum eq Digest::SHA::sha256_hex($content)) {
					return ($fh, $a, $content);
				}
			} else {
				return ($fh, ($a eq '' ? undef : $a), $content);
			}
			$fh->close();
		}
	}
	return;
}

sub _close_status {
	my ($self, $offset) = @_;
	my $status_fh = delete *$self->{status_fh};
	$status_fh->close() if defined $status_fh;
}

sub _getline {
	my $self = shift;
	my $fh = $self->_fh;
	if (defined $fh) {
		my $buffer_ref = *$self->{int_buffer};
		DO_GETLINE:
		my $ret = undef;
		$$buffer_ref = $fh->getline();
		if (not defined $$buffer_ref) {
			# we are at the end of the current file
			# we need to check if the file was rotated
			# in the meantime
			my @fh_stat = stat($fh);
			my $filename = *$self->{filename};
			my @file_stat = stat($filename . ( defined *$self->{archive} ? *$self->{archive} : '' ));
			if (not @file_stat or "@fh_stat[0, 1]" ne "@file_stat[0, 1]") {
				# our file was rotated, or generally
				# is no longer where it was when
				# we started to read
				my ($older_fh, $older_archive, $older_content)
					= $self->_get_archive(*$self->{archive}, 'older', $fh->tell, $self->_get_current_checksum);
				if (not defined $older_fh) {
					# we have lost the file / sync
					return;
				}
				*$self->{_fh}->close();
				*$self->{_fh} = $fh = $older_fh;
				*$self->{data_array} = [ $older_content ];
				*$self->{data_length} = length $older_content;
				*$self->{archive} = $older_archive;
				goto DO_GETLINE;
			} elsif (defined *$self->{archive}) {
				# our file was not rotated
				# however, if our file is in fact
				# a rotate file, we should go to the
				# next one
				my ($newer_fh, $newer_archive) = $self->_get_archive(*$self->{archive}, 'newer');
				if (not defined $newer_fh) {
					return;
				}
				*$self->{_fh}->close();
				*$self->{_fh} = $fh = $newer_fh;
				*$self->{data_array} = [ '' ];
				*$self->{data_length} = 0;
				*$self->{archive} = $newer_archive;
				goto DO_GETLINE;
			}
			return;
		}
		$self->_push_to_data($$buffer_ref);
		seek(*$self->{int_fh}, 0, 0);
		my $line = *$self->{int_fh}->getline();
		return $line;
	} else {
		return undef;
	}
}

sub getline {
	my $self = shift;
	my $ret = $self->_getline();
	no warnings 'uninitialized';
	if (*$self->{opts}{autocommit} == 2) {
		$self->commit();
	}
	return $ret;
}

sub getlines {
	my $self = shift;
	my @out;
	while (1) {
		my $l = $self->_getline();
		if (not defined $l) {
			last;
		}
		push @out, $l;
	}
	no warnings 'uninitialized';
	if (*$self->{opts}{autocommit} == 2) {
		$self->commit();
	}
	@out;
}

sub commit {
	my $self = shift;
	my $fh = *$self->{_fh};
	my $offset = $fh->tell;
	$self->_save_offset_to_status($offset);
}

sub close {
	my $self = shift;
	if (*$self->{opts}{autocommit}) {
		$self->commit();
	}
	$self->_close_status();
	my $fh = delete *$self->{_fh};
	$fh->close() if defined $fh;
}

sub TIEHANDLE() {
	if (ref $_[0]) {
		# if we already have object, probably called from new(),
		# just return that
		return $_[0];
	} else {
		my $class = shift;
		return $class->new(@_);
	}
}

sub READLINE() {
	goto &getlines if wantarray;
	goto &getline;
}

sub CLOSE() {
	my $self = shift;
	$self->close();
}

sub DESTROY() {
	my $self = shift;
	$self->close() if defined *$self->{_fh};
}

1;

=head1 DESCRIPTION

Log files are files that are generated by various running programs.
They are generally only appended to. When parsing information from
log files, it is important to only read each record / line once,
both for performance and for accounting and statistics reasons.

The C<Logfile::Tail> provides an easy way to achieve the
read-just-once processing of log files.

The module remembers for each file the position where it left
out the last time, in external status file, and upon next invocation
it seeks to the remembered position. It also stores checksum
of 512 bytes before that position, and if the checksum does not
match the file content the next time it is read, it will try to
find the rotated file and read the end of it before advancing to
newer rotated file or to the current log file.

Both .num and -date suffixed rotated files are supported.

=head1 METHODS

=over 4

=item new()

=item new( FILENAME [,MODE [,PERMS]], [ { attributes } ] )

=item new( FILENAME, IOLAYERS, [ { attributes } ] )

Constructor, creates new C<Logfile::Tail> object. Like C<IO::File>,
it passes any parameters to method C<open>; it actually creates
an C<IO::File> handle internally.

Returns new object, or undef upon error.

=item open( FILENAME [,MODE [,PERMS]], [ { attributes } ] )

=item open( FILENAME, IOLAYERS, [ { attributes } ] )

Opens the file using C<IO::File>. If the file was read before, the
offset where the reading left out the last time is read from an
external file in the ./.logfile-tail-status directory and seek is
made to that offset, to continue reading at the last remembered
position.

If however checksum, which is also stored with the offset, does not
match the current content of the file (512 bytes before the offset
are checked), the module assumes that the file was rotated / reused
/ truncated in the mean time since the last read. It will try to
find the checksum among the rotated files. If no match is found,
it will reset the offset to zero and start from the beginning of
the file.

Returns true, or undef upon error.

The attributes are passed as an optional hashref of key => value
pairs. The supported attribute is

=over 4

=item autocommit

Value 0 means that no saving takes place; you need to save explicitly
using the commit() method.

Value 1 (the default) means that position is saved when the object is
closed via explicit close() call, or when it is destroyed. The value
is also saved upon the first open.

Value 2 causes the position to be save in all cases as value 1,
plus after each successful read.

=item status_dir

The attribute specifies the directory (or subdirectory of current
directory) which is used to hold status files. By default,
./.logfile-tail-status directory is used. To store the status
files in the current directory, pass empty string or dot (.).

=item status_file

The attribute specifies the name of the status file which is used to
hold the offset and SHA256 checksum of 512 bytes before the offset.
By default, SHA256 of the full (absolute) logfile filename is used
as the status file name.

=back

=item commit()

Explicitly save the current position and checksum in the status file.

Returns true, or undef upon error.

=item close()

Closes the internal filehandle. It stores the current position
and checksum in an external file in the ./.logfile-tail-status
directory.

Returns true, or undef upon error.

=item getline()

Line <$fh> in scalar context.

=item getlines()

Line <$fh> in list context.

=back

=head1 AUTHOR AND LICENSE

Copyright (c) 2010 Jan Pazdziora.

Logfile::Tail is free software. You can redistribute it and/or modify
it under the terms of either:

a) the GNU General Public License, version 2 or 3;

b) the Artistic License, either the original or version 2.0.

