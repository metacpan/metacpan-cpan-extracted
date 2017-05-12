package Games::Mines;

require 5.005_62;
use strict;
use warnings;
use Carp qw(verbose);

use Data::Dumper;
our $VERSION = sprintf("%01d.%02d", 0,q$Revision: 2.2 $ =~ /(\d+)\.(\d+)/);

=head1 NAME

Games::Mines - a mine finding game

=head1 SYNOPSIS

    require Games::Mines;

    # get new 30x40 mine field with 50 mines
    my($game) = Games::Mines->new(30,40,50); 

    # fill with mines, except at the four corners
    $game->fill_mines([0,0],[0,40],[30,0],[30,40]);

=head1 DESCRIPTION

This module is the basis for mine finding game. It contains the basic
methods necessary for a game. 

=cut

# Preloaded methods go here.

# internal:
#       - nothing
#   1-8 - number of mines around that square
#   *   - mine (steped on )
# visible:
#     . - unsteped
#     F - unstepped and flaged
#       - stepped

# 'unstepped' => '.',
# 'flagged'   => 'F',
# 'mine'      => '*',
# 'wrong'     => 'X',
# 'blank'     => ' ',


=head2 Class and object Methods


=over 5

=item $Class->new;

The new method creates a new mine field object. It takes three
arguments: The width of the field, the height of the field, and the
number of mines.  

=cut

sub new {
    my($base) = shift;
    
    # Get class or object ref and construct object
    my($class) = ref($base) || $base;
    
    my($width,$height,$count,) = @_;
    
    if( $count > $width*$height ) {
	return;
    }
    
    my($mine_field) = {
	'on'      => 0,
	'field'  => undef(),

	# mine count
	'count' => $count,
	'flags' => 0,
	'unknown' => 0,
	
	# game information text
	'why'            => 'not started',
	'pre-start-text' => 'not started',
	'running-text'   => 'Running',
	'win-text'       => 'You Win!!!',
	'lose-text'      => 'KABOOOOOM!!!',

	# extra field to hold other field information
	'extra'=>{}
    };
    
    bless $mine_field, $class;
    
    $mine_field->_reset($width,$height);
    
    return $mine_field;
}

=item $obj->width

Returns the width of a mine field.

=cut

sub width {
    my($mine_field) = shift;
    return $#{$mine_field->{field} };
}

=item $obj->height

Returns the height of the mine field.

=cut

sub height {
    my($mine_field) = shift;
    return $#{$mine_field->{field}[0]};
}

=item $obj->count

Returns the total number of mines within the field.

=cut

sub count {
    my($mine_field) = shift;
    return $mine_field->{count};
}

=item $obj->running

Returns a boolean that says if game play is still possible. Returns
false after field is create, but before fill_mines is called. Also
returns false if the whole field has been solved, or a mine has
been stepped on. 

=cut

sub running {
    my($mine_field) = shift;
    my($test);
    my($w,$h);
    
    if($mine_field->found_all && $mine_field->{on}) {
	$mine_field->{on}=0;
	$mine_field->{why} =  $mine_field->{'win-text'};
    }
    return $mine_field->{on};
}

=item $obj->why

Returns a human readable status of the current game. Mostly useful
after a game has ended to say why it has ended.

=cut

sub why {
    my($mine_field) = shift;

    return $mine_field->{why};
}

=item $obj->fill_mines

Randomly fills the field with mines. It takes any number of arguments,
which should be array references to a pair of coordinates of where
I<NOT> to put a mine. 

=cut

sub fill_mines {
    my($mine_field) = shift;
    my(@exclude) = @_;
    my($i,$w,$h);
    
    $mine_field->{why} = $mine_field->{'running-text'};
    $mine_field->{on} = 1;
    
    {
	for($i = 1; $i<=$mine_field->{count}; $i++) {
	    $w = int( rand( $mine_field->width()  +1 ) );
	    $h = int( rand( $mine_field->height() +1 ) );
	    redo if( $mine_field->_at($w,$h) eq '*');
	    
	    redo if( grep { ($_->[0] == $w) && ($_->[1] == $h)} @exclude);
	    redo unless( $mine_field->_check_mine_placement($w,$h));
	    
	    $mine_field->{field}[$w][$h]{contains} = '*';
	    $mine_field->_fill_count($w,$h);
	}
	unless( $mine_field->_check_mine_field ) {
	    $mine_field->_clear_mines;
	    redo;
	}
    }
}

=item $obj->at($col,$row)

Returns what is visible at the coordinates given. Takes two arguments:
the col and the row coordinates.

