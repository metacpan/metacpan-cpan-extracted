package Games::Mines::Play;

require 5.005_62;
use strict;
use warnings;

use Carp;
use vars qw($AUTOLOAD);

use Data::Dumper;

use Games::Mines;
our $VERSION = sprintf("%01d.%02d.%02d", 0,q$Revision: 1.11 $ =~ /(\d+)\.(\d+)/);

=head1 NAME

Games::Mines::Play;

=head1 SYNOPSIS

    require Games::Mines::Play;

    # get new 30x40 mine field with 50 mines
    my($game) = Games::Mines->new(30,40,50);

    # use color text
    $game->set_ANSI_Color;

    # fill with mines, except at the four corners
    $game->fill_mines([0,0],[0,40],[30,0],[30,40]);

    # print out playing field
    $game->print_out("field");
    $game->print_status_line;


=head1 DESCRIPTION

This module is he basis for mine finding game. It builds on the
Games::Mines base class to with all the various methods needed to play
a text version of the game. 

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
    
    my($game) = 'Games::Mines';
    
    my($w,$h,$m) = (shift,shift,shift);
    
    if(@_) {
	$game=shift;
    }
    
    my($new_game) = $game->new($w,$h,$m);
    return unless defined( $new_game);
    
    my($mine_field) = {
	'GAME' => $new_game,
	'map' =>'',
	'game number' => 1,
    };
    
    bless $mine_field, $class;
    $mine_field->set_ASCII;
    return $mine_field;
}

# class methodes

=item $class->default(%opts)

Returns an array of width, height, and number of mines, based on some
common arguments. It takes a has with the some combination of six
keys. The first three are B<small>, B<medium>, and B<large>. These
are boolean keys, who's value are only checked to see if they
contain a true value. The small field is 8x8 with 10 mines, the medium
field is 16x16 with 40 mines, and the large field is 16x30 with 99
mines. The other three are B<width>, B<height>, and B<mines>, which
sets the corresponding term. Note that this is designed to work with
Getopt::Long, so any other keys are ignored. The default is to return
a large field.

=cut

sub default {
    my($class) = shift; # don't really do anything with this.
    my(%opt) = @_;
    
    my (@defs) = (16,30,99);
    
    if( exists ( $opt{small} ) && $opt{small} ) {
	@defs = (8,8,10);
    }
    elsif( exists ( $opt{medium} )&& $opt{medium}) {
	@defs = (16,16,40);
    }
    elsif( exists ( $opt{large} ) && $opt{large} ) {
	@defs = (16,30,99);
    }
    
    if( defined( $opt{ height }) && ($opt{ height }>1) ) {
	$defs[0] = $opt{height};
    }
    if( defined( $opt{ width  }) && ($opt{ width  }>1) ) {
	$defs[1] = $opt{width};
    }
    if( defined( $opt{ mines  }) && ($opt{ mines  }>0) ) {
	$defs[2] = $opt{mines};
    }
    return @defs;
}

=back

=head2 Object Methods

=over 5

=item $obj->print_out($arg)

Prints out the game field. It takes one argument, saying what to
print. The "field" argument prints out the current visible
field. The "solution" argument prints out the actual location of
the mines. The "check" argument prints out the field, marking any
mistakes that where made. Default is is to print a "field".

=cut

sub print_out {
    my($mine_field) = shift;
    
    my($type) = shift ||"field";
    my($w,$h);
    
    $mine_field->_start_field;
    
    for($w = 0; $w <= $mine_field->width(); $w++) {
	$mine_field->_start_line($w);
	
	for($h = 0; $h<= $mine_field->height(); $h++) {
	    $mine_field->_start_cell($w,$h);
	    if($type eq "field") {
		$mine_field->_map( $mine_field->at($w,$h),$w,$h );
	    }
	    elsif($type eq "check") {
		$mine_field->_map( $mine_field->_diff($w,$h),$w,$h );
	    }
	    elsif($type eq "solution") {
		$mine_field->_map( $mine_field->_at($w,$h),$w,$h );
	    }
	    $mine_field->_end_cell($w,$h);
	}
	$mine_field->_end_line($w);
    }
    $mine_field->_end_field;
}

=item $obj->print_status_line

Prints out a status line of how many mines have been located. If the
game has ended, it also prints out the ending text saying why.

=cut

sub print_status_line {
    my($mine_field) = shift;
    print "mines: ",$mine_field->flags," of ",
          $mine_field->count,"\n";
    unless($mine_field->running) {
	print $mine_field->why,"\n";
    }
}

=item $obj->set_ASCII

Set the default mapping of the internal representation to the actual
characters printed out, to a plain ascii characters.

=cut

sub set_ASCII {
    my($mine_field) = shift;
    $mine_field->{'map'} = {
	'*' => '*',
	'.' => '.',
	'F' => 'F',
	'f' => 'f',
	' ' => ' ',
	'1' => '1',
	'2' => '2',
	'3' => '3',
	'4' => '4',
	'5' => '5',
	'6' => '6',
	'7' => '7',
	'8' => '8',
	'X' => 'X',
    };
}


