#! /usr/bin/perl

=head1

File::Store - a file content caching system

=head1 SYNOPSIS

	use File::Store;

	my $contents1 = File::Store::get('/etc/passwd');
	my $contents2 = File::Store::get('/etc/passwd');

or

	use File::Store;
	my $store = new File::Store;

	my $contents1 = $store->get('/etc/passwd');
	my $contents2 = $store->get('/etc/passwd');
	$store->clear();


=head1 DESCRIPTION

This modules acts as an in-memory cache for files. Each file is read once
unless the modification date changes; in which case the file is
reread. Files can be automatically flushed based on time, size or
number of files.

Files are read from the file system via the function I<get> and
cached in memory. Subsequent calls for the same file returns the
cached file contents. If the file has been updated on disc, the file
is re-read.

If no File::Store object is specified then a global store is used.

=cut

package File::Store;

use 5;
use strict;
use warnings;

use Carp;
require bytes;

use vars qw($VERSION $EXPIRE $SIZE $MAX);

$VERSION = '1.00';

$EXPIRE	= 0;
$MAX	= 0;
$SIZE	= 0;

=head1 DEFAULT OPTIONS

The default options are

=over 4

=item I<expire>

How long, in seconds, to keep files in the cache. The default is always (0).

=item I<size>

The maximum size, in bytes, of files kept in the cache.
The default is 0 (infinite).

=item I<max>

The maximum number of files kept in the cache.
The default is 0 (infinite).

=back 4

These defaults can be changed globally via the packages variables
C<$File::Store::EXPIRE>,
C<$File::Store::SIZE>
and
C<$File::Store::MAX> respectively.

=cut

=head1 FUNCTIONS

=over 4

=item C<new>

	my $store = new File::Store (<options>);

Create a new File::Store object with options.

=cut

sub debug { };
#sub debug { print STDERR (caller(1))[2], ' ', @_; };

