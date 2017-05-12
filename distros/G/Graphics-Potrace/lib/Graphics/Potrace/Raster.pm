package Graphics::Potrace::Raster;
$Graphics::Potrace::Raster::VERSION = '0.76';
# ABSTRACT: raster representation for Graphics::Potrace

use strict;
use warnings;
use English qw( -no_match_vars );
use Carp;
use Config;

my ($LONGSIZE, $N, $PACK_TEMPLATE);

BEGIN {
   $LONGSIZE      = $Config{longsize};
   $N             = $LONGSIZE * 8;
   $PACK_TEMPLATE = $LONGSIZE == 8 ? 'Q<*' : 'I*';
}

sub _index_and_mask {
   my ($self, $x) = @_;
   $self->{_max_width} = $x + 1 if $self->{_max_width} < $x + 1;
   my @retval = (int($x / $N), (1 << ($N - 1 - ($x % $N))));
   return @retval;
} ## end sub _index_and_mask

sub new {
   my $package = shift;
   my $self = bless {}, $package;
   $self->reset();
   return $self;
} ## end sub new

sub reset {
   my $self = shift;
   %$self = (
      _max_width => 0,
      _bitmap    => [],
   );
} ## end sub reset

sub width {
   my $self = shift;
   $self->{_width} = shift if @_;
   return $self->{_width} if exists $self->{_width};
   return $self->{_max_width};
} ## end sub width

sub height {
   my $self = shift;
   $self->{_height} = shift if @_;
   return $self->{_height} if exists $self->{_height};
   return scalar(@{$self->{_bitmap}});
} ## end sub height

sub dy {
   my $self = shift;
   $self->{_dy} = shift if @_;
   return $self->{_dy} if exists $self->{_dy};
   my $width = $self->width();
   return int(( $width + $N - 1 ) / $N);
} ## end sub dy

sub real_bitmap {
   my $self = shift;
   $self->{_bitmap} = shift if @_;
   return $self->{_bitmap};
}

sub mirror_vertical {
   my $self = shift;
   $self->{_bitmap} = [ reverse @{ $self->{_bitmap} } ];
   return $self;
}

sub bitmap {
   my ($self, $width, $height) = @_;
   $width ||= $self->width();
   $height ||= $self->height();

   my @bitmap = map { [ @{ $_ ? $_ : [] } ]} @{$self->{_bitmap}};;

   # adjust the bitmap, starting from the height
   splice @bitmap, $height if @bitmap > $height;
   push @bitmap, [] while @bitmap < $height;

   # trim the width
   my ($n, $mask) = $self->_index_and_mask($width - 1);
   ++$n;    # number of aggregates in each row
   my $supermask = 0;
   $mask >>= 1;
   while ($mask) {
      $supermask |= $mask;
      $mask >>= 1;
   }
   $supermask = ~$supermask;
   for my $row (@bitmap) {
      $row ||= [];
      splice @$row, $n if @$row > $n;
      push @$row, (0) x ($n - @$row);
      $row->[-1] &= $supermask;
   } ## end for my $row (@$bitmap)

   return @bitmap if wantarray();
   return \@bitmap;
}

sub packed_bitmap {
   my $self = shift;
   return scalar pack $PACK_TEMPLATE, map { @$_ } $self->bitmap(@_);
}

sub packed {
   my $self   = shift;
   my %bitmap = (
      width  => $self->width(),
      height => $self->height(),
      dy     => $self->dy(),
      map    => $self->packed_bitmap(),
   );
   return \%bitmap;
} ## end sub pack

sub get {
   my ($self, $x, $y) = @_;
   my ($i, $m) = $self->_index_and_mask($x);
   return ($self->{_bitmap}[$y][$i] ||= 0) & $m ? 1 : 0;
}

sub set {
   my ($self, $x, $y, $value) = @_;
   my ($i, $mask) = $self->_index_and_mask($x);
   my $rword = \($self->{_bitmap}[$y][$i] ||= 0);
   if (defined $value && !$value) {
      $$rword &= ~$mask;
   }
   else {
      $$rword |= $mask;
   }
   return $self;
} ## end sub set

