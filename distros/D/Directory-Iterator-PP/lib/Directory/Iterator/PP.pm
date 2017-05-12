package Directory::Iterator::PP;

use strict;
use Carp;
use File::Spec;

our $VERSION = '1.001004';

sub new {
    my $class = shift;
    my $dir = shift;

    my $sep = File::Spec->join('x','x');
    $dir =~ s:$sep$::;

    $sep =~ y/x//d;
    my %self = (file=>undef, dir=>$dir, dirs=>[], ds=>$sep, recurse=>1);
    opendir($self{dh},$dir) or croak "$dir: $!";
    bless \%self, $class;
}

sub show_dotfiles {
    my $self = shift;
    my $arg = shift;
    $self->{show_dotfiles} = $arg? 1 : 0;
}

sub show_directories {
    my $self = shift;
    my $arg = shift;
    $self->{show_directories} = $arg? 1 : 0;
}

sub recursive {
	my $self = shift;
	my $arg = shift;
	$self->{recurse} = $arg;
}

sub get {
    my $self = shift;
    return $self->{file};
}

sub _scan {
    my $self = shift;
    while (my $de = readdir $self->{dh}) {
		if ($self->{show_dotfiles}) {
			next if ($de eq '.' or $de eq '..');
		} else {
			next if ( $de =~ m/^\./ );
		}
		my $path = File::Spec->join("$self->{dir}", $de);
		return undef unless lstat($path);
		if ( -d _ and ! -l _ ) {
			push @{$self->{dirs}}, $path 
			  if $self->{recurse};

			if ($self->{show_directories}) {
				$self->{is_dir} = 1;
				return $self->{file} = $path;
			}
		}
		elsif ( -f _ ) {
			$self->{is_dir} = undef;
			return $self->{file} = $path;
		}
	}
    return undef;
}

sub is_directory {
	return $_[0]{is_dir};
}

sub prune_directory {
	my $self = shift;
	pop @{$self->{dirs}};
}

sub next {
  my $self = shift;
  
  if ($self->{dh}) {
    my $rv = $self->_scan;
    if( defined $rv ) {
      return $rv;
    }
    else {
      $self->{dh} = undef;
    }
  }
  
  while ( @{ $self->{dirs} } ) {
    $self->{dir} = pop @{ $self->{dirs} };
    opendir( $self->{dh}, $self->{dir} ) or carp "$self->{dir}: $!";
    if ( $self->{dh} ) {
      my $rv = $self->_scan;
      return $rv if defined $rv; 
    }
  }
  return undef;
}

sub prune {
    my $self = shift;
    undef $self->{dh};
	
    # while ($self->{dirs}[-1] =~ m/$self->{dir}$self->{sep}/) {
	# 	pop @{ $self->{dirs} };
    # }
}

use overload '<>' => \&next, '""' => \&get;
1;

__END__

=head1 NAME

Directory::Iterator::PP - Recursive directory listing, pure-Perl backend.

=head1 SYNOPSIS

  use Directory::Iterator::PP

  my $list = Directory::Iterator::PP->new($directory);
  while ($list->next) {
    print $list->get, "\n";
  }

=head1 DESCRIPTION

The module creates a list-like generator to recursively list files in a
directory.  The directories are scanned as the list is consumed, so only the
one directory handle and a list of directories to scan are stored in memory.

=head2 METHODS

=over

=item B<new>(I<DIRECTORY>)

Create a new instance on the specified I<DIRECTORY>, which must be the name
of an existing directory.

=item B<next>

Advance to the next item.  Returns 1 if there is a next item, 0 otherwise.

=item B<get>

Get the current file (which must be set from a previous call to next).

=item B<prune>

Prune the current diretory, so no more files are read from it.  When
scanning the list of files, when you get a file from a directory that you
aren't interested in, calling I<prune> will close that directory, to prevent
spending time listing its contents.

As currently implemented, it's possible that some subdirectories could've
been queued before the first file was seen, so it's not guaranteed that a
single call to prune will always suffice. Its purpose is simply to be more
efficient than continuing to read files from an unwanted directory.

To skip over a subdirectory with a single call, use B<show_directories> and
B<prune_directory>.

=item B<show_dotfiles>(I<ARG>) 

If I<ARG> is true, hidden files & directories, those with names that begin
with a I<.> will be processed as regular files.  By default, such files are
skipped.

=item B<show_directories>(I<ARG>) 

If I<ARG> is true, directories will be returned from the list, in addition
to being queued to process their files.

=item B<is_directory>

Returns true if the most recently returned file entry is a directory; used
to enable quickly differentiating directories form plain files.

=item B<prune_directory>

Removes the most recently queued directory, and returns the name of the
removed directory.  This allows the module to quickly skip over
subdirectories entirely, without ever opening them.

=item B<recursive>(I<ARG>) 

if I<ARG> is false, just look in the top-level directory; don't queue
subdirectories for processing.

=back

=head1 AUTHOR

Steve Sanbeg

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Steve Sanbeg

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.


=cut