=item $obj->set_ANSI_Color

Set the default mapping of the internal representation to the actual
characters printed out, to ascii characters with ANSI colors. If
Term::ANSIColor is not installed on your machine, this will quietly
fail.

=cut

use vars q($loaded_ansi_color);

BEGIN {
    eval 'use Term::ANSIColor; $loaded_ansi_color=1';
}

sub set_ANSI_Color {
    my($mine_field) = shift;
    return unless( $loaded_ansi_color );
    $mine_field->{'map'} = {
	'*' => colored('*',"black","on_white"),
	'.' => colored('L',"black","on_blue","bold"),
	'F' => colored('F',"red","on_blue","bold"),
	'f' => colored('f',"black","on_red"),
	' ' => colored(' ',"on_white"),
	'1' => colored('1',"blue","on_white"),
	'2' => colored('2',"green","on_white"),
	'3' => colored('3',"red","on_white"),
	'4' => colored('4',"black","on_white"),
	'5' => colored('5',"magenta","on_white"),
	'6' => colored('6',"cyan","on_white"),
	'7' => colored('7',"yellow","on_white"),
	'8' => colored('8',"black","on_white"),
	'X' => colored('*',"black","on_red","blink"),
    };
}


=item $obj->save_game($filename,$number)

Saves the current game. Takes two arguments: The filename to save it
to, and the game number to save it under. Note that if you give it
a game number that already exists within that file, that game will
get over written by this one. If no such game number exists, then
it is simply added to the end.

=cut

sub save_game {
    my($field) = shift;
    my($file,$game) = @_;
    my($reading)=1;
    
    my($mine_field) = $field->{'GAME'};
    
    $game ||=$mine_field->{'game number'};
    
    unless( open(FILE, "$file") ){
	$reading=0;
    }
    unless( open(FILE_TO, "> $file.working") ){
	warn("can't open file $file.working for temporary file: $!");
	return;
    }
    
    my($line)="\n";
    # skip games untill we find the right one
    if($reading) {
	while($line=<FILE>) {
	    last if( $line =~/Game\s+$game\s*$/);
	    print FILE_TO $line;
	}
    }
    
    print FILE_TO "Game $game\n";
    print FILE_TO $mine_field->width+1,"x",$mine_field->height+1,"\n";

    my($w,$h);
    for($w = 0; $w <= $mine_field->width(); $w++) {
	for($h = 0; $h<= $mine_field->height(); $h++) {
	    if($mine_field->at($w,$h) eq ' ') {
		print FILE_TO ' ';
	    }
	    elsif($mine_field->at($w,$h) =~/\d/) {
		print FILE_TO ' ';
	    }
	    elsif($mine_field->at($w,$h) eq '*') {
		print FILE_TO '*';
	    }
	    elsif($mine_field->at($w,$h) eq '.') {
		if($mine_field->_at($w,$h) eq ' ') {
		    print FILE_TO '.';
		}
		elsif($mine_field->_at($w,$h) =~/\d/) {
		    print FILE_TO '.';
		}
		elsif($mine_field->_at($w,$h) eq '*') {
		    print FILE_TO ':';
		}
	    }
	    elsif($mine_field->at($w,$h) eq 'F') {
		if($mine_field->_at($w,$h) eq ' ') {
		    print FILE_TO 'f';
		}
		elsif($mine_field->_at($w,$h) =~/\d/) {
		    print FILE_TO 'f';
		}
		elsif($mine_field->_at($w,$h) eq '*') {
		    print FILE_TO 'F';
		}
	    }
	}
	print FILE_TO "\n";
    }
    print FILE_TO"\n";
    
    if($reading) {
	while(not eof(FILE)) {
	    # dump old game number
	    while($line=<FILE>) {
		last if( $line =~/Game/);
	    }
	    last if( eof(FILE));
	    # copy rest of games
	    print FILE_TO  $line;
	    while($line=<FILE>) {
		print FILE_TO $line;
	    }
	}
    }
    
    close(FILE_TO);
    if($reading) {
	close(FILE);
    }
    if($reading) {
	rename($file,"$file.bak") || die("Can't move $file to backup: $!");
    }
    
    rename("$file.working",$file) || 
	die("Can't rename temporary file $file.working to $file: $!");
}

=item $obj->load_game($filename,$number)

Loads a previously saved game to replace the current game. It takes
two arguments: the file name to get the game from and the game
number to load. If it can't open the file or find the given game
number will leave the current game unchanged, and return undefined.

=cut

