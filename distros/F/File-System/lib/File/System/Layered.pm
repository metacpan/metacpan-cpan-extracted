package File::System::Layered;

use strict;
use warnings;

use base 'File::System::Object';

use Carp;
use File::System;

our $VERSION = '1.16';

=head1 NAME

File::System::Layered - A file system implementation with "layered" roots

=head1 SYNOPSIS

  use File::System;

  my $root = File::System->new('Layered',
      [ 'Real', root => '/usr/local' ],
      [ 'Real', root => '/usr' ],
      [ 'Real', root => '/cw/usr/local' ],
      [ 'Real', root => '/sw/usr/local' ],
  );

  my $dir = $root->lookup('/bin');
  print "All files:\n";
  print map({ " - $_\n" } $root->children_paths);

=head1 DESCRIPTION

This file system allows for the layering of other file systems. A layerd file system contains one or more other file systems such that the list of files available at a certain path in the tree is the union of the files available in all the contained file systems. When reading from or writing to file content, the file system with the highest priority is given preference.

The priority of the file systems is determined during construction, and may be modified later.

=head2 LAYERED API

The constructor of this module provides the initial layer prioritization. The C<File::System::Layered> package also provides methods for altering the layers after the file system has been established.

=over

=item $root = File::System-E<gt>new('Layered', @file_systems)

The constructor establishes the initial layout of the file system. Each element of C<@file_systems> is either a file system object or is a reference to an array that may be passed to C<File::System::new> to construct a file system object.

The layers are prioritized by the order given in C<@file_systems>. The file systems listed first are given the higher priority.

=cut

sub new {
	my $class = shift;

	@_
		or croak "No file systems given.";

	my $self = bless { }, $class;

	$self->set_layers(@_);

	$self->{here} = $self->{layers}[0];

	return $self;
}

=item @layers = $obj-E<gt>get_layers

Returns the list of the file system layers in descending order of priority. By using this method to get the list of layers, they can be reordered, removed, added to and then passed back to C<set_layers> to alter the file system.

=cut

sub get_layers {
	my $self = shift;

	return @{ $self->{layers} };
}

=item $obj-E<gt>set_layers(@layers)

Reset the layers of the file system in descending order of priority. This effectively reinitializes the file system. The semantics are the same as that of the constructor.

=cut

sub set_layers {
	my $self = shift;

	@_
		or croak "No file systems given.";

	my @layers;
	for my $fs (@_) {
		
		my $init_fs;
		if (UNIVERSAL::isa($fs, 'File::System::Object')) {
			$init_fs = $fs;
		} elsif (ref $fs eq 'ARRAY') {
			$init_fs = File::System->new(@$fs);
		} else {
			croak "File system must be an array reference or an actual File::System::Object. '$fs' is neither of these. See the documentation of File::System::Layer for details.";
		}

		push @layers, $init_fs;
	}

	$self->{layers} = \@layers;

	return @layers;
}

sub root {
	my $self = shift;

	return bless {
		here   => $self->{layers}[0],
		layers => $self->{layers},
	}, ref $self;
}

sub exists {
	my $self = shift;
	my $path = shift || $self->path;

	for my $layer (@{ $self->{layers} }) {
		my $res = $layer->exists($path);
		return $res if $res;
	}

	return '';
}

sub lookup {
	my $self = shift;
	my $path = $self->normalize_path(shift);

	for my $layer (@{ $self->{layers} }) {
		my $res = $layer->lookup($path);
		return bless {
			here   => $res,
			layers => $self->{layers},
		}, ref $self if defined $res;
	}

	return undef;
}

sub glob {
	my $self = shift;
	my $glob = $self->normalize_path(shift);

	my %results;
	for my $layer (reverse @{ $self->{layers} }) {
		my @matches = $layer->glob($glob);
		for my $match (@matches) {
			$results{$match->path} = $match;
		}
	}

	return 
		map { bless { here => $_, layers => $self->{layers} }, ref $self } 
		sort values %results;
}

sub find {
	my $self = shift;
	my $want = shift;

	if (@_) {
		@_ = map { $self->normalize_path("$_") } @_;
	} else {
		@_ = ("$self");
	}

	my %results;
	for my $layer (reverse @{ $self->{layers} }) {
		my @matches = $layer->find($want, @_);

		for my $match (@matches) {
			$results{$match->path} = $match;
		}
	}

	return
		map { bless { here => $_, layers => $self->{layers} }, ref $self }
		sort values %results;
}

sub is_creatable {
	my $self = shift;
	my $path = shift;
	my $type = shift;

	for my $layer (@{ $self->{layers} }) {
		my $res = $layer->is_creatable($path, $type);
		return $res if $res;
	}

	return '';
}

sub create {
	my $self = shift;
	my $path = shift;
	my $type = shift;

	defined $path
		or croak "No path argument given.";

	defined $type
		or croak "No type argument given.";

	for my $layer (@{ $self->{layers} }) {
		if ($layer->is_creatable($path, $type)) {
			my $obj = $layer->create($path, $type);
			if (defined $obj)  {
				return bless {
					here   => $obj,
					layers => $self->{layers},
				}, ref $self;
			} else {
				return undef;
			}
		}
	}

	return undef;
}

sub is_valid {
	my $self = shift;

	for my $layer (@{ $self->{layers} }) {
		my $obj = $layer->lookup($self->{here}->path);
		next unless defined $obj;
		my $res = $obj->is_valid;
		return $res if $res;
	}

	return '';
}

