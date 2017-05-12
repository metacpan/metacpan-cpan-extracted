package Graphics::Potrace;
$Graphics::Potrace::VERSION = '0.76';
# ABSTRACT: bindings to the potrace library

use strict;
use warnings;
use English qw< -no_match_vars >;
use Scalar::Util qw< blessed >;
use Carp qw< croak >;
use Graphics::Potrace::Raster qw<>;
use Graphics::Potrace::Vectorial qw<>;

use Exporter qw( import );
{
   our @EXPORT_OK   = qw< raster raster2vectorial trace >;
   our @EXPORT      = ();
   our %EXPORT_TAGS = (all => \@EXPORT_OK);
}

use XSLoader;
XSLoader::load('Graphics::Potrace', $Graphics::Potrace::VERSION || '0.1');

sub raster {
   return $_[0]    # return if already a raster... it might happen :)
     if @_
        && ref($_[0])
        && blessed($_[0])
        && $_[0]->isa('Graphics::Potrace::Raster');
   return Graphics::Potrace::Raster->new()->dwim_load(@_);
} ## end sub raster

sub raster2vectorial {
   my $raster = shift;
   my %args = (@_ && ref($_[0])) ? %{$_[0]} : @_;
   my %params;
   for
     my $field (qw< turdsize turnpolicy opticurve alphamax opttolerance >)
   {
      $params{$field} = $args{$field} if exists $args{$field};
   }
   return Graphics::Potrace::Vectorial->new(
      _trace(\%params, $raster->packed()));
} ## end sub raster2vectorial

sub trace {
   my %args = ref $_[0] ? %{$_[0]} : @_;

   croak "no raster provided" unless exists $args{raster};
   my $raster = raster($args{raster});

   my $vector = raster2vectorial($raster, %args);

   # Set bounds for saving to those provided by the raster
   $vector->width($raster->width());
   $vector->height($raster->height());

   # Save if so requested
   $vector->export(@{$args{vectorial}}) if exists $args{vectorial};

   # Return vector anyway
   return $vector;
} ## end sub trace

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Graphics::Potrace - bindings to the potrace library

=head1 VERSION

version 0.76

=head1 SYNOPSIS

   # Step by step
   use Graphics::Potrace qw< raster >;
   my $raster = raster('
   ..........................
   .......XXXXXXXXXXXXXXX....
   ..XXXXXXXX.......XXXXXXX..
   ....XXXXX.........XXXXXX..
   ......XXXXXXXXXXXXXXX.....
   ...XXXXXX........XXXXXXX..
   ...XXXXXX........XXXXXXX..
   ....XXXXXXXXXXXXXXXXXX....
   ..........................
   ');
   my $vector = $raster->trace();
   $vector->export(Svg => file => 'example.svg');
   $vector->export(Svg => file => \my $svg_dump);
   $vector->export(Svg => fh   => \*STDOUT);

   # There is a simpler way to get a dump in a scalar
   my $eps_dump = $vector->render('Eps');

   # All in one facility
   use Graphics::Potrace qw< trace >;
   trace(
      raster => '
      ..........................
      .......XXXXXXXXXXXXXXX....
      ..XXXXXXXX.......XXXXXXX..
      ....XXXXX.........XXXXXX..
      ......XXXXXXXXXXXXXXX.....
      ...XXXXXX........XXXXXXX..
      ...XXXXXX........XXXXXXX..
      ....XXXXXXXXXXXXXXXXXX....
      ..........................
      ',
      vectorial => [ Svg => file => 'example.svg' ],
   );

   # There is a whole lot of DWIMmery in both raster() and trace().
   # Stick to Graphics::Potrace::Raster for finer control
   use Graphics::Potrace::Raster;
   my $raster = Graphics::Potrace::Raster->load(
      Ascii => text => '
      ..........................
      .......XXXXXXXXXXXXXXX....
      ..XXXXXXXX.......XXXXXXX..
      ....XXXXX.........XXXXXX..
      ......XXXXXXXXXXXXXXX.....
      ...XXXXXX........XXXXXXX..
      ...XXXXXX........XXXXXXX..
      ....XXXXXXXXXXXXXXXXXX....
      ..........................
      ',
   );
   # you know what to do with $raster - see above!

=head1 DESCRIPTION

Potrace (L<http://potrace.sourceforge.net/>) is a program (and a library)
by Peter Selinger for I<Transforming bitmaps into vector graphics>. This
distribution aims at binding the library from Perl for your fun and
convenience.

=head1 INTERFACE

=head2 B<< raster >>

   my $raster = raster(@parameters);

Generate a L<Graphics::Potrace::Raster> object for further usage.

If the first parameter you provide is already such an object, it is
returned back. This lets you forget about what you actually have, and
it might be handy.

Otherwise, a new L<Graphics::Potrace::Raster> object is created, and
L<Graphics::Potrace::Raster/dwim_load> is called upon it passing the
provided parameters. This applies an heuristic to give you something
reasonable, see there for details.

=head2 B<< raster2vectorial >>

   my $vector = raster2vectorial($raster, %parameters);
   my $vector = raster2vectorial($raster, \%parameters);

Arguments:

=over

=item C<$raster>

a C<Graphics::Potrace::Raster> object, or anything that has a
C<packed()> method programmed to return the right hash ref.

=item C<%parameters>

=item C<$parameters>

parameters for tracing. This version of the bindings is aligned with
C<libpotrace> 1.10 and supports the following parameters:

=over

=item *

turdsize

=item *

turnpolicy

=item *

opticurve

=item *

alphamax

=item *

opttolerance

=back

See e.g. L<http://potrace.sourceforge.net/potracelib.pdf> for details.

=back

You should never actually need this function, because you can just as
well call:

   my $vector = $raster->trace(%parameters); # or with \%parameters

unless C<$raster> isn't actually a C<Graphics::Potrace::Raster> object
and you managed to duck a C<packed()> method in it.

=head2 B<< trace >>

   my $vector = trace(%parameters);
   my $vector = trace($parameters);

This is the most I<Do What I Mean> (a.k.a. DWIM) function of the whole
distribution. It tries to be as bloated as it can, but to provide you
a single interface for your one-off needs.

The following arguments can be provided either via C<%parameters> or
through an input hash ref:

=over

=item C<raster>

the raster to load. This parameter is used to call L</raster> above, see
there and L<Graphics::Potrace::Raster/dwim_load> for in-depth
documentation. And yes, if you I<already> have a
L<Graphics::Potrace::Raster> object you can pass it in.

This parameter is mandatory.

=item C<vectorial>

a description of what you want to do with the vector, e.g. export it
or get a representation. If present, this parameter is expected to be
an array reference containing parameters for
L<Graphics::Potrace::Vectorial/export>, see there for details.

This parameter is optional.

=item I<< all Potrace parameters supported by L</raster2trace> >>

these parameters will be passed over to C<raster2trace>, they are all
optional.

=back

Any other parameter will be ignored.

=head2 B<< version >>

This function returns the version of the Potrace library.

=head1 SEE ALSO

See L<http://potrace.sourceforge.net/> for Potrace - it's awesome!

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
