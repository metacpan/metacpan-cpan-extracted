package HTML::Widget::Constraint::Time;

use warnings;
use strict;
use base 'HTML::Widget::Constraint';
use Date::Calc;

=head1 NAME

HTML::Widget::Constraint::Time - Time Constraint

=head1 SYNOPSIS

    my $c = $widget->constraint( 'Time', 'hour', 'minute', 'second' );

=head1 DESCRIPTION

Time Constraint.

=head1 METHODS

=head2 process

=cut

sub process {
    my ( $self, $w, $params ) = @_;

    return []
        unless ( $self->names && @{ $self->names } == 3 );

    my ( $hour, $min, $sec ) = @{ $self->names };
    my $h = $params->{$hour} || 0;
    my $m = $params->{$min}  || 0;
    my $s = $params->{$sec}  || 0;
    return [] unless ( $h && $m && $s );
    my $results = [];

    unless ( $h =~ /^\d+$/
        && $m =~ /^\d+$/
        && $s =~ /^\d+$/
        && Date::Calc::check_time( $h, $m, $s ) )
    {
        push @$results, HTML::Widget::Error->new(
            { name => $hour, message => $self->mk_message } );
        push @$results, HTML::Widget::Error->new(
            { name => $min, message => $self->mk_message } );
        push @$results, HTML::Widget::Error->new(
            { name => $sec, message => $self->mk_message } );
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