=cut

sub at {
    my($mine_field) = shift;
    my($w,$h) = $mine_field->_limit(@_);
    
    if($mine_field->shown($w,$h)) {
	return $mine_field->_at($w,$h);
    }
    return $mine_field->{field}[$w][$h]{visibility};
}

=item $obj->hidden($col,$row)

Returns a boolean saying if the position has not been stepped on and
exposed. Takes two arguments: the col and the row coordinates.

=cut

sub hidden {
    my($mine_field) = shift;
    my($w,$h) = $mine_field->_limit(@_);
    return $mine_field->{field}[$w][$h]{visibility};
}

=item $obj->shown($col,$row)

Returns a boolean saying if the position has been stepped on and
exposed. Takes two arguments: the col and the row coordinates.

=cut

sub shown {
    my($mine_field) = shift;
    my($w,$h) = $mine_field->_limit(@_);
    #print STDERR "getting value w,h: ", $w,", ",$h,"\n";
    return not($mine_field->{field}[$w][$h]{visibility});
}


=item $obj->step($col,$row)

Steps on a particular square, exposing what was underneath. Takes
two arguments: the col and the row coordinates. Note that if the
particular field is blank, indicating it has no mines in any of
the surrounding squares, it will also automatically step on those
squares as well. Returns false if already stepped on that square,
or if a mine is under it. Returns true otherwise. 

=cut

sub step {
    my($mine_field) = shift;
    
    my(@stepping) = ( [ $mine_field->_limit(@_) ] );

    while(@stepping) {
	my($w,$h) = @{ shift @stepping };
	
	next if( $mine_field->shown($w,$h) );
	$mine_field->{field}[$w][$h]{visibility} = '';
	$mine_field->{unknown}--;
	
	if($mine_field->_at($w,$h) eq '*' ) {
	    $mine_field->{field}[$w][$h]{visibility} = 'X';
	    $mine_field->{on} = 0;
	    $mine_field->{why}= $mine_field->{'lose-text'};
	    return;
	}
	
	if(	$mine_field->at($w,$h) eq ' ') {
	    foreach my $dw (-1..1) {
		next if( $w+$dw <0);
		next if( $w+$dw > $mine_field->width());
		
		foreach my $dh (-1 ..1) {
		    next if($dw ==0 && $dh==0);
		    next if( $h+$dh <0);
		    next if( $h+$dh > $mine_field->height());
		    
		    next if( $mine_field->shown($w+$dw,$h+$dh) );
		    push @stepping, [$w+$dw, $h+$dh];
		}
	    }
	}
    }
    return 1;
}

=item $obj->flag($col,$row)

Place a flag on a particular unexposed square. Takes two arguments:
the col and the row coordinates. Returns true if square can and has
been flagged.

=cut

sub flag {
    my($mine_field) = shift;
    
    my($w,$h) = $mine_field->_limit(@_);
    
    return if( $mine_field->shown($w,$h) );
    return if( $mine_field->flagged($w,$h) );
    $mine_field->{field}[$w][$h]{visibility} = 'F';
    $mine_field->{flags}++;
    $mine_field->{unknown}--;
    return 1;
}

=item $obj->unflag($col,$row)

Removes a flag from a particular unexposed square. Takes two
arguments: the col and the row coordinates. Returns true if
square can and has been unflagged.

=cut

sub unflag {
    my($mine_field) = shift;
    
    my($w,$h) = $mine_field->_limit(@_);
    
    return if( $mine_field->shown($w,$h) );
    return if( not $mine_field->flagged($w,$h) );
    $mine_field->{field}[$w][$h]{visibility} = '.';
    $mine_field->{flags}--;
    $mine_field->{unknown}++;
    return 1;
}


=item $obj->flagged($col,$row)

Returners a boolean based on whether a flag has been placed on a
particular square.  Takes two arguments: the col and the row
coordinates. 

=cut

sub flagged {
    my($mine_field) = shift;
    
    my($w,$h) = $mine_field->_limit(@_);
    
    return if( $mine_field->shown($w,$h) );
    #print STDERR Dumper($mine_field->{field}[$w][$h]{visibility}, $h,$w);
    return $mine_field->{field}[$w][$h]{visibility} eq 'F';
}


=item $obj->flags

Return the total number of flags throughout the whole field.

=cut

sub flags {
    my($mine_field) = shift;
    return $mine_field->{flags};
}

=item $obj->found_all

Returners a boolean saying whether all mines have been found or not. 

=cut

