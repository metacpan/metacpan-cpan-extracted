package HTML::Widget::Constraint::All;

use warnings;
use strict;
use base 'HTML::Widget::Constraint';

=head1 NAME

HTML::Widget::Constraint::All - All Constraint

=head1 SYNOPSIS

    my $c = $widget->constraint( 'All', 'foo', 'bar' );

=head1 DESCRIPTION

All named fields are required.

=head1 METHODS

=head2 process

=cut

sub process {
    my ( $self, $w, $params ) = @_;
    my $results = [];
    for my $name ( @{ $self->names } ) {
        push @$results,
            HTML::Widget::Error->new(
            { name => $name, message => $self->mk_message } )
            if $self->not
            ? ( defined $params->{$name} && length $params->{$name} )
            : ( !defined $params->{$name} || !length( $params->{$name} ) );
    }
    return $results;
}

=head1 AUTHOR

Sebastian Riedel, C<sri@oook.de>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
