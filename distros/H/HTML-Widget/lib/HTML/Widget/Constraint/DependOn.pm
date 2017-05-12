package HTML::Widget::Constraint::DependOn;

use warnings;
use strict;
use base 'HTML::Widget::Constraint';

=head1 NAME

HTML::Widget::Constraint::DependOn - DependOn Constraint

=head1 SYNOPSIS

    my $c = $widget->constraint( 'DependOn', 'foo', 'bar' );

=head1 DESCRIPTION

If the first field listed is filled in, all of the others are required.

=head1 METHODS

=head2 process

=cut

sub process {
    my ( $self, $w, $params ) = @_;
    my $results = [];
    my @names   = @{ $self->names };
    my $first   = shift @names;

    return [] if !exists $params->{$first};

    for my $name (@names) {
        push @$results,
            HTML::Widget::Error->new(
            { name => $name, message => $self->mk_message } )
            if $self->not ? $params->{$name} : !$params->{$name};
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
