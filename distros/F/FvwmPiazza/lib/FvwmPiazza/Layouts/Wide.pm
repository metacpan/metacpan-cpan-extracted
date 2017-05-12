package FvwmPiazza::Layouts::Wide;
{
  $FvwmPiazza::Layouts::Wide::VERSION = '0.3001';
}
use strict;
use warnings;

=head1 NAME

FvwmPiazza::Layouts::Wide - Wide layout.

=head1 VERSION

version 0.3001

=head1 SYNOPSIS

    $obj->apply_layout(%args);

=head1 DESCRIPTION

This defines the "Wide" layout for FvwmPiazza.
One "wide" row and the rest of the windows in the other row.

=cut

use lib `fvwm-perllib dir`;

use FVWM::Module;
use FvwmPiazza::Tiler;
use FvwmPiazza::Page;
use FvwmPiazza::Group;
use FvwmPiazza::GroupWindow;

use base qw( FvwmPiazza::Layouts );

our $ERROR;
our $DEBUG = 0 unless defined $DEBUG;

=head1 METHODS

=head2 init

=cut

sub init {
    my ($self, $config) = @_;

    return $self;
} # init


=head2 apply_layout

Apply the requested tiling layout.

=cut
sub apply_layout {
    my $self = shift;
    my %args = (
		area=>undef,
		options=>[],
		left_offset=>0,
		right_offset=>0,
		top_offset=>0,
		bottom_offset=>0,
		vp_width=>0,
		vp_heigt=>0,
		max_win=>2,
		tiler=>undef,
		@_
	       );
    my $err = $self->check_args(%args);
    if ($err)
    {
        return $self->error($err);
    }
    my $area = $args{area};

    # parse the options, if any
    my @options = @{$args{options}};
    my $wide_style;
    my @rat_args = ();
    my $width_ratio;
    my $height_ratio;

    {
        local @ARGV = @options;
        my $parser = new Getopt::Long::Parser();
        if (!$parser->getoptions(
                'variant=s' => \$wide_style,
                'ratios=s@' => \@rat_args,
                "width_ratio=s" => \$width_ratio,
                "height_ratio=s" => \$height_ratio))
        {
            $args{tiler}->debug("Failed to parse options: " . join(':', @options));
        }
        @options = @ARGV;
    }
    if (@rat_args)
    {
        # width first, then height
        if (@rat_args = 1)
        {
            my @rat = split(',', $args{ratios});
            $width_ratio = $rat[0];
            $height_ratio = $rat[1];
        }
        else # more than one, take first two
        {
            $width_ratio = $rat_args[0];
            $height_ratio = $rat_args[1];
        }
    }
    # old-style
    if (!defined $wide_style)
    {
        $wide_style = (@options ? shift @options : '');
    }
    if (!defined $width_ratio)
    {
        $width_ratio = (@options ? shift @options : '');
    }
    if (!defined $height_ratio)
    {
        $height_ratio = (@options ? shift @options : '');
    }

    my $working_width = $args{vp_width} -
	($args{left_offset} + $args{right_offset});
    my $working_height = $args{vp_height} -
	($args{top_offset} + $args{bottom_offset});

    my $num_win = $area->num_windows();
    my $max_win = $args{max_win};

    my $num_rows = 2;
    my $wide_row_nr = 0;
    if ($wide_style =~ /Bottom/)
    {
	$wide_row_nr = 1;
    }
    if ($num_win < $max_win)
    {
	$max_win = $num_win;
	$area->redistribute_windows(n_groups=>$max_win);
    }
    elsif ($area->num_groups() != $max_win)
    {
	$area->redistribute_windows(n_groups=>$max_win);
    }
    my $num_cols = $max_win - 1;

    # Calculate the width and height ratios
    my @width_ratios =
	$self->calculate_ratios(num_sets=>$num_cols, ratios=>$width_ratio);
    my @height_ratios =
	$self->calculate_ratios(num_sets=>$num_rows, ratios=>$height_ratio);

    my $col_nr = 0;
    my $row_nr = 0;
    my $ypos = $args{top_offset};
    my $xpos = $args{left_offset};
    for (my $gnr=0; $gnr < $max_win; $gnr++)
    {
	my $col_width = int($working_width * $width_ratios[$col_nr]);
	my $row_height = int($working_height * $height_ratios[$row_nr]);
	my $group = $area->group($gnr);

	if ($row_nr == $wide_row_nr)
	{
	    $group->arrange_group(module=>$args{tiler},
				  x=>$args{left_offset},
				  y=>$ypos,
				  width=>$working_width,
				  height=>$row_height);
	    $args{tiler}
	    ->debug("wide_row_nr=$wide_row_nr row_height=$row_height");
	}
	else
	{
	    $group->arrange_group(module=>$args{tiler},
				  x=>$xpos,
				  y=>$ypos,
				  width=>$col_width,
				  height=>$row_height);
	    $args{tiler}
	    ->debug("col=$col_nr, row=$row_nr, xpos=$xpos, ypos=$ypos");
	}

	if ($row_nr == $wide_row_nr)
	{
	    $row_nr++;
	    $col_nr = 0;
	    $xpos = $args{left_offset};
	    $ypos += $row_height;
	}
	else
	{
	    $col_nr++;
	    $xpos += $col_width;
	    if ($col_nr == $num_cols)
	    {
		$col_nr = 0;
		$xpos = $args{left_offset};
		$row_nr++;
		$ypos += $row_height;
	    }
	}
	if ($row_nr == $num_rows)
	{
	    $row_nr = 0;
	    $col_nr = 0;
	    $xpos = $args{left_offset};
	    $ypos = $args{top_offset};
	}
    }

} # apply_layout

=head1 REQUIRES

    Class::Base

=head1 BUGS

Please report any bugs or feature requests to the author.

=head1 AUTHOR

    Kathryn Andersen (RUBYKAT)
    perlkat AT katspace dot org
    http://www.katspace.com/tools/fvwm_tiler/

=head1 COPYRIGHT AND LICENCE

Copyright (c) 2009 by Kathryn Andersen

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of FvwmPiazza::Layouts
__END__
