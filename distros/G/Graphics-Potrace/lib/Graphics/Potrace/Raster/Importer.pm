package Graphics::Potrace::Raster::Importer;
$Graphics::Potrace::Raster::Importer::VERSION = '0.76';
# ABSTRACT: vectorial exporter base class for Graphics::Potrace

use strict;
use warnings;
use Carp qw< croak >;
use English qw< -no_match_vars >;

use Moo;

has _target => (
   is        => 'rw',
   isa       => sub { $_[0]->isa('Graphics::Potrace::Raster') },
   lazy      => 1,
   predicate => 'has_target',
   clearer   => 'clear_target',
   init_arg  => 'target',
);

sub target {
   my $self = shift;
   return $self->_target(@_) if @_;
   return $self->_target()   if $self->has_target();
   require Graphics::Potrace::Raster;
   return Graphics::Potrace::Raster->new();
} ## end sub target

sub load_data {
   my $self = shift;
   open my $fh, '<', \$_[0];
   return $self->load_handle($fh);
} ## end sub import

sub load_handle {
   my ($self, $fh) = @_;
   local $/;
   binmode $fh, ':raw';
   my $contents = <$fh>;
   return $self->load_data($contents);
} ## end sub load_handle

sub load {
   my ($self, $type, $f) = @_;
   return $self->load_data($f)   if $type =~ /\A(?:data|text)\z/mxs;
   return $self->load_handle($f) if $type eq 'fh';
   if ($type eq 'file') {
      open my $fh, '<:raw', $f or die "open('$f'): $OS_ERROR";
      return $self->load_handle($fh);
   }
   croak "unknown load type $type";
} ## end sub load

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Graphics::Potrace::Raster::Importer - vectorial exporter base class for Graphics::Potrace

=head1 VERSION

version 0.76

=head1 DESCRIPTION

This is a base class for building up raster importers. One example
of using this base class is shipped directly in the distribution
as L<Graphics::Potrace::Raster::Ascii>.

You only need to override one of three methods: L</load_handle> or L</load_data>.

In this class these two methods are both defined in terms of the other,
so that you can really override only one of them and get the other one
for free.

=head1 INTERFACE

=head2 B<< clear_target >>

Clears the currently set target raster (see L</target>).

=head2 B<< has_target >>

Checks whether the object has a target bitmap for load operations or not.
See also L</target>.

=head2 B<< load_data >>

   my $bitmap = $importer->load_data($scalar);

Import data from a scalar variable. The format the data inside the
C<$scalar> depends on the particular derived class.

=head2 B<< load >>

   my $bitmap = $importer->load(data => $scalar);
   my $bitmap = $importer->load(file => $filename);
   my $bitmap = $importer->load(fh => $filehandle);

Import data from a scalar, a file or a filehandle. The format of the data
in the file/filehandle depends on the derived class. This method
leverages upon B</load_data> and L</load_handle>. In this way you can use
one single method and decide what you want to pass in exactly.

=head2 B<< load_handle >>

   my $bitmap = $importer->load_handle($filehandle);

Import data from a filehandle. This functionality is already covered
by L</load> above, but this method is more useful for overriding in
derived classes.

=head2 B<< new >>

   my $i = Graphics::Potrace::Raster::Importer->new(%args);

Constructor. The only common parameter that you can set is C<target>,
corresponding to set L</target>.

=head2 B<< target >>

   my $raster = $importer->target();
   $importer->target($raster);

Quasi-accessor for setting the target bitmap for the import. This is
a I<quasi>-accessor because if no target is currently defined (you can
check it with C</has_target>) then a new one will be provided each time
you call this method.

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
