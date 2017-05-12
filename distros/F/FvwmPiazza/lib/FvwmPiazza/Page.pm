package FvwmPiazza::Page;
{
  $FvwmPiazza::Page::VERSION = '0.3001';
}
use strict;
use warnings;

=head1 NAME

FvwmPiazza::Page - FvwmPiazza class for keeping track of page info.

=head1 VERSION

version 0.3001

=head1 SYNOPSIS

    use base qw(FvwmPiazza::Page);

=head1 DESCRIPTION

This module keeps track of information for one Fvwm page.

=cut

use lib `fvwm-perllib dir`;
use FvwmPiazza::Group;
use FvwmPiazza::GroupWindow;

use base qw( Class::Base );

our $ERROR = '';
our $DEBUG = 0 unless defined $DEBUG;

=head2 init

Initialize.

=cut
sub init {
    my ($self, $config) = @_;
    
    $self->params($config,
	{
	    DESK => 0,
	    PAGEX => 0,
	    PAGEY => 0,
	    LAYOUT => 'None',
	    MAX_WIN=>1,
	})
	|| return undef;

    $self->{groups} = {};
    return $self;
} # init

=head2 num_groups

How many groups?

=cut
sub num_groups {
    my $self = shift;

    my @groups = keys %{$self->{groups}};
    my $num = @groups;
    return $num;
} # num_groups

=head2 num_windows

How many windows?

=cut
sub num_windows {
    my $self = shift;

    my $num = 0;
    foreach my $gid (sort keys %{$self->{groups}})
    {
	$num += $self->{groups}->{$gid}->num_windows();
    }
    return $num;
} # num_windows

=head2 group

Return the given group.
$grp = $self->group($index);

=cut
sub group {
    my $self = shift;
    my $ind = shift;

    my @gids = (sort keys %{$self->{groups}});
    if (!@gids)
    {
	return $self->error("No groups");
    }
    if ($ind >= @gids or $ind < 0)
    {
	return $self->error("Index $ind out of range");
    }
    my $gid = $gids[$ind];
    return $self->{groups}->{$gid};
} # group

=head2 distribute_windows

Takes a list of windows and distributes them among the existing groups.

=cut
sub distribute_windows {
    my $self = shift;
    my %args = (
	window_list=>undef,
	@_
    );
    if (!$args{window_list})
    {
	return $self->error("need a window list");
    }
    my @window_list = @{$args{window_list}};
    if (!@window_list)
    {
	return $self->error("window list is empty");
    }
    # empty groups need to have at least one window each
    if ($self->num_windows() < $self->num_groups())
    {
	my $gid = 0;
	while (@window_list
	    and $self->num_windows() < $self->num_groups()
	    and $gid < $self->num_groups())
	{
	    if (!$self->{groups}->{$gid}->num_windows())
	    {
		my $window = shift @window_list;
		$self->{groups}->{$gid}->add_window_to_group(window=>$window);
		$self->debug("added window " . $window->{ID}
			     . " to empty group $gid\n");
	    }
	    $gid++;
	}
	$self->debug("num_windows=" . $self->num_windows()
	. " num_groups=" . $self->num_groups()
	. " gid=$gid"
	. " remaining_windows=" . @window_list
	. "\n");
    }
    if ($self->num_windows() < $self->num_groups()
	and $self->num_windows() > 0
	and !@window_list)
    {
	$self->debug("distribute_windows: too few windows for groups\n");
	# still not enough windows for all the groups
	my $gid = $self->num_groups() - 1;
	while ($self->num_groups() > $self->num_windows()
	    and $gid >= 0)
	{
	    if ($self->{groups}->{$gid}->num_windows() == 0)
	    {
		delete $self->{groups}->{$gid};
		$self->debug("deleted group $gid\n");
	    }
	    $gid--;
	}
	$self->debug("num_windows=" . $self->num_windows()
	. " num_groups=" . $self->num_groups()
	. " gid=$gid"
	. "\n");
    }
    else
    {
	my $gid = 0;
	while (@window_list)
	{
	    my $window = shift @window_list;
	    $self->{groups}->{$gid}->add_window_to_group(window=>$window);
	    $self->debug("added window " . $window->{ID} . " to group $gid\n");
	    $gid++;
	    if ($gid >= $self->num_groups())
	    {
		$gid = 0;
	    }
	}
    }
    return 1;
} # distribute_windows

=head2 windows_to_n_groups

Takes a list of windows and distributes them among N groups.

