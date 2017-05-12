package FvwmPiazza::Layouts::Columns;
{
  $FvwmPiazza::Layouts::Columns::VERSION = '0.3001';
}
use strict;
use warnings;

=head1 NAME

FvwmPiazza::Layouts::Columns - Columns layout.

=head1 VERSION

version 0.3001

=head1 SYNOPSIS

    $obj->apply_layout(%args);

=head1 DESCRIPTION

This defines the "Columns" layout
for FvwmPiazza.

=cut

use lib `fvwm-perllib dir`;

use FVWM::Module;
use FvwmPiazza::Tiler;
use FvwmPiazza::Page;
use FvwmPiazza::Group;
use FvwmPiazza::GroupWindow;
use Getopt::Long;

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

    my $working_width = $args{vp_width} -
	($args{left_offset} + $args{right_offset});
    my $working_height = $args{vp_height} -
	($args{top_offset} + $args{bottom_offset});

    my $num_cols = $args{max_win};
    my $num_win = $area->num_windows();

    if ($num_win == 0)
    {
	return $self->error("there are zero windows");
    }
    if ($num_win < $num_cols)
    {
	$area->redistribute_windows(n_groups=>$num_win);
	$num_cols = $num_win;
    }
    elsif ($area->num_groups() != $num_cols)
    {
	$area->redistribute_windows(n_groups=>$num_cols);
    }
    
    # Calculate the column widths
    # Don't apply the passed-in ratios if we have fewer columns
    # than the layout requires
    my @ratios = ();
    if ($num_cols == $args{max_win} and defined $options[0])
    {
        local @ARGV = @options;
        my $ratio_arg;
        my $parser = new Getopt::Long::Parser();
        if ($ARGV[0] =~ /^\d[\d:]*$/)
        {
            $ratio_arg = $options[0];
        }
        elsif (!$parser->getoptions("ratios=s" => \$ratio_arg))
        {
            $args{tiler}->debug("Columns: failed to parse options: " . join(':', @options));
            $ratio_arg = $num_cols;
        }
        @ratios = $self->calculate_ratios(num_sets=>$num_cols,
	    ratios=>$ratio_arg);
        @options = @ARGV;
    }
    else
    {
	@ratios = $self->calculate_ratios(num_sets=>$num_cols);
    }

    # Arrange the windows
    my $ypos = $args{top_offset};
    my $xpos = $args{left_offset};
    for (my $col_nr=0; $col_nr < $num_cols; $col_nr++)
    {
	my $col_width = int($working_width * $ratios[$col_nr]);
	my $group = $area->group($col_nr);
	$group->arrange_group(module=>$args{tiler},
	    x=>$xpos,
	    y=>$ypos,
	    width=>$col_width,
	    height=>$working_height);
	$xpos += $col_width;
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
