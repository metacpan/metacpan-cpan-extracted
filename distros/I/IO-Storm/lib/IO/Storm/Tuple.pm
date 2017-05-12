# ABSTRACT: Storm's primitive data type passed around via streams.

package IO::Storm::Tuple;
$IO::Storm::Tuple::VERSION = '0.17';
# Imports
use strict;
use warnings;
use v5.10;

# Setup Moo for object-oriented niceties
use Moo;
use namespace::clean;

has 'id' => ( is => 'rw' );

has 'component' => ( is => 'rw' );

has 'stream' => ( is => 'rw' );

has 'task' => ( is => 'rw' );

has 'values' => ( is => 'rw' );

sub TO_JSON {
    my ($self) = @_;
    return {
        id        => $self->id,
        component => $self->component,
        stream    => $self->stream,
        task      => $self->task,
        values    => $self->values
    };
}

1;

__END__

=pod

=head1 NAME

IO::Storm::Tuple - Storm's primitive data type passed around via streams.

=head1 VERSION

version 0.17

=head1 NAME

IO::Storm::Tuple - Storm's primitive data type passed around via streams.

=head1 VERSION

version 0.06

=head1 AUTHORS

=over 4

=item *

Cory G Watson <gphat@cpan.org>

=item *

Dan Blanchard <dblanchard@ets.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Infinity Interactive, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 AUTHORS

=over 4

=item *

Dan Blanchard <dblanchard@ets.org>

=item *

Cory G Watson <gphat@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Educational Testing Service.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
