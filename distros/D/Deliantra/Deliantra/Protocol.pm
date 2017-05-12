=head1 NAME

Deliantra::Protocol - client protocol module

=head1 SYNOPSIS

   use base Deliantra::Protocol; # you have to subclass

=head1 DESCRIPTION

Base class to implement a crossfire client.

=over 4

=cut

package Deliantra::Protocol;

BGIN { die "FATAL: Deliantra::Protocol needs to be rewritten to be properly subclassed form Deliantra::Protocol::Base" }

our $VERSION = '0.1';

use common::sense;

sub feed_map1a {
   my ($self, $data) = @_;

   my $map = $self->{map} ||= [];

   my ($dx, $dy) = delete @$self{qw(delayed_scroll_x delayed_scroll_y)};

   if ($dx || $dy) {
      my ($mx, $my, $mw, $mh) = @$self{qw(mapx mapy mapw maph)};

      {
         my @darkness;

         if ($dx > 0) {
            push @darkness, [$mx, $my, $dx - 1, $mh];
         } elsif ($dx < 0) {
            push @darkness, [$mx + $mw + $dx + 1, $my, 1 - $dx, $mh];
         }

         if ($dy > 0) {
            push @darkness, [$mx, $my, $mw, $dy - 1];
         } elsif ($dy < 0) {
            push @darkness, [$mx, $my + $mh + $dy + 1, $mw, 1 - $dy];
         }

         for (@darkness) {
            my ($x0, $y0, $w, $h) = @$_;
            for my $x ($x0 .. $x0 + $w) {
               for my $y ($y0 .. $y0 + $h) {

                  my $cell = $map->[$x][$y]
                     or next;

                  $cell->[0] = -1;
               }
            }
         }
      }

      # now scroll

      $self->{mapx} += $dx;
      $self->{mapy} += $dy;

      # shift in new space if moving to "negative indices"
      if ($self->{mapy} < 0) {
         unshift @$_, (undef) x -$self->{mapy} for @$map;
         $self->{mapy} = 0;
      }

      if ($self->{mapx} < 0) {
         unshift @$map, (undef) x -$self->{mapx};
         $self->{mapx} = 0;
      }

      $self->map_scroll ($dx, $dy);
   }

   my @dirty;
   my ($coord, $x, $y, $darkness, $fa, $fb, $fc, $cell);

   while (length $data) {
      $coord = unpack "n", substr $data, 0, 2, "";

      $x = (($coord >> 10) & 63) + $self->{mapx};
      $y = (($coord >>  4) & 63) + $self->{mapy};

      $cell = $map->[$x][$y] ||= [];

      if ($coord & 15) {
         @$cell = () if $cell->[0] < 0;

         $cell->[0] = $coord & 8
                    ? unpack "C", substr $data, 0, 1, ""
                    : 255;

         $cell->[1] = unpack "n", substr $data, 0, 2, ""
            if $coord & 4;
         $cell->[2] = unpack "n", substr $data, 0, 2, ""
            if $coord & 2;
         $cell->[3] = unpack "n", substr $data, 0, 2, ""
            if $coord & 1;
      } else {
         $cell->[0] = -1;
      }

      push @dirty, [$x, $y];
   }

   $self->map_update (\@dirty);
}

sub feed_newmap {
   my ($self) = @_;

   $self->{map}  = [];
   $self->{mapx} = 0;
   $self->{mapy} = 0;

   delete $self->{delayed_scroll_x};
   delete $self->{delayed_scroll_y};

   $self->map_clear;
}

sub feed_image {
   my ($self, $data) = @_;

   $self->SUPER::feed_image ($data);

   my ($num, $len, $data) = unpack "NNa*", $data;

   my @dirty;

   for my $x (0..$self->{mapw} - 1) {
      for my $y (0..$self->{maph} - 1) {
         push @dirty, [$x, $y]
            if grep $_ == $num, @{$self->{map}[$x][$y] || []};
      }
   }

   $self->map_update (\@dirty);
}

=back

=head1 AUTHOR

 Marc Lehmann <schmorp@schmorp.de>
 http://home.schmorp.de/

 Robin Redeker <elmex@ta-sa.org>
 http://www.ta-sa.org/

=cut

1
