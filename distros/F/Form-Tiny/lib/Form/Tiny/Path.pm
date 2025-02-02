package Form::Tiny::Path;
$Form::Tiny::Path::VERSION = '2.26';
use v5.10;
use strict;
use warnings;
use Moo;
use Carp qw(croak);
use Types::Standard qw(ArrayRef);

our $nesting_separator = q{.};
our $array_marker = q{*};
our $escape_character = q{\\};

has 'path' => (
	is => 'ro',
	isa => ArrayRef,
	writer => '_set_path',
	required => 1,
);

# Note: this clashes with 'meta' from Moo :/
# will stay as it is though as long as it works (overrides the other meta)
# properly, since can't know how much external code uses it
has 'meta' => (
	is => 'ro',
	isa => ArrayRef,
	writer => '_set_meta',
	required => 1,
);

# cache for meta array positions
has 'meta_arrays' => (
	is => 'ro',
	default => sub {
		return [
			map {
				$_ eq 'ARRAY'
			} @{$_[0]->meta}
		];
	},
	init_arg => undef,
);

sub BUILD
{
	my ($self) = @_;

	my @parts = @{$self->path};

	# we allow empty paths here due to ->empty and ->clone methods
	# we disallow them in ->from_name instead
	if (scalar @parts) {
		croak 'path specified contained an empty part: ' . $self->dump
			if scalar grep { length $_ eq 0 } @parts;

		croak 'path specified started with an array: ' . $self->dump
			if $self->meta_arrays->[0];
	}
}

sub dump
{
	my ($self) = @_;
	my @parts = @{$self->path};
	my @meta = @{$self->meta};

	return join ' -> ',
		map { "`$parts[$_]` ($meta[$_])" }
		0 .. $#parts;
}

sub from_name
{
	my ($self, $name) = @_;

	croak 'path specified was empty'
		unless length $name;

	# use custom escape character for path building
	# (won't be mistaken for literal backslash)
	my $escape = "\x00";
	$name =~ s/(\Q$escape_character\E{1,2})/length $1 == 2 ? $escape_character : $escape/ge;

	my @parts = split /(?<!$escape)\Q$nesting_separator\E/, $name, -1;
	my @meta;

	for my $part (@parts) {
		if ($part eq $array_marker) {
			push @meta, 'ARRAY';
		}
		else {
			push @meta, 'HASH';
		}
	}

	@parts = map {
		s{ $escape ( \Q$nesting_separator\E | \Q$array_marker\E ) }{$1}gx;
		$_
	} @parts;

	return $self->new(path => \@parts, meta => \@meta);
}

sub empty
{
	my ($self) = @_;
	return $self->new(path => [], meta => []);
}

sub clone
{
	my ($self) = @_;
	return $self->new(path => [@{$self->path}], meta => [@{$self->meta}]);
}

sub prepend
{
	my ($self, $meta, $key) = @_;
	$key //= $array_marker
		if $meta eq 'ARRAY';

	unshift @{$self->path}, $key;
	unshift @{$self->meta}, $meta;
	return $self;
}

sub append
{
	my ($self, $meta, $key) = @_;
	$key //= $array_marker
		if $meta eq 'ARRAY';

	push @{$self->path}, $key;
	push @{$self->meta}, $meta;
	return $self;
}

sub append_path
{
	my ($self, $other_path) = @_;

	push @{$self->path}, @{$other_path->path};
	push @{$self->meta}, @{$other_path->meta};
	return $self;
}

sub make_name_path
{
	my ($self, $prefix) = @_;

	my @real_path = @{$self->path};
	my $meta = $self->meta;

	@real_path = @real_path[0 .. $prefix]
		if defined $prefix;

	for my $ind (0 .. $#real_path) {
		if ($meta->[$ind] ne 'ARRAY') {
			$real_path[$ind] =~ s{
				(\Q$escape_character\E | \Q$nesting_separator\E | \A\Q$array_marker\E\z)
			}{$escape_character$1}gx;
		}
	}

	return @real_path;
}

sub join
{
	my ($self, $prefix) = @_;
	return join $nesting_separator, $self->make_name_path($prefix);
}

sub follow
{
	my ($self, $structure) = @_;

	return undef if !ref $structure;

	my @found = ($structure);
	my @path = @{$self->path};
	my $meta = $self->meta_arrays;
	my $has_array = 0;

	for my $ind (0 .. $#path) {
		my $is_array = $meta->[$ind];
		my @new_found;

		for my $item (@found) {
			if ($is_array && ref $item eq 'ARRAY') {
				push @new_found, @{$item};
			}
			elsif (ref $item eq 'HASH' && exists $item->{$path[$ind]}) {
				push @new_found, $item->{$path[$ind]};
			}
		}

		@found = @new_found;
		$has_array ||= $is_array;
	}

	return $has_array
		? \@found
		: $found[0];
}

1;

