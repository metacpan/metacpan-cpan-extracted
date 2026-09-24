package HTTP::API::Core::Example::GitLab;

use strict;
use warnings;

use HTTP::API::Core;
use HTTP::API::Core::Auth qw(api_key_auth);

sub new {
    my ($class, %args) = @_;
    my $token = delete $args{token};
    die "token is required\n" if !defined($token) || $token eq '';

    my $api = HTTP::API::Core->new(
        base_url => delete($args{base_url}) || 'https://gitlab.com/api/v4',
        hooks => { before_request => api_key_auth(name => 'PRIVATE-TOKEN', value => $token, in => 'header') },
        %args,
    );
    return bless { api => $api }, $class;
}

sub projects_pager {
    my ($self, %query) = @_;
    my $per_page = delete($query{per_page}) || 20;
    return $self->{api}->paginate(
        '/projects',
        mode => 'page',
        items => sub { return $_[0] },
        page_param => 'page',
        page_size_param => 'per_page',
        page_size => $per_page,
        query => \%query,
    );
}

1;
