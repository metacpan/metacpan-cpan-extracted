package IO::Easy;

use Class::Easy;

use vars qw($VERSION);
$VERSION = '0.16';

use File::Spec;

my $stat_methods = [qw(dev inode mode nlink uid gid rdev size atime mtime ctime blksize blocks)];
my $stat_methods_hash = {};

sub import {
	my $pack    = shift;
	my $callpkg = caller;
	my @params  = @_;
	
	my $import_ok = (scalar grep {$_ eq 'no_script'} @params) ? 0 : 1;
	my $script_ok = (scalar grep {$_ eq 'project'} @params) ? 1 : 0;

	# probably check for try_to_use is enough
	return
		if defined *{"$callpkg\::file"}{CODE}
			and Class::Easy::sub_fullname (*{"$callpkg\::file"}{CODE}) eq 'IO::Easy::__ANON__';
	
	if ($script_ok || $import_ok) {
		
		my $callpkg = $script_ok ? 'main' : caller;
		
		require IO::Easy::File;
		require IO::Easy::Dir;
		
		my $io_easy_subclass = eval {$callpkg->isa ('IO::Easy')};
		
		return if $io_easy_subclass;
		
		foreach my $type (qw(file dir)) {
			make_accessor ($callpkg, $type, default => sub {
				my $class = 'IO::Easy::' . ucfirst ($type);
				return $class->new (@_)
					if @_ > 0;
				$class
			});
		}
	}
}

foreach my $i (0 .. $#$stat_methods) {
	has ($stat_methods->[$i], default => sub {
		my $self = shift;
		my $stat = $self->stat;

		return $stat->[$i];
	});
	$stat_methods_hash->{$stat_methods->[$i]} = $i;
}

use overload
	'""'  => 'path',
	'cmp' => '_compare';

our $FS = 'File::Spec';

sub new {
	my $class = shift;
	my $path  = shift;
	my $args  = shift || {};
	
	my $self = bless {%$args, path => $path}, $class;
	
	my $initialized = $self;
	$initialized = $self->_init
		if $self->can ('_init');
	
	return $initialized;
}

sub attach_interface {
	my $self = shift;
	
	if (-f $self->{path}) {
		return $self->as_file;
	} elsif (-d $self->{path}) {
		return $self->as_dir;
	}
}

sub name {
	my $self = shift;
	
	my ($vol, $dir, $file) = $FS->splitpath ($self->{path});
	
	return $file;
}

sub base_name {
	my $self = shift;
	
	my $file_name = $self->name;
	
	my $base_name = ($file_name =~ /(.*?)(?:\.[^\.]+)?$/)[0];
	
	return $base_name;
}

sub extension {
	my $self = shift;
	
	my $file_name = $self->name;
	
	my $extension = ($file_name =~ /(?:.*?)(?:\.([^\.]+))?$/)[0];
	
	return $extension;
}

sub as_file {
	my $self = shift;
	
	my $file_object = {%$self};
	try_to_use ('IO::Easy::File');
	bless $file_object, 'IO::Easy::File';
}

sub as_dir {
	my $self = shift;
	
	my $file_object = {%$self};
	try_to_use ('IO::Easy::Dir');
	bless $file_object, 'IO::Easy::Dir';
}

sub append {
	my $self = shift;
	
	my $appended = File::Spec->join ($self->{path}, @_);
	return IO::Easy->new ($appended);
}

sub file_io {
	my $self = shift;
	
	my $appended = File::Spec->join ($self->{path}, @_);
	return IO::Easy::File->new ($appended);
}

sub dir_io {
	my $self = shift;
	
	my $appended = File::Spec->join ($self->{path}, @_);
	return IO::Easy::Dir->new ($appended);
}

sub append_in_place {
	my $self = shift;
	
	my $appended = File::Spec->join ($self->{path}, @_);
	$self->{path} = $appended;
	
	return $self;
}

sub path {
	my $self = shift;
	
	return $self->{path};
}

sub _compare { # for overload only
	my $self = shift;
	my $value = shift;
	return $self->{path} cmp $value;
}

# we need ability to create abstract file object without any 
# filesystem checks, but when call any method, assigned to 
# concrete class, we must create another object and call this method

sub touch {
	my $self = shift;

	if (! -e $self) {
		return $self->as_file->touch;
	}
	return $self->attach_interface->touch;
}

sub abs_path {
	my $self = shift;
	
	my $pack = ref $self;
	
	if ($FS->file_name_is_absolute ($self->{path})) {
		return $self;
	} else {
		return $pack->new ($FS->rel2abs ($self->{path}))
	}
	
}

sub rel_path {
	my $self = shift;
	my $relative_to = shift;
	
	my $path = $self->{path};
	$path = $self->abs_path
		if $FS->file_name_is_absolute ($relative_to);
	
	return $FS->abs2rel ($path, $relative_to);
}

sub path_components {
	my $self = shift;
	my $relative = shift;
	
	my $path = $self->{path};
	
	if ($relative) {
		$path = $FS->abs2rel ($path, $relative);
	}
	
	return $FS->splitdir ($path);
	
}

sub stat {
	my $self  = shift;
	
	my $stat = [stat $self->{path}];
	
	return $stat
		unless @_;
	
	my $result = [];
	
	foreach my $stat_opt (@_) {
		if ($stat_opt =~ /^(\d+)$/) {
			push @$result, $stat->[$1];
		} elsif (exists $stat_methods_hash->{$stat_opt}) {
			push @$result, $stat->[$stat_methods_hash->{$stat_opt}];
		} else {
			die "unknown stat field: $stat_opt";
		}
	}
	
	return @$result;
}