sub found_all {
    my($mine_field) = shift;
    
    my($w,$h);
	
    if(     $mine_field->{flags}+$mine_field->{unknown} 
	    == $mine_field->{count} ) {
	
	for($w = 0; $w <= $mine_field->width(); $w++) {
	    for($h = 0; $h<= $mine_field->height(); $h++) {
		if(     $mine_field->at($w,$h) eq 'F' &&
			not ($mine_field->_at($w,$h) eq '*')){
		    return;
		}
	    }
	}
	$mine_field->{why} = $mine_field->{'win-text'};
	$mine_field->{on} = 0;
	
	return 1;
    }
    
    return;
}


=begin for developers

=item $obj->_limit($col,$row)

An internal check to make sure the coordinates given are actually on
the field itself. Will truncate to the field limits and values
that are no.

=cut

sub _limit {
    my($mine_field) = shift;
    my($w,$h,@rest)=@_;

    if( $w<0) {
	$w =0;
    }
    elsif(  $w >= $mine_field->width() ) {
	$w = $mine_field->width();
    }
    
    if($h<0) {
	$h=0;
    }
    elsif( $h >= $mine_field->height() ) {
	$h = $mine_field->height();
    }

    return ($w,$h,@rest);
}

=item $obj->_reset($width,$height)
    
This is the method that actually sets up the whole data structure that
represents the field, and fills it with the default values. Takes
two arguments: The width of the column and row of the
coordinates.

=cut

sub _reset {
    my($mine_field) = shift;
    
    my($width,$height) = @_;
    my($w,$h);
    
    $mine_field->{field} = [ undef() x $width ];
    for( $w = 0; $w <= $width-1; $w++) {
	$mine_field->{field}[$w] = [ undef() x $height ];
	
	for( $h = 0; $h<= $height-1; $h++) {
	    $mine_field->{field}[$w][$h] =  {
		contains    => " ",
		visibility  => '.',
		extra       =>{},
	    };
	}
    }
    $mine_field->{unknown} = $w * $h;
}


=item $obj->_fill_count($col,$row)

Used to add to the numbers surrounding a mine. Normally called from
fill_mines to fill the field with the mine counts. Takes two
coordinates, the $col and $row coordinates. Assumes there is a
mine at the center.

=cut

sub _fill_count {
    my($mine_field) = shift;
    
    my($w,$h)=$mine_field->_limit(@_);
    
    foreach my $dw (-1..1) {
	next if( $w+$dw <0);
	next if( $w+$dw > $mine_field->width());
	
	foreach my $dh (-1 ..1) {
	    next if($dw ==0 && $dh==0);
	    next if( $h+$dh <0);
	    next if( $h+$dh > $mine_field->height());
	    
	    next if( $mine_field->_at($w+$dw, $h+$dh) eq '*');
	    
	    $mine_field->{field}[ $w+$dw ][ $h+$dh ]{contains}++;
	}
    }
}

=item $obj->_clear_mines

Clears mine field of all bombs, and resets the field to a pre-start 
state.

=cut

sub _clear_mines {
    my($mine_field) = shift;
    my($i);
    my($w,$h) = ($mine_field->width(),$mine_field->height() );
    $mine_field->{'why'} = $mine_field->{'pre-start-text'};
    $mine_field->_reset($w,$h);
}

=item $obj->_check_mine_placement($col,$row)

It checks to see if a mine should be placed at the the coordinates given.
Returns true if it's an acceptable position.

This is a placeholder method for modules that inherit from this one
to over ride. Always returns true by default.

=cut

sub _check_mine_placement {
    return 1;
}

=item $obj->_check_mine_field

It checks to see if a mine field has an acceptable layout.
Returns true if it's an acceptable field.

This is a placeholder method for modules that inherit from this one
to over ride. Always returns true by default.

=cut

sub _check_mine_field {
    return 1;
}

=item $obj->_at($col,$row)

Returns what is underneath at the coordinates given, regardless of
weather it is uncovered or not. Takes two arguments: the col and
the row coordinates.

=cut

sub _at {
    my($mine_field) = shift;
    my($w,$h) = $mine_field->_limit(@_);
    return $mine_field->{field}[$w][$h]{contains};
}



=end for developers

=back

=head1 AUTHOR

Martyn W. Peck <mwp@mwpnet.com>

=head1 BUGS

None known. But if you find any, let me know.

=head1 COPYRIGHT

Copyright 2003, Martyn Peck. All Rights Reserves.

This program is free software. You may copy or redistribute 
it under the same terms as Perl itself.

=cut

1;

