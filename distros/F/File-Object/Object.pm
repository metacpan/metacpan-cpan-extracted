package File::Object;

use strict;
use warnings;

use Class::Utils qw(set_params);
use Error::Pure qw(err);
use File::Spec::Functions qw(catdir catfile splitdir);
use FindBin qw($Bin $Script);

our $VERSION = 0.13;

# Constructor.
sub new {
	my ($class, @params) = @_;

	# Create object.
	my $self = bless {}, $class;

	# Directory path.
	$self->{'dir'} = [];

	# File path.
	$self->{'file'} = undef;

	# Type of path.
	$self->{'type'} = 'dir';

	# Process parameters.
	set_params($self, @params);

	# Check to right 'type'.
	if (! $self->{'type'} || ($self->{'type'} ne 'file'
		&& $self->{'type'} ne 'dir')) {

		err 'Bad \'type\' parameter.';
	}

	# Check to dir.
	if (ref $self->{'dir'} ne 'ARRAY') {
		err '\'dir\' parameter must be a reference to array.';
	}

	# Check to file.
	if ($self->{'type'} eq 'file' && @{$self->{'dir'}}
		&& ! defined $self->{'file'}) {

		err 'Bad file constructor with undefined \'file\' parameter.';
	}

	# Remove undef dirs.
	if (@{$self->{'dir'}}) {
		my @dir = map { defined $_ ? $_ : () } @{$self->{'dir'}};
		$self->{'dir'} = \@dir;
	}

	# Update path.
	$self->_update_path;

	# Set values.
	$self->set;

	# Object.
	return $self;
}

# Add dir.
sub dir {
	my ($self, @dirs) = @_;

	foreach my $dir (@dirs) {
		if (defined $dir) {
			$self->_dir($dir);
		}
	}

	# Object.
	return $self;
}

# Add file.
sub file {
	my ($self, @file_path) = @_;

	my $file = pop @file_path;
	$self->dir(@file_path);
	$self->_file($file);

	return $self;
}


# Get dir.
sub get_dir {
	my ($self, $dir_num) = @_;

	$dir_num ||= 1;
	if ($self->{'type'} eq 'file') {
		$dir_num++;
	}

	return $self->{'path'}->[-$dir_num];
}

# Get file.
sub get_file {
	my $self = shift;

	if ($self->{'type'} eq 'file') {
		return $self->{'path'}->[-1];
	} else {
		return;
	}
}

# Reset to constructor values.
sub reset {
	my $self = shift;

	# Reset to setted values.
	$self->{'dir'} = $self->{'_set'}->{'dir'};
	$self->{'file'} = $self->{'_set'}->{'file'};
	$self->{'type'} = $self->{'_set'}->{'type'};

	# Update path.
	$self->_update_path;

	return $self;
}

# Serialize path.
sub s {
	my $self = shift;

	if ($self->{'type'} eq 'dir') {
		return catdir(@{$self->{'path'}});
	} else {
		return catfile(@{$self->{'path'}});
	}
}

# Set actual values to constructor values.
sub set {
	my $self = shift;

	my @path = @{$self->{'path'}};
	$self->{'_set'}->{'type'} = $self->{'type'};
	if ($self->{'type'} eq 'file') {
		$self->{'_set'}->{'file'} = pop @path;
		$self->{'_set'}->{'dir'} = \@path;
	} else {
		$self->{'_set'}->{'dir'} = \@path;
	}

	return $self;
}

# Go to parent directory.
sub up {
	my ($self, $up_num) = @_;

	# Check number and positive number.
	if (! $up_num || $up_num !~ m/^\d$/ms) {
		$up_num = 1;
	}

	# Process.
	foreach (1 .. $up_num) {
		if ($self->{'type'} eq 'file') {
			if (@{$self->{'path'}} > 2) {
				$self->{'type'} = 'dir';
				$self->{'file'} = undef;
				splice @{$self->{'path'}}, -2;
			} else {
				err 'Cannot go up.', 'PATH', $self->s;
			}
		} else {
			if (@{$self->{'path'}}) {
				pop @{$self->{'path'}};
			} else {
				err 'Cannot go up.', 'PATH', $self->s;
			}
		}
	}

	# Object.
	return $self;
}

# Add dir array.
sub _dir {
	my ($self, @dir) = @_;

	if ($self->{'type'} eq 'file') {
		$self->{'type'} = 'dir';
		$self->{'file'} = undef;
		pop @{$self->{'path'}};
	}
	push @{$self->{'path'}}, @dir;

	return;
}

# Add file array.
sub _file {
	my ($self, $file) = @_;

	if (! defined $file) {
		return;
	}
	if ($self->{'type'} eq 'file') {
		pop @{$self->{'path'}};
		push @{$self->{'path'}}, $file;
	} else {
		push @{$self->{'path'}}, $file;
		$self->{'type'} = 'file';
	}

	return;
}

