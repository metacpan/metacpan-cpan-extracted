package Magpie::Component::ContentCache;
# ABSTRACT: Internally added content cache component
$Magpie::Component::ContentCache::VERSION = '1.163200';
use Moose;
extends 'Magpie::Transformer';
use Magpie::Constants;

__PACKAGE__->register_events( qw(cache_content));

sub load_queue { return qw( cache_content ) }


sub cache_content {
    my $self = shift;
    my $ctxt = shift;
    return OK unless $self->resource->can('cache');
    return OK if $self->has_error;
    my $content = undef;
    my $uri = $self->request->uri->as_string;
    my $cache = $self->resource->cache;

    if ($self->resource->has_data) {
        $content = $self->resource->data;
    }
    else {
        $content = $self->response->body;
    }

    my $cached = $cache->get($uri) || {};
    $cached->{content} = $content;
    $cache->set($uri, $cached);
    return OK;
}

# SEEALSO: Magpie

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Magpie::Component::ContentCache - Internally added content cache component

=head1 VERSION

version 1.163200

=head1 AUTHORS

=over 4

=item *

Kip Hampton <kip.hampton@tamarou.com>

=item *

Chris Prather <chris.prather@tamarou.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Tamarou, LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
