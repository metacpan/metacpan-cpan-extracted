package Gtk2::Ex::DBITableFilter::BrowserBar;

use strict;
use warnings;
use Glib qw(TRUE FALSE);
use Data::Dumper;

sub new {
	my ($class, $parent) = @_;
	my $self  = {};
	bless ($self, $class);
	$self->{parent} = $parent;
	return $self;
}

sub get_widget {
	my ($self) = @_;
	my $parent = $self->{parent};
	my $nextbutton = Gtk2::Button->new_from_stock('gtk-go-forward');
	my $prevbutton = Gtk2::Button->new_from_stock('gtk-go-back');
	my $firstbutton = Gtk2::Button->new_from_stock('gtk-goto-first');
	my $lastbutton = Gtk2::Button->new_from_stock('gtk-goto-last');
	$nextbutton->signal_connect(clicked => sub { $self->_go_to_next; }	);
	$prevbutton->signal_connect(clicked => sub { $self->_go_to_previous; }	);
	$firstbutton->signal_connect(clicked => sub { $self->_go_to_first; }	);
	$lastbutton->signal_connect(clicked => sub { $self->_go_to_last; }	);
	my $progressbar = Gtk2::ProgressBar->new;
	$self->{progress}->{bar} = $progressbar;	
	$progressbar->set_text('Showing 0 records');
	my $hboxleft = Gtk2::HBox->new (TRUE, 0);
	$hboxleft->pack_start ($firstbutton, FALSE, TRUE, 0);    
	$hboxleft->pack_start ($prevbutton, FALSE, TRUE, 0);    
	my $hboxright = Gtk2::HBox->new (TRUE, 0);
	$hboxright->pack_start ($nextbutton, FALSE, TRUE, 0);  
	$hboxright->pack_start ($lastbutton, FALSE, TRUE, 0);    
	my $hboxbottom = Gtk2::HBox->new (FALSE, 0);
	$hboxbottom->pack_start ($hboxleft, FALSE, TRUE, 0);    	
	$hboxbottom->pack_start ($progressbar, TRUE, TRUE, 0);    	
	$hboxbottom->pack_start ($hboxright, FALSE, TRUE, 0);    	
	return $hboxbottom;
}

sub _go_to_next {
	my ($self) = @_;
	my $parent = $self->{parent};
	my $limit = $parent->{limit};
	return if $limit->{end} >= $limit->{total};
	$limit->{start} += $limit->{increment} ;
	$limit->{end} += $limit->{increment} ;
	$limit->{end} = $limit->{total} 
		if $limit->{end} >= $limit->{total};
	$limit->{step} = $limit->{increment};
	if ($limit->{start} + $limit->{increment} > $limit->{end}) {
		$limit->{step} = $limit->{end} - $limit->{start};
	}
	$parent->{limit} = $limit;
	$parent->refresh;
	return 0;
}

sub _go_to_previous {
	my ($self) = @_;
	my $parent = $self->{parent};
	my $limit = $parent->{limit};
	return if $limit->{start} <= 0;
	$limit->{start} -= $limit->{increment} ;
	$limit->{end} = 
		$limit->{start} + $limit->{increment} ;
	$limit->{step} = $limit->{increment};
	if ($limit->{start} + $limit->{increment} > $limit->{end}) {
		$limit->{step} = $limit->{end} - $limit->{start};
	}
	$parent->{limit} = $limit;
	$parent->refresh;
	return 0;
}

sub _go_to_last {
	my ($self) = @_;
	my $parent = $self->{parent};
	my $limit = $parent->{limit};
	$limit->{start} = int($limit->{total}/$limit->{increment})* $limit->{increment};					
	$limit->{end} = $limit->{total};
	$limit->{step} = $limit->{increment};
	if ($limit->{start} + $limit->{increment} > $limit->{end}) {
		$limit->{step} = $limit->{end} - $limit->{start};
	}
	$parent->{limit} = $limit;
	$parent->refresh;
	return 0;
}

sub _go_to_first {
	my ($self) = @_;
	my $parent = $self->{parent};
	my $limit = $parent->{limit};
	$limit->{start} = 0;
	$limit->{end} = $limit->{increment} ;
	$limit->{end} = $limit->{total} if $limit->{end} >= $limit->{total};
	$limit->{step} = $limit->{increment};
	if ($limit->{start} + $limit->{increment} > $limit->{end}) {
		$limit->{step} = $limit->{end} - $limit->{start};
	}
	$parent->{limit} = $limit;
	$parent->refresh;
	return 0;
}

sub update_progress_label {
	my ($self, $action) = @_;
	if ($action eq 'Counting') {
		$self->{progress}->{bar}->set_text('Counting');
		return 0;
	}
	my $parent = $self->{parent};
	my $limit = $parent->{limit};
	$limit->{end} = $limit->{total} if $limit->{end} >= $limit->{total};
	my $countstring = "$action ".$limit->{start}.
	                  ' to '.$limit->{end}.
	                  ' of '.$limit->{total}.'records';
	$self->{progress}->{bar}->set_text($countstring);
	$self->{limit} = $limit;
}

sub start_progress {
	my ($self, $from, $to) = @_;
	$self->{progress}->{count} = 1;
	$self->{progress}->{timer} = 
		Glib::Timeout->add(100, \&_make_progress, [$self, $from, $to]);
}

sub _make_progress {
	my $ary = shift;
	my ($self, $from, $to) = @$ary;	
	my $pbar = $self->{progress}->{bar};
	my $fraction = $from + ($to - $from)*(1 - 0.9**$self->{progress}->{count});
	$pbar->set_fraction($fraction);
	$self->{progress}->{count}++;
	return 1;
}

sub end_progress {
	my ($self, $to) = @_;
	my $pbar = $self->{progress}->{bar};
	$pbar->set_fraction($to);
	Glib::Source->remove($self->{progress}->{timer});
	$self->{progress}->{count} = 1;
}

1;

__END__

=head1 COPYRIGHT & LICENSE

Copyright 2005 Ofey Aikon, All Rights Reserved.

This library is free software; you can redistribute it and/or modify it under
the terms of the GNU Library General Public License as published by the Free
Software Foundation; either version 2.1 of the License, or (at your option) any
later version.

This library is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.  See the GNU Library General Public License for more
details.

You should have received a copy of the GNU Library General Public License along
with this library; if not, write to the Free Software Foundation, Inc., 59
Temple Place - Suite 330, Boston, MA  02111-1307  USA.

=cut
