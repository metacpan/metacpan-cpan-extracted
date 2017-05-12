use strict;
use warnings;

package Footprintless::WebUrlResolverFactory;

use Template::Resolver;
use Log::Any;

my $logger = Log::Any->get_logger();

sub new {
    return bless( {}, shift )->_init(@_);
}

sub _init {
    my ($self) = @_;
    return $self;
}

sub new_resolver {
    my ( $self, $resolver_spec, @resolver_opts ) = @_;
    $logger->debugf( 'new_resolver: %s', \@_ );
    return new Template::Resolver(
        $resolver_spec,
        @resolver_opts,
        additional_transforms => {
            web_url => sub {
                my ( $resolver_self, $value ) = @_;

                my $url =
                    $resolver_self->_property("$value.https")
                    ? 'https://'
                    : 'http://';

                $url .= $resolver_self->_property("$value.hostname")
                    || croak("hostname required for web_url");

                my $port = $resolver_self->_property("$value.port");
                $url .= ":$port" if ($port);

                $url .= $resolver_self->_property("$value.context_path")
                    || '';

                return $url;
            }
        }
    );
}

1;
