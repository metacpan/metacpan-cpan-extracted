use utf8;
package Hg::Revision;
# ABSTRACT: An object representation of a single revision of a mercurial
# repository.

use strict;
use warnings;
use 5.14.0;

use Moose;
use Moose::Util::TypeConstraints;

use Carp;

has 'repository' => (
	is       => 'ro',
	isa      => 'Hg::Repository',
	required => 1,
);

subtype 'NodeHexString',
	as      'Str',
	where   { $_ =~ /[0-9a-f]{40}/i },
	message { 'Not a forty digit hexadecimal number' };

has 'node' => (
	is       => 'ro',
	isa      => 'NodeHexString',
	required => 1,
);

sub BUILD {
    my ($self) = @_;

    my $result = $self->_hg('log --template "{node}"');

    croak "Not a valid revision"
        unless $result->[0] eq $self->node;
}

sub _hg {
	my ($self,$command) = @_;

	my $full_command = $command.' -r '.$self->node;

	return $self->repository->_hg($full_command);
}

sub _get_attr {
	my ($self,$attr) = @_;

	my $result = $self->_hg('log --template "{'.$attr.'}\n"')->[0];

	chomp $result;

	return $result;
}

sub author {
    my ($self) = @_;

	return $self->_get_attr('author');
}

sub bookmarks {
    my ($self) = @_;
    croak "Not Implemented";
}

sub branch {
    my ($self) = @_;

	return $self->_get_attr('branch');
}

sub children {
    my ($self) = @_;
    croak "Not Implemented";
}

sub date {
    my ($self) = @_;

	return $self->_get_attr('date');
}

sub description {
    my ($self) = @_;

	return $self->_get_attr('desc');
}

sub diffstat {
    my ($self) = @_;
    croak "Not Implemented";
}

sub file_adds {
    my ($self) = @_;
    croak "Not Implemented";
}

sub file_copies {
    my ($self) = @_;
    croak "Not Implemented";
}

sub file_deletes {
    my ($self) = @_;
    croak "Not Implemented";
}

sub file_mods {
    my ($self) = @_;
    croak "Not Implemented";
}

sub files {
    my ($self) = @_;
    croak "Not Implemented";
}

sub latest_tag {
    my ($self) = @_;

	return $self->_get_attr('latesttag');
}

sub phase {
    my ($self) = @_;

	return $self->_get_attr('phase');
}

sub number {
    my ($self) = @_;

	return $self->_get_attr('rev');
}

sub tags {
    my ($self) = @_;

	return $self->_get_attr('tags');
}

use namespace::autoclean;
__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Hg::Revision - An object representation of a single revision of a mercurial

=head1 VERSION

version 0.003

=head1 ATTRIBUTES

=head2 repository

The repository this revision is from.

=head2 node

The 40 digit hex string that identifies this revision.

=head1 METHODS

=head2 author

Returns the author of this revision.

=head2 bookmarks

Not Implemented

=head2 branch

Returns this revisi

=head2 bookmarks

Not Implemented

=head2 date

Returns the revision's commit date

=head2 description

Returns the revision's description

=head2 diffstat

Not Implemented

=head2 file_adds

Not Implemented

=head2 file_copies

Not Implemented

=head2 file_deletes

Not Implemented

=head2 file_mods

Not Implemented

=head2 files

Not Implemented

=head2 latest_tag

Returns the most recent tag relative to this revision.

=head2 phase

Returns the revision phase.

=head2 number

Returns the revision number.

=head2 tags

Returns the revision's tags.

=head1 AUTHOR

Robert Ward <robert@rtward.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Robert Ward.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