sub properties {
	my $self = shift;

	my %result;
	for my $layer (reverse @{ $self->{layers} }) {
		my @props = $layer->properties;
		for my $prop (@props) {
			$result{$prop}++;
		}
	}

	return sort keys %result;
}

sub settable_properties {
	my $self = shift;

	my %result;
	for my $layer (reverse @{ $self->{layers} }) {
		my @props = $layer->settable_properties;
		for my $prop (@props) {
			$result{$prop}++;
		}
	}

	return sort keys %result;
}

sub get_property {
	my $self = shift;
	return $self->{here}->get_property(@_);
}

sub set_property {
	my $self = shift;
	$self->{here}->set_property(@_);
}

sub rename {
	my $self = shift;
	$self->{here}->rename(@_);
}

sub move {
	my $self = shift;
	my $to   = shift;
	
	my $layer_to;
	if (!$self->{here}->exists($to->path)) {
		if ($self->{here}->is_creatable($to->path, 'd')) {
			$layer_to = $self->{here}->create($to->path, 'd');
		} elsif ($self->{here}->is_creatable($to->path, 'df')) {
			$layer_to = $self->{here}->create($to->path, 'df');
		} else {
			croak "Move failed; no path '$to' exists in the same layer as $self.";
		}
	} else {
		$layer_to = $self->{here}->lookup($to->path);
	}

	$self->{here}->move($layer_to, @_);

	return $self;
}

sub copy {
	my $self = shift;
	my $to   = shift;

	my $layer_to;
	if (!$self->{here}->exists($to->path)) {
		if ($self->{here}->is_creatable($to->path, 'd')) {
			$layer_to = $self->{here}->create($to->path, 'd');
		} elsif ($self->{here}->is_creatable($to->path, 'df')) {
			$layer_to = $self->{here}->create($to->path, 'df');
		} else {
			croak "Copy failed; no path '$to' exists in the same layer as $self.";
		}
	} else {
		$layer_to = $self->{here}->lookup($to->path);
	}

	return bless {
		here   => $self->{here}->copy($layer_to, @_),
		layers => $self->{layers},
	}, ref $self;
}

sub remove {
	my $self = shift;
	$self->{here}->remove(@_);
}

my @delegates = qw/
	is_readable
	is_seekable
	is_writable
	is_appendable
	open
	content
/;

for my $name (@delegates) {
	eval q(
sub ).$name.q( {
	my $self = shift;
	return $self->{here}->).$name.q((@_);
}
);

	die $@ if $@;
}

sub has_children {
	my $self = shift;

    my $path = $self->path;
    my @layers
        = grep    { defined }
          map     { $_->lookup($path) }
          reverse @{ $self->{layers} };

	for my $layer (@layers) {
		my $res = $layer->has_children;
		return $res if $res;
	}

	return '';
}

sub children_paths {
	my $self = shift;

    my $path = $self->path;

	my %results;
    my @layers
        = grep    { defined }
          map     { $_->lookup($path) }
          reverse @{ $self->{layers} };

	for my $layer (@layers) {
		my @paths = $layer->children_paths;
		for my $path (@paths) {
			$results{$path}++;
		}
	}

	return sort keys %results;
}

sub children {
	my $self = shift;

    my $path = $self->path;

	my %results;
    my @layers
        = grep    { defined }
          map     { $_->lookup($path) }
          reverse @{ $self->{layers} };

	for my $layer (@layers) {
		my @children = $layer->children;
		for my $child (@children) {
			$results{$child->path} = $child;
		}
	}

	return map { bless { here => $_, layers => $self->{layers} }, ref $self }
		sort values %results;
}

sub child {
	my $self = shift;
    my $path = $self->normalize_path(shift);

	my $child;
	for my $layer (@{ $self->{layers} }) {
		$child = $layer->lookup($path);
		last if defined $child;
	}

	if (defined $child) {
		return bless {
			here   => $child, 
			layers => $self->{layers},
		}, ref $self;
	} else {
		return undef;
	}
}

=back

=head1 BUGS

This list includes things that aren't always bugs, but eccentricities of the implementation forced by the the nature of the service provided. This provides an explanation for anything that might not be obvious. I've tried to make the implementations work in a simple and natural way, but a few decisions were arbitrary.

The C<copy>, C<move>, and C<rename> methods are stuck within the file system they are in. That is, if you move, rename, or copy a file, the new file, location, or duplicate will be stored within the same layer as the original. If you attempt to move or copy to a location that exists in one layer, but not another, those methods will attempt to use C<create> to create the needed directory in the other layer. Due to these kinds of complications, these methods haven't yet been fully tested.

Removing a file or directory might not have the expected effect. If there are two layers with the same file or directory, removal will just remove the version in the highest layer, so the file or directory will still appear to exist.

The C<is_creatable> method returns true if I<any> layer returns true. The C<create> method uses the C<is_creatable> of each layer to find out if the file can be created and will create the file on the first layer it finds where it is true.

The C<glob> and C<find> methods rely upon the slowish defaults. This situation could probably be improved with a little bit of effort.

=head1 SEE ALSO

L<File::System>, L<File::System::Object>, L<File::System::Real>, L<File::System::Table>

=head1 AUTHOR

Andrew Sterling Hanenkamp, E<lt>hanenkamp@users.sourceforge.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2005 Andrew Sterling Hanenkamp. All Rights Reserved.

This library is distributed and licensed under the same terms as Perl itself.

=cut

1
