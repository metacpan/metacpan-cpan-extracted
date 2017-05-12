require 5;
package MIDI::Praxis::Variation;
use strict;
use warnings;
use MIDI::Simple;

BEGIN {
	use Exporter ();
	use vars qw ($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
	$VERSION     = 0.05;
	@ISA         = qw (Exporter);
	@EXPORT      = qw ();
 	@EXPORT_OK   = qw (
		note_name_to_number
		dur
		tye
		raugmentation
		rdiminution
		augmentation
		diminution
		original
		retrograde
		transposition
		inversion
		retrograde_inversion
		ntup
	);
	%EXPORT_TAGS = (
	Functions => [ qw( 
		note_name_to_number
		dur
		tye
		raugmentation
		rdiminution
		augmentation
		diminution
	) ],
	Techniques => [ qw( 
		original
		retrograde
		transposition
		inversion
		retrograde_inversion
		raugmentation
		rdiminution
		augmentation
		diminution
	) ],
	Utilities => [ qw(
		ntup
	) ],
	);
}



########################################### main pod documentation begin ##


=head1 NAME

MIDI::Praxis::Variation - Interface for variation techniques commonly used in music composition.

=head1 SYNOPSIS

  use MIDI::Praxis::Variation


=head1 DESCRIPTION

Melodic variation techniques, as implemented here, expect an array of MIDI::Simple style note names as input. They return an array of Midi note numbers. These returned note representations can be printed directly or used, perhaps in MIDI::Simple fashion, as input to functions/methods that accept midi note number input.

=head1 BUGS

Any that still exist have eluded our testing. This software is supplied as is with no representations as to its fitness for use. Use it at your own risk. If your system, your data, or all the forces of good in the universe are corrupted or destroyed as a result of your use of this software -- so it goes. 

=head1 SUPPORT

None

=head1 AUTHOR

	Craig Bourne
	cbourne@cpan.org

=head1 COPYRIGHT

Copyright (c) Craig Bourne 2004
All rights reserved

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

MIDI::Simple(3).

=cut

############################################# main pod documentation end ##

# Have not yet thought out OO issues
# sub new
# {
# 	my ($class, %parameters) = @_;
# 
# 	my $self = bless ({}, ref ($class) || $class);
# 
# 	return ($self);
# }

                                                                                                 
=head2 note_name_to_number

 Usage     : note_name_to_number($note_name)
 Purpose   : Map a single note name to a midi note number.
 Returns   : An equivalent midi note number.

 Comments  : Expects to see a MIDI::Simple style note name.

=cut

sub note_name_to_number($) {

    my ( $note_number, $in, @ret ) = ( -1, $_[0] );
    return () unless length $in;

    if ( $in =~ /^([A-Za-z]+)(\d+)/s ) {    # E.g.,  "C3", "As4"
        $note_number = $MIDI::Simple::Note{$1} + $2 * 12
          if exists( $MIDI::Simple::Note{$1} );
    }

    return $note_number;
}


=head2 original

 Usage     : original(@array)
 Purpose   : Map note names to midi note numbers.
 Returns   : An equivalent array of midi note numbers.

 Argument  : @array -  an array of note names.

 Comments  : Expects to see a an array of MIDI::Simple style note names,
           : e.g.,  C5, Fs6, Bf3. It returns equivilent midi note
           : numbers leaving the array of note names untouched.

=cut

sub original {
	my @notes =  @_;
	my @ret = ();
	return () unless length $notes[0];
	my $inc = 0;
	for (@notes) {
		push @ret, note_name_to_number( $notes[$inc] );
		$inc++;
	}

	return @ret;
}


=head2 retrograde

 Usage     : retrograde(@array)
 Purpose   : Form the retrograde of an array of note names.
 Returns   : The retrograde equivalent array as midi note numbers.

 Argument  : @array -  an array of note names.

 Comments  : Expects to see a an array of MIDI::Simple style note names.
					 

=cut

sub retrograde {
	my @notes =  @_;
	my @ret = ();
	return () unless length $notes[0];
	@ret = reverse original( @notes );

	return @ret;
}


=head2 transposition

 Usage     : transposition($distance, @array)
 Purpose   : Form the transposition of an array of notes.
 Returns   : Midi note numbers equivalent by transposition to
           : an array of note names.

 Arguments : $distance - an integer giving distance and direction.
           : @array    - an array of note names. 

 Comments  : Expects to see an integer followed an array of
           : MIDI::Simple style note names. The integer specifies
           : the direction and distance of transposition. For
           : example, 8 indicates 8 semitones up while -7 asks
           : for 7 semitones down. The array argument specifies
           : the notes to be transposed.
					 
=cut

sub transposition {
	my ($delta, @notes) = @_;
	my @ret = ();
	return () unless length $notes[0];
	@ret = original(@notes);
	my $inc = 0;

	for ( @notes ) {
		$ret[$inc] += $delta;
		$inc++;
	}
	return @ret;
}


=head2 inversion

 Usage     : inversion($axis, @array)
 Purpose   : Form the inversion of an array of notes.
 Returns   : Midi note numbers equivalent by inversion to
           : an array of note names.

 Arguments : $axis  -  a note to use as the axis of this inversion.
           : @array -  an array of note names. 

 Comments  : Expects to see a MIDI::Simple style note name.
           : followed by an array of such names. These give
           : the axis of inversion and the notes to be inverted.
					 
=cut

sub inversion {
	my ($axis, @notes) = @_; # A note name followed by an array of note names
	return () unless length $axis;
	return () unless length $notes[0];
	my $center = -1;
	my $inc = 0;
	my $first = -1;
	my $delta = 0;
	my @transposed = ();
	my @ret = ();
	my $foo = -1;

	$center = note_name_to_number( $axis );
	$first = note_name_to_number( $notes[0] );
	$delta = $center - $first;
	@transposed = transposition( $delta, @notes);
	$inc = 0;
	for (@notes) {
		$foo =  $transposed[$inc];
		push @ret, (2 * $center - $foo);
		$inc++;
	}
	return @ret;
}


=head2 retrograde_inversion

 Usage     : retrograde_inversion($axis, @array)
 Purpose   : Form the retrograde inversion of an array of notes.
 Returns   : Midi note numbers equivalent by retrograde inversion to
           : an array of note names.

 Argument  : @array -  an array of note names.

 Comments  : Expects to see a an array of MIDI::Simple style note names.
           : Inverts about the supplied $axis.

=cut

sub retrograde_inversion {
	my ($axis, @notes) = @_; # A note name followed by an array of note names
	return () unless length $axis;
	return () unless length $notes[0];
	my @rev_notes = ();
	my @ret = ();

	@rev_notes = reverse @notes;
	@ret = inversion($axis, @rev_notes);

	return @ret;
}


=head2 dur

 Usage     : dur($dur_or_len)
 Purpose   : Compute duration of a note.
 Returns   : Duration as an integer.

 Argument  : $dur_or_len - a string consisting of a numeric MIDI::Simple
           : style numeric duration spec ( e.g., d48, or d60 ) or length
           : spec ( e.g., qn or dhn )

 Comments  : Note that string input is expected and integer output
           : is returned.

=cut

sub dur {
	my ($tempo, $arg) = (MIDI::Simple::Tempo, @_); 
	if($arg =~ m<^d(\d+)$>s) {   # numeric duration spec
		return 0 + $1;
	} elsif( exists( $MIDI::Simple::Length{$arg} )) {   # length spec
		return 0 + ($tempo * $MIDI::Simple::Length{$arg});
	}
}


=head2 tye

 Usage     : tye($dur_or_len)
 Purpose   : Compute the sum of the durations of notes. As with a tie
           : in music notation. This odd spelling is used to avoid
           : conflict with the perl reserved word tie.

 Returns   : Duration as an integer.

 Argument  : $dur_or_len - a string consisting of a numeric MIDI::Simple
           : style numeric duration spec ( e.g., d48, or d60 ) or length
           : spec ( e.g., qn or dhn )

 Comments  : Note that string input is expected and integer output
           : is returned.

=cut

sub tye {
	                                                                                            
	my @dur_or_len = @_;
		                                                                                            
	return () unless length $dur_or_len[0];
			                                                                                            
	my $sum = 0;
	my $inc = 0;

	for (@dur_or_len) {
		$sum += dur($dur_or_len[$inc]);
		$inc++;
	}
		return dur($sum);
																	                                                                                            
}

=head2 raugmentation

 Usage     : raugmentation($ratio, $dur_or_len)
 Purpose   : Augment duration of a note multiplying it by $ratio.
 Returns   : Duration as an integer.

 Argument  : $ratio      - an integer multiplier
           : $dur_or_len - a string consisting of a numeric MIDI::Simple
           : style numeric duration spec ( e.g., d48, or d60 ) or length
           : spec ( e.g., qn or dhn )

 Comments  : Note that string input is expected for $dur_or_len and
           : integer output is returned.

=cut

sub raugmentation {
	my ($ratio, $dur_or_len) = @_; 
	return () unless (1 < $ratio);
	return () unless length $dur_or_len;
	
	return dur($dur_or_len) * $ratio;
}



=head2 rdiminution

 Usage     : rdiminution($ratio, $dur_or_len)
 Purpose   : Diminish duration of a note dividing it by $ratio.
 Returns   : Duration as an integer.

 Argument  : $ratio      - an integer divisor
           : $dur_or_len - a string consisting of a numeric MIDI::Simple
           : style numeric duration spec ( e.g., d48, or d60 ) or length
           : spec ( e.g., qn or dhn )

 Comments  : Note that string input is expected for $dur_or_len and
           : integer output is returned. This integer is the aproximate
           : result of dividing the original duration by $ratio.

=cut

sub rdiminution {
	my ($ratio, $dur_or_len) = @_; 
	return () unless (1 < $ratio);
	return () unless length $dur_or_len;

	my $ret =  sprintf( "%.0f", (dur($dur_or_len) / $ratio));
	
	return $ret;

}



=head2 augmentation

 Usage     : augmentation($dur_or_len)
 Purpose   : Augment duration of a note multiplying it by 2,
           : (i.e., double it).
 Returns   : Duration as an integer.

 Argument  : $dur_or_len - a string consisting of a numeric MIDI::Simple
           : style numeric duration spec ( e.g., d48, or d60 ) or length
           : spec ( e.g., qn or dhn )

 Comments  : Note that string input is expected for $dur_or_len and
           : integer output is returned.

=cut

sub augmentation {

	my @dur_or_len = @_;

	return () unless length $dur_or_len[0];
	
	my $inc = 0;
	my @ret = ();
	for (@dur_or_len) {
		my $elem = "d";

		$elem .= raugmentation(2, $dur_or_len[$inc]);
		push @ret, $elem;
		$inc++;
	}
	return @ret;

}


=head2 diminution

 Usage     : diminution($dur_or_len)
 Purpose   : Diminish duration of a note dividing it by 2,
           : (i.e., halve it).
 Returns   : Duration as an integer.

 Argument  : $dur_or_len - a string consisting of a numeric MIDI::Simple
           : style numeric duration spec ( e.g., d48, or d60 ) or length
           : spec ( e.g., qn or dhn )

 Comments  : Note that string input is expected for $dur_or_len and
           : integer output is returned. This integer is the aproximate
           : result of dividing the original duration by 2.

=cut

sub diminution {


	my @dur_or_len = @_;

	return () unless length $dur_or_len[0];
	
	my $inc = 0;
	my @ret = ();
	for (@dur_or_len) {
		my $elem = "d";

		$elem .= rdiminution(2, $dur_or_len[$inc]);
		push @ret, $elem;
		$inc++;
	}
	return @ret;
}

=head2 ntup

 Usage     : ntup($nelem, @subject)
 Purpose   : Catalog tuples of length $nelem in @subject.
 Returns   : An array of tuples of length $nelem.

 Argument  : $nelem      - number of elements in each tuple
           : @subject    - subject array to be scanned for tuples

 Comments  : Scan begins with the 0th element of @subject looking for
           : a tuple of length $nelem. Scan advances by one until it
           : has found all tuples of length $nelem. For example:
           : given the array @ar = qw( 1 2 3 4 ) and $nelem = 2 
           : ntup(2, @ar) would return @ret = qw( 1 2 2 3 3 4 ). Note
           : that for $nelem == any of -1, 0, 5 using the same @ar as
           : its subject array ntup returns qw();

=cut

sub ntup {

	my $nelem = shift;
	my @tmpar = @_;
	my @ret = ();
	my $index=0;
	

	unless ( @tmpar < $nelem ) {
		for ($index=0; $index <= $#tmpar-$nelem+1; $index++) {
			push @ret, @tmpar[$index .. $index+$nelem-1];
		}
	}

	if ( @tmpar == $nelem ) {
		@ret = @_;
	}

	return @ret;
	
}


1; #this line is important and will help the module return a true value
__END__