sub load_game {
    my($field) = shift;
    my($file,$game) = @_;
    
    my($old_field) = $field->{'GAME'};
    
    $game ||=$field->{'game number'};
    unless( open(FILE, $file) ){
	warn("can't open save file  $file: $!");
	return;
    }
    
    my($line);
    # skip games untill we find the right one
    while($line=<FILE>) {
	last if( $line =~/Game $game\s*$/);
    }
    
    return if(eof(FILE));
    
    # get the width and height and make new field
    $line=<FILE>;
    $line=~/\s*(\d+)x(\d+)/;
    my($width,$height) = ($1,$2);
    
    my($mine_field) = $old_field->new($width,$height,0);
    
    my($w,$h);
    my($error)=0;
    # fill in playing field
    for($w =0;$w<=$mine_field->width;$w++) {
	
	$line=<FILE>;
	
	my(@sq) = split('',$line);
	
	my($cont,$vis);
	for($h=0; $h<=$mine_field->height;$h++) {
	    if($sq[$h] eq '.') { #no mine/unstepped
		$mine_field->{field}[$w][$h]{visibility} = '.';
	    }
	    elsif($sq[$h] eq 'f') { #no mine/flagged
		$mine_field->{field}[$w][$h]{visibility} = 'F';
		$mine_field->{flags}++;
		$mine_field->{unknown}--;
	    }
	    elsif($sq[$h] eq ' ') { #no mine/stepped
		$mine_field->{field}[$w][$h]{visibility} = '',;
		$mine_field->{unknown}--;
	    }
	    elsif($sq[$h] =~/\d/) { #no mine/stepped
		$mine_field->{field}[$w][$h]{visibility} = '',;
		$mine_field->{unknown}--;
	    }
	    elsif($sq[$h] eq ':') { # mine/unstepped
		$mine_field->{field}[$w][$h] =  {
		    contains => '*',
		    visibility  => '.',
		};
		$mine_field->{count}++;
		$mine_field->_fill_count($w,$h);
	    }
	    elsif($sq[$h] eq 'F') { #mine/flagged
		$mine_field->{field}[$w][$h] =  {
		    contains => '*',
		    visibility  => 'F',
		};
		$mine_field->_fill_count($w,$h);
		$mine_field->{flags}++;
		$mine_field->{unknown}--;
		$mine_field->{count}++;
	    }
	    elsif($sq[$h] eq 'X') { #mine/stepped : shouldn't happen
		$mine_field->{field}[$w][$h] =  {
		    contains => '*',
		    visibility  => '',
		};
		$mine_field->_fill_count($w,$h);
		$mine_field->{flags}++;
		$mine_field->{unknown}--;
		$mine_field->{count}++;
	    }
	    else { #got something totaly unknown
		die("Don't know how to interpret $sq[$h] in Game $game at line $.\n");
		$error=1;
		last;
	    }
	}
    }
    
    if($error) {
	$field->{'GAME'} = $old_field;
	return;
    }
    
    $mine_field->{on} =  1;
    $field->{'GAME'} = $mine_field;
    
    return 1;
}

=begin for developers

=cut

sub _start_field {
    my($mine_field) = shift;
    my($w,$h);
    
    my $cars= length($mine_field->height());
    my($format) = "%0". length($mine_field->height()). "u";
    
    foreach my $line (0.. $cars-1 ) {
	print " "x(length($mine_field->width())+1);
	
	foreach my $h (0.. $mine_field->height()) {
	    print substr(sprintf($format,$h),$line,1);
	}
	print "\n";
    }
    
    print 
	" "x(length($mine_field->width())),
	"+",
	"-"x($mine_field->height()+1),
	"+\n";
}

sub _end_field {
    my($mine_field) = shift;
    print 
	" "x(length($mine_field->width())),
	"+",
	"-"x($mine_field->height()+1),
	"+\n";
}

sub _start_line {
    my($mine_field) = shift;
    my($line) = shift;
    my($format) = "%0". length($mine_field->width()). "u|";
    printf($format,$line);
}

sub _end_line {
    print "|\n";
}

sub _map {
    my($mine_field) = shift;
    
    my($value) = shift;
    print $mine_field->{map}->{ $value };
}

sub _start_cell {1;}

sub _end_cell {1;}

=item $obj->_diff

Internal method used to print out the end game results, indicating any
wrongly marked or stepped fields.

=cut

sub _diff {
    my($field) = shift;
    my($mine_field) = $field->{'GAME'};
    my($w,$h) = @_;
    
    if($mine_field->shown($w,$h)) {
	return $mine_field->_at($w,$h);
    }
    elsif($mine_field->at($w,$h) eq 'X') {
	return 'X';
    }
    elsif($mine_field->at($w,$h) eq 'F') {
	if($mine_field->_at($w,$h) eq '*'){
	    return $mine_field->_at($w,$h);
	}
	else {
	    return 'f';
	}
    }
    return $mine_field->_at($w,$h);
}

=item AUTOLOAD 

Pass any unknown method calls to the contined object.

=cut

sub AUTOLOAD {
    my($game) = shift;
    
    # DESTROY messages should never be propagated.
    return if $AUTOLOAD =~ /::DESTROY$/;
    
    my($attr) = $AUTOLOAD;
    $attr =~ s/^.*:://;

    unless (  $game->{GAME}->can($attr)) {
      croak "Don't have a method of type $attr";
    }
    
    $game->{GAME}->$attr(@_);
}

=end for developers

=back

=head1 SEE ALSO

Games::Mines for more details of the base class.

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
