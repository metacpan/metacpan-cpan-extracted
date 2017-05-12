package Dir::List;

# Module contains perldoc as well as inline code documentation.
# The best is you read the perldoc (perldoc Dir::List), look
# at the doc/example*.pl and if you still don't know what to
# do, read the source. :-)

use 5.008;
use strict;
use warnings;

# This modules should be listed in Makefile.PL as well.
use Cache::File;
use Filesys::DiskUsage qw/du/;
use Clone qw/clone/;
use File::Type;
use Date::Format;
use FreezeThaw qw/safeFreeze thaw/;

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

# Set our version (comes from cvs).
(our $VERSION) = '$Revision: 1.4 $' =~ /([\d.]+)/;

# Base constructor
sub new {
	my $class = shift;
	my $args = shift;
	my $self = {};

	if($args) {
		die "The argument supplied is not a reference; Use ->new({ exclude = [ ^iso ^pub ] }) for example." unless ref $args;
	}
	my @default_exclude = qw//;
	$self->{exclude} = $args->{exclude} || \@default_exclude;
	$self->{use_cache} = $args->{use_cache} || 0;
	$self->{check_diskusage} = $args->{check_diskusage} || 1;
	$self->{show_directory_owner} = $args->{show_directory_owner} || 1;
	$self->{show_file_owner} = $args->{show_file_owner} || 1;
	$self->{show_directory_group} = $args->{show_directory_group} || 1;
	$self->{show_file_group} = $args->{show_file_group} || 1;
	$self->{datetimeformat} = $args->{datetimeformat} || "%Y-%m-%d %H:%M:%S";
	$self->{new_is_max_sec} = $args->{new_is_max_sec} || 86400 * 5;

	if($self->{use_cache}) {
		$self->{__cache} = Cache::File->new(
			cache_root		=>	$args->{cache_root} || '/tmp/Dir_List',
			default_expires	=>	$args->{cache_expires} || '5 minutes',
		);
	}

	bless($self, $class);
	return $self;
}

