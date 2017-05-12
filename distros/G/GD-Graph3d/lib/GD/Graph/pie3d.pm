############################################################
#
# Module: GD::Graph::pie3d
#
# Description: 
# This is merely a wrapper around GD::Graph::pie that forces 
# the 3d option for pie charts.
#
# Created: 2000.Jan.19 by Jeremy Wadsack for Wadsack-Allen Digital Group
# 	Copyright (C) 2000,2001 Wadsack-Allen. All rights reserved.
############################################################
# Date      Modification                               Author
# ----------------------------------------------------------
# 2000APR18 Modified to be compatible w/ GD::Graph 1.30   JW
# 2000APR24 Set default slice label color to black        JW
# 2001Feb16 Added support for a legend                    JW
############################################################
package GD::Graph::pie3d;

use strict;
use GD;
use GD::Graph;
use GD::Graph::pie;
use GD::Graph::utils qw(:all);
use Carp;

@GD::Graph::pie3d::ISA = qw( GD::Graph::pie );
$GD::Graph::pie3d::VERSION = '0.63';

my %Defaults = (
	'3d'         => 1,
	axislabelclr => 'black',	# values on slices. black because default colors use dblue

	# Size of the legend markers
	legend_marker_height	=> 8,
	legend_marker_width	=> 12,
	legend_spacing			=> 4,
	legend_placement		=> 'BC',		# '[BR][LCR]'
	lg_cols					=> undef,
	legend_frame_margin	=> 4,
	legend_frame_size		=> undef,
);

# PRIVATE
# Have to include because this is a different %Defaults hash
sub _has_default { 
	my $self = shift;
	my $attr = shift || return;
	exists $Defaults{$attr} || $self->SUPER::_has_default($attr);
}

sub initialise {
	my $self = shift;
	my $rc = $self->SUPER::initialise();

	while( my($key, $val) = each %Defaults ) { 
		$self->{$key} = $val;
	} # end while

	$self->set_legend_font(GD::gdTinyFont);
	return $rc;
} # end initialise

# Add lengend calc and draw code
sub plot
{
	my $self = shift;
	my $data = shift;

	$self->check_data($data) 		or return;
	$self->init_graph() 			or return;
	$self->setup_text()				or return;
	$self->setup_legend();
	$self->setup_coords() 			or return;
	$self->{b_margin} += 4 if $self->{label};		# Kludge for descenders
	$self->draw_text()				or return;
	$self->draw_pie()				or return;
	$self->draw_data()				or return;
	$self->draw_legend();

	return $self->{graph};
}

# Added legend stuff
sub setup_text 
{
	my $self = shift;

	my $rc = $self->SUPER::setup_text( @_ );
	
	$self->{gdta_legend}->set(colour => $self->{legendci});
	$self->{gdta_legend}->set_align('top', 'left');
	$self->{lgfh} = $self->{gdta_legend}->get('height');
	
	return $rc
} # end setup_text

# Inherit everything else from GD::Graph::pie


# Legend Support. Added 16.Feb.2001 - JW/WADG

sub set_legend # List of legend keys
{
	my $self = shift;
	$self->{legend} = [@_];
}

sub set_legend_font # (font name)
{
	my $self = shift;
	$self->_set_font('gdta_legend', @_);
}



