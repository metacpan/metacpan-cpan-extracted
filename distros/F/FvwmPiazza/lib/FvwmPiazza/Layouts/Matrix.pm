package FvwmPiazza::Layouts::Matrix;
{
  $FvwmPiazza::Layouts::Matrix::VERSION = '0.3001';
}
use strict;
use warnings;

=head1 NAME

FvwmPiazza::Layouts::Matrix - Matrix layout.

=head1 VERSION

version 0.3001

=head1 SYNOPSIS

    $obj->apply_layout(%args);

=head1 DESCRIPTION

This defines the "Matrix" layout for FvwmPiazza.

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
    my @options = @{$args{options}};
    my $num_cols = 2;
    my @rat_args = ();
    my $width_ratio = '';
    my $height_ratio = '';
    my @row_arr = ();

    {
        local @ARGV = @options;
        my $parser = new Getopt::Long::Parser();
        if (!$parser->getoptions('cols=n' => \$num_cols,
                                 'rows=s@' => \@row_arr,
                                 'ratios=s@' => \@rat_args,
                                 "width_ratio=s" => \$width_ratio,
                                 "height_ratio=s" => \$height_ratio))
        {
            $args{tiler}->debug("Failed to parse options: " . join(':', @ARGV));
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

    my @row_set = ();
    if (@row_arr)
    {
        if (@row_arr == 1)
        {
            # comma-separated
            push @row_set, split(/,/, $row_arr[0]);
        }
        else
        {
            push @row_set, @row_arr;
        }
        # repeat the last one until full
        while ($num_cols > @row_set)
        {
            push @row_set, $row_arr[$#row_arr];
        }
    }
    # the default number of rows per column is 2
    while ($num_cols > @row_set)
    {
	push @row_set, 2;
    }
    # row_set should now have a value for each column.

    my $working_width = $args{vp_width} -
	($args{left_offset} + $args{right_offset});
    my $working_height = $args{vp_height} -
	($args{top_offset} + $args{bottom_offset});

    my $num_win = $area->num_windows();
    my $max_win = $args{max_win};

    # adjust the max-win if we have few windows
    if ($num_win < $max_win)
    {
	$max_win = $num_win;
	$area->redistribute_windows(n_groups=>$max_win);
    }
    elsif ($area->num_groups() != $max_win)
    {
	$area->redistribute_windows(n_groups=>$max_win);
    }

    $num_cols = 1 if $num_win == 1;

    # Calculate the width ratios
    my @width_ratios =
	$self->calculate_ratios(num_sets=>$num_cols, ratios=>$width_ratio);

    my $col_nr = 0;
    my $row_nr = 0;
    my $ypos = $args{top_offset};
    my $xpos = $args{left_offset};
    for (my $gnr=0; $gnr < $max_win; $gnr++)
    {
	my $group = $area->group($gnr);
	my $col_width = int($working_width * $width_ratios[$col_nr]);
	my $num_rows = $row_set[$col_nr];

	# Re-calculate the height ratios for each column,
	# since there are a varying number of rows
	# Note that there is only ONE height-ratio given for row-heights,
	# so its effectiveness is somewhat limited.
	my @height_ratios =
	$self->calculate_ratios(num_sets=>$num_rows, ratios=>$height_ratio);
	my $row_height = int($working_height * $height_ratios[$row_nr]);

        $args{tiler}->debug("MATRIX gnr=$gnr num_rows=$num_rows col_nr=$col_nr row_nr=$row_nr xpos=$xpos ypos=$ypos");
	$group->arrange_group(module=>$args{tiler},
                              x=>$xpos,
                              y=>$ypos,
                              width=>$col_width,
                              height=>$row_height);

	$row_nr++;
	$ypos += $row_height;
	if ($row_nr == $num_rows)
	{
	    $row_nr = 0;
            $ypos = $args{top_offset};
	    $col_nr++;
	    $xpos += $col_width;
	    if ($col_nr == $num_cols)
	    {
		$col_nr = 0;
                $xpos = $args{left_offset};
	    }
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
