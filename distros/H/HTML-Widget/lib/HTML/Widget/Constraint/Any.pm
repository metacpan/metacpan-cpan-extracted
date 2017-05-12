package HTML::Widget::Constraint::Any;

use warnings;
use strict;
use base 'HTML::Widget::Constraint';

=head1 NAME

HTML::Widget::Constraint::Any - Any Constraint

=head1 SYNOPSIS

    my $c = $widget->constraint( 'Any', 'foo', 'bar' );

=head1 DESCRIPTION

One or more of the named fields must be present.

=head1 METHODS

=head2 process

=cut

sub process {
    my ( $self, $w, $params ) = @_;

    my $results = [];
    my $present = 0;
    for my $name ( @{ $self->names } ) {
        unless ( $params->{$name} ) {
            push @$results, HTML::Widget::Error->new(
                { name => $name, message => $self->mk_message } );
        }
        else { $present++ }
    }
    $present = $self->not ? !$present : $present;
    return $present ? [] : $results;
}

=head2 default_message

=cut

sub default_message {'Alternative Missing'}

=head2 render_errors

Arguments: @names

A list of element names for which an error should be displayed.

If this is not set, the default behaviour is for the error to be displayed 
for all of the Constraint's named elements.  

=head1 AUTHOR

Sebastian Riedel, C<sri@oook.de>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
