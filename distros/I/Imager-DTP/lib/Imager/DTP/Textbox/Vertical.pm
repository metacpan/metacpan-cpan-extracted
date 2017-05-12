package Imager::DTP::Textbox::Vertical;
use base Imager::DTP::Textbox;
use Imager::DTP::Line::Vertical;
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
		my $dbgx = $self->_draw_getAlignPos(x=>$x);
		my $width  = ($self->getWrapWidth())?  $self->getWrapWidth()  : $self->_getWidth();
		my $height = ($self->getWrapHeight())? $self->getWrapHeight() : $self->_getHeight();
		$o{target}->box(filled=>1,color=>'#BBBBBB',xmin=>$dbgx-$width,ymin=>$y,
	                    xmax=>$dbgx,ymax=>$y+$height);
	}
	my $lineWidth = $self->_getMaxLetterSize();
	my $lineSpace = $self->_calcLineSpace();
	foreach my $line (@{$self->getLines()}){
		# line flaws from right to left
		$x -= $lineSpace if($i > 0);
		$x -= $lineWidth;
		# vertical align
		my $liney = $y;
		if($self->getValign() eq 'bottom'){
			$liney += $self->_getHeight() - $line->getHeight();
		}elsif($self->getValign() eq 'center'){
			$liney += ( $self->_getHeight() - $line->getHeight() )/2;
		}
		# horizontal align
		my $linex = $self->_draw_getAlignPos(x=>$x);
		# draw line
		$line->draw(target=>$o{target},x=>$linex,y=>$liney,leading=>$lineWidth,
		            others=>$o{others},debug=>$o{debug}) or die $line->errstr;
		$i++;
	}
	return 1;
}

sub _draw_getAlignPos {
	my $self = shift;
	my %o = @_;
	if($self->getHalign() eq 'left'){
		$o{x} += $self->_getWidth();
	}elsif($self->getHalign() eq 'center'){
		$o{x} += $self->_getWidth()/2;
	}
	return $o{x};
}

sub _draw_getStartPos {
	my $self = shift;
	my %o = @_;
	if($self->getValign() eq 'bottom'){
		return ($o{x},$o{y}-$self->_getHeight());
	}elsif($self->getValign() eq 'center'){
		return ($o{x},$o{y} - ($self->_getHeight()/2) );
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
	my $lineWidth = $self->_getMaxLetterSize();
	my $lineSpace = $self->_calcLineSpace();
	my($w,$h,$i) = qw(0 0 0);
	foreach my $line (@{$self->getLines()}){
		$w += $lineWidth;
		$w += $lineSpace if ($i < $#{$self->getLines()});
		$h  = ($line->getHeight() > $h) ? $line->getHeight() : $h;
		$i++;
	}
	$self->{width}  = $w;
	$self->{height} = $h;
	$self->{isUpdated} = 1;
	return 1;
}

sub _calcWrap_LetterStack_getWrapMax {
	return shift->getWrapHeight();
}

sub _calcWrap_LetterStack_getLineMax {
	my $self = shift;
	my %o = @_;
	return $o{line}->getHeight();
}

sub _calcWrap_LetterStack_getLetterSize {
	my $self = shift;
	my %o = @_;
	return $o{letter}->getGlobalAscent() - $o{letter}->getGlobalDescent();
}

sub _calcWrap_LineStack_getWrapMax {
	return shift->getWrapWidth();
}

sub _setAlign_setDefault {
	my $self = shift;
	$self->{halign} = 'right' if(!$self->{halign});
	$self->{valign} = 'top'  if(!$self->{valign});
	return 1;
}

sub _getMaxLetterSize {
	my $self = shift;
	my $widest=0;
	foreach my $line (@{$self->getLines()}){
		$widest = ($line->getWidth() > $widest)? $line->getWidth() : $widest;
	}
	return $widest;
}

sub _getNewLineInstance {
	my $self = shift;
	return Imager::DTP::Line::Vertical->new(@_);
}

1;
__END__

=pod

=head1 NAME

Imager::DTP::Textbox::Vertical - extended class of Imager::DTP::Textbox.

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
