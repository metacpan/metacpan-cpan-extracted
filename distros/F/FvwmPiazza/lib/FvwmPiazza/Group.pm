package FvwmPiazza::Group;
{
  $FvwmPiazza::Group::VERSION = '0.3001';
}
use strict;
use warnings;

=head1 NAME

FvwmPiazza::Group - FvwmPiazza class for grouping.

=head1 VERSION

version 0.3001

=head1 SYNOPSIS

    use base qw(FvwmPiazza::Group);

=head1 DESCRIPTION

This module manages groups of windows.

=cut

use lib `fvwm-perllib dir`;
use FVWM::Module;

use base qw( Class::Base );

our $ERROR;
our $DEBUG = 0 unless defined $DEBUG;

=head2 init

Initialize.

=cut
sub init {
    my ($self, $config) = @_;
    
    $self->params($config,
	{
	    GID => '',
	})
	|| return undef;

    $self->{windows} = {};
    return $self;
} # init

=head2 DESTROY

Destruction.

=cut
sub DESTROY {
    my $self = shift;
    $self->remove_all_windows();
} # DESTROY


=head2 add_window_to_group

    $self->add_window_to_group(window=>$window);

=cut
sub add_window_to_group {
    my $self = shift;
    my %args = (
	window=>undef,
	@_
    );
    if (!defined $args{window})
    {
	return $self->error("No window given");
    }
    my $wid;
    my $window;
    if (ref $args{window})
    {
	$window = $args{window};
	$wid = $window->{ID};
    }
    else
    {
	$wid = $args{window};
	$window = FvwmPiazza::GroupWindow->new(ID=>$wid);
    }
    $window->set_group(group=>$self->{GID});
    if (exists $self->{windows}->{$wid}
	or defined $self->{windows}->{$wid})
    {
	return $self->error("window $wid already in group " . $self->{GID});
    }
    $self->{windows}->{$wid} = $window;
    return 1;
} # add_window_to_group

=head2 remove_window_from_group

    $win_rec = $self->remove_window_from_group(window=>$window);

=cut
sub remove_window_from_group {
    my $self = shift;
    my %args = (
	window=>undef,
	@_
    );
    if (!defined $args{window})
    {
	return $self->error("No window given");
    }
    if (!$self->{windows})
    {
	return $self->error("No windows to remove");
    }
    my $wid;
    my $window = undef;
    if ($args{window} eq 'Any')
    {
	my @windows = (keys %{$self->{windows}});
	$wid = pop @windows;
    }
    elsif (ref $args{window})
    {
	$window = $args{window};
	$wid = $window->{ID};
    }
    else
    {
	$wid = $args{window};
    }
    if (!exists $self->{windows}->{$wid}
	or !defined $self->{windows}->{$wid})
    {
	return $self->error("window $wid not in group " . $self->{GID});
    }
    $window = $self->{windows}->{$wid};
    delete $self->{windows}->{$wid};

    $window->set_group(group=>undef);
    return $window;
} # remove_window_from_group

=head2 remove_all_windows

    @windows = $self->remove_all_windows();

=cut
sub remove_all_windows {
    my $self = shift;
    my %args = (
	@_
    );

    my @all_windows = ();
    foreach my $id (sort keys %{$self->{windows}})
    {
	my $window = $self->{windows}->{$id};
	if (defined $window)
	{
	    $window->set_group(group=>undef);
	    push @all_windows, $window;
	}
	delete $self->{windows}->{$id};
    }

    return @all_windows;
} # remove_all_windows

=head2 num_windows

Number of windows in this group

=cut
sub num_windows {
    my $self = shift;

    my @windows = keys %{$self->{windows}};
    my $num = @windows;

    return $num;
} # num_windows

=head2 arrange_group

Resize and move the group.

$self->arrange_group(x=>$xpos,
y=>$ypos,
width=>$width,
height=>$height,
module=>$mod_ref,
);

=cut
sub arrange_group {
    my $self = shift;
    my %args = (
	x=>undef,
	y=>undef,
	width=>undef,
	height=>undef,
	module=>undef,
	@_
    );
    if (!$self->{windows})
    {
	return $self->error("no windows to arrange");
    }
    $self->{X} = $args{x};
    $self->{Y} = $args{y};
    $self->{WIDTH} = $args{width};
    $self->{HEIGHT} = $args{height};
    while (my ($wid, $window) = each %{$self->{windows}})
    {
	$window->arrange_self(%args);
    }
} # arrange_group

1;
