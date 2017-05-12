package Facebook::Graph::Cmdline::Role::HTTPAccessToken;
{
  $Facebook::Graph::Cmdline::Role::HTTPAccessToken::VERSION = '0.123490';
}

#ABSTRACT: Embeds an HTTP::Daemon to implement OAuth callback for Facebook Authorization of Commandline Facebook apps.

use v5.10;
use Any::Moose 'Role';

#all provided by Facebook::Graph
requires qw(
    access_token
    authorize
    fetch
    postback
    request_access_token
);

has +postback     => ( is => 'ro', required   => 1 );
has +access_token => ( is => 'rw', lazy_build => 1 );

use HTTP::Daemon 6.00;
use URI;

###
# provides code, token
# requires permissions
# can override prompt_message, success_message

has code => (
    is         => 'rw',
    lazy_build => 1,
);
#has token => (
#    is         => 'rw',
#    lazy_build => 1,
#);
has permissions => (
    is      => 'ro',
    default => sub { [] }
);

# fmt will be called with url as arg
has prompt_message_fmt => (
    is      => 'rw',
    default => "Please visit this url to authorize application:\n%s\n"
);
has success_message => (
    is      => 'rw',
    default => 'Success!'
);

sub _build_code
{
    my $self = shift;
    my $uri  = $self
        ->authorize
        ->extend_permissions( @{ $self->permissions } )
        ->uri_as_string;
    printf $self->prompt_message_fmt, $uri;

    use HTTP::Daemon;
    my $postback = URI->new( $self->postback );
    my $d        = HTTP::Daemon->new(
        LocalAddr => $postback->host,
        LocalPort => $postback->port,
    ) || die;

    my $code = '';
    until ($code)
    {
        my $c = $d->accept;
        my $r = $c->get_request;
        next unless $r;

        if (    $r->url->path eq $postback->path
            and $r->url->query_param('code') )
        {
            $code = $r->url->query_param('code');
            $c->send_response(
                HTTP::Response->new(
                    200, undef, undef, $self->success_message
                )
            );
        }
        else
        {
            $c->send_response('204');
        }
    }
    $code;
}

sub _build_access_token
{
    my $self = shift;
    return $self->request_access_token( $self->code )->token;
}

sub verify_access_token
{
    my $self = shift;
    return 0 unless $self->has_access_token();

    say "verifying token";    ## DEBUG
    #$self->access_token( $self->token );
    my $resp;
    eval { $resp = $self->fetch('me') };
    if ($@)
    {
        say "Bad access_token, deleting";    ## INFO
        $self->clear_access_token;
        return 0;
    }
    return 1;
}

1;

__END__
=pod

=head1 NAME

Facebook::Graph::Cmdline::Role::HTTPAccessToken - Embeds an HTTP::Daemon to implement OAuth callback for Facebook Authorization of Commandline Facebook apps.

=head1 VERSION

version 0.123490

=head1 AUTHOR

Andrew Grangaard <spazm@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Andrew Grangaard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