# TODO: rename to last_modified, add sub modified_since?
sub modified {
	my $self = shift;
	
	my $stat = $self->stat;
	return $stat->[9];
}

sub parent {
	my $self = shift;
	
	return $self->up (@_);
}

sub up {
	my $self = shift;
	
	my @chunks = $FS->splitdir ($self->path);
	pop @chunks;
	
	my $updir = $FS->catdir (@chunks);
	
	try_to_use ('IO::Easy::Dir');
	
	$updir = IO::Easy::Dir->current
		if $updir eq '';
	
	return IO::Easy::Dir->new ($updir);
}


1;

=head1 NAME

IO::Easy - is easy to use class for operations with filesystem objects.

=head1 ABSTRACT

We wanted to provide Perl with the interface for file system objects
with the simplicity similar to shell. The following operations can be
used as an example: operations for recursive creation (mkdir -p) and
removing (rm -rf), touching file.

IO::Easy transparently handles OS path delimiters (e.g., Win* or *nix) using
File::Spec module and does not require a lot of additional modules from CPAN.

For better understanding of IO::Easy processing principles you should
keep in mind that it operates with "Path Context". "Path Context" means
that for any path in any file system IO::Easy takes path parts which are
between path separators, but doesn't include path separators themselves,
and tries to build the path in the current system using these path parts.
This way it can substitute different path separators from system to system
(as long as they may differ depending on operating system, this also
includes drive specification e.g. for Windows) and doesn't depend on
some system specifics of paths representation.

=head1 SYNOPSIS

	use IO::Easy;
	
	# abstract filesystem i/o interface
	my $io = IO::Easy->new ('.');
	
	# directory interface
	my $dir = $io->as_dir;
	
	# or easy
	$dir = dir->current;
	$dir = dir->new ('.');
	
	# or even easier
	$dir = dir ('.');

	# file object "./example.txt" for unix
	my $file = $io->append ('example.txt')->as_file;
	
	# or
	$file = $io->file_io ('example.txt');

	my $content = "Some text goes here!";
	
	# Overwrite file contents with $content
	$file->store ($content); 
	
or
	
	# easier scripts: you can replace IO::Easy::Dir for dir and so on
	use IO::Easy qw(script);
	
	my $abs_path = dir->current->abs_path; # IO::Easy::Dir->current->abs_path;

	my $test_file = file->new ('test');

	$test_file->touch;

	print "ok"
		if -f $test_file and $test_file->size eq 0;
	
=head1 METHODS

=head2 new

Creates new IO::Easy object, takes path as parameter. IO::Easy object
for abstract file system path. For operating with typed objects there
were 2 additional modules created:
	IO::Easy::File
	IO::Easy::Dir

You can use method attach_interface for automatic object conversion
for existing filesystem object or force type by using methods
as_file or as_dir.

	Init file object:

	my $io = IO::Easy->new ('/');

	my $file = $io->append(qw(home user my_stuff.bak file.txt));

In examples we will use this object to show results of method call.

=cut

=head2 filesystem object path manipulation

=head3 path

return current filesystem object path, also available as overload of "" # ???

	# example :
	$file->path	# /home/user/my_stuff/file.txt

=cut

=head3 name

return current filesystem object name, without path (filename in most of cases)

	# example :
	$file->name	# file.txt

=cut

=head3 base_name, extension

name part before last dot and after last dot

	# example :
	$file->base_name	# file
	$file->extension	# txt

=cut

=head2 as_file, as_dir

rebless object with specified type (currently 'dir' or 'file')

=cut

=head3 abs_path

absolute path

	# example :
	$file->abs_path	# /home/user/my_stuff.bak/file.txt

=cut

=head3 append, append_in_place

append filesystem objects to IO::Easy object

	my $config = IO::Easy::Dir->current->append (qw(etc config.json));

produce ./etc/config.json on unix

=cut

=head3 file_io, dir_io

append filesystem objects to IO::Easy subclass object

	my $config = IO::Easy::Dir->current->file_io (qw(etc config.json));

produce ./etc/config.json on unix, blessed into IO::Easy::File

=cut

=head3 up, parent

directory container for io object

	my $config = IO::Easy::Dir->current->append (qw(etc config.json)); # './etc/config.json'
	my $config_dir = $config->up; # './etc'

=cut

=head3 rel_path

relative path to specified directory
	
	my $current = IO::Easy::Dir->current; # '.'
	my $config = $current->append (qw(etc config.json)); # './etc/config.json'
	my $config_rel = $config->rel_path ($current); # 'etc/config.json'

=cut

=head3 path_components

path, split by filesystem separators

=cut

=cut

=head2 filesystem object manipulation

=head3 attach_interface

rebless object with autodetected filesystem object type

=cut

=head3 stat, modified, dev, inode, mode, nlink, uid, gid, rdev, size, atime, mtime, ctime, blksize, blocks

complete stat array or this array accessors

=cut

=head3 touch

constructor for IO::Easy::Dir object
	
	my $current = IO::Easy::Dir->current; # '.'
	my $config = $current->append (qw(etc config.json)); # './etc/config.json'
	$config->touch; # file created

=cut

=cut

=head1 AUTHOR

Ivan Baktsheev, C<< <apla at the-singlers.us> >>

=head1 BUGS

Please report any bugs or feature requests to my email address,
or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=IO-Easy>. 
I will be notified, and then you'll automatically be notified
of progress on your bug as I make changes.

=head1 SUPPORT



=head1 ACKNOWLEDGEMENTS



=head1 COPYRIGHT & LICENSE

Copyright 2007-2009 Ivan Baktsheev

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut
