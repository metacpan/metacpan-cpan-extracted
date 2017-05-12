=head1 NAME

Graphics::Simple::TkCanvas -- implement Graphics::Simple using Tk Canvas

=head1 SYNOPSIS

	use Graphics::Simple;
	# use those operations

=head1 DESCRIPTION

The module C<Graphics::Simple::TkCanvas> is an implementation
of the C<Graphics::Simple> API.

=head1 DEVICE-DEPENDENT OPERATIONS

=head2 stop

Waiting is implemented by waiting for a button click in any of the windows
managed by this module.

=cut

use strict;
print "GSTK\n";

package Graphics::Simple::TkCanvas;
use strict;

use base 'Graphics::Simple::Window';

use Tk;
use Tk::Canvas;

use vars qw/$BP/;
$BP = 0; # A global variable, button pressed to indicate continuing.

sub _construct {
	my($type, $x, $y) = @_;
	my $t = MainWindow->new();
	$t->geometry("$x".'x'."$y");
	my $c = $t->Canvas();
	my $this = bless {
		C => $c,
	}, $type;
	$t->bind("<Button-1>",sub { $BP++; print "$BP\n"; });
	$c->pack;
	return $this;
}

sub _line {
	my $this = shift;
	my $name = shift;
#	print "POI: @_\n";
	my $c = $this->{C};
	my $lid = $c->create('line',@_,-fill => $this->{Current_Color},
			     -width => $this->{Current_LineWidth});
	$this->{I}{$name} = $lid;
}

sub _ellipse {
	my($this, $name, $x1, $y1, $x2, $y2) = @_;
	my $c = $this->{C};
	my $aid = $c->create('arc',
		$x1, $y1, $x2, $y2,
		-outline => $this->{Current_Color},
		-width => $this->{Current_LineWidth},
	);
	$this->{I}{$name} = $aid;
}

sub _text {
	my($this, $name, $x, $y, $text) = @_;
#	print "T: $x $y $text\n";
	my $c = $this->{C};
	my $tid = $c->create('text',
		$x, $y,
		-text => $text,
		-fill => $this->{Current_Color},
	);
	$this->{I}{$name} = $tid;
}

sub _remove {
	my($this, $n) = @_;
	$this->{C}->delete(delete $this->{I}{$n});
}

sub _clear {
	my($this) = @_;
	for(values %{$this->{I}}) {
		print "DEST $_\n";
		$this->{C}->delete($_);
	}
	delete $this->{I};
}

sub _finish {
	my($this) = @_;
	$this->_wait();
}

# For now, just press button 1
sub _wait {
	my($this) = @_;
	$BP = 0;
	print "Waiting... Click a button in the window\n";
	my $t = $this->{C}->toplevel;
	$t->update while !$BP;
	print "Continuing...\n";
}

1;

=head1 AUTHOR

Copyright(C) Tuomas J. Lukka, Christian Soeller 1999. All rights reserved.
This software may be distributed under the same conditions as Perl itself.

=cut