sub unset {
   my ($self, $x, $y) = @_;
   return $self->set($x, $y, 0);
}

sub clear {
   my $self = shift;

   my $width  = $self->width();
   my ($n, $mask) = $self->_index_and_mask($width - 1);
   my @line_template = (0) x ($n + 1);

   my $height = $self->height();
   $self->{_bitmap} = [ map { [ @line_template ] } 1 .. $height ];

   return $self;
}

sub reverse {
   my $self = shift;

   my $width  = $self->width();
   my ($n, $mask) = $self->_index_and_mask($width - 1);
   my $supermask = 0;
   $mask >>= 1;
   while ($mask) {
      $supermask |= $mask;
      $mask >>= 1;
   }
   $supermask = ~$supermask;

   my $height = $self->height();
   my @bitmap = $self->bitmap();
   for my $row (@bitmap) {
      $_ = ~$_ for @$row;
      $row->[-1] &= $supermask;
   }
   $self->{_bitmap} = \@bitmap;

   return $self;
}

sub dwim_load {
   my ($self, $source) = @_;
   $self = $self->new() unless ref $self;
   if (! ref $source) {
      return $self->load(Ascii => file => $source)
         if ($source !~ /\n/) && (-e $source);
      return $self->load(Ascii => text => $source);
   }
   elsif (ref($source) eq 'GLOB') {
      return $self->load(Ascii => fh => $source);
   }
   elsif (ref($source) eq 'ARRAY') {
      return $self->load(@$source);
   }
   else {
      croak "unsupported source $source for dwim_load()";
   }
   return $self;
}

sub load {
   my $self = shift;
   my $type = shift;
   $self = $self->new() unless ref $self;
   $self->create_loader($type, target => $self)->load(@_);
   return $self;
}

sub create_loader {
   my ($self, $type, @parameters) = @_;
   my $package = __PACKAGE__ . '::' . ucfirst($type);
   (my $filename = $package) =~ s{::}{/}mxsg;
   require $filename . '.pm';
   return $package->new(@parameters);
}

sub trim {
   my ($self, $width, $height) = @_;
   $width  = $self->width(defined $width   ? $width  : $self->width());
   $height = $self->height(defined $height ? $height : $self->height());

   croak "width is not valid"  unless $width > 0;
   croak "height is not valid" unless $height > 0;
   croak "dy is not valid"     unless $self->dy();

   # adjust the bitmap, starting from the height
   my $bitmap = $self->{_bitmap};
   splice @$bitmap, $height if @$bitmap > $height;
   push @$bitmap, [] while @$bitmap < $height;

   # trim the width
   my ($n, $mask) = $self->_index_and_mask($width - 1);
   ++$n;    # number of aggregates in each row
   my $supermask = 0;
   $mask >>= 1;
   while ($mask) {
      $supermask |= $mask;
      $mask >>= 1;
   }
   $supermask = ~$supermask;
   for my $row (@$bitmap) {
      $row ||= [];
      splice @$row, $n if @$row > $n;
      push @$row, (0) x ($n - @$row);
      $row->[-1] &= $supermask;
   } ## end for my $row (@$bitmap)

   return;
} ## end sub trim

sub trace {
   my $self = shift;
   require Graphics::Potrace;
   return Graphics::Potrace::raster2vectorial($self, @_);
} ## end sub trace

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Graphics::Potrace::Raster - raster representation for Graphics::Potrace

=head1 VERSION

version 0.76

=head1 SYNOPSIS

   use Graphics::Potrace::Raster;
   my $bitmap = Graphics::Potrace::Raster->new();
   $bitmap->load(Ascii => filename => '/path/to/ascii.txt');
   my $vectorial = $bitmap->trace();

=head1 DESCRIPTION

=head1 INTERFACE

=head2 B<< bitmap >>

   my $raw_bitmap = $raster->bitmap();

Returns the raw bitmap as an array of integers whose bits
have been properly arranged for being used by Potrace (the
library).

=head2 B<< clear >>

   $raster->clear();

Clear the raster to all blank pixels.

=head2 B<< create_loader >>

   my $loader = Graphics::Potrace::Raster->create_loader($type, @params);

