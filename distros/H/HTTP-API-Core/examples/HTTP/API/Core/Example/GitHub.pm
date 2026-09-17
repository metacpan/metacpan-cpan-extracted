package HTTP::API::Core::Example::GitHub;

use strict;
use warnings;
use parent 'HTTP::API::Core';

sub new {
    my ($class, %args) = @_;
    my $token = delete $args{token};
    die "token is required\n" if !defined($token) || $token eq '';

    return $class->SUPER::new(
        base_url => 'https://api.github.com',
        headers  => {
            Accept                 => 'application/vnd.github+json',
            Authorization          => "Bearer $token",
            'X-GitHub-Api-Version' => '2026-03-10',
        },
        %args,
    );
}

sub repositories_pager {
    my ($self, %args) = @_;
    my $per_page = delete($args{per_page}) || 100;
    my $affiliation = delete $args{affiliation};
    my $sort = delete $args{sort};
    my $direction = delete $args{direction};
    die "unknown repositories option: $_\n" for sort keys %args;

    return $self->paginate(
        '/user/repos',
        mode            => 'page',
        items           => sub { return $_[0] },
        page_size       => $per_page,
        page_param      => 'page',
        page_size_param => 'per_page',
        query           => {
            affiliation => $affiliation,
            sort        => $sort,
            direction   => $direction,
        },
    );
}

1;
