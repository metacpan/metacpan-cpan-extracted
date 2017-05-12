package Imager::DTP::Line::Vertical;
use base Imager::DTP::Line;
use strict;
use vars qw($VERSION);

$VERSION = '0.03';

sub draw {
	my $self = shift;
	my %o = @_;
	my $x = ($o{x})? $o{x} : 0;
	my $y = ($o{y})? $o{y} : 0;
	# re-calculate bounding box
	$self->_calcWidthHeight();
	my $lineWidth = ($o{leading})? $o{leading} : $self->getWidth();
	# draw box - debug
	if($o{debug}){
		$o{target}->box(filled=>1,color=>'#EFEFEF',xmin=>$x,ymin=>$y,xmax=>$x+$lineWidth,
		                ymax=>$y+$self->getHeight());
	}
	foreach my $ltr (@{$self->getLetters()}){
		my $nowx =  sprintf("%.0f",($lineWidth - $ltr->getAdvancedWidth()) / 2) + $x;
		$ltr->draw(target=>$o{target},x=>$nowx,y=>$y,debug=>$o{debug},
		           others=>$o{others});
		$y += $ltr->getGlobalAscent() - $ltr->getGlobalDescent + $self->getWspace();
	}
	return 1;
}

sub _calcWidthHeight {
	my $self = shift;
	return undef if($self->{isUpdated});
	return undef if(@{$self->getLetters()} == 0);
	my %o = @_;
	my ($w,$h,$a,$d) = qw(0 0 0 0);
	my $wspace = $self->getWspace();
	foreach my $ltr (@{$self->getLetters()}){
		$ltr->_calcWidthHeight();
		$w  = ($ltr->getWidth() > $w)? $ltr->getWidth() : $w;
		$h += $ltr->getGlobalAscent() - $ltr->getGlobalDescent + $wspace;
		$a  = ($ltr->getGlobalAscent() > $a)? $ltr->getGlobalAscent() : $a;
		# remember, descent is a negative integer
		$d  = ($ltr->getGlobalDescent() < $d)? $ltr->getGlobalDescent() : $d;
	}
	$h -= $wspace; # don't need the last wspace
	$self->{height}  = $h;
	$self->{width}   = $w;
	$self->{ascent}  = $a;
	$self->{descent} = $d;
	$self->{isUpdated} = 1;
	return 1;
}

sub _setText_parse {
	my $self = shift;
	my %o = @_;
	my ($i,$skip) = qw(0 0);
	my @text = split(//,$o{text});
	foreach my $t (@text){
		if($skip){
			$skip=0; $i++; next;
		}
		my $ltr;
		# if special letter
		if($self->_isDoubleDigitNum($i,\@text)){
			$ltr = Imager::DTP::Letter->new(text=>$t.$text[$i+1],font=>$o{font});
			# skip the next $t loop
			$skip=1;
		# normal text
		}else{
			$ltr = Imager::DTP::Letter->new(text=>$t,font=>$o{font});
		}
		push(@{$self->{letters}},$ltr) if($ltr);
		$i++;
	}
	return 1;
}

sub _isDoubleDigitNum {
	my ($self,$i,$txt) = @_;
	return ( $txt->[$i] =~ /[0-9]/  &&
			(defined($txt->[$i+1])  && $txt->[$i+1] =~ /[0-9]/) && 
			(!defined($txt->[$i-1]) || (defined($txt->[$i-1]) && $txt->[$i-1] !~ /[0-9]/)) &&
			(!defined($txt->[$i+2]) || (defined($txt->[$i+2]) && $txt->[$i+2] !~ /[0-9]/)) );
}

sub _isTwoCapitalLetters {
	my ($self,$i,$txt) = @_;
	return ( $txt->[$i] =~ /[A-Z]/  &&
			(defined($txt->[$i+1])  && $txt->[$i+1] =~ /[A-Z]/) && 
			(!defined($txt->[$i-1]) || (defined($txt->[$i-1]) && $txt->[$i-1] !~ /[A-Z]/)) &&
			(!defined($txt->[$i+2]) || (defined($txt->[$i+2]) && $txt->[$i+2] !~ /[A-Z]/)) );
}

1;
__END__

=pod

=head1 NAME

Imager::DTP::Line::Vertical - extended class of Imager::DTP::Line.

=head1 SYNOPSIS

See L<Imager::DTP::Line> for synopsis and description.

=head1 DESCRIPTION

=head2 Two digit numeral will be parsed as one letter automatically.

With most of commercial publication (in my country - Japan), two digit numerals are printed as one letter in vertical writings.  Since that, I've implemented the same logic in this module.  If you don't want this to happen, add "return undef;" to the second line in _isDoubleDigitNum() method, or let me know and I'll add a option to disable it.

=head1 AUTHOR

Toshimasa Ishibashi, <iandeth99@ybb.ne.jp>

=head1 COPYRIGHT & LICENSE

Copyright 2005 Toshimasa Ishibashi, all rights reserved.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

L<Imager>, L<Imager::DTP>

=cut
