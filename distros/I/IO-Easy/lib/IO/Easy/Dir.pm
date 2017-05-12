package IO::Easy::Dir;

use Class::Easy;

use IO::Easy;
use base qw(IO::Easy);

use File::Spec;
my $FS = 'File::Spec';

use Cwd ();

sub current {
	my $pack = shift;
	return $pack->new (Cwd::cwd());
}

sub home {
	my $pack = shift;
	return $pack->new (
		$ENV{USERPROFILE} || $ENV{HOME} || (getpwuid($<)) [7]
	);
}

sub create {
	my $self = shift;
	my @path = @_;
	
	my $path = $self->{path};
	if (scalar @path) { # create @path into received directory
		$path = File::Spec->catdir ($path, @path);
	}
	
	my @dirs = File::Spec->splitdir ($path);
    
    foreach my $depth (0 .. scalar @dirs - 1) {
		my $dir = File::Spec->join(map {$dirs[$_]} 0..$depth);
		mkdir $dir
			unless -d $dir;
    }

}

sub type {
	return 'dir';
}

sub items {
	my $self   = shift;
	my $filter = shift || '';
	my $is_regexp = shift || 0;
	
	my $path = $self->{path};
	
	unless ($is_regexp) {
		$filter = join '', '\.', $filter, '$';
	}
	
	opendir (DH, $path) || die "can't open $path: $!";
	my @files = ();
	foreach my $file_name (readdir (DH)) {
		next if $file_name =~ /^\.+$/;
		
		next if $filter ne '\.$' and $file_name !~ /$filter/i;
		
		my $file = $self->append ($file_name);
		
		next unless -e $file;
		
		push @files, $file->attach_interface;
	}
	closedir (DH);
	
	return @files;
}

sub rm_tree {
	my $self = shift;
	
	my @files = $self->items;
	foreach my $file (@files) {
		my $path = $file->{path};
		unlink $path
			if -f $path;
		$file->rm_tree
			if -d $path;
	}
	
	rmdir $self->{path};
}

sub scan_tree {
	my $self    = shift;
	my $handler = shift;
	
	my $flag = '';
	
	if (@_) {
		($handler, $flag) = (shift, $handler);
	}
	
	my $path = $self->{path};
	
	opendir (DH, $path) || die "can't open $path: $!";
	
	my @files;
	
	foreach my $file_name (readdir (DH)) {
		next if $file_name eq $FS->curdir or $file_name eq $FS->updir; # omit . ..
		
		my $file = $self->append ($file_name)->attach_interface;
		
		my $return = 1;
		$return = &$handler ($file)
			if ($flag eq 'for_files_only' && -f $file) || $flag ne 'for_files_only';
		
		push @files, $file
			if $return || $flag eq 'ignoring_return';
		
	}
	closedir (DH);
	
	foreach my $file (@files) {
		if ($file->type eq 'dir') {
			$file->scan_tree ($handler);
		} elsif ($file->type eq 'file') {
			
		}
	}
}

sub copy_children {
	my $self = shift;
	my $target = shift;
	my $handler = shift;
	
	$self->scan_tree (sub {
		my $file = shift;
		
		my $path = $file->rel_path ($self->{path});
		
		if (ref $handler eq 'CODE') {
			next unless &$handler ($file);
		}
		
		if ($file->type eq 'dir') {
			$target->create ($path);
			return 1;
		}
		
		$target->append ($path)->as_file->store (
			$file->contents
		);
	});
}

sub copy_node {
	my $self = shift;
	my $target = shift;
	
	$target->create ($self->name);
	
	$self->scan_tree (sub {
		my $file = shift;
		
		my $path = $file->rel_path ($self->up);
		
		if ($file->type eq 'dir') {
			$target->create ($path);
			return 1;
		}
		
		$target->append ($path)->as_file->store (
			$file->contents
		);
	});
}

