package Imager::DTP::Textbox;
use strict;
use Carp;
use Imager;
use vars qw($VERSION);

$VERSION = '0.04';

sub new {
	my $self = shift;
	my %o = @_;
	# define properties
	my $p = {
		lines   => [],
		leading => 150,
		width   => 0,
		height  => 0,
		halign  => '',
		valign  => '',
		wrapWidth  => 0,
		wrapHeight => 0,
		isUpdated  => 0, # check flag for _calcWidthHeight needs
	};
	$self = bless($p,$self);
	# set properties
	$self->setLeading(percent=>$o{leading});
	$self->setAlign(valign=>$o{valign},halign=>$o{halign});
	$self->setWrap(width=>$o{wrapWidth},height=>$o{wrapHeight});
	if(defined($o{text})){
		$self->setText(text=>$o{text},font=>$o{font});
		$self->setWspace(pixel=>$o{wspace});
	}
	if($o{xscale} || $o{yscale}){
		$self->setLetterScale(x=>$o{xscale},y=>$o{yscale});
	}
	return $self;
}

sub draw {
	my $self = shift;
	my %o = @_;
	# validation
	if($o{target} && ref($o{target}) !~ /^Imager(::.+)?$/){
		confess "target: must be an Imager Object";
	}
	$o{x} = 0 if(!$o{x});
	$o{y} = 0 if(!$o{y});
	# calculate width and height
	$self->_calcWidthHeight();
	# calculate text wrap
	$self->_calcWrap();
	# draw directly to target image
	if($o{target}){
		my($x,$y) = $self->_draw_getStartPos(x=>$o{x},y=>$o{y});
		$self->_draw_drawLines(target=>$o{target},x=>$x,y=>$y,debug=>$o{debug},others=>$o{others});
		return 1;
	# or return drawn Imager object
	}else{
		my $tmp = Imager->new(xsize=>$self->_getWidth(),
		          ysize=>$self->_getHeight(),channels=>3) or die $Imager::ERRSTR;
		$o{bgcolor} = '$FFFFFF' if(!$o{bgcolor});
		$tmp->box(filled=>1,color=>$o{bgcolor});
		$self->_draw_drawLines(target=>$tmp,debug=>$o{debug},others=>$o{others});
		return $tmp;
	}
}

sub _draw_drawLines {
	confess "_draw_drawLines - this is an abstract method";
}

sub _draw_getAlignPos {
	confess "_draw_getAlignPos - this is an abstract method";
}

sub _draw_getStartPos {
	confess "_draw_getStartPos - this is an abstract method";
}

sub _calcWidthHeight {
	confess "_calcWidthHeight - this is an abstract method";
}

sub _calcWrap {
	my $self = shift;
	# letter wrapping
	$self->_calcWrap_LetterStack();
	# line truncating
	$self->_calcWrap_LineStack();
	return 1;
}

