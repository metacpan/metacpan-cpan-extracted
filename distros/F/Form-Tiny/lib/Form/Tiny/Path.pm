package Form::Tiny::Path;

use v5.10;
use strict;
use warnings;
use Moo;
use Carp qw(croak);
use Types::Standard qw(ArrayRef);

use namespace::clean;

our $VERSION = '2.04';

our $nesting_separator = q{.};
our $array_marker = q{*};
our $escape_character = q{\\};

has "path" => (
	is => "ro",
	isa => ArrayRef,
	writer => "_set_path",
	coerce => 1,
	required => 1,
);

has "meta" => (
	is => "ro",
	isa => ArrayRef,
	writer => "_set_meta",
	lazy => 1,
	required => 1,
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
			if $self->meta->[0] eq 'ARRAY';
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

	my $escape = "\x00";
	$name =~ s/(\Q$escape_character\E{1,2})/length $1 == 2 ? $escape_character : $escape/ge;

	my $arr = quotemeta $array_marker;
	my $sep = quotemeta $nesting_separator;
	my @parts = split /(?<!$escape)$sep/, $name, -1;
	my @meta;

	for my $part (@parts) {
		if ($part eq $array_marker) {
			push @meta, 'ARRAY';
		}
		else {
			push @meta, 'HASH';
		}
	}
	@parts = map { s/$escape($sep|$arr)/$1/ge; $_ } @parts;

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

sub append
{
	my ($self, $meta, $key) = @_;
	$key = $array_marker
		if $meta eq 'ARRAY';

	push @{$self->path}, $key;
	push @{$self->meta}, $meta;
	return $self;
}

sub make_name_path
{
	my ($self, $prefix) = @_;

	my @real_path;
	my @path = @{$self->path};
	my @meta = @{$self->meta};

	$prefix //= $#path;
	for my $ind (0 .. $prefix) {
		my $part = $path[$ind];

		$part =~ s/\Q$escape_character\E/$escape_character$escape_character/g;
		$part =~ s/\Q$nesting_separator\E/$escape_character$nesting_separator/g;
		$part =~ s/\A\Q$array_marker\E\z/$escape_character$array_marker/g
			unless $meta[$ind] eq 'ARRAY';

		push @real_path, $part;
	}

	return @real_path;
}

sub join
{
	my ($self, $prefix) = @_;
	return join $nesting_separator, $self->make_name_path($prefix);
}

1;
