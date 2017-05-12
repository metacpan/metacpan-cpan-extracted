package Magpie::Resource::Abstract;
$Magpie::Resource::Abstract::VERSION = '1.163200';
# ABSTRACT: INCOMPLETE - Default Resource class.

use Moose;
extends 'Magpie::Resource';
use Magpie::Constants;

sub GET {
    my $self = shift;
    my $ctxt = shift;
    $self->parent_handler->resource($self);
    $self->data( $self->plack_response->body );
    return OK;
}

sub POST {
    my $self = shift;
    my $ctxt = shift;
    $self->parent_handler->resource($self);
    $self->data( $self->plack_response->body );
    return OK;
}

sub DELETE {
    my $self = shift;
    $self->parent_handler->resource($self);
    return OK;
};

sub PUT {
    my $self = shift;
    $self->parent_handler->resource($self);
    return OK;
};
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Magpie::Resource::Abstract - INCOMPLETE - Default Resource class.

=head1 VERSION

version 1.163200

# SEALSO: Magpie, Magpie::Resource

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
