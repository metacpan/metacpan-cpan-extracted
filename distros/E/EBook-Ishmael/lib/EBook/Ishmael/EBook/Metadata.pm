package EBook::Ishmael::EBook::Metadata;
use 5.016;
our $VERSION = '1.07';
use strict;
use warnings;

sub new {

	my $class = shift;
	my $data  = shift // {};

	for my $k (keys %{ $data }) {
		unless (ref $data->{ $k } eq 'ARRAY') {
			die "'$k' is not an array ref";
		}
	}

	my $self = {
		Author      => $data->{Author}      // [],
		Software    => $data->{Software}    // [],
		Created     => $data->{Created}     // [],
		Modified    => $data->{Modified}    // [],
		Format      => $data->{Format}      // [],
		Title       => $data->{Title}       // [],
		Language    => $data->{Language}    // [],
		Genre       => $data->{Genre}       // [],
		ID          => $data->{ID}          // [],
		Description => $data->{Description} // [],
		Contributor => $data->{Contributor} // [],
	};

	return bless $self, $class;

}

sub hash {

	my $self = shift;

	my $hash = { %{ $self } };

	for my $k (keys %{ $hash }) {
		unless (@{ $hash->{ $k } }) {
			delete $hash->{ $k };
		}
	}

	return $hash;

}

sub author {

	my $self = shift;
	my $set  = shift;

	unless (defined $set) {
		return $self->{Author};
	}

	unless (ref $set eq 'ARRAY') {
		die "Setter requires array ref as argument";
	}

	$self->{Author} = $set;

}

sub software {

	my $self = shift;
	my $set  = shift;

	unless (defined $set) {
		return $self->{Software};
	}

	unless (ref $set eq 'ARRAY') {
		die "Setter requires array ref as argument";
	}

	$self->{Software} = $set;

}

sub created {

	my $self = shift;
	my $set  = shift;

	unless (defined $set) {
		return $self->{Created};
	}

	unless (ref $set eq 'ARRAY') {
		die "Setter requires array ref as argument";
	}

	$self->{Created} = $set;

}

sub modified {

	my $self = shift;
	my $set  = shift;

	unless (defined $set) {
		return $self->{Modified};
	}

	unless (ref $set eq 'ARRAY') {
		die "Setter requires array ref as argument";
	}

	$self->{Modified} = $set;

}

sub format {

	my $self = shift;
	my $set  = shift;

	unless (defined $set) {
		return $self->{Format};
	}

	unless (ref $set eq 'ARRAY') {
		die "Setter requires array ref as argument";
	}

	$self->{Format} = $set;

}

sub title {

	my $self = shift;
	my $set  = shift;

	unless (defined $set) {
		return $self->{Title};
	}

	unless (ref $set eq 'ARRAY') {
		die "Setter requires array ref as argument";
	}

	$self->{Title} = $set;

}

sub language {

	my $self = shift;
	my $set  = shift;

	unless (defined $set) {
		return $self->{Language};
	}

	unless (ref $set eq 'ARRAY') {
		die "Setter requires array ref as argument";
	}

	$self->{Language} = $set;

}

sub genre {

	my $self = shift;
	my $set  = shift;

	unless (defined $set) {
		return $self->{Genre};
	}

	unless (ref $set eq 'ARRAY') {
		die "Setter requires array ref as argument";
	}

	$self->{Genre} = $set;

}

sub id {

	my $self = shift;
	my $set  = shift;

	unless (defined $set) {
		return $self->{ID};
	}

	unless (ref $set eq 'ARRAY') {
		die "Setter requires array ref as argument";
	}

	$self->{ID} = $set;

}

sub description {

	my $self = shift;
	my $set  = shift;

	unless (defined $set) {
		return $self->{Description};
	}

	unless (ref $set eq 'ARRAY') {
		die "Setter requires array ref as argument";
	}

	$self->{Description} = $set;

}

sub contributor {

	my $self = shift;
	my $set  = shift;

	unless (defined $set) {
		return $self->{Contributor};
	}

	unless (ref $set eq 'ARRAY') {
		die "Setter requires array ref as argument";
	}

	$self->{Contributor} = $set;

}

=head1 NAME

EBook::Ishmael::EBook::Metadata - Ebook metadata interface

=head1 SYNOPSIS

  use EBook::Ishmael::EBook::Metadata;

  my $meta = EBook::Ishmael::EBook::Metadata->new;

  $meta->title([ 'Moby-Dick' ]);
  $meta->author([ 'Herman Melville' ]);
  $meta->language([ 'en' ]);

=head1 DESCRIPTION

B<EBook::Ishmael::EBook::Metadata> is a module used by L<ishmael> to provide
a format-agnostic interface to ebook metadata. This is developer documentation,
for user documentation please consult the L<ishmael> manual.

=head1 METHODS

=head2 $m = EBook::Ishmael::EBook::Metadata->new([ $meta ])

Returns a blessed C<EBook::Ishmael::EBook::Metadata> object. Can optionally be
given a C<$meta> hash ref of metadata fields and their array ref of values.
The following are valid fields:

=over 4

=item Author

=item Software

=item Created

=item Modified

=item Format

=item Title

=item Language

=item Genre

=item ID

=item Description

=item Contributor

=back

=head2 $h = $m->hash

Returns a plain hash ref of the object's metadata.

=head2 Accessors

Each accessor method is both a setter and getter. When ran with no arguments,
returns the array ref currently in the field. When ran with an array ref as
argument, sets that field to the given array ref.

=head3 $a = $m->author([ $set ])

Set/get the author(s) of the ebook.

=head3 $s = $m->software([ $set ])

Set/get the software used to create the ebook.

=head3 $c = $m->created([ $set ])

Set/get the creation date(s) of the ebook.

=head3 $o = $m->modified([ $set ])

Set/get the modification date(s) of the ebook.

=head3 $f = $m->format([ $set ])

Set/get the format(s) of the ebook.

=head3 $t = $m->title([ $set ])

Set/get the title(s) of the ebook.

=head3 $l = $m->language([ $set ])

Set/get the language(s) of the ebook.

=head3 $g = $m->genre([ $set ])

Set/get the genre(s) of the ebook.

=head3 $i = $m->id([ $set ])

Set/get the identifier(s) of the ebook.

=head3 $d = $m->description([ $set ])

Set/get the text description(s) of the ebook.

=head3 $c = $m->contributor([ $set ])

Set/get the contributor(s) of the ebook.

=head1 AUTHOR

Written by Samuel Young, E<lt>samyoung12788@gmail.comE<gt>.

This project's source can be found on its
L<Codeberg Page|https://codeberg.org/1-1sam/ishmael>. Comments and pull
requests are welcome!

=head1 COPYRIGHT

Copyright (C) 2025 Samuel Young

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

=cut