#
# Legend
#
sub setup_legend
{
	my $self = shift;

	return unless defined $self->{legend};

	my $maxlen = 0;
	my $num = 0;

	# Save some variables
	$self->{r_margin_abs} = $self->{r_margin};
	$self->{b_margin_abs} = $self->{b_margin};

	foreach my $legend (@{$self->{legend}})
	{
		if (defined($legend) and $legend ne "")
		{
			$self->{gdta_legend}->set_text($legend);
			my $len = $self->{gdta_legend}->get('width');
			$maxlen = ($maxlen > $len) ? $maxlen : $len;
			$num++;
		}
		# Legend for Pie goes over first set, and all points
		last if $num >= $self->{_data}->num_points;
	}

	$self->{lg_num} = $num;

	# calculate the height and width of each element
	my $legend_height = _max($self->{lgfh}, $self->{legend_marker_height});

	$self->{lg_el_width} = 
		$maxlen + $self->{legend_marker_width} + 3 * $self->{legend_spacing};
	$self->{lg_el_height} = $legend_height + 2 * $self->{legend_spacing};

	my ($lg_pos, $lg_align) = split(//, $self->{legend_placement});

	if ($lg_pos eq 'R')
	{
		# Always work in one column
		$self->{lg_cols} = 1;
		$self->{lg_rows} = $num;

		# Just for completeness, might use this in later versions
		$self->{lg_x_size} = $self->{lg_cols} * $self->{lg_el_width};
		$self->{lg_y_size} = $self->{lg_rows} * $self->{lg_el_height};

		# Adjust the right margin for the rest of the graph
		$self->{r_margin} += $self->{lg_x_size};

		# Adjust for frame if defined
		if( $self->{legend_frame_size} ) {
			$self->{r_margin} += 2 * ($self->{legend_frame_margin} + $self->{legend_frame_size});
		} # end if;

		# Set the x starting point
		$self->{lg_xs} = $self->{width} - $self->{r_margin};

		# Set the y starting point, depending on alignment
		if ($lg_align eq 'T')
		{
			$self->{lg_ys} = $self->{t_margin};
		}
		elsif ($lg_align eq 'B')
		{
			$self->{lg_ys} = $self->{height} - $self->{b_margin} - 
				$self->{lg_y_size};
		}
		else # default 'C'
		{
			my $height = $self->{height} - $self->{t_margin} - 
				$self->{b_margin};

			$self->{lg_ys} = 
				int($self->{t_margin} + $height/2 - $self->{lg_y_size}/2) ;
		}
	}
	else # 'B' is the default
	{
		# What width can we use
		my $width = $self->{width} - $self->{l_margin} - $self->{r_margin};

		(!defined($self->{lg_cols})) and 
			$self->{lg_cols} = int($width/$self->{lg_el_width});
		
		$self->{lg_cols} = _min($self->{lg_cols}, $num);

		$self->{lg_rows} = 
			int($num / $self->{lg_cols}) + (($num % $self->{lg_cols}) ? 1 : 0);

		$self->{lg_x_size} = $self->{lg_cols} * $self->{lg_el_width};
		$self->{lg_y_size} = $self->{lg_rows} * $self->{lg_el_height};

		# Adjust the bottom margin for the rest of the graph
		$self->{b_margin} += $self->{lg_y_size};
		# Adjust for frame if defined
		if( $self->{legend_frame_size} ) {
			$self->{b_margin} += 2 * ($self->{legend_frame_margin} + $self->{legend_frame_size});
		} # end if;

		# Set the y starting point
		$self->{lg_ys} = $self->{height} - $self->{b_margin};

		# Set the x starting point, depending on alignment
		if ($lg_align eq 'R')
		{
			$self->{lg_xs} = $self->{width} - $self->{r_margin} - 
				$self->{lg_x_size};
		}
		elsif ($lg_align eq 'L')
		{
			$self->{lg_xs} = $self->{l_margin};
		}
		else # default 'C'
		{
			$self->{lg_xs} =  
				int($self->{l_margin} + $width/2 - $self->{lg_x_size}/2);
		}
	}
}

sub draw_legend
{
	my $self = shift;

	return unless defined $self->{legend};

	my $xl = $self->{lg_xs} + $self->{legend_spacing};
	my $y  = $self->{lg_ys} + $self->{legend_spacing} - 1;

	# If there's a frame, offset by the size and margin
	$xl += $self->{legend_frame_margin} + $self->{legend_frame_size} if $self->{legend_frame_size};
	$y += $self->{legend_frame_margin} + $self->{legend_frame_size} if $self->{legend_frame_size};

	my $i = 0;
	my $row = 1;
	my $x = $xl;	# start position of current element

	foreach my $legend (@{$self->{legend}})
	{
		$i++;
		# Legend for Pie goes over first set, and all points
		last if $i > $self->{_data}->num_points;

		my $xe = $x;	# position within an element

		next unless defined($legend) && $legend ne "";

		$self->draw_legend_marker($i, $xe, $y);

		$xe += $self->{legend_marker_width} + $self->{legend_spacing};
		my $ys = int($y + $self->{lg_el_height}/2 - $self->{lgfh}/2);

		$self->{gdta_legend}->set_text($legend);
		$self->{gdta_legend}->draw($xe, $ys);

		$x += $self->{lg_el_width};

		if (++$row > $self->{lg_cols})
		{
			$row = 1;
			$y += $self->{lg_el_height};
			$x = $xl;
		}
	}
	
	# If there's a frame, draw it now
	if( $self->{legend_frame_size} ) {
		$x = $self->{lg_xs} + $self->{legend_spacing};
		$y = $self->{lg_ys} + $self->{legend_spacing} - 1;
		
		for $i ( 0 .. $self->{legend_frame_size} - 1 ) {
			$self->{graph}->rectangle(
				$x + $i,
				$y + $i, 
				$x + $self->{lg_x_size} + 2 * $self->{legend_frame_margin} - $i - 1,
				$y + $self->{lg_y_size} + 2 * $self->{legend_frame_margin} - $i - 1,
				$self->{acci},
			);
		} # end for
	} # end if
	
}

sub draw_legend_marker # data_set_number, x, y
{
	my $s = shift;
	my $n = shift;
	my $x = shift;
	my $y = shift;

	my $g = $s->{graph};

	my $ci = $s->set_clr($s->pick_data_clr($n));

	$y += int($s->{lg_el_height}/2 - $s->{legend_marker_height}/2);

	$g->filledRectangle(
		$x, $y, 
		$x + $s->{legend_marker_width}, $y + $s->{legend_marker_height},
		$ci
	);

	$g->rectangle(
		$x, $y, 
		$x + $s->{legend_marker_width}, $y + $s->{legend_marker_height},
		$s->{acci}
	);
}


1;
