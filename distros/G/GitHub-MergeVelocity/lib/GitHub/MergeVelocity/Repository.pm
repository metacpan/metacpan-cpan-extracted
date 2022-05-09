package GitHub::MergeVelocity::Repository;

use Moo;

our $VERSION = '0.000009';

use GitHub::MergeVelocity::Repository::PullRequest ();
use GitHub::MergeVelocity::Repository::Statistics  ();
use MooX::StrictConstructor;
use Types::Standard qw( ArrayRef Bool InstanceOf Str );
use URI ();

has github_client => (
    is       => 'ro',
    isa      => InstanceOf ['Pithub::PullRequests'],
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
    isa      => InstanceOf ['GitHub::MergeVelocity::Repository::Statistics'],
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

    my $pulls = $self->_get_pull_requests;

    my $total = $pulls ? scalar @{$pulls} : 0;

    my %summary = ( total_velocity => 0 );

    foreach my $pr ( @{$pulls} ) {
        $summary{ $pr->state }++;
        $summary{ $pr->state . '_age' } += $pr->age;
        $summary{total_velocity} += $pr->velocity;
    }

    return GitHub::MergeVelocity::Repository::Statistics->new(%summary);
}

## no critic (ValuesAndExpressions::ProhibitAccessOfPrivateData)
sub _get_pull_requests {
    my $self = shift;

    my $result = $self->github_client->list(
        user   => $self->user,
        repo   => $self->name,
        params => { per_page => 100, state => 'all' },
    );

    $result->auto_pagination(1);

    my @pulls;

    while ( my $row = $result->next ) {

        # GunioRobot seems to create pull requests that clean up whitespace
        next if !$row->{user} || $row->{user}->{login} eq 'GunioRobot';

        my $pull_request
            = GitHub::MergeVelocity::Repository::PullRequest->new(
            created_at => $row->{created_at},
            $row->{closed_at} ? ( closed_at => $row->{closed_at} ) : (),
            $row->{merged_at} ? ( merged_at => $row->{merged_at} ) : (),
            number => $row->{number},
            title  => $row->{title},
            );

        push @pulls, $pull_request;
    }
    return \@pulls;
}
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

GitHub::MergeVelocity::Repository - Encapsulate pull request data for a repository

=head1 VERSION

version 0.000009

=head1 AUTHOR

Olaf Alders <olaf@wundercounter.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Olaf Alders.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: Encapsulate pull request data for a repository