sub _calcWrap_LetterStack {
	my $self = shift;
	my $wrapMax = $self->_calcWrap_LetterStack_getWrapMax();
	return undef if(!$wrapMax);
	my $lines = $self->getLines();
	my $li = 0;
	foreach my $line (@{$lines}){
		my $lineMax = $self->_calcWrap_LetterStack_getLineMax(line=>$line);
		if($wrapMax && $wrapMax < $lineMax){
			my $wi = 0;
			my $nowMax = 0;
			my $exceeded = 0;
			my $letters = $line->getLetters();
			# check exceedance
			while (1){
				my $ltr = $letters->[$wi];
				$nowMax += $self->_calcWrap_LetterStack_getLetterSize(letter=>$ltr);
				if($nowMax > $wrapMax){
					$exceeded = 1;
					last;
				}
				last if($wi == $#{$letters});
				$nowMax += $line->getWspace() if($wi < $#{$letters});
				$wi++;
			}
			# cut off exceeded letters
			if($exceeded){
				my @exceed = ();
				# line contains more than 1 letter & $wrapMax is less than 1 letter size
				if($wi == 0 && $#{$letters} > 0){
					@exceed = @{$letters}[1 .. $#{$letters}];
				# line contains only 1 letter & $wrapMax is less than 1 letter size
				}elsif($wi == 0 && $#{$letters} == 0){
					@exceed = ();
				# other than above (usual case)
				}else{
					# grab some more letters if it's in a middle of an alphabet word
					$wi = $self->_calcWrap_LetterStack_eExceed(wi=>$wi,
					      letters=>$letters);
					@exceed = @{$letters}[$wi .. $#{$letters}];
				}
				# delete space at beginning of exceed letters
				$self->_calcWrap_LetterStack_CutFrontSpace(exceed=>\@exceed);
				# cut off exceeded letters
				my $to = ($wi > 0)? $wi-1 : 0;
				@{$letters} = @{$letters}[0 .. $to];
				# create new line if needed
				if($li == $#{$lines}){
					my $newLine = $self->_getNewLineInstance(wspace=>$line->getWspace(),isWrap=>1);
					$newLine->{letters} = \@exceed;
					$newLine->_calcWidthHeight();
					push(@{$lines},$newLine);
				# un-shift exeeded letters to the later line
				}else{
					my $laterLine = $lines->[$li+1];
					# if the later line was a line created during calcWrap()
					if($laterLine->{isWrap} == 1){
						unshift(@{$laterLine->{letters}},@exceed);
						$laterLine->{isUpdated} = 0; # force re-calculation
						$laterLine->_calcWidthHeight();
					# or else add new line in between this and later line
					}else{
						my $newLine = $self->_getNewLineInstance(wspace=>$line->getWspace(),isWrap=>1);
						$newLine->{letters} = \@exceed;
						$newLine->_calcWidthHeight();
						@{$lines} = (@{$lines}[0 .. $li], $newLine, @{$lines}[$li+1 .. $#{$lines}]);
					}
				}
				# re-calculate width and height of the current line
				$line->{isUpdated} = 0; # register for re-calculation
			}
		}
		$li++;
	}
	# re-calculate width and height
	$self->{isUpdated} = 0;
	$self->_calcWidthHeight();
	return 1;
}

sub _calcWrap_LetterStack_getWrapMax {
	confess "_calcWrap_LetterStack_getWrapMax - this is an abstract method";
}
sub _calcWrap_LetterStack_getLineMax {
	confess "_calcWrap_LetterStack_getLineMax - this is an abstract method";
}
sub _calcWrap_LetterStack_getLetterSize {
	confess "_calcWrap_LetterStack_getLetterSize - this is an abstract method";
}

sub _calcWrap_LetterStack_eExceed {
	my $self = shift;
	my %o = @_;
	my $pattern = qr/[a-zA-Z0-9'!?%$(),.]/;
	# return if exceeded letter was not a single-byte character
	return $o{wi} if($o{letters}->[$o{wi}]->getText() !~ /$pattern/);
	my $i;
	for($i=$o{wi};$i>=0;$i--){
		my $t = $o{letters}->[$i]->getText();
		# find a word breaking spot
		last if($t =~ /\s/ || $t !~ /$pattern/);
	}
	# if $wi spot is at the beggining of line, don't count as exceed,
	# infact, find the end of the word and count that as exceed point.
	if($i+1 == 0){
		my $c;
		for($c=$o{wi};$c<=$#{$o{letters}};$c++){
			my $t = $o{letters}->[$c]->getText();
			# find a word breaking spot
			last if($t =~ /\s/ || $t !~ /$pattern/);
		}
		return $c;
	# else return the spot where the word starts
	}else{
		return $i+1;
	}
}

sub _calcWrap_LetterStack_CutFrontSpace {
	my $self = shift;
	my %o = @_;
	return undef if(@{$o{exceed}} == 0);
	my $firstLetter = $o{exceed}->[0];
	if($firstLetter->getText() =~ /\s/){
		shift(@{$o{exceed}});
		return 1;
	}
	return undef;
}

sub _calcWrap_LineStack {
	my $self = shift;
	my $wrapMax = $self->_calcWrap_LineStack_getWrapMax();
	return undef if(!$wrapMax);
	my $lines = $self->getLines();
	my $li = 0;
	my $nowMax = 0;
	my $lineMax = $self->_getMaxLetterSize();
	my $lineSpace = $self->_calcLineSpace();
	my $exceed = 0;
	foreach my $line (@{$lines}){
		$nowMax += $lineMax;
		if($nowMax > $wrapMax){
			$exceed = 1;
			last;
		}
		$nowMax += $lineSpace if($li < $#{$lines});
		$li++;
	}
	# cut off exceeded lines
	if($exceed){
		my $to = ($li == 0)? 0 : $li-1;
		@{$lines} = @{$lines}[0 .. $to];
		# re-calculate width and height if needed
		$self->{isUpdated} = 0;
		$self->_calcWidthHeight();
	}
	return 1;
}

sub _calcWrap_LineStack_getWrapMax {
	confess "_calcWrap_LineStack_getWrapMax - this is an abstract method";
}

sub _calcLineSpace {
	my $self = shift;
	my $base = $self->_getMaxLetterSize();
	return ($self->getLeading() / 100 - 1) * $base;
}

sub setText {
	my $self = shift;
	my %o = @_;
	# validation
	if(!defined($o{text}) || $o{text} eq ''){
		confess "text: must not be empty or null.";
	}
	$o{text} =~ s/\r\n/\n/g; # replate CR+LF to LF
	$o{text} =~ s/\r/\n/g;   # replate CR to LF
	# get last line object
	my $lastLine;
	if(@{$self->{lines}} > 0){
		$lastLine   = pop(@{$self->{lines}});
		my $letters = $lastLine->getLetters();
		$o{wspace}  = $lastLine->getWspace() if(!defined($o{wspace}));
		$o{font}    = $letters->[-1]{font} if(!defined($o{font}) && scalar @{$letters} > 0);
	}
	# validation for font object
	if(ref($o{font}) !~ /^Imager::Font(::.+)?$/){
		confess "font: must define an Imager::Font Object";
	}
	# clear current lines
	$self->{lines} = [] if(!$o{add});
	# parse by line feeds
	my(@lineTexts,$t,$len);
	($t) = ($o{text} =~ /^(\n+)/); # look for pre-\n's
	$len = ($t)? length($t) : 0;
	if($len > 0){
		push(@lineTexts,'') for (1 .. $len);
	}
	($t) = ($o{text} =~ /(\n+)$/); # look for post-\n's
	$len = ($t)? length($t) : 0;
	@lineTexts = split(/\n/,$o{text}); # split inner text by line feeds
	if($len > 0){
		push(@lineTexts,'') for (1 .. $len);
	}
	@lineTexts = ('') if(scalar @lineTexts == 0); # to create a blank line
	my $i=0;
	foreach my $text (@lineTexts){
		if($i == 0 && $lastLine && $o{add}){
			# add new texts to the end of last line
			$lastLine->setText(text=>$text,font=>$o{font},add=>1);
			push(@{$self->{lines}},$lastLine);
		}else{
			# create new Line instance if a clean blank line is needed
			my $newLine = $self->_getNewLineInstance(wspace=>$o{wspace});
			$newLine->setText(text=>$text,font=>$o{font});
			push(@{$self->{lines}},$newLine);
		}
		$i++;
	}
	$self->{isUpdated} = 0;
	return 1;
}

sub setWrap {
	my $self = shift;
	my %o = @_;
	# validation
	if($o{width} && $o{width} !~ /^\d+$/){
		confess "width: must be an integer ($o{width})";
	}
	if($o{height} && $o{height} !~ /^\d+$/){
		confess "height: must be an integer ($o{height})";
	}
	$self->{wrapWidth}  = $o{width} if($o{width});
	$self->{wrapHeight} = $o{height} if($o{height});
	$self->{isUpdated} = 0;
	return 1;
}

sub setAlign {
	my $self = shift;
	my %o = @_;
	if($o{halign} && $o{halign} !~ /^(left|center|right)$/){
		confess "halign: must be either of left/center/right ($o{h})";
	}
	if($o{valign} && $o{valign} !~ /^(top|center|bottom)$/){
		confess "valign: must be either of top/center/bottom ($o{v})";
	}
	$self->_setAlign_setDefault(%o);
	$self->{halign} = $o{halign} if($o{halign});
	$self->{valign} = $o{valign} if($o{valign});
	return 1;
}

sub setLeading {
	my $self = shift;
	my %o = @_;
	if($o{percent} && $o{percent} !~ /^\d+$/){
		confess "percent: must be a percentage numeral ($o{value})";
	}
	$self->{leading} = $o{percent} if($o{percent});
	$self->{isUpdated} = 0;
	return 1;
}

sub setWspace {
	my $self = shift;
	my %o = @_;
	foreach my $line (@{$self->getLines()}){
		$line->setWspace(@_);
	}
	return 1;
}

sub setLetterScale {
	my $self = shift;
	my %o = @_;
	foreach my $line (@{$self->getLines()}){
		$line->setLetterScale(@_);
	}
	return 1;
}

sub getWidth {
	my $self = shift;
	$self->_calcWidthHeight();
	$self->_calcWrap();
	return $self->_getWidth();
}
sub getHeight {
	my $self = shift;
	$self->_calcWidthHeight();
	$self->_calcWrap();
	return $self->_getHeight();
}
sub getLines {
	return shift->{lines};
}
sub getLeading {
	return shift->{leading};
}
sub getHalign {
	return shift->{halign};
}
sub getValign {
	return shift->{valign};
}
sub getWrapWidth {
	return shift->{wrapWidth};
}
sub getWrapHeight {
	return shift->{wrapHeight};
}
sub _getWidth {
	return shift->{width};
}
sub _getHeight {
	return shift->{height};
}
sub _getMaxLetterSize {
	confess "_getMaxLetterSize - this is an abstract method";
}

1;
__END__

=pod

=head1 NAME

Imager::DTP::Textbox - multi-byte text handling module with text wrapping and line alignment, for use with L<Imager>.

=head1 SYNOPSIS

   use Imager::DTP::Textbox::Horizontal;  # or Vertical
   
   # first, define font & text string
   my $font  = Imager::Font->new(file=>'path/to/foo.ttf',type=>'ft2',
               size=>14,color=>'#000000',aa=>1);
   my $text  = 'The Greater Of Two Evils';
   
   # create instance
   my $tb = Imager::DTP::Textbox::Horizontal->new(
            text=>$text,font=>$font);
   
   # draw the text string on target image
   my $target = Imager->new(xsize=>250,ysize=>250);
   $target->box(filled=>1,color=>'#FFFFFF'); # with white background
   $tb->draw(target=>$target,x=>10,y=>10);
   
   # and write out image to file
   $target->write(file=>'result.jpg',type=>'jpeg');

=head1 DESCRIPTION

Imager::DTP::Textbox is a module intended for handling sentences and paragraphs consisted with multi-byte characters, such as Japanese and Chinese.  It supports text wrapping and line alignment, and is able to draw text string vertically from top to bottom as well.  All the text string provided (by setText() method) will be splitted by "\n", and each chunk will be turned into Imager::DTP::Line instance internally.  So in another words, Imager::DTP::Textbox can be described as "a big box to put lines and letters in order". It's like WWW Browser's textarea input, or Adobe Illustrator's textbox tool.

   # creating instance - basic way
   my $tb = Imager::DTP::Textbox::Horizontal->new();
   $tb->setText(text=>$text,font=>$font); # set text with font
   $tb->setWspace(pixel=>5); # set space between letters
   $tb->setLeading(percent=>180); # set space between lines
   $tb->setAlign(halign=>'left',valign=>'top'); # set text alignment
   $tb->setWrap(width=>200,height=>150); # set text wrapping
   $tb->setLetterScale(x=>1.2,y=>0.5); # set letter transform scale
   
   # creating instance - or the shorcut way
   my $tb = Imager::DTP::Textbox::Horizontal->new(
               text=>$text,     # set text
               font=>$font,     # set font
               wspace=>5,       # set word distance (pixels)
               leading=>150,    # set line distance (percent)
               halign=>'left',  # set horizontal alignment
               valign=>'top',   # set vertical alignment
               wrapWidth=>200,  # set text wrap width
               wrapHeight=>180, # set text wrap height
               xscale=>1.5,     # set letter transformation x scale
               yscale=>0.5,     # set letter transformation y scale
            );

=head1 CLASS RELATION

Imager::DTP::Textbox is an ABSTRACT CLASS. The extended class would be Imager::DTP::Textbox::Horizontal and Imager::DTP::Textbox::Vertical.  (Yes, I know the package name is much longer than it should be... I took the advantage of comprehension).  So you must "use" the extended class (either of Horizonal or Vertical), and not the Imager::DTP::Textbox itself.  The difference between Horizontal and Vertical is as follows:

=over

=item Imager::DTP::Textbox::Horizontal

letters are drawn from left to right, line stacks from top to bottom.

=item Imager::DTP::Textbox::Vertical

letters are drawn from top to bottom, line stacks from right to left.

=back

=head1 METHODS

=head2 BASIC METHODS

=head3 new

Can be called with or without options.

   use Imager::DTP::Textbox::Horizontal;
   my $tb = Imager::DTP::Textbox::Horizontal->new();
   
   # or set all/any options at the same time
   my $font  = Imager::Font->new(file=>'path/to/foo.ttf',type=>'ft2',
               size=>14);
   my $text  = "Hello me... meet the real me.\n";
      $text .= "And my misfits way of life.";
   my $tb = Imager::DTP::Textbox::Horizontal->new(text=>$text,
            font=>$font, wspace=>5, leading=>150, halign=>'left',
            valign=>'top', wrapWidth=>200, wrapHeight=>180,
            xscale=>1.2, yscale=>0.5);

=head3 setText

Set text string to the instance.  Text must not be undef or '', and font option is not optional either.  For multi-byte letters/characters, text must be encoded to utf8, with it's internal utf8-flag ENABLED (This could be done by using utf8::decode() method).

   my $font  = Imager::Font->new(file=>'path/to/foo.ttf',type=>'ft2',
               size=>14);
   my $text  = 'Smashing through the boundaries,';
      $text .= 'Lunacy has found me...';
   $tb->setText(text=>$text,font=>$font);

By default, each time the method is called, it replaces the previous text with the provided new text.  But by putting the "add" option, it will add new text to the end of the current text.

   my $moreText = 'Cannot stop the battery!';
   $tb->setText(text=>$moreText,add=>1);

Font is optional this time.  If there is any previous text set, the new text will automatically inherit the font preference of last line, last letter's font preference.

The following characters will be translated to corresponding string internally:

=over

=item \r => \n

=item \r\n => \n

=back

"\n" will be used as a delimiter for splitting text string to each line object, and "\t" will stay the same until the time of draw() method call (see description of L<Imager::DTP::Line>->draw() method for what will happen then).

=head3 setWspace

Set size for blank spaces inserted in between each letters.  See L<Imager::DTP::Line>->setWspace() for 
more description.

   # setting a 5 pixel word space
   $tb->setWspace(pixel=>5);

=head3 setLeading

The word "leading" in DTP application means "space between two consecutive lines".  Thus, by setting some value (in percentage) here will affect the distance between each line.  The default value is 150%, so setting any value greater than this will widen the distance, and setting smaller value (like 50%) will make the lines come closer (and with 50%, it will probably end up with two lines overlapping a little).

   # set leading to 180%
   $tb->setLeading(percent=>180);

The percentage is based on the ascent value of a letter, which has the maximum value out of all the letters held inside.

=head3 setAlign

Set horizontal and vertical alignment of lines, as if viewed from draw() method's x and y point.

   $tb->setAlign(halign=>'right',valign=>'bottom');

Available options are:

=over

=item halign (horizontal alignment)

left / center / right

=item valign (vertical alignment)

top / center / bottom

=back

The default alignment for each extended class is as follows:

=over

=item Imager::DTP::Textbox::Horizontal

halign => 'left'
valign => 'top'

=item Imager::DTP::Textbox::Vertical

halign => 'right'
valign => 'top'

=back

=head3 setWrap

Set the maximum width and height of the bounding box, for the lines and letters to be wrapped inside.  By setting these values to 0 will disable text wrapping (which is the default setting).  Width will always be the horizontal measure, and height will be the vertical measure, no matter which extended class you choose (Imager::DTP::Textbox::Horizontal or Vertical).

   # set x axis bounding to 200 pixels
   $tb->setWrap(width=>200);
   
   # set both x/y axis bounding to 100 pixels
   $tb->setWrap(width=>100,height=>100);

Wrapping logic is letter-based, meaning text may be wrapped right in the middle of a "word", which is a normal wrapping rule for multi-byte texts (at least for Japanese, yes) in DTP applications.  But with single-byte character word, this logic will make the sentence look ugly, so I've added some logic for single-byte character words to "always wrap at the beginning of the word".  With it, alphabetical sentences and paragraphs will look OK, although hyphenation is not implemented (yet).

=head3 setLetterScale

Setting x/y scale will make each letter transform to the specified ratio.  See <Imager::DTP::Letter>->setScale() method for further description.

   # make width of each letter to 80%
   $tb->setLetterScale(x=>0.8);
   
   # make width 120% and height 60%
   $tb->setLetterScale(x=>1.2,y=>0.6);

=head3 draw

Draw all the lines and letters held with-in, to the target image (Imager object).

   my $target = Imager->new(xsize=>250,ysize=>250);
   $tb->draw(target=>$target,x=>10,y=>10);

Each letter is drawn with Imager::DTP::Letter->draw() method, which internally is using Imager->String() method, so you can pass any extra Imager::String options to it by setting in 'others' option (See more details in L<Imager::DTP::Letter>->draw() method description).

   # passing Imager::String options
   $tb->draw(target=>$target,x=>10,y=>10,others=>{aa=>1});

There is an extra debug option, which will draw a 'width x height' dark gray box underneath the textbox, a light grax box underneath each line, and a black bounding box for each letters. Handy for checking each object's bounding size/position.

   # debug mode
   $tb->draw(target=>$target,x=>10,y=>10,debug=>1);

=head4 Obtaining text drawn image

By NOT passing any target option, the method will return an Imager object, with all the lines and letters drawn to it.  This is usefull when you want to perform some transformation (such as X/Y scaling, cropping, color filtering) to these text string.

   # obtaining text drawn image
   # x/y position will be forced at (0,0)
   my $newimg = $tb->draw();
   
   # apply some Imager's transformation method
   my $scaled = $newimg->scaleX(pixels=>100);

=head2 GETTER METHODS

Calling these methods will return a property value corresponding to the method name.

=head3 getLines

Returns a reference (pointer) to an array containing all the Imager::DTP::Line object held internally.

=head3 getLeading

Returns the current value of leading.

=head3 getWidth

Return the actuall width of textbox.  Actuall here means "not the wrapping width", but the precise width of the lines and letters held inside.

=head3 getHeight

Return the actuall height of textbox.  Actuall here means "not the wrapping height", but the precise height of the lines and letters held inside.

=head3 getHalign

Returns the current value of horizontal alignment.

=head3 getValign

Returns the current value of vertical alignment.

=head3 getWrapWidth

Returns the current value of horizontal text wrap bounding.

=head3 getWrapHeight

Returns the current value of vertical text wrap bounding.

=head1 TODO

=over

=item * hyphenation with single-byte characters.

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

