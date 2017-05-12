package Imager::LineTrace::Figure;
use 5.008001;
use strict;
use warnings;

sub new {
    my $pkg = shift;
    my $args_ref = shift;

    my @points = map {
        bless $_, 'Imager::LineTrace::Point';
    } @{$args_ref->{points}};

    my $type = "Undefined";
    if ( $args_ref->{is_closed} ) {
        $type = "Polygon";
    }
    elsif ( 3 <= scalar(@points) ) {
        $type = "Polyline";
    }
    elsif ( 2 <= scalar(@points) ) {
        $type = "Line";
    }
    else {
        $type = "Point";
    }

    bless {
        points    => \@points,
        is_closed => $args_ref->{is_closed},
        value     => $args_ref->{value},
        type      => $type
    }, $pkg;
}

1;
__END__

=encoding utf-8

=head1 NAME

Imager::LineTrace::Figure - Result of line trace

=head1 SYNOPSIS

    use Imager::LineTrace::Figure;

    my $figure = reverse (
        points    => [ [0, 0], [1, 0] ],
        is_closed => 0,
        value     => 1, # Traced value
    );

    print $figure->{type}; # => "Line"

=head1 DESCRIPTION

Result object of Imager::LineTracer.

RETURN DATA

Basic Overview

    # $figure->{points} is ARRAY reference.
    foreach my $point (@{$figure_ref->{points}}) {
        printf( "x = %d, y = %d\n", $point->[0], $point->[1] );
    }

    # If $figure->{is_closed} is 1, end point linked to start point.
    print $figure->{is_closed};

    # $figure->{value} is traced value.
    print $figure->{value};

    # $figure->{type} is one of "Point", "Line", "Polyline" and "Polygon".
    print $figure->{type};

=head1 LICENSE

Copyright (C) neko.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

neko E<lt>techno.cat.miau@gmail.comE<gt>

=cut