sub dirinfo($) {
	my $self = shift;
	my $dir = shift;
	delete $self->{list};

	my $ft = new File::Type;

	# Add a slash if not yet there...
	$dir .= '/' unless $dir =~ /\/$/;

	# Check if caching is enabled and cache has been defined
	if($self->{use_cache}) {
		if($self->{__cache}) {
			# Check if we cached the list allready.
			if(my $dirinfo = $self->{__cache}->get($dir)) {
				# We allways use safeFreeze to store complex structures
				# to the cache, so thaw it first.
				$dirinfo = \thaw($dirinfo);
				# On ref is enough.
				$dirinfo = $$dirinfo;
				# Set the cached flag, so developer knows, it comes from the cache.
				$dirinfo->{cache_info}->{cached} = 1;

				# Hmm. That's it, nothin' more to do. return the list.
				# I love cachin'...
				return $dirinfo;
			}
		}
	}

	# Open the directory
	if(opendir(DIR, $dir)) {

		# Read the files
		my @files = readdir(DIR);

		# Loop through the filelist.
		foreach(sort @files) {
			my $excluded = 0;
			# Run through the exclude regexes initialized at new()
			foreach my $exclude_regex (@{$self->{exclude}}) {
				if($_ =~ /$exclude_regex/) {
					# If it matches...
					$excluded = 1;
				}
			}
			# Skip it.
			next if $excluded;

			# Also ignore the current directory '.' and the parent directory;
			next if $_ eq '.';
			if($_ eq '..') {
				$self->{has_parent} = 1;
				next;
			} else {
				$self->{has_parent} = 0;
			}

			# At this point we have excluded (hidden) all files that we don't want to show and
			# we skipped the current directory...


			# Check if the "file" is a directory
			if(-d "$dir$_") {
				my($retval, $size);

				# Bad hack to check if the directory is accessible
				open(TST, "pushd $dir$_ >/dev/null 2>&1; RETVAL=\$?; echo \$RETVAL|");
				$retval = <TST>;
				close(TST);

				# Retval 1 means, there was some error; Normally a "permission denied"
				if($retval == 1) {
					# Set size to unknown, as we cannot gather the diskusage.
					$self->{list}->{dirs}->{$_}->{size} = "Unknown";
					# Set the inaccessible flag
					$self->{list}->{dirs}->{$_}->{inaccessible} = 1;
				} else {
					# Calculate the diskusage using File::DiskUsage du function, which is simliar to the unix command 'du'
					$self->{list}->{dirs}->{$_}->{size} = du({ 'human-readable' => 1 }, "$dir$_") || "Unknown";
					# Set the inaccessible flag to 0, as this directory is not inaccessible
					$self->{list}->{dirs}->{$_}->{inaccessible} = 0;
				}
				# Get the uid/gid fomr the directory
				$self->{list}->{dirs}->{$_}->{uid} = $self->getuid("$dir$_");
				$self->{list}->{dirs}->{$_}->{gid} = $self->getgid("$dir$_");

				# Gather user/group if the developer want's us to
				if($self->{show_directory_owner}) {
					$self->{list}->{dirs}->{$_}->{userinfo} = $self->getuserinfo($self->{list}->{dirs}->{$_}->{uid});
				}
				if($self->{show_directory_group}) {
					$self->{list}->{dirs}->{$_}->{groupinfo} = $self->getgroupinfo($self->{list}->{dirs}->{$_}->{gid});
				}

				# Gather/set the last_modified
				$self->{list}->{dirs}->{$_}->{last_modified} = $self->last_modified("$dir$_");

				# Check if this is a new directory; Based on the new_is_max_sec.
				$self->{list}->{dirs}->{$_}->{new} = $self->is_new("$dir$_");
			} else {
				# Gather the size of the file... Yes, stat would tell us the size as well, but du has build
				# in human-readable support. :-)
				$self->{list}->{files}->{$_}->{size} = du({ 'human-readable' => 1 }, "$dir$_") || "Unknown";

				# Gather uid/gid
				$self->{list}->{files}->{$_}->{uid} = $self->getuid("$dir$_");
				$self->{list}->{files}->{$_}->{gid} = $self->getgid("$dir$_");

				# Gather user/group if the developer want's us to
				if($self->{show_file_owner}) {
					$self->{list}->{files}->{$_}->{userinfo} = $self->getuserinfo($self->{list}->{files}->{$_}->{uid});
				}
				if($self->{show_file_group}) {
					$self->{list}->{files}->{$_}->{groupinfo} = $self->getgroupinfo($self->{list}->{files}->{$_}->{gid});
				}

				# Check the mime_type
				$self->{list}->{files}->{$_}->{system_mime_type} = $ft->mime_type("$dir$_");
				# Check the internal type (FileLister specific)
				$self->{list}->{files}->{$_}->{internal_type} = $self->internaltype($_);
				# Gather/set the last_modified
				$self->{list}->{files}->{$_}->{last_modified} = $self->last_modified("$dir$_");
				# Check if this is a new file; Based on the new_is_max_sec.
				$self->{list}->{files}->{$_}->{new} = $self->is_new("$dir$_");
			}
		}

		# Check if caching is enabled and the cache has been defined
		if($self->{use_cache}) {
			if($self->{__cache}) {
				# Add some information to the cache (times)
				my @lt = localtime(time);
				$self->{list}->{cache_info}->{time_string} = strftime($self->{datetimeformat}, @lt);
				$self->{list}->{cache_info}->{time_epoch} = time;
				# Save it to the cache
				$self->{__cache}->set($dir, safeFreeze($self->{list}));
			}
		}
		# We don't need to give the caching info to the developer, if it's
		# not the cached version...
		delete $self->{list}->{cache_info};

		# Return the list...
		return $self->{list};
	} else {
		return undef;
	}
}

