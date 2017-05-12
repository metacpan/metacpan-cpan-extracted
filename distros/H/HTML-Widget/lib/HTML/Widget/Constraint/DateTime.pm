package HTML::Widget::Constraint::DateTime;

use warnings;
use strict;
use base 'HTML::Widget::Constraint';
use Date::Calc;

=head1 NAME

HTML::Widget::Constraint::DateTime - DateTime Constraint

=head1 SYNOPSIS

    my $c =
      $widget->constraint( 'DateTime', 'year', 'month', 'day', 'hour',
        'minute', 'second' );

=head1 DESCRIPTION

DateTime Constraint.

=head1 METHODS

=head2 process

=cut

sub process {
    my ( $self, $w, $params ) = @_;

    # PS: Commented out. What if I don't want to provide time? I could use
    # 'Date', but, all these fields are allowed to be 0 anyway. And I may
    # not want to check seconds or minutes. So we'll change this to #3

    #    return []
    #      unless ( $self->names && @{ $self->names } == 6 );
    return [] unless ( $self->names && @{ $self->names } >= 3 );

    my ( $year, $month, $day, $hour, $min, $sec ) = @{ $self->names };
    my $y = $params
        ->{$year};    # 0 is a valid year, but Date::Calc doesn't support it
    my $mo = $params->{$month};
    my $d  = $params->{$day};
    my $h  = $params->{$hour} || 0;
    my $mi = $params->{$min} || 0;
    my $s  = $params->{$sec} || 0;

    # PS: Commented out. This is silly. Hour, minute, and second
    # can all be validly 0.
    # return [] unless ( $y && $mo && $d && $h && $mi && $s );
    return [] unless ( $y && $mo && $d );

    my $results = [];

    unless ( $y =~ /^\d+$/
        && $mo =~ /^\d+$/
        && $d  =~ /^\d+$/
        && $h  =~ /^\d+$/
        && $mi =~ /^\d+$/
        && $s  =~ /^\d+$/
        && Date::Calc::check_date( $y, $mo, $d )
        && Date::Calc::check_time( $h, $mi, $s ) )
    {
        push @$results, HTML::Widget::Error->new(
            { name => $year, message => $self->mk_message } );
        push @$results, HTML::Widget::Error->new(
            { name => $month, message => $self->mk_message } );
        push @$results, HTML::Widget::Error->new(
            { name => $day, message => $self->mk_message } );
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
