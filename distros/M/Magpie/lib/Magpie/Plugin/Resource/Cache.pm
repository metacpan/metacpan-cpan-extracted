package Magpie::Plugin::Resource::Cache;
$Magpie::Plugin::Resource::Cache::VERSION = '1.163200';
use Moose::Role;

# ABSTRACT: A Role to add Caching to a Resource;
#
use Magpie::Constants;

requires qw(mtime);

has cache => (
    is          => 'ro',
    lazy_build  => 1,
);

around 'GET' => sub {
    my $orig = shift;
    my $self = shift;
    my $mtime = $self->mtime;
    my $uri = $self->request->uri->as_string;

    if ( $mtime && $mtime > 0 ) {
        my $data = $self->cache->get($uri);
        if ($data && defined $data->{resource} && defined defined $data->{resource}->{mtime} && $mtime == $data->{resource}->{mtime}) {
            my $content = $data->{content};
            $self->data($content);
            return DONE;
        }
        else {
            # actual content will be added at the end of the pipeline process
            my $data = { content => '', resource => { mtime => $mtime,}};
            $self->cache->set($uri, $data);
            $self->parent_handler->add_handler('Magpie::Component::ContentCache');
        }
    }

    return $self->$orig(@_);
};

after [qw(add_dependency delete_dependency)] => sub {
    my $self = shift;
    my $uri = $self->request->uri->as_string;
    my $data = $self->cache->get($uri);

    unless ( $data ) {
        $data = {};
    }

    $data->{resource}->{dependencies} = $self->dependencies;

    $self->cache->set($uri, $data);
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Magpie::Plugin::Resource::Cache - A Role to add Caching to a Resource;

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
