package HTML::Feature::Fetcher;
use strict;
use warnings;
use LWP::UserAgent;
use HTTP::Request;
use base qw(HTML::Feature::Base);

__PACKAGE__->mk_accessors($_) for qw(fetcher);

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new(@_);
    $self->_setup;
    return $self;
}

sub _setup {
    my $self    = shift;
    my $c       = $self->context;
    my $fetcher = LWP::UserAgent->new;
    my $config  = $c->config;
    if ( $config->{user_agent} ) {
        $fetcher->user_agent( $config->{user_agent} );
    }
    if ( $config->{http_proxy} ) {
        $fetcher->proxy( ['http'], $config->{http_proxy} );
    }
    else {
        $fetcher->env_proxy;
    }
    if ( $config->{timeout} ) {
        $fetcher->timeout( $config->{timeout} );
    use Data::Dumper;
        print Dumper $fetcher;
    }
    $self->fetcher($fetcher);
}

sub request {
    my $self     = shift;
    my $url      = shift;
    my $request  = HTTP::Request->new( GET => $url );
    my $response = $self->fetcher->request($request);
    return $response;
}

1;
__END__

=head1 NAME

HTML::Feature::Fetcher - Fetch a HTML document. 

=head1 SYNOPSIS

  use HTML::Feature::Fetcher;

  my $fetcher       = HTML::Feature::Fetch->new;
  my $http_response = $fetcher->request($url);

=head1 DESCRIPTION

This is a wrapper LWP::UserAgent.

=head1 METHODS

=head2 new

=head2 request 

=head1 AUTHOR

Takeshi Miki E<lt>miki@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