=cut
sub windows_to_n_groups {
    my $self = shift;
    my %args = (
	window_list=>undef,
	n_groups=>1,
	@_
    );
    if (!$args{window_list})
    {
	return $self->error("need a window list");
    }
    my @window_list = @{$args{window_list}};
    if (!@window_list)
    {
	return $self->error("window list is empty");
    }
    while ($self->num_groups() < $args{n_groups})
    {
	$self->new_group();
	$self->debug("windows_to_n_groups: adding a group\n");
    }
    while ($self->num_groups() > $args{n_groups})
    {
	$self->debug("windows_to_n_groups: reducing a group\n");
	if (!$self->reduce_groups())
	{
	    $self->debug("windows_to_n_groups: reduce_groups failed: $ERROR\n");
	    last;
	}
    }
    $self->debug("windows_to_n_groups: num_groups=" . $self->num_groups() . "\n");
    return $self->distribute_windows(window_list=>\@window_list);
} # windows_to_n_groups

=head2 redistribute_windows

Redistributes the current windows amongst the current groups.

=cut
sub redistribute_windows {
    my $self = shift;
    my %args = (
	n_groups=>0,
	@_
    );

    my $n_groups = ($args{n_groups} ? $args{n_groups} : $self->num_groups());

    # This mostly preserves window groupings because it
    # preserves the order of the windows taken from the groups
    my @window_list = ();
    foreach my $gid (sort keys %{$self->{groups}})
    {
	push @window_list, $self->{groups}->{$gid}->remove_all_windows();
    }
    my $num_win = @window_list;
    $self->debug("redistribute_windows: total_win=$num_win, n_groups=$n_groups\n");
    return $self->windows_to_n_groups(window_list=>\@window_list, n_groups=>$n_groups);
} # redistribute_windows

=head2 add_window_to_page

Add a new window to the page.

$self->add_window_to_page(window=>$wid, current_group=>$gid);

=cut
sub add_window_to_page {
    my $self = shift;
    my %args = (
	window=>0,
	current_group=>0,
	@_
    );

    my $old_group_count = $self->num_groups();
    if ($old_group_count < $self->{MAX_WIN})
    {
	# create a new group and add a window to it
	my $new_gid = $self->new_group();
	$self->add_window_to_group(window=>$args{window},
				   group=>$new_gid);
    }
    elsif (defined $args{current_group}
	and exists $self->{groups}->{$args{current_group}})
    {
	if (!$self->add_window_to_group(window=>$args{window},
				   group=>$args{current_group}))
	{
	    $self->add_window_to_group(window=>$args{window},
				       group=>0);
	}
    }
    else
    {
	$self->add_window_to_group(window=>$args{window},
				   group=>0);
    }
    return 1;
} # add_window_to_page

=head2 remove_window_from_page

Remove a window from the page.

$self->remove_window_from_page(window=>$wid, group=>$gid);

=cut
sub remove_window_from_page {
    my $self = shift;
    my %args = (
	window=>0,
	group=>0,
	@_
    );

    my $old_group_count = $self->num_groups();
    $self->remove_window_from_group(window=>$args{window},
				    group=>$args{group});
    # if this group has no more windows in it
    # remove this group
    if ($self->{groups}->{$args{group}}->num_windows() == 0)
    {
	$self->destroy_group(group=>$args{group});
	$self->renumber_groups();
    }

    return 1;
} # remove_window_from_page

=head2 renumber_groups

Renumber the groups and their windows.

=cut
sub renumber_groups {
    my $self = shift;

    my @group_windows = ();
    foreach my $gid (sort keys %{$self->{groups}})
    {
	my @window_list = ();
	push @window_list, $self->{groups}->{$gid}->remove_all_windows();
	push @group_windows, \@window_list;
	$self->destroy_group(group=>$gid);
    }
    while (@group_windows)
    {
	my @window_list = @{shift @group_windows};
	my $new_gid = $self->new_group();
	while (@window_list)
	{
	    my $window = shift @window_list;
	    $self->{groups}->{$new_gid}->add_window_to_group(window=>$window);
	}
    }
} # renumber_groups

=head2 new_group

$self->new_group();

Add a new group

=cut
sub new_group {
    my $self = shift;

    my $gid = 0;
    while (exists $self->{groups}->{$gid})
    {
	$gid++;
    }
    $self->{groups}->{$gid} = FvwmPiazza::Group->new(GID=>$gid);
    return $gid;
} # new_group

=head2 destroy_group

$self->destroy_group(group=>1);

Destroy the given group, losing the window
information.

=cut
sub destroy_group {
    my $self = shift;
    my %args = (
	group =>undef,
	@_
    );

    my $gid = $args{group};
    if (exists $self->{groups}->{$gid})
    {
	delete $self->{groups}->{$gid};
    }

} # destroy_group

=head2 reduce_groups

Reduce the number of groups by one,
by taking the windows from the last group
and redistributing them amongst the other groups.

$self->reduce_groups();

