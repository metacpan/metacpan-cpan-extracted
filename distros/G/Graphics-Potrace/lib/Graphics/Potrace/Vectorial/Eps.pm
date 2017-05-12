package Graphics::Potrace::Vectorial::Eps;
$Graphics::Potrace::Vectorial::Eps::VERSION = '0.76';
# ABSTRACT: Encapsulated Postscript exporter for Graphics::Potrace

use strict;
use Carp;
use English qw( -no_match_vars );

use Moo;
extends 'Graphics::Potrace::Vectorial::Exporter';

sub save {
   my $self = shift;
   my $fh = $self->fh();

   # Header
   print {$fh} "%!PS-Adobe-3.0 EPSF-3.0\n";
   printf {$fh} "%%%%BoundingBox: 0 0 %d %d\n",
      $self->boundaries();

   # Every vector
   $self->_save_core($fh, $_) for @_;

   # Footer
   print {$fh} "%EOF\n";

   return;
} ## end sub save

sub _save_core {
   my ($self, $fh, $vector) = @_;

   my $colorline = exists $vector->{color}
      ? sprintf("%.4f %.4f %.4f setrgbcolor fill\n", @{$vector->{color}})
      : "0 setgray fill\n";

   my @groups      = @{$vector->list()};
   my $closed_path = 1;
   while (@groups) {
      my $group = shift @groups;
      my $curve = $group->{curve};
      print {$fh} "newpath\n" if $closed_path;
      printf {$fh} "%lf %lf moveto\n", @{$curve->[0]{begin}};
      for my $segment (@$curve) {
         if ($segment->{type} eq 'bezier') {
            printf {$fh} "%lf %lf %lf %lf %lf %lf curveto\n",
              @{$segment->{u}},
              @{$segment->{w}},
              @{$segment->{end}};
         } ## end if ($segment->{type} eq...
         else {
            printf {$fh} "%lf %lf lineto\n", @{$segment->{corner}};
            printf {$fh} "%lf %lf lineto\n", @{$segment->{end}};
         }
      } ## end for my $segment (@$curve)
      $closed_path = (!@groups) || ($groups[0]{sign} eq '+');
      if ($closed_path) {
         print {$fh} "closepath\n";
         print {$fh} "gsave\n";
         print {$fh} $colorline;
         print {$fh} "grestore\n";
      } ## end if ($closed_path)
   } ## end while (@groups)

   return $vector;
} ## end sub save_core

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Graphics::Potrace::Vectorial::Eps - Encapsulated Postscript exporter for Graphics::Potrace

=head1 VERSION

version 0.76

=head1 DESCRIPTION

L<Graphics::Potrace::Vectorial::Exporte> derived class to provide export
facilities to Encapsulated Postscript.

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
