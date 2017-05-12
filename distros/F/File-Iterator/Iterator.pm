package File::Iterator;

use 5.005;
use strict;
use Carp;
use vars qw($VERSION);

$VERSION = '0.14';

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = {
		DIR				=> '.',
		RECURSE			=> 1,
		FILTER			=> undef,
		RETURNDIRS		=> 0,
		FOLLOWSYMLINKS	=> 0,
		@_
	};
	
	$self->{FILES} = [];
	bless ($self, $class);
	
	# remove trailing slash unless user has supplied the root directory
	if ( ! _isRootDir( $self->{DIR} ) ) {
		if ( $^O eq "MSWin32" || $^O eq "os2") { # trailing slash can be either / or \
			$self->{DIR} =~ s|[\\/]$||;
		}
		elsif ( $^O eq "NetWare" ) { # uses \ as directory separator
			$self->{DIR} =~ s|\\$||;
		}
		else {
			$self->{DIR} =~ s|/$||;
		}
	}
	
	$self->_probeDir( $self->{DIR} );
	return $self;
}

sub _isRootDir {
	$_[0] =~ m{^(([a-z]:)?[\\/]|\\\\)$}i; # true if arg is /, \, X:\, X:/ or \\
}

sub _probeDir {
	my $self = shift;
	my $dir = shift;
	my $slash = _isRootDir($dir) ? "" : ( $^O eq "MSWin32" || $^O eq "NetWare" || $^O eq "os2" ) ? "\\" : "/";

	if (opendir DIR, $dir) {
		my @files = grep { !/^\.{1,2}$/ } readdir DIR; # ignore . and ..
		unshift @{$self->{FILES}}, map $dir.$slash.$_, sort { lc $a cmp lc $b } @files;
		closedir DIR;
	}
	else {
		carp "Can't open $dir: $!";
	}
}

sub next {
	my $self = shift;
	my $nextfile = shift @{$self->{FILES}} or return undef;
	if (-d $nextfile) {
		# if we are recursing and either the directory is not a symlink or we're following symlinks...
		if ( $self->{RECURSE} && (!-l $nextfile || $self->{FOLLOWSYMLINKS} ) ) { 
			$self->_probeDir($nextfile);
		}
		
		if (!$self->{RETURNDIRS}) {
			return $self->next();
		}
	}

	my $filter = $self->{FILTER};
	if ( $filter && !($filter->($nextfile)) ) {
		return $self->next();
	}
	else {
		return $nextfile;
	}
}

sub reset {
	my $self = shift;
	$self->{FILES} = [];
	$self->_probeDir( $self->{DIR} );
}

1;

__END__
=head1 NAME

File::Iterator - an object-oriented Perl module for iterating across
files in a directory tree.

=head1 SYNOPSIS

	use File::Iterator;

	$it = new File::Iterator(
		DIR     => '/etc',
		RECURSE => 0,
		FILTER  => sub { $_[0] =~ /\.cf$/ },
	);

	while ($file = $it->next()) {
		# do stuff with $file
	}

=head1 INTRODUCTION

File::Iterator wraps a simple iteration interface around the files in
a directory or directory tree. It builds a list of filenames, and
maintains a cursor that points to one filename in the list. The user
can work through the filenames sequentially by repeatedly doing stuff
with the next filename that the cursor points to until their are no
filenames left.

=head1 CONSTRUCTOR

=over 2

=item new( [ DIR => '$somedir' ] [, RECURSE => 0 ] [, FILTER => sub { ... } ] [, RETURNDIRS => 1] [, FOLLOWSYMLINKS => 1] )

The constructor for a File::Iterator object. The starting directory for
the iteration is specified as shown. If DIR is not specified, the
current directory is used.

By default, File::Iterator works recursively, and will therefore list
all files in the starting directory and all its subdirectories. To use
File::Iterator non-recursively, set the RECURSE option to 0. Note that
the module does not follow symbolic links to directories. To override
this behaviour, set the FOLLOWSYMLINKS option to 1. Be careful though,
as this can lead to endless iteration if a link points to a directory 
higher up its own directory tree.

Use the FILTER option to pass in a reference to a function to filter
the files. Such a function will be passed the filename (including
path) to filter and should return true if you are interested in that
file.

	sub config {
		my $filename = shift;
		return 1 if $filename =~ /\.(cf|conf)$/; # only look for config files
	}
	
	$it = new File::Iterator(
		DIR => "/etc",
		FILTER => \&config
	);
	
	# or simply...
	
	$it = new File::Iterator(
		DIR => "/etc",
		FILTER => sub { $_[0] =~ /\.(cf|conf)$/ }
	);

Don't try to use the FILTER option to exclude subdirectories. This
won't work:

	$it = new File::Iterator(
		DIR => "/etc",
		FILTER => sub { ! -d $_[0] }
	);

Set the RECURSE option to 0 instead.

By default, the module only returns filenames and not directory names
(although the module will still search subdirectories if the RECURSE
option is on). To return directory names as well as filenames, set
the RETURNDIRS option to 1.

=back

=head1 METHODS

=over 2

=item next()

Returns the name of the next file (including the path) then advances
the cursor, or returns undef if there are no more files to process.
Note that because next() advances the cursor, the following code will
produce erroneous results, because the two calls to next() return
different values:

	while ($it->next()) {
		push @textfiles, $it->next() if -T $it->next();
	}

What you wanted to write was:
	
	while ($file = $it->next()) {
		push @textfiles, $file if -T $file;
	}

=item reset()

Resets the iterator so that the next call to next() returns the first
file in the list.

=back

=head1 ACKNOWLEDGEMENTS

Marius Feraru provided valuable input in the module's early days.

Jamie O'Shaughnessy E<lt>jos@cpan.org E<gt> was responsible for the
reworking of the FILTER option in 0.07 and gave some good advice
about avoiding unnecessary recursion.

Paul Hoffman spotted that the test on $^O in versions pre-0.08 would 
recognise Darwin as a Windows OS. He probably saved my life. :-)

=head1 AUTHOR

Copyright 2002 Simon Whitaker E<lt>swhitaker@cpan.orgE<gt>

=cut