Creates a loader for the specific C<$type>, i.e. a class that is
searched under C<Graphics::Potrace::Raster::$type>
(see e.g. L<Graphics::Potrace::Raster::Ascii>). See
L<Graphics::Potrace::Raster::Importer> for further information about what
you can do with these importers.

=head2 B<< dwim_load >>

   my $bitmap = Graphics::Potrace->dwim_load($source);

Tries to do the Right Thing (TM), which currently boils down
to analysing the provided parameters like this:

=over

=item *

if C<$source> is a simple scalar, has no newlines and can be
mapped to an existing file, it is considered an Ascii file
(see L<Graphics::Potrace::Raster::Ascii>) and loaded
accordingly;

=item *

if C<$source> is a simple scalar containing newlines or that
cannot be mapped onto an existing file, it is considered as
straight data and loaded accordingly (again assuming an
Ascii format);

=item *

if C<$source> is a glob it is used to load data as if they
are in Ascii representation format;

=item *

if C<$source> is an array it is considered a sequence of
parameters to be provided to C</load>.

=back

=head2 B<< dy >>

   my $dy = $raster->dy();
   $raster->dy($dy);

Get (or set) the C<dy> parameter, needed by Potrace library.

=head2 B<< get >>

   my $value = $raster->get($x, $y);

Get the value associated to the specified pixel.

=head2 B<< height >>

   my $height = $raster->height();
   $raster->height($new_height);

Accessor for raster's height. It performs trimming or enlargement
where necessary.

=head2 B<< load >>

   $bitmap->load($type, $flavour, $info);

Load the bitmap. C<$type> is the name of a helper loader type that is
searched as class C<Graphics::Potrace::Raster::$type> (see
e.g. L<Graphics::Potrace::Raster::Ascii>). C<$flavour> is an indication
of what C<info> contains, see L<Graphics::Potrace::Raster::Importer> for
details about the possible C<$flavour>/C<$info> possible associations.

=head2 B<< mirror_vertical >>

   $raster->mirror_vertical();

Flip bitmap vertically.

=head2 B<< new >>

   my $raster = Graphics::Potrace::Raster->new();

Constructor.

=head2 B<< packed >>

   my $hash = $raster->packed();

Returns a packed representation of the raster, consisting of an
anonymous hash containing fields useful for calling the proper
tracing function from Potrace's library.

=head2 B<< packed_bitmap >>

   my $sequence = $raster->packed_bitmap();

Returns a packed representation of the bitmap section of the whole
raster, i.e. the binary representation used by Potrace's library.

=head2 B<< real_bitmap >>

   my $sequence = $raster->real_bitmap();

Accessor to the low-level representation of the bitmap.

=head2 B<< reset >>

   $raster->reset();

Reset the bitmap to an empty one.

=head2 B<< reverse >>

   $raster->reverse();

Reverse the bitmap: all blanks will be turned to full and vice-versa.

=head2 B<< set >>

   $raster->set($x, $y);
   $raster->set($x, $y, 1); # equivalent to the above, but explicit
   $raster->set($x, $y, 0); # equivalent to $raster->unset(...)

Set the value of the specific pixel to the provided value (or to 1
if no value is provided).

=head2 B<< trace >>

   my $vectorial = $raster->trace(%options);
   my $vectorial = $raster->trace($options);

Get a vectorial representation of the raster image. This works in
terms of L<Graphics::Potrace/raster2vectorial>, see there for additional
info.

=head2 B<< trim >>

   $raster->trim();
   $raster->trim($width);
   $raster->trim($width, $height);
   $raster->trim(undef, $height);

Trim the bitmap according to the available data. A trimming width or
height can be provided, otherwise the one already known for the raster
will be used.

=head2 B<< unset >>

   $raster->unset($x, $y);

Set the specific pixel to empty. Equivalent to calling:

   $raster->set($x, $y, 0);

=head2 B<< width >>

   my $width = $raster->width();
   $raster->width($width);

Get/set the width of the raster. If explicitly set, it will be kept and
trimming will happen, otherwise the raster will grow as necessary.

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