sub touch {
	my $self = shift;
	
	if(-e $self->{path})
	{
		if(-d _)
		{
			my $t = time;
			
			die "can't utime $self->{path}: $!"
				unless utime $t, $t, $self->{path};
		}
		else
		{
			warn "not a dir: $self->{path}\n";
		}
	}
	else
	{
		die "can't create $self->{path}: $!"
			unless mkdir $self->{path};
	}

	return 1;
}


1;

=head1 NAME

IO::Easy::Dir - IO::Easy child class for operations with directories.

=head1 SYNOPSIS

	use IO::Easy;

	my $dir = IO::Easy->new ('.')->as_dir;

	$dir->scan_tree (sub {
		my $file = shift;

		return 0 if $file->type eq 'dir' and $file->name eq 'CVS';
	});

	$dir->create (qw(t IO-Easy)); # creates ./t/IO-Easy

	my $source = $dir->append('data')->as_dir;
	my $destination = $dir->append('backup')->as_dir;
	$source->copy_children($destination, $handler);


=head1 METHODS

=head2 scan_tree

Scans directory tree.

There's a standard module File::Find exists. But it's monstrous and is used 
because of historical reasons. For the same functionality IO::Easy has a 
method scan_tree and this method can replace File::Find in the most cases.

	my $io = IO::Easy->new ('.');
	my $dir = $io->as_dir;
	$dir->scan_tree ($handler);

$handler is a code ref which is called during scan for each found object
and retrieves the found object as a parameter.

Symlinks processing during directory scanning must be handled by user of this 
module himself at the moment.

As an example with help of $handler you can recursively scan directory and get 
the number of files with defined extension, in this case function will look like 
the following:

	my $counter = 0;
	my $handler = sub {
		my $file = shift;
		$counter++ if $file->extension eq 'pl';
	}							 

	$dir->scan_tree ($handler);

	print "The number of files/directories with 'pl' extension:", $counter;

BEWARE: If $handler returns 0 for the directory, then scan_tree doesn't scan its contents,
this can be useful in e.g. ignoring CVS or any other unwanted directories.

This method can be called with any of two optional flags:
'for_files_only' and 'ignoring_return'

For example:

	my $counter = 0;
	my $handler = sub {
		my $file = shift;
		$counter++ if $file->extension eq 'pl';
	}

	$dir->scan_tree (for_files_only => $handler);

	print "The number of files with 'pl' extension:", $counter;

Flag 'for_files_only' tell method to call handler only with objects
with file (-f) check

Flag 'ignoring_return' tell method to ignore return value from handler
and process any found directory

=cut

=head2 copy_children, copy_node

recursive copying of directory contents

	my $io = IO::Easy->new ('.');
	my $source = $io->append('data')->as_dir;
	my $destination = $io->append('backup')->as_dir;
	$source->copy_children($destination, $handler);

In this example $handler code ref, which is performed for every file during copying.
With help of the $handler you can easily control the spice which files will be copied.

	my $handler = sub {
		my $file = shift;
		return 1 if $file->extension eq 'txt';
		return 0;
	};

In this case $handler function copies only files with 'txt' extension to the new 
directory.

=cut

=head2 create

creates new directory

	my $io = IO::Easy->new ('.');
	my $dir = $io->append('data')->as_dir; 	# appends 'data' to $io and returns 
											#the new object; blesses into directory object.
	$dir->create;							# creates directory './data/'

or

	$io->as_dir->create ('data');

=cut

=head2 items

directory contents in array. you can provide filter for file extension, plain or regexp

	$dir->items ('txt'); # plain
	$dir->items ('txt|doc', 1); # regexp

=cut

=head2 rm_tree

recursive deletion directory contents

=cut

=head2 current

current directory constructor, using Cwd

=cut

=head2 home

user home directory

=cut

=head2 type

always 'dir'

=head2 touch

similar to unix touch command - updates file timestamp

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
