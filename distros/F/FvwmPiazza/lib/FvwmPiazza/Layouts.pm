package FvwmPiazza::Layouts;
{
  $FvwmPiazza::Layouts::VERSION = '0.3001';
}
use strict;
use warnings;

=head1 NAME

FvwmPiazza::Layouts - Base class for FvwmPiazza layouts.

=head1 VERSION

version 0.3001

=head1 SYNOPSIS

    use base qw(FvwmPiazza::Layouts);

=head1 DESCRIPTION

This is the base class for defining different layout modules
for FvwmPiazza.

=cut

use lib `fvwm-perllib dir`;

use FVWM::Module;
use General::Parse;
use YAML::Syck;

use FvwmPiazza::Tiler;

use base qw( Class::Base );

our $ERROR;
our $DEBUG = 0 unless defined $DEBUG;

=head2 name

The name of this layout.

=cut
sub name {
    my $self = shift;

    if (!$self->{NAME})
    {
	my $name = ref $self;
	$name =~ s/FvwmPiazza::Layouts:://;
	$self->{NAME} = $name;
    }
    return $self->{NAME};
} # name

=head2 check_args

Check the arguments

=cut
sub check_args {
    my $self = shift;
    my %args = (
		area=>undef,
		work_area=>undef,
		max_win=>1,
		tiler=>undef,
		@_
	       );
    if (!defined $args{area})
    {
	return "area not defined";
    }
    if (!defined $args{tiler})
    {
	return "tiler not defined";
    }
    if ($args{vp_width} == 0)
    {
	return "vp_width is zero";
    }
    if ($args{vp_height} == 0)
    {
	return "vp_height is zero";
    }
    if ($args{area}->num_windows() == 0)
    {
	return "there are zero windows";
    }
    if (exists $args{wid} and defined $args{wid})
    {
	my $window = $args{area}->window_by_id($args{wid});
	if (!defined $window)
	{
	    return "window $args{wid} not defined";
	}
    }
    return '';
} # check_args

=head2 apply_layout

Apply the requested tiling layout.

=cut
sub apply_layout {
    my $self = shift;
    my %args = (
		@_
	       );

} # apply_layout

=head2 place_window

Place one window within the tiling layout

=cut
sub place_window {
    my $self = shift;
    my %args = (
		@_
	       );

} # place_window

=head2 calculate_ratios

Calculate the desired ratios for lengths or widths.

=cut
sub calculate_ratios {
    my $self = shift;
    my %args = (
		num_sets=>1,
		ratios=>'',
		@_
	       );
    my $num_sets = $args{num_sets};

    my @ratios = ();
    if ($args{ratios}
	and $args{ratios} =~ /^([\d:]+)/)
    {
	my $ratio_str = $1;
	my @r_args = split(':', $ratio_str);

	my $ratio_total = 0;
	for (my $i=0; $i < @r_args; $i++)
	{
	    $ratio_total += $r_args[$i];
	}

	# If the number of ratio args is greater than or equal the
	# number of sets, then treat it as a straight ratio,
	# taking $num_sets arguments for the ratio
	if ($num_sets <= @r_args)
	{
	    if ($num_sets < @r_args)
	    {
		$ratio_total = 0;
		for (my $i=0; $i < $num_sets; $i++)
		{
		    $ratio_total += $r_args[$i];
		}
	    }
	    for (my $i=0; $i < $num_sets; $i++)
	    {
		$ratios[$i] = $r_args[$i] / $ratio_total;
	    }
	}
	# If there is only one ratio-arg,
	# treat it as a percent, and divide the rest evenly
	elsif ($num_sets > @r_args and @r_args == 1)
	{
	    my $percent_left = 100;
	    my $cols_left = $num_sets;
	    for (my $i=0; $i < $num_sets; $i++)
	    {
		if ($i < @r_args)
		{
		    $ratios[$i] = $r_args[$i] / 100;
		    $percent_left -= $r_args[$i];
		    $cols_left--;
		}
		else
		{
		    $ratios[$i] = ($percent_left / $cols_left) / 100;
		}
	    }
	}
	else
	{
	    # The number of ratio args is less than the number of sets.
	    # Divide the first N by the ratio, and the rest evenly.
	    $ratio_total = $ratio_total * ($num_sets / @r_args);
	    for (my $i=0; $i < $num_sets; $i++)
	    {
		if ($i < @r_args)
		{
		    $ratios[$i] = $r_args[$i] / $ratio_total;
		}
		else
		{
		    $ratios[$i] = 1/$num_sets;
		}
	    }
	}
    }
    else # divide everything evenly
    {
	for (my $i=0; $i < $num_sets; $i++)
	{
	    $ratios[$i] = 1/$num_sets;
	}
    }

    return @ratios;
} # calculate_ratios

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
