package HTML::Widget::Constraint::Date;

use warnings;
use strict;
use base 'HTML::Widget::Constraint';
use Date::Calc;

=head1 NAME

HTML::Widget::Constraint::Date - Date Constraint

=head1 SYNOPSIS

    my $c = $widget->constraint( 'Date', 'year', 'month', 'day' );

=head1 DESCRIPTION

Date Constraint.

=head1 METHODS

=head2 process

=cut

sub process {
    my ( $self, $w, $params ) = @_;

    return []
        unless ( $self->names && @{ $self->names } == 3 );

    my ( $year, $month, $day ) = @{ $self->names };
    my $y = $params->{$year};
    my $m = $params->{$month};
    my $d = $params->{$day};
    return [] unless ( $y && $m && $d );
    my $results = [];

    unless ( $y =~ /^\d+$/
        && $m =~ /^\d+$/
        && $d =~ /^\d+$/
        && Date::Calc::check_date( $y, $m, $d ) )
    {
        push @$results, HTML::Widget::Error->new(
            { name => $year, message => $self->mk_message } );
        push @$results, HTML::Widget::Error->new(
            { name => $month, message => $self->mk_message } );
        push @$results, HTML::Widget::Error->new(
            { name => $day, message => $self->mk_message } );
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
