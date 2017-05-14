use utf8;
package Hg::Repository;
#ABSTRACT: This object represents a specific Mercurial repository.

use strict;
use warnings;
use 5.14.0;

use Moose;

use Carp;
use Hg::Revision;

has dir => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

has hg => (
    is      => 'ro',
    isa     => 'Str',
    default => sub {
        my $path_hg          = `which hg`;
        my $bin_hg           = '/bin/hg';
        my $usr_bin_hg       = '/usr/bin/hg';
        my $usr_local_bin_hg = '/usr/local/bin/hg';

        return $path_hg          if -x $path_hg;
        return $bin_hg           if -x $bin_hg;
        return $usr_bin_hg       if -x $usr_bin_hg;
        return $usr_local_bin_hg if -x $usr_local_bin_hg;
    },
);

sub BUILD {
	my ($self) = @_;

    croak "Can't find a working version of Mercurial at ".$self->hg
        unless -x $self->hg;

	my $command = $self->hg.' --version';
	my @version_output = `$command`;
	my $hg_version = $version_output[0];

	croak "Can't find a working version of Mercurial at ".$self->hg
		unless $hg_version =~ /Mercurial Distributed SCM \(version [\d\.]*\)/;

    croak "Can't find a Mercurial repository at ".$self->dir
        unless -d $self->dir;
}

sub _hg {
	my ($self,$command) = @_;

	my $full_command = $self->hg.' -R '.$self->dir.' '.$command;

	my @results = `$full_command`;

	return \@results;
}

sub clean {
    my ($self) = @_;

    my $results = $self->_hg('status');

    # Unless our status list is empty, the repo is dirty
    if(@$results) {
        return 0;
    }
    else {
        return 1;
    }
}

sub dirty {
    my ($self) = @_;

    return $self->clean ? 0 : 1;
}

sub changes {
    my ($self) = @_;

    croak "Not Implemented";
}

sub revisions {
	my ($self) = @_;

	my $results = $self->_hg('log --template "{node}\n"');

	my @revisions;

	for my $result( @$results ) {
		chomp $result;

		push
			@revisions,
			Hg::Revision->new(
				repository => $self,
				node       => $result);
	}

	return \@revisions;
}

sub revision {
	my ($self,$rev) = @_;

	my $result = $self->_hg('log --template "{node}\n" -r '.$rev)->[0];

	chomp $result;

	return Hg::Revision->new(
		repository => $self,
		node       => $result);
}

sub tip {
	my ($self) = @_;

    return $self->revision('tip');
}

sub current {
	my ($self) = @_;

	my $result = $self->_hg('summary')->[0];

	chomp $result;

    $result =~ s/parent: (\d*):.*/$1/;

	return $self->revision($result);
}

use namespace::autoclean;
__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Hg::Repository - This object represents a specific Mercurial repository.

=head1 VERSION

version 0.003

=head1 ATTRIBUTES

=head2 dir

The root directory of the repository.

=head2 hg

The full path to the hg binary.  If there is an hg binary in the current path
this will automatically be set to that.  If there isn't one, or you want to
use a different mercurial, please set this to the path.

=head1 METHODS

=head2 clean

Returns a boolean indicating whether or not the repository has uncommitted

changes.

=head2 dirty

Returns the opposite of clean

=head2 changes

Not implemented yet.

=head2 revisions

Returns an arrayref of all of the repository's revisions.

=head2 revision

Returns a specific revision, this method can take any valid mercurial revision
specifier.

=head2 tip

Returns the tip revision.

=head2 current

Returns the parent of the current state.

=head1 AUTHOR

Robert Ward <robert@rtward.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Robert Ward.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