# Helper function to clear the cache (not used internal, developer's may use this)
sub clearcache {
	my $self = shift;
	if($self->{__cache}) {
		$self->{__cache}->clear();
	}
}

# Helper function to remove an entry from the cache (not used internal, developer's may use this)
sub remove_from_cache($) {
	my $self = shift;
	my $arg = shift;

	if($self->{__cache}) {
		$self->{__cache}->remove($arg);
	}
}

# Helper function to retrieve the uid from a file/directory
sub getuid($) {
	my $self = shift;
	my $arg = shift;
	# UID is number four in stat
	return (stat($arg))[4];
}

# Helper function to retrieve the userinformation for a uid
sub getuserinfo($) {
	my $self = shift;
	my $arg = shift;
	# If it's allready cached (within' this process/instance), don't ask the system again
	unless(defined $self->{uid_cache}->{$arg}) {
		my($name,$passwd,$uid,$gid,$quota,$comment,$gcos,$dir,$shell,$expire) = getpwuid($arg);

		# Save the information to our current instance (caching).
		$self->{uid_cache}->{$arg} = {
			name	=> $name,
			passwd	=> $passwd,
			uid		=> $uid,
			gid		=> $gid,
			quota	=> $quota,
			comment	=> $comment,
			gcos	=> $gcos,
			dir		=> $dir,
			shell	=> $shell,
			expire	=> $expire,
		};
	}
	# We need to clone it, else we would get a reference to the existing hash
	return clone($self->{uid_cache}->{$arg});
}

# Helper function to retrieve the gid from a file/directory
sub getgid($) {
	my $self = shift;
	my $arg = shift;
	return (stat($arg))[5];
}

# Helper function to retrieve the groupinformation for a gid
sub getgroupinfo($) {
	my $self = shift;
	my $arg = shift;
	# If it's allready cached (within' this process/instance), don't ask the system again
	unless(defined $self->{gid_cache}->{$arg}) {
		my($name,$passwd,$gid,$members) = getgrgid($arg);
		$self->{gid_cache}->{$arg} = {
			gid		=> $gid,
			name	=> $name,
			passwd	=> $passwd,
			members	=> $members,
		};
	}
	# We need to clone it, else we would get a reference to the existing hash
	return clone($self->{gid_cache}->{$arg});
}

# We have an internal list of filetypes.
sub internaltype($) {
	my $self = shift;
	my $arg = shift;
	# Make an array containing hashes, that holds
	# our types.
	# This must be an array! Else it could be that .gz
	# would override the .tar.gz regex...
	my @types = (
		{	regex	=> "\.zip",			type	=> 'zip' },
		{	regex	=> "\.rar",			type	=> 'rar' },
		{	regex	=> "\.tgz",			type	=> 'tgz' },
		{	regex	=> "\.tar.gz",		type	=> 'tgz' },
		{	regex	=> "\.gz",			type	=> 'gz' },
		{	regex	=> "\.tar",			type	=> 'tar' },
		{	regex	=> "\.rpm",			type	=> 'rpm' },
		{	regex	=> "\.pdf",			type	=> 'pdf' },
		{	regex	=> "\.patch",		type	=> 'patch' },
		{	regex	=> "\.patch.gz",	type	=> 'patch' },
		{	regex	=> "\.sh",			type	=> 'sh' },
		{	regex	=> "\.pl",			type	=> 'pl' },
		{	regex	=> "\.text",		type	=> 'txt' },
		{	regex	=> "\.txt",			type	=> 'txt' },
		{	regex	=> "\.tex",			type	=> 'tex' },
		{	regex	=> "\.iso",			type	=> 'iso' },
	);
	# Loop through the types
	foreach (@types) {
		# If it matches, return it, we don't need to loop any longer
		return $_->{type} if $arg =~ /$_->{regex}$/;
	}
	# We can get here, if no type matched... => return undef.
	return undef;
}

