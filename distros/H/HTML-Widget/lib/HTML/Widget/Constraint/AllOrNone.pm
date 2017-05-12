package HTML::Widget::Constraint::AllOrNone;

use warnings;
use strict;
use base 'HTML::Widget::Constraint';

=head1 NAME

HTML::Widget::Constraint::AllOrNone - AllOrNone Constraint

=head1 SYNOPSIS

    my $c = $widget->constraint( 'AllOrNone', 'foo', 'bar' );

=head1 DESCRIPTION

AllOrNone means that if one is filled out, all of them have to be.

=head1 METHODS

=head2 process

=cut

sub process {
    my ( $self, $w, $params ) = @_;
    my $results = [];
    my $one;
    for my $name ( @{ $self->names } ) {
        if ($self->not
            ? ( defined $params->{$name} && length $params->{$name} )
            : ( !defined $params->{$name} || !length $params->{$name} ) )
        {
            push @$results, HTML::Widget::Error->new(
                { name => $name, message => $self->mk_message } );
        }
        else {
            $one++;
        }
    }
    return ( $one ? $results : [] );
}

=head1 AUTHOR

Marcus Ramberg, C<mramberg@cpan.org>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