sub new
{
	my ($class, @args) = @_;
	croak "odd number of option arguments" unless ($#args % 2);

	my $self = {};
	bless $self, $class;

	$self->{option} = {
		expire	=> $EXPIRE,
		max	=> $MAX,
		size	=> $SIZE,
	};

	$self->{cache}	= {};
	$self->{queue}	= [];
	$self->{count}	= 0;
	$self->{size}	= 0;

	$self->configure(@args);

	$self;
}

# Default file store.
our $base = new File::Store();

=item C<configure>

	$store->configure(<options>);

Configure a File::Store.

=cut

sub configure
{
	if (ref $_[0] ne 'File::Store') { unshift @_, $base; }
	my ($this, @args) = @_;

	croak "odd number of option arguments" unless ($#args % 2);
	my %args = @args;

	$this->{option}->{expire} = delete $args{expire}
		if exists $args{expire};
	$this->{option}->{size} = delete $args{size} 
		if exists $args{size};
	$this->{option}->{max} = delete $args{max} 
		if exists $args{max};

	croak "unknown configuration keys '", join("', '", keys %args) . "'" if (%args);

	# purge any files from the cache.
	$this->purge();

	$this;
}

=item C<get>

	$store->get($file);

Return the contents of the specified file from the cache, reading the
file from disc if necessary.

=cut
# return any cached file, or load it if needed.
sub get
{
	if (ref $_[0] ne 'File::Store') { unshift @_, $base; }
	my ($this, $file) = @_;

	debug "getting '$file'\n";

	# Check the cache first.
	my $mtime = (stat($file))[9];

	# Does the file exist?
	unless (defined $mtime)
	{
		# no such file.
		$this->clear($file); # just in case.
		return undef;
	}

	unless ($this->cached($file) == $mtime)
	{
		debug "reading $file from disc\n";

		# clear, just in case.
		$this->clear($file);

		# Open file.
		local (*F);
		open (F, '<', $file) || return undef;

		# Read file.
		local ($/) = undef;
		my $str = <F>;
		close (F);

		# Remember
		$this->{cache}->{$file}->{mtime}	= $mtime;
		$this->{cache}->{$file}->{content}	= $str;

		$this->{count}++;
		$this->{size} += bytes::length($str);
	}

	# remember when it was last used.
	$this->{cache}->{$file}->{when} = time;

	# requeue
	local $_;
	@{$this->{queue}} = grep {$_ ne $file} @{$this->{queue}};
	push @{$this->{queue}}, $file;

	# reorder the cache
	#my $tmp = $this->{cache}->{$file};
	#debug "List0 ", join(' ', keys %{$this->{cache}}), "\n";
	#$this->{tie}->DELETE($file);
	#debug "List1 ", join(' ', keys %{$this->{cache}}), "\n\n";
	#$this->{cache}->{$file} = $tmp;

	# There is a slight chance that purging will 
	# delete this file. So remember the contents before 
	# purging.
	my $contents = $this->{cache}->{$file}->{content};

	# spring clean
	$this->purge();

	$contents;
}

=item C<clear>

	$store->clear();
	$store->clear($file1, $file2, ...);

Clear the caches inside a File::Store. If files are specified,
information about those files are clear. Otherwise the whole cache is
cleared.

=cut

sub clear
{
	if (ref $_[0] ne 'File::Store') { unshift @_, $base; }
	my ($this, @files) = @_;

	unless  (@files)
	{
		debug "clearing cache.\n";

		$this->{count}	= 0;
		$this->{size}	= 0;
		$this->{cache}	= {};
		$this->{queue}	= [];

		return $this;
	}

	for my $f (@files)
	{
		next unless exists $this->{cache}->{$f};

		debug "clearing '$f'.\n";
		local $_;

		$this->{count} --;
		$this->{size} -= bytes::length($this->{cache}->{$f}->{content});
		@{$this->{queue}} = grep {$_ ne $f} @{$this->{queue}};

		delete $this->{cache}->{$f};
	}
	
	$this;
}

=item C<purge>

	$store->purge();

Remove any items in the cache according to the options I<expire>,
I<size> and I<max>. If the cache is too large, then the oldest items
(according to their last use) are removed.

=cut

sub purge
{
	if (ref $_[0] ne 'File::Store') { unshift @_, $base; }
	my ($this) = @_;

	debug "list ", join(' ', @{$this->{queue}}), "\n";

	my @files;

	# Look through the list and expire the cache
	if ($this->{option}->{expire} > 0)
	{
		for my $f (keys %{$this->{cache}})
		{
			if ($this->{cache}->{$f}->{when} < time - $this->{option}->{expire})
			{
				$this->clear($f);
				push @files, $f;
				debug "purged expired '$f'.\n";
			}
		}
	}

	# Have we cached too much data?
	if ($this->{option}->{size} > 0 && $this->{size} > $this->{option}->{size})
	{
		my @list = sort { $this->{cache}->{$a}->{when} <=> $this->{cache}->{$b}->{when}; }
			keys %{$this->{cache}};

		while ($this->{size} > $this->{option}->{size})
		{
			# too much.
			my $f = shift @list;
			$this->clear($f);
			push @files, $f;
			debug "purged size excess '$f'.\n";
		}
	}

	# Have we cached too many files?
	if ($this->{option}->{max} > 0 && $this->{count} > $this->{option}->{max})
	{
		my @list = sort { $this->{cache}->{$a}->{when} <=> $this->{cache}->{$b}->{when}; }
			keys %{$this->{cache}};

		@list = @{$this->{queue}};

		while ($this->{count} > $this->{option}->{max})
		{
			# too many.
			my $f = shift @list;
			$this->clear($f);
			push @files, $f;
			debug "purged count excess '$f'; count=$this->{option}->{max}.\n";
		}
	}

	# return the list of purged files.
	@files;
}


=item C<count>

	$store->count();

Return the number of files in the File::Store.

=cut

sub count 
{
	if (ref $_[0] ne 'File::Store') { unshift @_, $base; }
	my ($this) = @_;

	$this->{count};
}

=item C<size>

	$store->size();

Return the size, in bytes, of the File::Store.

=cut

sub size 
{
	if (ref $_[0] ne 'File::Store') { unshift @_, $base; }
	my ($this) = @_;

	$this->{size};
}

=item C<cached>

	$store->cached($file);

Return the last modification time of a file contained in the cache.
Return 0 if the file isn't cached.

=cut
sub cached
{
	if (ref $_[0] ne 'File::Store') { unshift @_, $base; }
	my ($this, $file) = @_;
	croak "No file specified" unless $file;

	return -1 unless exists $this->{cache}->{$file};
	$this->{cache}->{$file}->{mtime};
}

=item C<fresh>

	$store->fresh($file1, $file2, ...);

Return whether the list of files are up to date or not. Returns 1 if
all files are fresh and undef otherwise.

=cut
# Check the file list for freshness.
sub fresh
{
	if (ref $_[0] ne 'File::Store') { unshift @_, $base; }
	my $this = shift(@_);

	for my $f (@_)
	{
		return undef unless exists $this->{cache}->{$f};

		my $m = (stat($f))[9] || 0;
	
		return undef if ($m != $this->{cache}->{$f}->{mtime});
	}

	# all is fresh
	1;
}

=head1 SEE ALSO

Perl, Cache::Cache

=head1 VERSION

This is version 1.0 released 2008.

=head1 AUTHOR

        Anthony Fletcher arif+perl@cpan.org

=head1 COPYRIGHT

Copyright (c) 1998-2008 Anthony Fletcher. All rights reserved. This
module is free software; you can redistribute them and/or modify them
under the same terms as Perl itself.

This code is supplied as-is - use at your own risk.

=cut

1;