# Helper function, that returns a nice formated datetime.
sub last_modified($) {
	my $self = shift;
	my $arg = shift;
	my @lt = localtime(((stat($arg)))[9]);
	return strftime($self->{datetimeformat}, @lt);
}

# Helper function, that returns 0/1; Based on new_is_max_sec and the difference
# between current datetime and files last_modfication datetime.
sub is_new($) {
	my $self	= shift;
	my $arg		= shift;

	my $filetime = (((stat($arg)))[9]);
	return 1 if time - $filetime < $self->{new_is_max_sec};
	return 0;
}

1;
__END__

=head1 NAME

Dir::List - Perl extension for retrieving directory/fileinformation

=head1 SYNOPSIS

  use Dir::List;

  my $dir = Dir::List->new();

  my $dirinfo = $dir->dirinfo('/var/ftp');

  A few things can be defined @ new, that will change the behaviour of Dir::List:

	- exclude (array, default: empty)
	- use_cache (1/0, default: 0 (disabled))
	- cache_root (path where to store the cache, if enabled, default: "/tmp/Dir_List")
	- cache_expires (Cache::File expires, default: '5 monutes')
	- check_diskusage (1/0, default: 1 (enabled))
	- show_directory_owner (1/0, default: 1 (enabled))
	- show_directory_group (1/0, default: 1 (enabled))
	- show_file_group (1/0, default: 1 (enabled))
	- show_file_owner (1/0, default: 1 (enabled))
	- datetimeformat (Date::Format template, default: "%Y-%m-%d %H:%M:%S")
	- new_is_max_sec (seconds as int, default 86400 * 5 (five days)

  These arguments can be specified the way (don't forget the '{'!)

  my $dir = new Dir::List({
	  exclude => [ qw/^iso ^pub/ ],
	  use_cache => 1,
	  cache_root => '/tmp/MyApplication_Cache/',
	  cache_expires => '20 minutes',
	  check_diskusage => 1,
	  show_directory_owner => 1,
	  show_directory_group => 1,
	  show_file_owner => 1,
	  show_file_group => 1,
	  datetimeformat => "%Y-%m-%d %H:%M:%S",
	  new_is_max_sec => 86400 * 5,
  });

=head1 DESCRIPTION

  Dir::List is a wrapper around a few other modules. It provides you with various
  informations about the contents of a directory. Eg. diskusage of directory,
  user/group, uid/gid of files/directories, last modified date/time, if it's
  accessible by the current user and so on.

  Dir::List has caching functionality. This is usefull if you list many files/directories
  and don't want to Dir::List to consume to much CPU and I/O all the time.
  Also gatherin' the uid/gid an internal caching mechanism is used to speed up Dir::List.

  The module provides you with a few functions:

  dirinfo()

  This function is easy to use. Instanciate a new Dir::List and do:

  my $dirinfo = $dir->dirinfo('/var/ftp').

  $dirinfo will now hold a lots of information about the files/directories within /var/ftp.

  That's it. :-)

  There are two functions that help you with the cache:

  clearcache()

  Takes no arguments, simply clears the cache completely.

  remove_from_cache()

  Takes a path (always with the trailing slash!) as argument and removes the entry from the cache.

  Please note, that all functions from Cache::File and Cache are available through the $dir->{__cache},
  but normally it's not a good idea to modify internal variables directly...

  This module is a split of, of my FileLister project. As FileLister will become
  a mod_perl application sooner or later (I'm working on a rewrite), I think it's
  better to put more logic into modules and provide this function to other developers
  as well.

  Note, that I rewrote the functions from FileLister and did a lot of optimizations/changes to speed up
  things.

=head2 EXPORT

None by default.

=head1 SEE ALSO

Cache::File
Filesys::DiskUsage
Clone
File::Type
Date::Format

=head1 AUTHOR

Oliver Falk, E<lt>oliver@linux-kernel.atE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Oliver Falk

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
