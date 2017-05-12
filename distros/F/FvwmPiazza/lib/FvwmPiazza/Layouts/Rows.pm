package FvwmPiazza::Layouts::Rows;
{
  $FvwmPiazza::Layouts::Rows::VERSION = '0.3001';
}
use strict;
use warnings;

=head1 NAME

FvwmPiazza::Layouts::Rows - Rows layout.

=head1 VERSION

version 0.3001

=head1 SYNOPSIS

    $obj->apply_layout(%args);

=head1 DESCRIPTION

This defines the "Rows" layout for FvwmPiazza.

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
    my $ratio_args;
    {
        local @ARGV = @options;
        my $parser = new Getopt::Long::Parser();
        if (!$parser->getoptions('ratios=s' => \$ratio_args))
        {
            $args{tiler}->debug("Grid failed to parse options: " . join(':', @options));
        }
        @options = @ARGV;
    }
    if (!defined $ratio_args)
    {
        $ratio_args = (@options ? shift @options : '');
    }

    my $working_width = $args{vp_width} -
	($args{left_offset} + $args{right_offset});
    my $working_height = $args{vp_height} -
	($args{top_offset} + $args{bottom_offset});

    my $num_rows = $args{max_win};
    my $num_win = $area->num_windows();

    if ($num_win < $num_rows)
    {
	$area->redistribute_windows(n_groups=>$num_win);
	$num_rows = $num_win;
    }
    elsif ($area->num_groups() != $num_rows)
    {
	$area->redistribute_windows(n_groups=>$num_rows);
    }

    # Calculate the row heights
    # Don't apply the passed-in ratios if we have fewer rows
    # than the layout requires
    my @ratios = ();
    if ($num_rows == $args{max_win} and $ratio_args)
    {
	@ratios = $self->calculate_ratios(num_sets=>$num_rows,
	    ratios=>$ratio_args);
    }
    else
    {
	@ratios = $self->calculate_ratios(num_sets=>$num_rows);
    }

    # Arrange the windows
    my $ypos = $args{top_offset};
    my $xpos = $args{left_offset};
    for (my $row_nr=0; $row_nr < $num_rows; $row_nr++)
    {
	my $row_height = int($working_height * $ratios[$row_nr]);
	my $group = $area->group($row_nr);
	$group->arrange_group(module=>$args{tiler},
			      x=>$xpos,
			      y=>$ypos,
			      width=>$working_width,
			      height=>$row_height);
	$ypos += $row_height;
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
