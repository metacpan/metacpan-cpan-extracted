package Imager::DTP::Textbox::Horizontal;
use base Imager::DTP::Textbox;
use Imager::DTP::Line::Horizontal;
use strict;
use vars qw($VERSION);

$VERSION = '0.03';

sub _draw_drawLines {
	my $self = shift;
	my %o = @_;
	my $i=0;
	my $x=($o{x})? $o{x} : 0;
	my $y=($o{y})? $o{y} : 0;
	# draw box for debug
	if($o{debug}){
		my $dbgy = $self->_draw_getAlignPos(y=>$y);
		my $width  = ($self->getWrapWidth())?  $self->getWrapWidth()  : $self->_getWidth();
		my $height = ($self->getWrapHeight())? $self->getWrapHeight() : $self->_getHeight();
		$o{target}->box(filled=>1,color=>'#BBBBBB',xmin=>$x,ymin=>$dbgy,
	                    xmax=>$x+$width,ymax=>$dbgy+$height);
	}
	my $lineHeight = $self->_getMaxLetterSize();
	my $lineSpace  = $self->_calcLineSpace();
	foreach my $line (@{$self->getLines()}){
		# line flaws top to down
		if($i > 0){
			$y += $lineHeight;
			$y += $lineSpace;
		}
		# horizontal align
		my $linex = $x;
		if($self->getHalign() eq 'right'){
			$linex += $self->_getWidth() - $line->getWidth();
		}elsif($self->getHalign() eq 'center'){
			$linex += ( $self->_getWidth() - $line->getWidth() )/2;
		}
		# vertical align
		my $liney = $self->_draw_getAlignPos(y=>$y);
		# draw line
		$line->draw(target=>$o{target},x=>$linex,y=>$liney,leading=>$lineHeight,
		            others=>$o{others},debug=>$o{debug}) or die $line->errstr;
		$i++;
	}
	return 1;
}

sub _draw_getAlignPos {
	my $self = shift;
	my %o = @_;
	if($self->getValign() eq 'bottom'){
		$o{y} -= $self->_getHeight();
	}elsif($self->getValign() eq 'center'){
		$o{y} -= $self->_getHeight()/2;
	}
	return $o{y};
}

sub _draw_getStartPos {
	my $self = shift;
	my %o = @_;
	if($self->getHalign() eq 'right'){
		return ($o{x}-$self->_getWidth(),$o{y});
	}elsif($self->getHalign() eq 'center'){
		return ( $o{x} - ($self->_getWidth()/2), $o{y} );
	}else{
		return ($o{x},$o{y});
	}
}

sub _calcWidthHeight {
	my $self = shift;
	return undef if($self->{isUpdated});
	foreach my $line (@{$self->getLines()}){
		$line->_calcWidthHeight();
	}
	my($w,$h,$i) = qw(0 0 0);
	my $lineHeight = $self->_getMaxLetterSize();
	my $lineSpace  = $self->_calcLineSpace();
	foreach my $line (@{$self->getLines()}){
		$h += $lineHeight;
		$h += $lineSpace if($i < $#{$self->getLines()});
		$h += -$line->getDescent() if($i == $#{$self->getLines()});
		$w  = ($line->getWidth() > $w) ? $line->getWidth() : $w;
		$i++;
	}
	$self->{width}  = $w;
	$self->{height} = $h;
	$self->{isUpdated} = 1;
	return 1;
}

sub _calcWrap_LetterStack_getWrapMax {
	return shift->getWrapWidth();
}

sub _calcWrap_LetterStack_getLineMax {
	my $self = shift;
	my %o = @_;
	return $o{line}->getWidth();
}

sub _calcWrap_LetterStack_getLetterSize {
	my $self = shift;
	my %o = @_;
	return $o{letter}->getAdvancedWidth();
}

sub _calcWrap_LineStack_getWrapMax {
	return shift->getWrapHeight();
}

sub _setAlign_setDefault {
	my $self = shift;
	$self->{halign} = 'left' if(!$self->{halign});
	$self->{valign} = 'top'  if(!$self->{valign});
	return 1;
}

sub _getMaxLetterSize {
	my $self = shift;
	my $highest=0;
	foreach my $line (@{$self->getLines()}){
		$highest = ($line->getAscent() > $highest)? $line->getAscent() : $highest;
	}
	return $highest;
}

sub _getNewLineInstance {
	my $self = shift;
	return Imager::DTP::Line::Horizontal->new(@_);
}

1;
__END__

=pod

=head1 NAME

Imager::DTP::Textbox::Horizontal - extended class of Imager::DTP::Textbox.

=head1 SYNOPSIS

See L<Imager::DTP::Textbox> for synopsis and description.

=head1 AUTHOR

Toshimasa Ishibashi, <iandeth99@ybb.ne.jp>

=head1 COPYRIGHT & LICENSE

Copyright 2005 Toshimasa Ishibashi, all rights reserved.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

L<Imager>, L<Imager::DTP>

=cut
