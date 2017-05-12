#!/usr/bin/perl

package Directory::Transactional::Stream;
BEGIN {
  $Directory::Transactional::Stream::VERSION = '0.09';
}
use Moose;

use Carp qw(croak);

use namespace::clean -except => 'meta';

with qw(Data::Stream::Bulk);

has manager => (
	isa => "Directory::Transactional",
	is  => "ro",
	required => 1,
);

has dir => (
	isa => "Str",
	is  => "ro",
    default => "",
);

has depth_first => (
	isa => "Bool",
	is  => "rw",
	default => 1,
);

has only_files => (
	isa => "Bool",
	is  => "ro",
);

has chunk_size => (
	isa => "Int",
	is  => "rw",
	default => 250,
);

has _stack => (
	isa => "ArrayRef",
	is  => "ro",
	default => sub { [] },
);

has _queue => (
	isa => "ArrayRef",
	is  => "ro",
	lazy => 1,
	default => sub { [ shift->dir ] },
);

sub is_done {
	my $self = shift;
	return (
		@{ $self->_stack } == 0
			and
		@{ $self->_queue } == 0
	);
}

sub next {
	my $self = shift;

	my $queue = $self->_queue;
	my $stack = $self->_stack;

	my $depth_first = $self->depth_first;
	my $only_files  = $self->only_files;
	my $chunk_size  = $self->chunk_size;

	my @ret;

	my $m = $self->manager;

	{
		outer: while ( @$stack ) {
			my $frame = $stack->[-1];

			my ( $parent, $children ) = @$frame;

			$children ||= ( $frame->[1] = [ $m->list($parent) ] );

			while ( defined(my $path = shift @$children) ) {
				if ( $m->is_dir($path) ) {
					if ( $depth_first ) {
						unshift @$queue, $path;
					} else {
						push @$queue, $path;
					}

					last outer;
				} else {
					push @ret, $path;
					return \@ret if @ret >= $chunk_size;
				}
			}

			# we're done reading this dir
			pop @$stack;
		}

		if ( @$queue ) {
			my $dir = shift @$queue;

			if ( $depth_first ) {
				push @$stack, [ $dir ],
			} else {
				unshift @$stack, [ $dir ],
			}

			unless ( $only_files ) {
				push @ret, $dir if length $dir;
				return \@ret if @ret >= $chunk_size;
			}

			redo;
		}
	}

	return unless @ret;
	return \@ret;
}


__PACKAGE__->meta->make_immutable;

__PACKAGE__

__END__

=pod

=head1 NAME

Directory::Transactional::Stream - Traverse files in L<Directory::Transactional>

=head1 VERSION

version 0.09

=head1 SYNOPSIS

	$dir->file_stream(
		depth_first => 1,
	);

=head1 DESCRIPTION

This stream produces depth or breadth first traversal order recursion through
a L<Directory::Transactional> object, providing a view of the head transaction.

=head1 ATTRIBUTES

=over 4

=item dir

The directory to list. Defaults to C<""> (the root directory).

=item chunk_size

Defaults to 250.

=item depth_first

Chooses between depth first and breadth first traversal order.

=item only_files

If true only L<Path::Class::File> items will be returned in the output streams
(no directories).

=back

=head1 METHODS

=over 4

=item is_done

Returns true when no more files are left to iterate.

=item next

Returns the next chunk of L<Path::Class> objects

=back

=cut