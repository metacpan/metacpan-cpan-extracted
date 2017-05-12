package Graphics::Potrace::Vectorial::Svg;
$Graphics::Potrace::Vectorial::Svg::VERSION = '0.76';
# ABSTRACT: SVG exporter for Graphics::Potrace

use strict;
use Carp;
use English qw( -no_match_vars );

use Moo;
extends 'Graphics::Potrace::Vectorial::Exporter';

sub save {
   my $self = shift;
   my $fh = $self->fh();

   # Header
   my $header_template = <<'END_OF_HEADER';
<?xml version="1.0" standalone="no"?>
<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">

<svg width="%d" height="%d" version="1.1" xmlns="http://www.w3.org/2000/svg">
END_OF_HEADER
   printf {$fh} $header_template, $self->boundaries(@_);

   # Save vector
   $self->_save_core($fh, $_) for @_;

   # Footer
   print {$fh} "</svg>\n";

   return;
} ## end sub save

sub _save_core {
   my ($self, $fh, $vector) = @_;

   printf {$fh} "<g style=\"fill:%s;stroke:none\" transform=\"matrix(1, 0, 0, -1, 0, %d)\">\n",
      $vector->{color} || 'black', $vector->height();
#   printf {$fh} "<g style=\"fill:%s;stroke:none\">\n",
#      $vector->{color} || 'black';

   my @groups      = @{$vector->list()};
   my $closed_path = 1;
   while (@groups) {
      my $group = shift @groups;
      my $curve = $group->{curve};
      print {$fh} "<path d=\"\n" if $closed_path;
      printf {$fh} "   M %lf %lf\n", @{$curve->[0]{begin}};
      for my $segment (@$curve) {
         if ($segment->{type} eq 'bezier') {
            printf {$fh} "   C %lf %lf %lf %lf %lf %lf\n",
              @{$segment->{u}},
              @{$segment->{w}},
              @{$segment->{end}};
         } ## end if ($segment->{type} eq...
         else {
            printf {$fh} "   L %lf %lf\n", @{$segment->{corner}};
            printf {$fh} "   L %lf %lf\n", @{$segment->{end}};
         }
      } ## end for my $segment (@$curve)
      print {$fh} "   z\n";
      $closed_path = (!@groups) || ($groups[0]{sign} eq '+');
      print {$fh} "\" />" if $closed_path;
   } ## end while (@groups)

   print {$fh} "</g>\n";

   return $vector;
} ## end sub save_core

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Graphics::Potrace::Vectorial::Svg - SVG exporter for Graphics::Potrace

=head1 VERSION

version 0.76

=head1 DESCRIPTION

L<Graphics::Potrace::Vectorial::Exporter> derived class to provide export
facilities to Scalable Vector Graphics.

=head1 INTERFACE

=head2 B<< save >>

Overrides L<Graphics::Potrace::Vectorial::Exporter/save> method to provide
something useful.

=head1 AUTHOR

Flavio Poletti <polettix@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011-2015 by Flavio Poletti polettix@cpan.org.

This module is free software.  You can redistribute it and/or
modify it under the terms of the Artistic License 2.0.

This program is distributed in the hope that it will be useful,
but without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut
