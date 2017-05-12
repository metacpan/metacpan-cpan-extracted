package Games::SGF::Go;

use strict;
use warnings;
require Games::SGF;
no warnings 'redefine';

=head1 NAME

Games::SGF::Go - A Go Specific SGF Parser

=head1 VERSION

Version 0.993

=cut
our( @ISA ) = ('Games::SGF');
our $VERSION = 0.993;

=head1 SYNOPSIS

  use Games::SGF::Go;

  my $sgf = new Games::SGF::Go;

  $sgf->readFile('somegame.sgf');

  # fetch Properties
  my $komi = $sgf->property('KM');
  my $handicap = $sgf->property('HA');

  # move to next node
  $sgf->next;

  # get a move
  my $move = $sgf->property('B');
  
  # add it to a board
  
  $board[ $move->[0] ][ $move->[1] ] = 'B';

=head1 DISCRIPTION

Games::SGF::Go Extends L<Games::SGF> for the game specifics of Go. These
include adding the tags 'TB', 'TW', 'HA', and 'KM'. It will also parse and
check the stone, move, and point types.

The stone, move and point types will be returned as an array ref containing
the position on the board.

You can set application specific tags using L<Games::SGF/setTag>. All the
callbacks to L<Games::SGF> have been set and thus can't be reset.

All other methods from L<Games::SGF/METHODS> can be used as you normally would.

=head1 METHODS

=head2 new

  my $sgf = new Games::SGF::Go;

This will create the Games::SGF::Go object.

=cut

sub new {
   my $inv = shift;
   my $class = ref $inv || $inv;
   my $self = $class->SUPER::new(@_);

   # add Go Tags

   # Territory Black
   $self->addTag('TB', $self->T_NONE, $self->V_POINT,
            $self->VF_EMPTY | $self->VF_LIST | $self->VF_OPT_COMPOSE);

   # Territory White
   $self->addTag('TW', $self->T_NONE, $self->V_POINT,
            $self->VF_EMPTY | $self->VF_LIST | $self->VF_OPT_COMPOSE);

   # Handicap
   $self->addTag('HA', $self->T_GAME_INFO, $self->V_NUMBER);

   # Komi
   $self->addTag('KM', $self->T_GAME_INFO, $self->V_REAL);

   
   # redefine tags so that stone becomes point
   $self->redefineTag('AB', "", $self->V_POINT,
               $self->VF_LIST | $self->VF_OPT_COMPOSE);
   $self->redefineTag('AW', "", $self->V_POINT,
               $self->VF_LIST | $self->VF_OPT_COMPOSE);

   # add Go CallBacks
   # Read
   $self->setPointRead( sub { 
         return $self->point( _readPoint($_[0]) );
   });
   $self->setMoveRead( sub {
      if( $_[0] eq "" ) {
         return $self->pass;
      } else {
         return $self->move( _readPoint($_[0]));
      }
   });

   # Check
   $self->setPointCheck(\&_checkPoint);
#   $self->setStoneCheck(\&_checkPoint);
   $self->setMoveCheck( sub {
      if( $self->isPass($_[0]) ) {
         return 1;
      } else {
         return &_checkPoint($_[0]);
      }
   });

   # Write
   $self->setPointWrite( \&_writePoint );
#   $self->setStoneWrite( \&_writePoint );
   $self->setMoveWrite( sub {
         if( $self->isPass( $_[0] ) ) {
            return "";
         } else {
            _writePoint($_[0]);
         }
      });
   

   return bless $self, $class; # reconsecrate
}

# SGF -> internal
sub _readPoint {
   my $text = shift;
   my( @cord ) = split //, $text;
   
   foreach( @cord ) {
      if( $_ ge 'a' and $_ le 'z' ) {
         $_ = ord($_) - ord('a'); # 0 - 25
      } elsif( $_ ge 'A' and $_ le 'Z' ) {
         $_ = ord($_) - ord('A') + 26; # 26 - 51
      } else {
         #error;
      }
   }
   return @cord;
}

# checks internal
sub _checkPoint {
   my $struct = shift;
   return 0 if @$struct <= 0;
   foreach( @$struct ) {
      if( /\D/ ) {
         return 0;
      }
      if( $_ < 0 or $_ > 52 ) {
         return 0;
      }
   }
   return 1;
}

# internal -> SGF
sub _writePoint {
   my $struct = shift;
   my $text = "";
   foreach(@$struct) {
      if( $_ < 26 ) {
         $text .= chr( ord('a') + $_ );
      } else {
         $text .= chr( ord('A') + $_ - 26 );
      }
   }
   return $text;
}

=head2 point

=head2 stone

=head2 move

  $struct = $self->move(@cord);
  @cord = $self->move($struct);

If a point, stone, or move is passed in, it will be broken into it's parts
and returned. If the parts are passed in it will construct the internal
structure which the parser uses.

These override L<Games::SGF/point>, L<Games::SGF/stone>, and
L<Games::SGF/move>.

=cut

# if passed @cord will return @cord again
sub point {
   my $self = shift;
   if( $self->isPoint($_[0]) ) {
      return @{$_[0]};
   } else {
      return bless [@_], 'Games::SGF::Go::point';
   }
}
sub move {
   my $self = shift;
   if( $self->isMove($_[0]) ) {
      return @{$_[0]};
   } else {
      return bless [@_], 'Games::SGF::Go::move';
   }
}
sub stone {
   my $self = shift;
   if( $self->isStone($_[0]) ) {
      return @{$_[0]};
   } else {
      return bless [@_], 'Games::SGF::Go::stone';
   }
}

=head2 isPass

   $sgf->isPass($move);

The method will return true if the move was a pass.

This is represented in the SGF as an empty string:

  ;B[];W[]

=cut

sub isPass {
   my $self = shift;
   my $move = shift;

   if( $self->isMove($move) ) {
      if( $move->[0] eq "" ) {
         return 1;
      }
   }
   return 0;
}

=head2 pass

   $move = $sgf->pass;

This will return a $move which is a pass.

=cut

sub pass {
   my $self = shift;
   return $self->move("");
}

1;
__END__

=head1 ALSO SEE

L<Games::SGF>

L<http://www.red-bean.com/sgf/go.html>

=head1 AUTHOR

David Whitcomb, C<< <whitcode at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-games-sgf at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Games-SGF>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Games::SGF::Go


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Games-SGF>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Games-SGF>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Games-SGF>

=item * Search CPAN

L<http://search.cpan.org/dist/Games-SGF>

=back


=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2008 David Whitcomb, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
.
