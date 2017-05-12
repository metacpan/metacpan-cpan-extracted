package Games::SGF::Util;

use warnings;
use strict;
use Games::SGF;
no warnings 'redefine';

=head1 NAME

Games::SGF::Util - Utility pack for Games::SGF objects

=head1 VERSION

Version 0.993

=cut

our $VERSION = 0.993;


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Games::SGF::Util;

    my $util = new Games::SGF::Util($sgf);
    
    $util->filter( "C", undef ); # removes all comments from SGF

=head1 DISCRIPTION

This is a collection of useful methods for manipulating a Games::SGF object.

All Util methods in this module will not call any game movement methods. This
means in order to work with files with multiple games you must move to the
game of choice then pass it into a util object.

=head1 METHODS

=head2 new

  $util = new Games::SGF::Util($sgf);

This initializes a new Games::SGF::Util object. Will return C<undef> if C<$sgf>
is no supplied.

=cut

sub new {
   my $inv = shift;
   my $class = ref $inv || $inv;
   my $sgf = shift;
   if($sgf) {
#      $sgf = $sgf->clone(); # So we are not working with the actual sgf file
   } else {
      return undef;
   }
   return bless \$sgf, $class;
}

=head2 touch

  $util->touch(\&sub);

This will call C<&sub> for every node in $sgf. C<&sub> will be passed the
C<$sgf> object. any subroutines which manipulate the C<$sgf> tree will lead
to undefined behavior. The safe methods to use are:

=over

=item L<Games::SGF/property>

=item L<Games::SGF/getProperty>

=item L<Games::SGF/setProperty>

=item L<Games::SGF/isCompose>

=item L<Games::SGF/isStone>

=item L<Games::SGF/isMove>

=item L<Games::SGF/isPoint>

=item L<Games::SGF/compose>

=item L<Games::SGF/stone>

=item L<Games::SGF/move>

=item L<Games::SGF/point>

=item L<Games::SGF/err>

=back

=cut

sub touch {
   my $self = shift;
   my $callback = shift;
   my $sgf = $$self;
   my( @branches ) = (-1); # Stores the branch stack
   $sgf->gotoRoot;
   {
      my $last = pop @branches;
      &$callback($sgf) if $last == -1; # callback on current node

      if( $last < $sgf->branches and $sgf->gotoBranch(++$last)) {
         push @branches, $last,-1;
      } elsif(@branches > 0 ) {
         $sgf->prev;
         pop @branches;
      } else {
         last;
      }
      redo;
   }
}

=head2 filter

  $util->fiter( $tag, \&sub);

Will call C<&sub> for every $tag which is in C<$sgf>. C<&sub> will be passed
the tag value. The value then be reset to the return of C<&sub>. If the return
is "" the tag will be unset.

If the tag has a value list each value will be sent to $callback.

If the $callback returns undef it will not be set.

Example:

  # removes all comments that don't match m/Keep/
  $util->filter( "C", sub { return $_[0] =~ m/Keep/ ? $_[0] : ""; );

=cut

sub filter {
   my $self = shift;
   my $tag = shift;
   my $callback = shift;

   return $self->touch(
      sub {
         my $sgf = shift;
         my $values = $sgf->property($tag);
         my @set;
         if( $values ) {
            if( $callback ) {
               foreach( @$values ) {
                  my $ret = &$callback($_);
                  if( defined $ret ) {
                     push @set, $ret
                  }
               }
            } # else unset tag
            $sgf->setProperty($tag,@set);
         }
      }
   );         
}

=head2 gameInfo

  my(@games) = $util->gameInfo;
  foreach my $game (@games) {
      print "New Game\n";
      foreach my $tag (keys %$game) {
         print "\t$tag -> $game->{$tag}\n";
      }
  }

Will return the game-info tags for all games represented in the current
game tree. The return order is the closest to the root, and then the closest
to the main line branch.

UNWRITTEN

=cut

sub gameInfo {
   my $self = shift;
   my $isRec = shift; # set if a recursive call
   my $sgf = $$self;
   my( @games );
   # if this is first run 
   $sgf->gotoRoot unless $isRec;
   
   # touch all nodes in this branch
   {
      # check for games and add to @games
      my(@tags) = $sgf->property;
      my $game = {};
      foreach my $t (@tags) {
         if( $sgf->getTagType($t) & $sgf->T_GAME_INFO ) {
            $game->{$t} = $sgf->getProperty($t);
         }
      }
      if( keys %$game ) {
         $games[@games] = $game;
      }
      redo if $sgf->next;
   }

   # touch all variations
   for( my $i = 0; $i < $sgf->branches; $i++ ) {
      #add game info of branch onto our list
      $sgf->gotoBranch($i);
      push @games, $self->gameInfo( 1 );
      $sgf->gotoParent;
   }
   return @games;
}

=head2 sgf

   $sgf = $util->sgf;
   $sgf = $util->sgf($sgf)

This returns a clone of the C<$sgf> object associated with C<$util>, or sets the
C<$sgf> object to a clone of object supplied.

=cut

sub sgf {
   my $self = shift;
   my $sgf = shift;
   if($sgf) {
      $$self = $sgf;#->clone();
      return $sgf;
   }
   $sgf = $$self;
   return $sgf;#->clone();
}
1;
__END__

=head1 ALSO SEE

L<Games::SGF>

=head1 AUTHOR

David Whitcomb, C<< <whitcode at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-games-sgf at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Games-SGF>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Games::SGF::Util


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

=head1 COPYRIGHT & LICENSE

Copyright 2008 David Whitcomb, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

