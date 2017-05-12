package Imager::DTP::Line;
use strict;
use Carp;
use utf8;
use Imager::DTP::Letter;
use vars qw($VERSION);

$VERSION = '0.05';

sub new {
	my $self = shift;
	my %o = @_;
	my $p = {
		letters   => [],
		width     => 0,
		height    => 0,
		ascent    => 0,
		descent   => 0,
		wspace    => 0,
		# check flag for _calcWidthHeight needs
		isUpdated => 0,
		# check flag enabled for lines created during text-wrap
		isWrap    => (defined($o{isWrap}))? $o{isWrap} : 0,
	};
	$self = bless($p,$self);
	$self->setWspace(pixel=>$o{wspace}) if($o{wspace});
	if($o{text}){
		$self->setText(text=>$o{text},font=>$o{font});
	}
	if($o{xscale} || $o{yscale}){
		$self->setLetterScale(x=>$o{xscale},y=>$o{yscale});
	}
	return $self;
}

sub draw {
	confess "draw - this is an abstract method";
}

sub setText {
	my $self = shift;
	my %o = @_;
	# get last letter's font preference
	if(!defined($o{font}) && @{$self->{letters}} > 0){
		$o{font} = $self->{letters}[-1]{font};
	}
	# validation
	if(ref($o{font}) !~ /^Imager::Font(::.+)?$/){
		confess "font: must define an Imager::Font Object";
	}
	$o{text} = ' ' if(!defined($o{text})); # to create a blank line
	$o{text} =~ s/\r\n/\n/g; # replace CR+LF to LF
	$o{text} =~ s/\r/\n/g;   # replace CR to LF
	$o{text} =~ s/\n/ /g;    # replace line feeds to space
	$o{text} =~ s/\t/    /g; # replace tabs to 4 spaces
	# clear current letters
	$self->{letters} = [] if(!$o{add});
	$self->_setText_parse(text=>$o{text},font=>$o{font});
	$self->{isUpdated} = 0;
	return 1;
}

sub _setText_parse {
	confess "_setText_parse - this is an abstract method";
}

sub setWspace {
	my $self = shift;
	my %o = @_;
	if(defined($o{pixel}) && $o{pixel} !~ /^(-)?\d+$/){
		confess "pixel: must be an integer ($o{pixel})";
	}
	$self->{wspace} = (defined $o{pixel})? $o{pixel} : 0;
	$self->{isUpdated} = 0;
	return 1;
}

sub setLetterScale {
	my $self = shift;
	my %o = @_;
	foreach my $ltr (@{$self->getLetters()}){
		$ltr->setScale(@_);
	}
	return 1;
}

sub _calcWidthHeight {
	confess "_calcWidthHeight - this is an abstract method";
}

sub getLetters {
	return shift->{letters};
}
sub getWidth {
	my $self = shift;
	$self->_calcWidthHeight();
	return $self->{width};
}
sub getHeight {
	my $self = shift;
	$self->_calcWidthHeight();
	return $self->{height};
}
sub getAscent {
	my $self = shift;
	$self->_calcWidthHeight();
	return $self->{ascent};
}
sub getDescent {
	my $self = shift;
	$self->_calcWidthHeight();
	return $self->{descent};
}
sub getWspace {
	return shift->{wspace};
}

1;
__END__

=pod

=head1 NAME

Imager::DTP::Line - line handling module for Imager::DTP package.

=head1 SYNOPSIS

   use Imager::DTP::Line::Horizontal;  # or Vertical
   
   # first, define font & text string
   my $font = Imager::Font->new(file=>'path/to/foo.ttf',type=>'ft2',
              size=>16,color=>'#000000',aa=>1);
   my $text = 'master of puppets';
   
   # create instance
   my $line = Imager::DTP::Line::Horizontal->new(text=>$text,
              font=>$font);
   
   # draw the text string on target image
   my $target = Imager->new(xsize=>250,ysize=>50);
   $target->box(filled=>1,color=>'#FFFFFF'); # with white background
   $line->draw(target=>$target,x=>10,y=>10);
   
   # and write out image to file
   $target->write(file=>'result.jpg',type=>'jpeg');

=head1 DESCRIPTION

Imager::DTP::Line is a module intended for handling chunk of letters lined-up in a single vector, out of the whole text string (sentence or paragraph).  Here, the word "Line" is meant to be "a single row", "a single row in a text-wrapped textbox", and not "1-pixel thick line" as in graphical meaning.  The text string provided (by setText() method) will be parsed into letters, and each letter will be turned into Imager::DTP::Letter instance internally.  Thus, Imager::DTP::Line could be understood as "a content holder for Imager::DTP::Letter instances", or "a box to put Letters in order". Each letter could hold their own font-preferences (like face/size/color), and this could be done by adding text (using setText() method) with different font-preferences one-by-one.  Then, you'll only need to call draw() method once to draw all those letters.

   # creating instance - basic way
   my $line = Imager::DTP::Line::Horizontal->new();
   $line->setText(text=>$text,font=>$font); # set text with font
   $line->setWspace(pixel=>5); # set space between letters
   $line->setLetterScale(x=>1.2,y=>0.5); # set letter transform scale
   
   # creating instance - or the shorcut way
   my $line = Imager::DTP::Line::Horizontal->new(text=>$text,
              font=>$font, wspace=>5, xscale=>1.2, yscale=>0.5);

