package GitHub::EmptyRepository::Repository::Commit;
use Moo;

our $VERSION = '0.00002';

use MooX::StrictConstructor;
use Types::Standard qw( ArrayRef Bool Int InstanceOf Str );
use Pithub::Repos::Commits ();

has github_client => (
    is       => 'ro',
    isa      => InstanceOf ['Pithub::Repos::Commits'],
    required => 1,
);

has user => (
    is  => 'ro',
    isa => Str,
);

has repo => (
    is  => 'ro',
    isa => Str,
);

has sha => (
    is  => 'ro',
    isa => Str,
);

has files => (
    is      => 'ro',
    isa     => ArrayRef,
    lazy    => 1,
    builder => '_get_files',
);

sub _get_files {
    my $self = shift;

    my $result = $self->github_client->get(
        user => $self->user,
        repo => $self->repo,
        sha  => $self->sha,
    );

    return [] unless $result->response->is_success;

    my @committed_files = ();

    foreach my $file ( @{ $result->content->{files} } ) {
        push @committed_files, $file->{filename};
    }

    return \@committed_files;
}

1;

=pod

=encoding UTF-8

=head1 NAME

GitHub::EmptyRepository::Repository::Commit - Encapsulate select data about a GitHub commit

=head1 VERSION

version 0.00002

=head1 AUTHORS

=over 4

=item *

Thibault Duponchelle <thibault.duponchelle@gmail.com>

=item *

Olaf Alders <olaf@wundercounter.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Thibault Duponchelle.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: Encapsulate select data about a GitHub commit
