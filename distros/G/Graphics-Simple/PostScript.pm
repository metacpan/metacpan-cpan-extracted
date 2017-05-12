=head1 NAME

Graphics::Simple::PostScript -- implement Graphics::Simple in PostScript files

=head1 SYNOPSIS

	use Graphics::Simple;
	# use those operations

=head1 DESCRIPTION

The module C<Graphics::Simple::PostScript> is an implementation
of the C<Graphics::Simple> API.

=head1 DEVICE-DEPENDENT OPERATIONS

=head2 stop

Waiting is implemented by writing the current image as a snapshot to a file.
The problem is that this only applies to the one window - code that
has two windows will not show all the upgrades that GnomeCanvas shows.
This should be adressed somehow - the problem is that we don't want
to duplicate all the static images in other windows if only one is changing.

The files are currently written into C</tmp/>.

=cut


package Graphics::Simple::PostScript;

my $fileno = 'dump000';

@ISA = 'Graphics::Simple::Window';

sub _construct {
	my($type, $x, $y, $fn) = @_;
	$fn = sub { '/tmp/'.$fileno++.".ps" } if !defined $fn;
	bless {
		X => $x, 
		Y => $y, 
		FN => $fn
	}, $type;
}

sub _finish {
	$_[0]->_wait
}

sub _clear {
	delete $_[0]{Objs};
	delete $_[0]{Obj};
}

sub _colorstr {
	my($this, $color) = @_;
	if(!defined $color) {
		$color = $this->{Current_Color};
	}
	my $c = Graphics::Simple::get_float_color($color);
	" $c->[0] $c->[1] $c->[2] setrgbcolor ";
}

sub _widthstr {
	my($this, $width) = @_;
	if(!defined $width) {
		$width = $this->{Current_LineWidth};
	}
	" $width setlinewidth ";

}

sub _line {
	my $this = shift;
	my $name = shift;
	my $s = $this->_widthstr.$this->_colorstr."\n newpath ";
	my $f;
	while(@_) {
		my ($x,$y) = (shift,shift);
		$s .= " $x $y ".($f ? 'lineto ':'moveto ');
		$f = 1;
	}
	$this->{Obj}{$name} = $s." stroke ";
	push @{$this->{Objs}}, $name;
}

sub _ellipse {
	my($this, $name, $x1, $y1, $x2, $y2) = @_;
	my $xr = $x2-$x1; my $yr = $y2-$y1;
	my ($xsca, $ysca, $r);
	if($xr > $yr) {
		$xsca = 1;
		$ysca = $yr/$xr;
		$r = $xr;
	} else {
		$ysca = 1;
		$xsca = $xr/$yr;
		$r = $yr;
	}
	my $s = sprintf($this->_widthstr.$this->_colorstr." gsave newpath
		%f %f translate %f %f scale %f 0 moveto 0 0 %f 0 360 arc 
				",
		($x2+$x1)/2, ($y2+$y1)/2, 
		$xsca, $ysca,
		$r,
		$r);
	$this->{Obj}{$name} = $s." stroke grestore ";
	push @{$this->{Objs}}, $name;
}

sub _text {
	my($this, $name, $x, $y, $text) = @_;
}

sub _wait {
	my($this) = @_;
#	use Data::Dumper; print Dumper($this);
	my $fn = $this->{FN};
	$fn = $fn->() if(ref $fn);
	open PSOUT, ">$fn";
	for(@{$this->{Objs}}) {
		print PSOUT $this->{Obj}{$_};
	}
	print PSOUT " showpage \n";
	close PSOUT;
	print "Output written to '$fn'\n";
}

=head1 BUGS

Writes much too much code, e.g. by setting width and color for each object.
Should check if it is already set and leave the old setting and other
such optimizations.

=head1 AUTHOR

Copyright(C) Tuomas J. Lukka 1999. All rights reserved.
This software may be distributed under the same conditions as Perl itself.

=cut
