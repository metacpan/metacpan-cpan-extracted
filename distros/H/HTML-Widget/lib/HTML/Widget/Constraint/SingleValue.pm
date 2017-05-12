package HTML::Widget::Constraint::SingleValue;

use warnings;
use strict;
use base 'HTML::Widget::Constraint';

=head1 NAME

HTML::Widget::Constraint::SingleValue - SingleValue Constraint

=head1 SYNOPSIS

    my $c = $widget->constraint( 'SingleValue', 'foo' );

=head1 DESCRIPTION

Ensures that multiple values were not submitted for the named element.

=head1 METHODS

=head2 process

=cut

sub process {
    my ( $self, $w, $params ) = @_;
    my $results = [];
    my ($name) = @{ $self->names };

    if ( ref $params->{$name} ) {
        push @$results, HTML::Widget::Error->new(
            { name => $name, message => $self->mk_message } );
    }

    return $results;
}

=head1 AUTHOR

Carl Franks, C<cfranks@cpan.org>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