=head1 CLASS RELATION

Imager::DTP::Line is an ABSTRACT CLASS. The extended class would be Imager::DTP::Line::Horizontal and Imager::DTP::Line::Vertical.  So you must "use" the extended class (either of Horizonal or Vertical), and not the Imager::DTP::Line itself.  The difference between Horizontal and Vertical is as follows:

=over

=item Imager::DTP::Line::Horizontal

letters are drawn from left to right.

=item Imager::DTP::Line::Vertical

letters are drawn from top to bottom.

=back

=head1 METHODS

=head2 BASIC METHODS

=head3 new

Can be called with or without options.

   use Imager::DTP::Line::Horizontal;
   my $line = Imager::DTP::Line::Horizontal->new();
   
   # or perform setText & setWspace method at the same time
   my $font = Imager::Font->new(file=>'path/to/foo.ttf',type=>'ft2',
              size=>16);
   my $text = 'I am the law';
   my $line = Imager::DTP::Line::Horizontal->new(text=>$text,
              font=>$font,wspace=>5);
   
   # also, can setLetterScale at the same time too.
   my $line = Imager::DTP::Line::Horizontal->new(text=>$text,
              font=>$font, wspace=>5, xscale=>1.2, yscale=>0.5);

=head3 setText

Set text string to the instance.  Text is optional (without text, it'll act as a blank-line), but when provided, font option must also be provided along with.  For multi-byte letters/characters, text must be encoded to utf8, with it's internal utf8-flag ENABLED (This could be done by using utf8::decode() method).

   my $font = Imager::Font->new(file=>'path/to/foo.ttf',type=>'ft2',
              size=>16);
   my $text = 'peace sells';
   $line->setText(text=>$text,font=>$font);

By default, when each time the method is called, it replaces the previous text with the provided new text.  But by putting the "add" option, it will add new text to the end of the current text.

   # as from above sample, this will make
   # the internal text to "peace sells but whos buying?"
   my $moreText = ' but whos buying?';
   $line->setText(text=>$moreText,add=>1);

Font is optional this time.  If there is any previous text set, the new text will automatically inherit the font preference of the previous text.

The following characters will be translated to corresponding string internally:

=over

=item \r => \n

=item \r\n => \n

=item \n => ' ' (blank space)

=item \t => '    ' (4 blank space)

=back

=head3 setWspace

Wspace is a blank space between each letters.  By setting a value (in pixels), a blank space will be inserted in between each letters.  Usefull with multi-byte characters, especially with vertical lines, adding much readability to it.  The default value is 0.

   # setting a 5 pixel word space
   $line->setWspace(pixel=>5);

=head3 setLetterScale

Setting x/y scale will make each letter transform to the specified ratio.  See <Imager::DTP::Letter>->setScale() method for further description.

   # make width of each letter to 80%
   $line->setLetterScale(x=>0.8);
   
   # make width 120% and height 60%
   $line->setLetterScale(x=>1.2,y=>0.6);

=head3 draw

Draw letters in a single vector, to the target image (Imager object).

   my $target = Imager->new(xsize=>250,ysize=>50);
   $line->draw(target=>$target,x=>10,y=>10);

Each letter is drawn with Imager::DTP::Letter->draw() method, which internally is using Imager->String() method, so you can pass any extra Imager::String options to it by setting in 'others' option (See more details in L<Imager::DTP::Letter>->draw() method description).

   # passing Imager::String options
   $line->draw(target=>$target,x=>10,y=>10,others=>{aa=>1});

There is an extra debug option, which will draw a 'width x height' light gray box underneath, and a gray bounding box fr each letters. Handy for checking each object's bounding size/position.

   # debug mode
   $line->draw(target=>$target,x=>10,y=>10,debug=>1);

=head2 GETTER METHODS

Calling these methods will return a property value corresponding to the method name.

=head3 getLetters

Returns a reference (pointer) to an array containing all the Imager::DTP::Letter object held internally.

=head3 getWidth

Returns the total width of line, meaning sum of all the wspaces in between, and each letter's advanced width.

=head3 getAscent

Compares each letter's ascent, and returns the maximum value.

=head3 getDescent

Compares each letter's descent, and returns the minimum value (since descent is usually negative integers).

=head3 getHeight

Returns the sum of getAscent() + (-getDescent()).  This will be the total height of the line.

=head3 getWspace

Returns the current value of word space.

=head1 BUGS

I can't figure out a way to call vertical-fonts inplemented inside multi-byte fonts.  Thus with Imager::DTP::Line::Vertical, punctuation character's position will be weird & odd, since it's just using normal horizontal fonts.  There seems to be a report of success with LaTex + Freetype...  need more research on it.

=head1 TODO

=over

=item * base-line alignment (align=>1)

=item * figure out a way to use vertical-fonts in Imager::DTP::Line::Vertical

=item * change Carp-only error handling to something more elegant.

=back

=head1 AUTHOR

Toshimasa Ishibashi, <iandeth99@ybb.ne.jp>

=head1 COPYRIGHT & LICENSE

Copyright 2005 Toshimasa Ishibashi, all rights reserved.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

L<Imager>, L<Imager::DTP>

=cut