# Update path.
sub _update_path {
	my $self = shift;

	if ($self->{'type'} eq 'file') {
		$self->{'path'} = [
			@{$self->{'dir'}},
			defined $self->{'file'} ? $self->{'file'} : (),
		];
		if (! @{$self->{'path'}}) {
			$self->{'path'} = [splitdir($Bin), $Script];
		}
	} else {
		$self->{'path'} = [@{$self->{'dir'}}];
		if (! @{$self->{'path'}}) {
			$self->{'path'} = [splitdir($Bin)];
		}
	}

	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

File::Object - Object system for filesystem paths.

=head1 SYNOPSIS

 use File::Object;

 my $obj = File::Object->new(%parameters);
 my $self = $obj->dir(@dir);
 my $self = $obj->file(@file_path);
 my $dir = $obj->get_dir($dir_num);
 my $file = $obj->get_file;
 my $self = $obj->reset;
 my $path = $obj->s;
 my $self = $obj->set;
 my $self = $obj->up($num);

=head1 METHODS

=head2 C<new>

 my $obj = File::Object->new(%parameters);

Constructor.

Returns instance of object.

=over 8

=item * C<dir>

Directory path in reference to array.

Default value is [].

=item * C<file>

File path.

Default value is undef.

=item * C<type>

Type of path.
Types:

 - file
 - dir

Default value is 'dir'.

=back

=head2 C<dir>

 my $self = $obj->dir(@dir);

Add directory or directories to object.

Returns instance of object.

=head2 C<file>

 my $self = $obj->file(@file_path);

Add file or directory/directories with file to object.

Returns instance of object.

=head2 C<get_dir>

 my $dir = $obj->get_dir($dir_num);

Default value of C<$dir_num> is 1.

Returns C<$dir_num> level directory.

=head2 C<get_file>

 my $file = $obj->get_file;

Returns:

 - Filename if object is file path.
 - undef if object is directory path.

=head2 C<reset>

 my $self = $obj->reset;

Reset to constructor values.

Returns instance of object.

=head2 C<s>

 my $path = $obj->s;

Serialize path and return.

Returns string.

=head2 C<set>

 my $self = $obj->set;

Set actual values to constructor values.

Returns instance of object.

=head2 C<up>

 my $self = $obj->up($num);

Go to $up_num upper directory.

Returns instance of object.

=head1 ERRORS

 new():
         'dir' parameter must be a reference to array.
         Bad 'type' parameter.
         Bad file constructor with undefined 'file' parameter.
         From Class::Utils::set_params():
                 Unknown parameter '%s'.

 up():
         Cannot go up.
                 PATH -> path;

=head1 EXAMPLE1

 use strict;
 use warnings;

 use File::Object;

 # Print actual directory path.
 print File::Object->new->s."\n";

 # Output which runs from /usr/local/bin:
 # /usr/local/bin

=head1 EXAMPLE2

 use strict;
 use warnings;

 use File::Object;

 # Print parent directory path.
 print File::Object->new->up->s."\n";

 # Output which runs from /usr/local/bin:
 # /usr/local

=head1 EXAMPLE3

 use strict;
 use warnings;

 use File::Object;

 # Object with directory path.
 my $obj = File::Object->new(
         'dir' => ['path', 'to', 'subdir'],
 );

 # Relative path to file1.
 print $obj->file('file1')->s."\n";

 # Relative path to file2.
 print $obj->file('file2')->s."\n";

 # Output:
 # Unix:
 # path/to/subdir/file1
 # path/to/subdir/file2
 # Windows:
 # path\to\subdir\file1
 # path\to\subdir\file2

=head1 EXAMPLE4

 use strict;
 use warnings;

 use File::Object;

 # Object with directory path.
 my $obj = File::Object->new(
         'dir' => ['path', 'to', 'subdir'],
 );

 # Relative path to dir1.
 print $obj->dir('dir1')->s."\n";

 # Relative path to dir2.
 print $obj->reset->dir('dir2')->s."\n";

 # Output:
 # Unix:
 # path/to/subdir/dir1
 # path/to/subdir/dir2
 # Windows:
 # path\to\subdir\dir1
 # path\to\subdir\dir2

=head1 DEPENDENCIES

L<Class::Utils>,
L<Error::Pure>,
L<FindBin>,
L<File::Spec::Functions>.

=head1 SEE ALSO

=over

=item L<File::Spec>

portably perform operations on file names

=item L<Path::Class>

Cross-platform path specification manipulation

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/File-Object>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© Michal Josef Špaček 2009-2021

BSD 2-Clause License

=head1 VERSION

0.13

=cut
