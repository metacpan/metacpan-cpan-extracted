package HTML::Widget::Constraint::Equal;

use warnings;
use strict;
use base 'HTML::Widget::Constraint';

=head1 NAME

HTML::Widget::Constraint::Equal - Equal Constraint

=head1 SYNOPSIS

    my $c = $widget->constraint( 'Equal', 'foo', 'bar' );

=head1 DESCRIPTION

Equal Constraint. All provided elements must be the same. Combine this
with the All constraint to make sure all elements are equal.

=head1 METHODS

=head2 process

=cut

sub process {
    my ( $self, $w, $params ) = @_;
    my $results  = [];
    my $equal    = $params->{ ${ $self->names }[0] };
    my $failures = 0;

    for my $name ( @{ $self->names } ) {
        $failures++ if $params->{$name} ne $equal;
    }

    if ($failures) {
        for my $name ( @{ $self->names } ) {
            push @$results, HTML::Widget::Error->new(
                { name => $name, message => $self->mk_message } );
        }
    }

    return $results;
}

=head2 render_errors

Arguments: @names

A list of element names for which an error should be displayed.

If this is not set, the default behaviour is for the error to be displayed 
for all of the Constraint's named elements.  

=head1 AUTHOR

Marcus Ramberg, C<mramberg@cpan.org>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