=cut
sub reduce_groups {
    my $self = shift;
    my %args = (
	@_
    );
    if ($self->num_groups() <= 1)
    {
	return $self->error("cannot reduce groups below 1");
    }
    my @gids = sort keys %{$self->{groups}};
    my $last_gid = pop @gids;
    my @window_list = ();
    if ($self->{groups}->{$last_gid}->num_windows())
    {
	@window_list = $self->{groups}->{$last_gid}->remove_all_windows();
    }
    delete $self->{groups}->{$last_gid};

    if (@window_list)
    {
	$self->distribute_windows(window_list=>\@window_list);
    }
    return 1;
} # reduce_groups

=head2 move_window_to_next_group

Move the given window from its group
to the next group on the page.

=cut
sub move_window_to_next_group {
    my $self = shift;
    my %args = (
	window =>undef,
	@_
    );
    if (!defined $args{window} or !$args{window})
    {
	return $self->error("window not defined");
    }
    if (!ref $args{window})
    {
	return $self->error("window must be a class");
    }
    if ($self->{MAX_WIN} <= 1)
    {
	return $self->error("no other group");
    }
    my $window = $args{window};
    my $old_gid = $window->{GID};
    if (!defined $old_gid)
    {
	return $self->error("window GID undefined");
    }
    $self->remove_window_from_group(window=>$window,
				    group=>$old_gid);
    my $new_gid = $old_gid;
    $new_gid++;
    if ($new_gid == $self->num_groups())
    {
	if ($new_gid < $self->{MAX_WIN})
	{
	    $new_gid = $self->new_group();
	}
	else
	{
	    $new_gid = 0;
	}
    }
    if ($self->{groups}->{$old_gid}->num_windows() == 0)
    {
	# Take a window from the new group and put it in the old
	# group if the old group would otherwise be empty.
	# In other words, swap.
	my $other_window = $self->remove_window_from_group(window=>'Any',
							   group=>$new_gid);
	$self->add_window_to_group(window=>$other_window,
				   group=>$old_gid) if $other_window;

    }
    $self->add_window_to_group(window=>$window,
			       group=>$new_gid);
} # move_window_to_next_group

=head2 move_window_to_prev_group

Move the given window from its group
to the previous group on the page.

=cut
sub move_window_to_prev_group {
    my $self = shift;
    my %args = (
	window =>undef,
	@_
    );
    if (!defined $args{window} or !$args{window})
    {
	return $self->error("window not defined");
    }
    if (!ref $args{window})
    {
	return $self->error("window must be a class");
    }
    if ($self->{MAX_WIN} <= 1)
    {
	return $self->error("no other group");
    }
    my $window = $args{window};
    my $old_gid = $window->{GID};
    if (!defined $old_gid)
    {
	return $self->error("window GID undefined");
    }
    $self->remove_window_from_group(window=>$window,
				    group=>$old_gid);
    my $new_gid = $old_gid;
    $new_gid--;
    if ($new_gid < 0)
    {
	if ($new_gid < $self->{MAX_WIN})
	{
	    $new_gid = $self->new_group();
	}
	else
	{
	    $new_gid = $self->num_groups() - 1;
	}
    }
    if ($self->{groups}->{$old_gid}->num_windows() == 0)
    {
	# Take a window from the new group and put it in the old
	# group if the old group would otherwise be empty.
	# In other words, swap.
	my $other_window = $self->remove_window_from_group(window=>'Any',
							   group=>$new_gid);
	$self->add_window_to_group(window=>$other_window,
				   group=>$old_gid) if $other_window;
    }
    $self->add_window_to_group(window=>$window,
			       group=>$new_gid);
} # move_window_to_prev_group

=head2 add_window_to_group

Add a window to a group

=cut
sub add_window_to_group {
    my $self = shift;
    my %args = (
	window =>undef,
	group =>'',
	@_
    );
    if (!defined $args{window})
    {
	return $self->error("window not defined");
    }

    my $gid = $args{group};
    if (!defined $gid)
    {
	return $self->error("group not given an ID");
    }
    if (!exists $self->{groups}->{$gid}
	or !defined $self->{groups}->{$gid})
    {
	if ($self->num_groups() == 0)
	{
	    $self->new_group();
	    ($gid) = keys %{$self->{groups}};
	}
	else
	{
	    return $self->error("group $gid does not exist");
	}
    }
    $self->{groups}->{$gid}->add_window_to_group(window=>$args{window});

} # add_window_to_group

=head2 remove_window_from_group

Remove a window from a group

=cut
sub remove_window_from_group {
    my $self = shift;
    my %args = (
	window => undef,
	group => 0,
	@_
    );
    my $gid = $args{group};
    if (!defined $args{window})
    {
	return $self->error("window not defined");
    }
    if (!defined $gid and ref $args{window})
    {
	$gid = $args{window}->{GID};
    }
    if (!exists $self->{groups}->{$gid}
	or !defined $self->{groups}->{$gid})
    {
	return $self->error("group $gid does not exist");
    }
    $self->{groups}->{$gid}->remove_window_from_group(window=>$args{window});

} # remove_window_from_group

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

1; # End of FvwmPiazza::Page
__END__
