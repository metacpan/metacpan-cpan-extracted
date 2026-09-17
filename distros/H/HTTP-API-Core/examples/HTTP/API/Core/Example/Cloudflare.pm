package HTTP::API::Core::Example::Cloudflare;

use strict;
use warnings;
use parent 'HTTP::API::Core';

sub new {
    my ($class, %args) = @_;
    my $token = delete $args{token};
    die "token is required\n" if !defined($token) || $token eq '';

    return $class->SUPER::new(
        base_url => 'https://api.cloudflare.com/client/v4',
        headers  => { Authorization => "Bearer $token" },
        %args,
    );
}

sub zones_pager {
    my ($self, %args) = @_;
    my $per_page = delete($args{per_page}) || 50;
    my $name = delete $args{name};
    my $status = delete $args{status};
    die "unknown zones option: $_\n" for sort keys %args;

    return $self->paginate(
        '/zones',
        mode            => 'page',
        items           => 'result',
        has_more        => sub {
            my ($data) = @_;
            my $info = $data->{result_info} || {};
            return ($info->{page} || 0) < ($info->{total_pages} || 0);
        },
        page_size       => $per_page,
        page_param      => 'page',
        page_size_param => 'per_page',
        query           => {
            name   => $name,
            status => $status,
        },
    );
}

1;
