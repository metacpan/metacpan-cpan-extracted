package LWP::UserAgent::Caching;

=head1 NAME

LWP::UserAgent::Caching - HTTP::Casing based UserAgent, finally done right

=cut

our $VERSION = '0.07';

use strict;
use warnings;

use parent 'LWP::UserAgent';
use HTTP::Caching;

=head1 SYNOPSIS

    use LWP::UserAgent::Caching;
    
    my $cache = CHI->new(
        driver              => 'File',
        root_dir            => '/tmp/LWP_UserAgent_Caching',
        file_extension      => '.cache',
        l1_cache            => {
            driver              => 'Memory',
            global              => 1,
            max_size            => 1024*1024
        },
    );
    
    my $ua = LWP::UserAgent::Caching->new(
        http_caching => {
            cache               => $cache,
            type                => 'private',
            request_directives  => (
                'max-age=86400',            # 24hrs
                'min-fresh=60',             # not over due within the next minute
            ),
        },
        # more LWP::UserAgent options
    );
    
    my $rqst = HTTP::Request->new( GET => 'http://example.com' );
    
    $rqst->header( cache_control => 'no-cache' ); # Oh... now we bypass it ?
    $rqst->header( accept_language => 'nl, en-GB; q=0.9, en; 0.8, *' ); 
    
    my $resp = $ua->request($rqst);


=head1 DESCRIPTION

C<LWP::UserAgent::Caching> gives you RFC compliant caching. It respects the old
HTTP/1 headerfields like 'Expires' but also implements the HTTP/1.1
'Cache-Control' directives.

Unlike many other cachng useragents, this one does actually invalidate the cache
after a non-error response returned by a non-safe request (like DELETE).

=head1 METHODS

Since it's a subclass of the standard LWP::UserAgent, it inherits all those. In
this module we also implemented the shortcuts from L<HTTP::Request::Common> so
that they will not call the parent class

=head1 SEE ALSO

L<HTTP::Caching> The RFC 7234 compliant brains
- DO NEVER USE THAT MODULE DIRECTLY

=cut

sub new {
    my ( $class, %params ) = @_;

    my $http_caching = delete $params{http_caching} || {};

    my $self = $class->SUPER::new(@_);

    $self->{http_caching} = HTTP::Caching->new(
        cache                   => $http_caching->{cache},
#       cache_meta              => $http_caching->{cache_meta} || $params{cache},
        cache_type              => $http_caching->{type} || 'private',
        cache_control_request   => $http_caching->{request_directives},
        forwarder               => sub { $self->SUPER::request(@_) }
    );

    return $self;
}

sub request {
    my $self = shift;
    my $rqst = shift->clone;
    $self->prepare_request($rqst);
    return $self->{http_caching}->make_request($rqst, @_);
}


#
# Now the shortcuts...
#
sub get {
    require HTTP::Request::Common;
    my($self, @parameters) = @_;
    my @suff = $self->_process_colonic_headers(\@parameters,1);
    return $self->request( HTTP::Request::Common::GET( @parameters ), @suff );
}

sub post {
    require HTTP::Request::Common;
    my($self, @parameters) = @_;
    my @suff = $self->_process_colonic_headers(\@parameters, (ref($parameters[1]) ? 2 : 1));
    return $self->request( HTTP::Request::Common::POST( @parameters ), @suff );
}

sub head {
    require HTTP::Request::Common;
    my($self, @parameters) = @_;
    my @suff = $self->_process_colonic_headers(\@parameters,1);
    return $self->request( HTTP::Request::Common::HEAD( @parameters ), @suff );
}

sub put {
    require HTTP::Request::Common;
    my($self, @parameters) = @_;
    my @suff = $self->_process_colonic_headers(\@parameters, (ref($parameters[1]) ? 2 : 1));
    return $self->request( HTTP::Request::Common::PUT( @parameters ), @suff );
}

sub delete {
    require HTTP::Request::Common;
    my($self, @parameters) = @_;
    my @suff = $self->_process_colonic_headers(\@parameters,1);
    return $self->request( HTTP::Request::Common::DELETE( @parameters ), @suff );
}


1;
