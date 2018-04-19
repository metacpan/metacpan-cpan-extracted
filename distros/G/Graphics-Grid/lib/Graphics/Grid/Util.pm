package Graphics::Grid::Util;

# ABSTRACT: Utility functions used internally in Graphics::Grid

use Graphics::Grid::Setup;

our $VERSION = '0.0001'; # VERSION

use Exporter 'import';

our @EXPORT_OK = qw(
  dots_to_cm cm_to_dots
  dots_to_inches inches_to_dots
  points_to_cm cm_to_points
);
our %EXPORT_TAGS = ( all => \@EXPORT_OK );

fun dots_to_inches( $x, $dpi ) { $x / $dpi; }
fun inches_to_dots( $x, $dpi ) { $x * $dpi; }

fun dots_to_cm( $x, $dpi ) { $x / $dpi * 2.54; }
fun cm_to_dots( $x, $dpi ) { $x / 2.54 * $dpi; }

fun points_to_cm($x) { $x / 72.27 * 2.54; }
fun cm_to_points($x) { $x / 2.54 * 72.27; }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Graphics::Grid::Util - Utility functions used internally in Graphics::Grid

=head1 VERSION

version 0.0001

=head1 SYNOPSIS

    use Graphics::Grid::Util qw(:all);

    # convert between dots and inches
    $inches = dots_to_inches($x, $dpi);
    $dots = inches_to_dots($x, $dpi);

    # convert between dots and centimeters
    $cm = dots_to_cm($x, $dpi);
    $dots = cm_to_dots($x, $dpi);

    # convert between points and centimeters   
    $cm = points_to_cm($x);
    $pt = cm_to_points($x);

=head1 SEE ALSO

L<Graphics::Grid>

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
