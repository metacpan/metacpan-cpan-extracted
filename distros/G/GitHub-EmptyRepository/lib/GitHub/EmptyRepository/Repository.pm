package GitHub::EmptyRepository::Repository;

use Moo;

our $VERSION = '0.00002';

use GitHub::EmptyRepository::Repository::Commit ();
use MooX::StrictConstructor;
use Types::Standard qw( HashRef ArrayRef Bool InstanceOf Str );
use URI ();

has github_client => (
    is       => 'ro',
    isa      => InstanceOf ['Pithub'],
    required => 1,
);

has name => (
    is       => 'ro',
    isa      => Str,
    init_arg => undef,
    lazy     => 1,
    default  => sub {
        my $self = shift;
        my ( undef, $name ) = $self->_parse_github_url( $self->url );
        return $name;
    },
);

has report => (
    is       => 'ro',
    isa      => HashRef,
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_report',
);

has url => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has user => (
    is       => 'ro',
    isa      => Str,
    init_arg => undef,
    lazy     => 1,
    default  => sub {
        my $self = shift;
        my ($user) = $self->_parse_github_url( $self->url );
        return $user;
    },
);

sub _build_report {
    my $self = shift;

    my $commits      = $self->_get_commits;
    my $branches     = $self->_get_branches;
    my $pullrequests = $self->_get_pullrequests;

    my $total_commits      = $commits      ? scalar @{$commits}      : 0;
    my $total_branches     = $branches     ? scalar @{$branches}     : 0;
    my $total_pullrequests = $pullrequests ? scalar @{$pullrequests} : 0;

    my %summary = (
        nb_commits      => $total_commits,
        nb_branches     => $total_branches,
        nb_pullrequests => $total_pullrequests
    );
    $summary{files} = [];

    foreach my $commit ( @{$commits} ) {
        foreach my $file ( @{ $commit->files } ) {
            push @{ $summary{files} }, $file;
        }
    }

    return \%summary;
}

## no critic (ValuesAndExpressions::ProhibitAccessOfPrivateData)
sub _get_commits {
    my $self = shift;

    my $result = $self->github_client->repos->commits->list(
        user   => $self->user,
        repo   => $self->name,
        params => { per_page => 2, state => 'all' },
    );

    $result->auto_pagination(0);

    my @commits;

    return \@commits unless $result->response->is_success;

    while ( my $row = $result->next ) {
        my $commit = GitHub::EmptyRepository::Repository::Commit->new(
            github_client => $self->github_client->repos->commits,
            repo          => $self->name,
            user          => $self->user,
            sha           => $row->{sha}
        );

        push @commits, $commit;
    }
    return \@commits;
}

sub _get_branches {
    my $self = shift;

    my $result = $self->github_client->repos->branches(
        user   => $self->user,
        repo   => $self->name,
        params => { per_page => 2, state => 'all' },
    );

    $result->auto_pagination(0);

    my @branches;

    return \@branches unless $result->response->is_success;

    while ( my $row = $result->next ) {
        my $branch = $row->{name};
        push @branches, $branch;
    }
    return \@branches;
}

sub _get_pullrequests {
    my $self = shift;

    my $result = $self->github_client->pull_requests->list(
        user   => $self->user,
        repo   => $self->name,
        params => { per_page => 2, state => 'all' },
    );

    $result->auto_pagination(0);

    my @pullrequests;

    return \@pullrequests unless $result->response->is_success;

    while ( my $row = $result->next ) {
        my $pullrequest = $row->{number};
        push @pullrequests, $pullrequest;
    }
    return \@pullrequests;
}

#
## use critic

sub _parse_github_url {
    my $self = shift;
    my $uri  = URI->new(shift);

    my @parts = split m{/}, $uri->path;

    # paths may or may not have a leading slash (absolute vs relative)
    my $user = shift @parts || shift @parts;
    my $name = shift @parts;
    $name =~ s{\.git}{};

    return ( $user, $name );
}

1;

=pod

=encoding UTF-8

=head1 NAME

GitHub::EmptyRepository::Repository - Encapsulate repository data for a repository

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

# ABSTRACT: Encapsulate repository data for a repository

