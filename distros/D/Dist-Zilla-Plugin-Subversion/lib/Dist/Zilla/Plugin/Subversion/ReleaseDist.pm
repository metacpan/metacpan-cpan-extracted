use 5.010;
use strict;
use warnings;
use utf8;

package Dist::Zilla::Plugin::Subversion::ReleaseDist;

BEGIN {
    $Dist::Zilla::Plugin::Subversion::ReleaseDist::VERSION = '1.101590';
}

# ABSTRACT: releases a distribution's tarball to Subversion

use Moose;
with 'Dist::Zilla::Role::Subversion';
with 'Dist::Zilla::Role::Releaser' => { -version => 4.101550 };

use English qw(-no_match_vars);
use Modern::Perl;
use MooseX::Types::URI 'Uri';
use namespace::autoclean;

has 'dist_url' => (
    is         => 'ro',
    isa        => Uri,
    coerce     => 1,
    lazy_build => 1,
);

sub _build_dist_url {
    my $url = $ARG[0]->_base_url->clone();
    $url->path_segments( $url->path_segments(), 'dists' );
    return $url;
}

sub release {
    my ( $self, $archive ) = @ARG;

    my $dist_url = $self->dist_url->clone();
    $dist_url->path_segments( $dist_url->path_segments(),
        $archive->basename() );
    $self->log("Importing $archive to $dist_url");

    if ( my $commit_info = $self->_svn->import( "$archive", "$dist_url", 0 ) )
    {
        $self->_log_commit_info( $commit_info,
            "imported $archive as $dist_url revision" );
        return;
    }

    $self->log_fatal("Failed import of $archive as $dist_url");
    return;
}

__PACKAGE__->meta->make_immutable();
no Moose;
1;

=pod

=head1 NAME

Dist::Zilla::Plugin::Subversion::ReleaseDist - releases a distribution's tarball to Subversion

=head1 VERSION

version 1.101590

=head1 DESCRIPTION

This L<Dist::Zilla|Dist::Zilla> release plugin can be used to copy your
distribution's tarball to a directory in Subversion.
In addition to the attributes listed here, it can be configured with
attributes from
L<Dist::Zilla::Role::Subversion|Dist::Zilla::Role::Subversion>.

=head1 ATTRIBUTES

=head2 dist_url

URL for the directory receiving distribution tarballs.  Defaults to "dists"
within the base directory of the distribution, alongside "trunk", "branches"
and "tags".

=head1 METHODS

=head2 release

Implemented for
L<Dist::Zilla::Role::Releaser|Dist::Zilla::Role::Releaser> role.
Imports the distribution tarball to the Subversion repository.

=encoding utf8

=head1 AUTHOR

  Mark Gardner <mjgardner@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Mark Gardner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__
