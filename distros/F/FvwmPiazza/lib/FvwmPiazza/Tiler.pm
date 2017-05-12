package FvwmPiazza::Tiler;
{
  $FvwmPiazza::Tiler::VERSION = '0.3001';
}
use strict;

=head1 NAME

FvwmPiazza::Tiler - Fvwm module for tiling windows.

=head1 VERSION

version 0.3001

=head1 SYNOPSIS

    use FvwmPiazza::Tiler;

    my $obj = FvwmPiazza::Tiler->new(\%args);

    ---------------------------------

    *FvwmPiazza: Struts I<left> I<right> I<top> I<bottom>
    *FvwmPiazza: Exclude Gimp
    *FvwmPiazza: UseMaximize true
    *FvwmPiazza: Layout0 Full
    *FvwmPiazza: Layout1 Columns 2

    Key	f   A	MS  SendToModule FvwmPiazza Full


=head1 DESCRIPTION

This tiles windows in different ways.

=cut

use lib `fvwm-perllib dir`;

use FVWM::Module;
use General::Parse;
use Getopt::Long;
use YAML::Syck;
use FvwmPiazza::Page;
use FvwmPiazza::Group;
use FvwmPiazza::GroupWindow;

use base qw( FVWM::Module );

use Module::Pluggable search_path => 'FvwmPiazza::Layouts',
    sub_name => 'layouts', instantiate => 'new';

our $ERROR;
our $DEBUG = 0 unless defined $DEBUG;

=head1 METHODS

=head2 new

=cut
sub new {
    my $class = shift;
    my %params = (
	@_
    );

    my $self = $class->SUPER::new(
	Name => "FvwmPiazza",
	Mask => M_STRING | M_FOCUS_CHANGE,
	EnableAlias => 1,
	Debug => 0,
	);
    bless $self, $class;

    $self->init(%params);
    return $self;
} # new

=head2 init

=cut

sub init {
    my $self = shift;
    my %params = (
	@_
    );

    $self->{configTracker} = $self->track('ModuleConfig',
		DefaultConfig => {
		Struts => '0 0 0 0',
		Include => '',
		Exclude => '',
		UseMaximize => 1,
	},
    );
    $self->{pageTracker} = $self->track("PageInfo");
    $self->{winTracker} = $self->track("WindowList", "winfo");

    $self->{all_windows} = {};
    $self->{current_group} = undef;
    my $maximize_val = $self->{configTracker}->data('UseMaximize');
    $self->{maximize} = ($maximize_val =~ /(1|true|on)/i);
    $self->{desks} = {};
    $self->{Layouts} = {};
    foreach my $lay ($self->layouts())
    {
	$self->debug("Layout: " . ref $lay);
	$self->{Layouts}->{$lay->name()} = $lay;
    }

    #
    # initializae the default layouts, if any
    #
    my $conf = $self->{configTracker}->data;
    my $this_page = $self->{pageTracker}->data;
    my $desk_pages_x = $this_page->{desk_pages_x};
    my $desk_pages_y = $this_page->{desk_pages_y};
    foreach my $key (sort keys %{$conf})
    {
	if ($key =~ /Layout(\d+)-(\d+)-(\d+)/) # By Page
	{
	    my $desk_n = $1;
	    my $pagex_n = $2;
	    my $pagey_n = $3;
	    $self->debug("init: desk_n=$desk_n, pagex_n=$pagex_n, pagey_n=$pagey_n, desk_pages_x=$desk_pages_x, desk_pages_y=$desk_pages_y");

	    my $action = '';
	    my $max_win = 1;
	    my @options = ();
	    if ($conf->{$key} =~ /Full/)
	    {
		$action = 'Full';
		$max_win = 1;
	    }
	    else
	    {
		my $opt_str;
		($action, $opt_str) = split(' ', $conf->{$key}, 2);
                @options = $self->parse_options($opt_str);
                $max_win = shift @options;
	    }
	    $self->init_new_page(desk_n=>$desk_n,
				 page_x=>$pagex_n,
				 page_y=>$pagey_n);
	    my $page_info = $self->{desks}->{$desk_n}->{$pagex_n}->{$pagey_n};
	    $page_info->{LAYOUT} = $action;
	    $page_info->{MAX_WIN} = $max_win;
	    $page_info->{OPTIONS} = \@options;
	}
	elsif ($key =~ /Layout(\d+)/) # By Desktop
	{
	    my $desk_n = $1;
	    $self->debug("init: desk_n=$desk_n, desk_pages_x=$desk_pages_x, desk_pages_y=$desk_pages_y");

	    my $action = '';
	    my $max_win = 1;
	    my @options = ();
	    if ($conf->{$key} =~ /Full/)
	    {
		$action = 'Full';
		$max_win = 1;
	    }
	    else
	    {
		my $opt_str;
		($action, $opt_str) = split(' ', $conf->{$key}, 2);
                @options = $self->parse_options($opt_str);
                $max_win = shift @options;
	    }
	    for (my $pagex=0; $pagex < $desk_pages_x; $pagex++)
	    {
		for (my $pagey=0; $pagey < $desk_pages_y; $pagey++)
		{
		    if (!exists $self->{desks}->{$desk_n}->{$pagex}->{$pagey})
		    {
			$self->init_new_page(desk_n=>$desk_n,
					     page_x=>$pagex,
					     page_y=>$pagey);
			my $page_info = $self->{desks}->{$desk_n}->{$pagex}->{$pagey};
			$page_info->{LAYOUT} = $action;
			$page_info->{MAX_WIN} = $max_win;
			$page_info->{OPTIONS} = \@options;
		    }
		}
	    }
	}
    }

    $self->addHandler(M_STRING, sub {
		      my ($module, $event) = @_;
		      $self->handle_command($event);
		      });

    $self->addHandler(M_FOCUS_CHANGE,
		      sub {
		      my ($module, $event) = @_;
		      $self->handle_focus_event($event);
		      });

    $self->{pageTracker}->observe("desk/page changed", sub {
	my $module = shift;
	$self->observe_page_change(@_);
    });
    $self->{winTracker}->observe("window moved", sub {
	my $module = shift;
	$self->observe_window_movement(@_);
    });
    $self->{winTracker}->observe("window added", sub {
	my $module = shift;
	$self->observe_window_addition(@_);
    });
    $self->{winTracker}->observe("window deleted", sub {
	my $module = shift;
	$self->observe_window_deletion(@_);
    });
    $self->{winTracker}->observe("window iconified", sub {
	my $module = shift;
	$self->observe_window_iconify(@_);
    });
    $self->{winTracker}->observe("window deiconified", sub {
	my $module = shift;
	$self->observe_window_deiconify(@_);
    });

    return $self;
} # init

=head2 start

$self->start();

Start the event loop.

=cut
sub start {
    my $self = shift;

    $self->eventLoop;
} # start

=head1 Handlers

=head2 observe_window_movement

A FVWM::Tracker::WindowList observer,
which tracks window movement
(so we can see if the window has changed desks/pages).

=cut
sub observe_window_movement {
    my $self = shift;
    my $tracker = shift;
    my $data = shift;
    my $wid = shift;
    my $old_data = shift;

    if (exists $self->{all_windows}->{$wid}
	and defined $self->{all_windows}->{$wid})
    {
	my $window = $self->{all_windows}->{$wid};
	my $old_desk = $old_data->{desk};
	my $old_page_x = $old_data->{page_nx};
	my $old_page_y = $old_data->{page_ny};
	my $new_desk = $data->{$wid}->{desk};
	my $new_page_x = $data->{$wid}->{page_nx};
	my $new_page_y = $data->{$wid}->{page_ny};

	if ((defined $old_desk
	     and $old_desk != $new_desk)
	    or (defined $old_page_x and $new_page_x != $old_page_x)
	    or (defined $old_page_y and $new_page_y != $old_page_y)
	   )
	{
	    # window has changed desks or pages
	    $self->debug("Window changed Desk/Page from $old_desk (${old_page_x}x${old_page_y}) to $new_desk(${new_page_x}x${new_page_y})");
	    my $old_gid = $window->{GID};
	    my $old_page_info = $self->{desks}->{$old_desk}->{$old_page_x}->{$old_page_y};
	    if (defined $old_page_info and defined $old_gid)
	    {
		$old_page_info->remove_window_from_page(window=>$wid,
							group=>$old_gid);
	    }
	    $self->manage_window(desk=>$new_desk,
				 pagex=>$new_page_x,
				 pagey=>$new_page_y,
				 window=>$wid);
	}
    }
} # observe_window_movement

=head2 observe_window_addition

A FVWM::Tracker::WindowList observer,
which tracks new windows

=cut
sub observe_window_addition {
    my $self = shift;
    my $tracker = shift;
    my $data = shift;
    my $wid = shift;
    my $old_data = shift;

    if (!$self->check_interest(window=>$wid))
    {
       $self->debug("Not Interested in window $wid");
       return 0;
    }
    my $new_window = FvwmPiazza::GroupWindow->new(
        ID=>$wid,
        MAXIMIZE=>$self->{maximize});
    $self->{all_windows}->{$wid} = $new_window;
    $self->manage_window(window=>$wid);
} # observe_window_addition

=head2 observe_window_deletion

A FVWM::Tracker::WindowList observer,
which tracks window destruction.

=cut
sub observe_window_deletion {
    my $self = shift;
    my $tracker = shift;
    my $data = shift;
    my $wid = shift;
    my $old_data = shift;

    if (exists $self->{all_windows}->{$wid}
	and defined $self->{all_windows}->{$wid})
    {
	my $gid = $self->{all_windows}->{$wid}->{GID};
	delete $self->{all_windows}->{$wid};

	$self->demanage_window(window=>$wid,
			       group=>$gid);

    }
} # observe_window_deletion

=head2 observe_window_iconify

A FVWM::Tracker::WindowList observer,
which tracks window iconify.

=cut
sub observe_window_iconify {
    my $self = shift;
    my $tracker = shift;
    my $data = shift;
    my $wid = shift;
    my $old_data = shift;

    if (exists $self->{all_windows}->{$wid}
	and defined $self->{all_windows}->{$wid})
    {
	# Treat an iconified window as if it has been deleted,
	# since we can no longer see it.  However, don't
	# delete the window from the global windows, just
	# remove it from its group.

	my $gid = $self->{all_windows}->{$wid}->{GID};
	$self->{all_windows}->{$wid}->{GID} = undef;
	$self->demanage_window(window=>$wid,
			       group=>$gid);
    }
} # observe_window_iconify

=head2 observe_window_deiconify

A FVWM::Tracker::WindowList observer,
which tracks window deiconify.

=cut
sub observe_window_deiconify {
    my $self = shift;
    my $tracker = shift;
    my $data = shift;
    my $wid = shift;
    my $old_data = shift;

    if (exists $self->{all_windows}->{$wid}
	and defined $self->{all_windows}->{$wid})
    {
	# Treat a de-iconified window as if it has been added,
	# since we can now see it.
	$self->manage_window(window=>$wid);
    }
} # observe_window_deiconify

=head2 observe_page_change

Respond to a page or desk-change event.

=cut
sub observe_page_change {
    my $self = shift;
    my $tracker = shift;
    my $data = shift;

    if (!$self->{_transaction_on})
    {
	$self->apply_tiling(layout=>'Refresh');
    }
} # observe_page_change

=head2 handle_focus_event

Respond to a focus window event.

=cut
sub handle_focus_event {
    my $self = shift;
    my $event = shift;

    my $wid = $event->args->{win_id};

    if ($event->type == M_FOCUS_CHANGE)
    {
	if (exists $self->{all_windows}->{$wid}
	    and defined $self->{all_windows}->{$wid})
	{
	    $self->{current_group} = $self->{all_windows}->{$wid}->{GID};
	    $self->debug("current_group=" . $self->{current_group});
	}
	else
	{
	    $self->{current_group} = undef;
	}
    }
} # handle_focus_event


=head2 handle_command

Respond to a command (SendToModule,M_STRING event)

=cut
sub handle_command {
    my $self = shift;
    my $event = shift;

    my $msg = $event->_text;
    $msg =~ s/^\s+//;
    return unless $msg;

    my ($action, $args) = split(/\s+/, $msg, 2);
    return unless $action;

    if ($action =~ /dump/i)
    {
	$self->debug("===============================\n"
		     . Dump($self)
		     . "---------------------\n");
    }
    elsif ($action =~ /transaction/i)
    {
	$self->set_transaction(event=>$event,
			       action=>$action,
			       args=>$args);
    }
    elsif ($action =~ /(next|prev)group/i)
    {
	$self->move_window_group(event=>$event,
				 action=>$action,
				 args=>$args);
    }
    else
    {
	$self->apply_tiling(layout=>$action,
			    args=>$args);
    }
} # handle_command

=head1 Helper methods

=head2 set_transaction

Set "transaction" on or off;
this will temporarily disable some handlers
since we don't want to react to things that
we ourselves caused.

=cut
sub set_transaction {
    my $self = shift;
    my %args = (
		event=>undef,
		action=>'Transaction',
		args=>'',
		@_
	       );
    my ($on_off, $other_args) = get_token($args{args});
    my $on = 0;
    if ($on_off =~ /^(on|true|start)$/i)
    {
	$on = 1;
    }
    $self->{_transaction_on} = $on;
} # set_transaction

=head2 move_window_group

Move the given window to the next or previous
group on this page.

=cut
sub move_window_group {
    my $self = shift;
    my %args = (
		event=>undef,
		action=>'',
		args=>'',
		@_
	       );
    my $action = $args{action};
    my $wid = $args{event}->_win_id;
    if (!defined $wid or !$wid)
    {
	$self->showError("$action: no window given");
	return 0;
    }
    if (!exists $self->{all_windows}->{$wid}
	or !defined $self->{all_windows}->{$wid})
    {
	$self->showError(sprintf("%s: window 0x%x not known", $action, $wid));
	return 0;
    }
    my $desk = $self->{pageTracker}->data->{desk_n};
    my $pagex = $self->{pageTracker}->data->{page_nx};
    my $pagey = $self->{pageTracker}->data->{page_ny};

    if (!exists $self->{desks}->{$desk}->{$pagex}->{$pagey}
	or !defined $self->{desks}->{$desk}->{$pagex}->{$pagey})
    {
	$self->showError("$desk-$pagex-$pagey: no page info");
	return 0;
    }
    my $page_info = $self->{desks}->{$desk}->{$pagex}->{$pagey};
    if ($args{action} =~ /next/i)
    {
	if ($page_info->
	    move_window_to_next_group(window=>$self->{all_windows}->{$wid}))
	{
	    $self->apply_tiling(layout=>'Refresh');
	}
    }
    else
    {
	if ($page_info->
	    move_window_to_prev_group(window=>$self->{all_windows}->{$wid}))
	{
	    $self->apply_tiling(layout=>'Refresh');
	}
    }
} # move_window_group

=head2 apply_tiling

Apply the requested tiling layout.

None Full

Additional layouts are provided by layout plugins.

=cut
sub apply_tiling {
    my $self = shift;
    my %args = (
		layout=>'Full',
		args=>'',
		@_
	       );

    my $desk = $self->{pageTracker}->data->{desk_n};
    my $pagex = $self->{pageTracker}->data->{page_nx};
    my $pagey = $self->{pageTracker}->data->{page_ny};

    if (!exists $self->{desks}->{$desk}->{$pagex}->{$pagey}
	or !defined $self->{desks}->{$desk}->{$pagex}->{$pagey})
    {
	$self->init_new_page();
    }
    my $page_info = $self->{desks}->{$desk}->{$pagex}->{$pagey};

    my $layout = $args{layout};
    $self->debug("LAYOUT=$layout ARGS=$args{args}");
    my @options = $self->parse_options($args{args});
    my $max_win = shift @options;

    if ($layout =~ /Inc/)
    {
	$layout = $page_info->{LAYOUT};
	$max_win = $page_info->{MAX_WIN} + $max_win;
	@options = @{$page_info->{OPTIONS}};
    }
    elsif ($layout =~ /Dec/)
    {
	$layout = $page_info->{LAYOUT};
	$max_win = $page_info->{MAX_WIN} - $max_win;
	@options = @{$page_info->{OPTIONS}};
    }
    elsif ($layout eq 'Refresh')
    {
	if ($page_info->{LAYOUT} eq 'None')
	{
	    # do nothing
	    return 1;
	}
	$layout = $page_info->{LAYOUT};
	$max_win = $page_info->{MAX_WIN};
	@options = @{$page_info->{OPTIONS}};
    }
    $self->debug("Tiler: max_win=$max_win\n");

    $max_win = 2 if !$max_win;
    $max_win = 1 if $layout eq 'Full';

    if ($page_info->num_groups() == 0
	or $page_info->num_windows() == 0)
    {
	# no groups, no windows, remember the args and return
	$page_info->{LAYOUT} = $layout;
	$page_info->{MAX_WIN} = $max_win;
	$page_info->{OPTIONS} = \@options;
	return 1;
    }

    #
    # "None" will clear layouts and reset the page info completely.
    #
    if (($layout eq 'None'))
    {
        if ($self->{maximize})
        {
            $self
                ->postponeSend("All (CurrentPage, Maximizable) Maximize False");
        }

	delete $self->{desks}->{$desk}->{$pagex}->{$pagey};
	$self->init_new_page(desk_n=>$desk,
			     page_x=>$pagex,
			     page_y=>$pagey);
	$page_info = $self->{desks}->{$desk}->{$pagex}->{$pagey};
	$page_info->{LAYOUT} = $layout;
	$page_info->{MAX_WIN} = undef;
	$page_info->{OPTIONS} = [];
	return 1;
    }
    #
    # Start transation
    #
    $self->postponeSend("SendToModule " . $self->name() . " Transaction start");

    my $vp_width = $self->{pageTracker}->data->{'vp_width'};
    my $vp_height = $self->{pageTracker}->data->{'vp_height'};
    my $struts = $self->{configTracker}->data('Struts');

    my ($left_offset, $right_offset, $top_offset, $bottom_offset)
	= split ' ', $struts;

    if (exists $self->{Layouts}->{$layout}
	and defined $self->{Layouts}->{$layout})
    {
	$self->{Layouts}->{$layout}
	->apply_layout(
	    area=>$page_info,
	    left_offset=>$left_offset,
	    right_offset=>$right_offset,
	    top_offset=>$top_offset,
	    bottom_offset=>$bottom_offset,
	    vp_width=>$vp_width,
	    vp_height=>$vp_height,
	    max_win=>$max_win,
	    options=>\@options,
	    tiler=>$self,
	);
	$page_info->{LAYOUT} = $layout;
	$page_info->{MAX_WIN} = $max_win;
	$page_info->{OPTIONS} = \@options;
    }

    #
    # Stop transation
    #
    $self->postponeSend("SendToModule " . $self->name() . " Transaction stop");

} # apply_tiling

=head2 manage_window

A new or newly visible window needs to be managed.

=cut
sub manage_window {
    my $self = shift;
    my %args = (
		window=>undef,
		desk=>$self->{pageTracker}->data->{desk_n},
		pagex=>$self->{pageTracker}->data->{page_nx},
		pagey=>$self->{pageTracker}->data->{page_ny},
		@_
	       );
    my $wid = $args{window};

    my $desk_n = $args{desk};
    my $pagex = $args{pagex};
    my $pagey = $args{pagey};
    my $cur_group = 0;
    if (exists $self->{current_group}
	and defined $self->{current_group})
    {
	$cur_group = $self->{current_group};
    }
    if (exists $self->{desks}->{$desk_n}->{$pagex}->{$pagey}
	and defined $self->{desks}->{$desk_n}->{$pagex}->{$pagey})
    {
	my $page_info = $self->{desks}->{$desk_n}->{$pagex}->{$pagey};
	my $old_win_count = $page_info->num_windows();
	if (!$page_info->add_window_to_page(window=>$self->{all_windows}->{$wid},
					    current_group=>$cur_group))
	{
	    $self->debug("failed to add window: " . $page_info->error());
	}
	my $new_win_count = $page_info->num_windows();
	$self->debug("PageInfo[$desk_n][$pagex][$pagey] window count $old_win_count => $new_win_count");
    }
    else
    {
	$self->debug("PageInfo[$desk_n][$pagex][$pagey] does not exist, cannot add $wid");
    }
    # Only do a refresh if we are not in the middle of a transation
    # and this change is for the current page
    if (!$self->{_transaction_on}
	and $desk_n == $self->{pageTracker}->data->{desk_n}
	and $pagex == $self->{pageTracker}->data->{page_nx}
	and $pagey == $self->{pageTracker}->data->{page_ny}
       )
    {
	$self->apply_tiling(layout=>'Refresh');
    }
} # manage_window

=head2 demanage_window

A destroyed or newly invisible window needs to be de-managed.

=cut
sub demanage_window {
    my $self = shift;
    my %args = (
		window=>undef,
		group=>undef,
		desk=>$self->{pageTracker}->data->{desk_n},
		pagex=>$self->{pageTracker}->data->{page_nx},
		pagey=>$self->{pageTracker}->data->{page_ny},
		@_
	       );
    my $wid = $args{window};
    my $gid = $args{group};

    my $desk_n = $args{desk};
    my $pagex = $args{pagex};
    my $pagey = $args{pagey};
    if (defined $gid
	and exists $self->{desks}->{$desk_n}->{$pagex}->{$pagey}
	and defined $self->{desks}->{$desk_n}->{$pagex}->{$pagey})
    {
	my $page_info = $self->{desks}->{$desk_n}->{$pagex}->{$pagey};
	$page_info->remove_window_from_page(window=>$wid,
					    group=>$gid);
    }
    if (!$self->{_transaction_on})
    {
	$self->apply_tiling(layout=>'Refresh');
    }
} # demanage_window

=head2 init_new_page

Initialize page information for the current page.

=cut
sub init_new_page {
    my $self = shift;
    my %args = (
		desk_n=>$self->{pageTracker}->data->{desk_n},
		page_x=>$self->{pageTracker}->data->{page_nx},
		page_y=>$self->{pageTracker}->data->{page_ny},
		@_
	       );

    my $desk_n = $args{desk_n};
    my $pagex = $args{page_x};
    my $pagey = $args{page_y};
    $desk_n = 0 if !defined $desk_n;
    $pagex = 0 if !defined $pagex;
    $pagey = 0 if !defined $pagey;
    if (!exists $self->{desks}->{$desk_n}
	or !defined $self->{desks}->{$desk_n})
    {
	$self->{desks}->{$desk_n} = {};
    }
    if (!exists $self->{desks}->{$desk_n}->{$pagex}
	or !defined $self->{desks}->{$desk_n}->{$pagex})
    {
	$self->{desks}->{$desk_n}->{$pagex} = {};
    }
    if (!exists $self->{desks}->{$desk_n}->{$pagex}->{$pagey}
	or !defined $self->{desks}->{$desk_n}->{$pagex}->{$pagey})
    {
	$self->{desks}->{$desk_n}->{$pagex}->{$pagey} = 
	    FvwmPiazza::Page->new(DESK=>$desk_n,
				 PAGEX=>$pagex,
				 PAGEY=>$pagey,
				 LAYOUT=>'None');
	my %page_windows = $self->get_page_windows(desk=>$desk_n,
						   pagex=>$pagex,
						   pagey=>$pagey);
	my @windows = ();
	foreach my $wid (sort keys %page_windows)
	{
	    my $pwin = $page_windows{$wid};
	    my $new_window = FvwmPiazza::GroupWindow
		->new(ID=>$wid,
		      X=>$pwin->{x},
		      Y=>$pwin->{y},
		      WIDTH=>$pwin->{width},
		      HEIGHT=>$pwin->{height},
		      DESK=>$pwin->{desk},
		      PAGEX=>$pwin->{page_nx},
		      PAGEY=>$pwin->{page_ny},
                      MAXIMIZE=>$self->{maximize},
		     );
	    $self->{all_windows}->{$wid} = $new_window;
	    push @windows, $new_window;
	}
	if (@windows
	    and !defined $self->{desks}->{$desk_n}->{$pagex}->{$pagey}
	->windows_to_n_groups(window_list=>\@windows, n_groups=>1))
	{
	    $self->debug("init_new_page ($desk_n/$pagex/$pagey) error: "
	    . FvwmPiazza::Page->error());
	}
    }
} # init_new_page

=head2 check_interest

Look at the properties of the given window to see if we are interested in it.
We aren't interested in SKIP_PAGER, SKIP_TASKBAR, DOCK or Withdrawn windows.
We also aren't interested in transient windows.

Also, we may not be interested in windows of certain classes or names.

$res = $self->check_interest(window=>$id, tracker=>$tracker);

$res = $self->check_interest(window=>$id, event=>$event);

=cut
sub check_interest {
    my $self = shift;
    my %args = (
		window=>undef,
		tracker=>undef,
		event=>undef,
		@_
	       );
    if (!defined $args{window} or !$args{window})
    {
	return 0;
    }
    my $wid = $args{window};
    my $window;
    if (ref $args{window} eq "FVWM::Window")
    {
	$window = $args{window};
	$wid = $window->{id};
    }
    elsif (ref $args{window} eq "FvwmPiazza::GroupWindow")
    {
	$wid = $window->{ID};
    }
    my $interest = 1;
    my $include = $self->{configTracker}->data('Include');
    my $exclude = $self->{configTracker}->data('Exclude');
    my @names = ();
    open (XPROP, "xprop -id $wid |") or die "Could not start xprop";
    while (<XPROP>)
    {
	if (/_NET_WM_WINDOW_TYPE_DOCK/
	    or /_NET_WM_STATE_SKIP_PAGER/
	    or /_NET_WM_STATE_SKIP_TASKBAR/
	    or /_NET_WM_WINDOW_TYPE_DIALOG/
	    or /window state: Withdrawn/
	    or /_NET_WM_STATE_STICKY/
	    or /_NET_WM_WINDOW_TYPE_DIALOG/
	    or /WM_TRANSIENT_FOR/
	    or /_NET_WM_WINDOW_TYPE_SPLASH/
	    or /_NET_WM_WINDOW_TYPE_DESKTOP/
	    or /_NET_WM_WINDOW_TYPE_MENU/
	)
	{
	    $interest = 0;
	    $self->debug(sprintf("No interest in 0x%x because %s", $wid, $_));
	    last;
	}
	# if we are including or excluding, then remember the class and names
	if (($exclude or $include)
	    and (/WM_CLASS/
		 or /WM_ICON_NAME/
		 or /WM_NAME/)
	   )
	{
	    if (/=\s*(.*)/)
	    {
		push @names, $1;
	    }

	}
    }
    close XPROP;
    # check the names, if we are interested
    if ($interest and @names)
    {
	# if we aren't checking includes, everything is included
	my $included = ($include ? 0 : 1);
	my $excluded = 0;
	foreach my $name (@names)
	{
	    if ($include and $name =~ /$include/i)
	    {
		$included = 1;
	    }
	    if ($exclude and $name =~ /$exclude/i)
	    {
		$excluded = 1;
		$self->debug(sprintf("No interest in 0x%x because excluding '%s'", $wid, $name));
	    }
	}
	if (!$included or $excluded)
	{
	    $interest = 0;
	}
    }

    return $interest;
} # check_interest

=head2 parse_options

Parse the option string, either old-style or new-style.
Return max_win and the options array.

max_win is the first thing in the array which is returned.

=cut
sub parse_options {
    my $self = shift;
    my $opt_str = shift;

    my $max_win = 1;
    my @options = ();
    if ($opt_str)
    {
        if ($opt_str =~ /\s/)
        {
            @options = split(/\s+/, $opt_str);
        }
        else # old-style
        {
            @options = split(/,/, $opt_str);
        }
    }
    else
    {
        # no options given
        return ($max_win);
    }

    # old-style parsing
    if (defined $options[0] and $options[0] =~ /^(\d+)$/)
    {
        $max_win = $1;
        shift @options;
    }
    else # new-style
    {
        local @ARGV = @options;
        my $parser = new Getopt::Long::Parser(
            config => [qw(pass_through)]
            );
        if (!$parser->getoptions("max_win=i" => \$max_win))
        {
            $self->debug("getopt parsing failed");
        }
        @options = @ARGV;
    }
    return ($max_win, @options);
} # parse_options

=head2 dump_properties

Dump the properties of the given window.

=cut
sub dump_properties {
    my $self = shift;
    my %args = (
		window=>undef,
		@_
	       );
    my $wid = $args{window};
    open (XPROP, "xprop -id $wid |") or die "Could not start xprop";
    while (<XPROP>)
    {
	$self->debug("$_");
    }
    close XPROP;

} # dump_properties

=head2 get_page_windows

Get the windows on the given page.

=cut
sub get_page_windows {
    my $self = shift;
    my %args = (
		desk=>undef,
		pagex=>undef,
		pagey=>undef,
		@_
	       );

    # Find all the windows on this page
    my %page_windows = ();
    my $windata = $self->{winTracker}->data();
    while (my ($id, $window) = each %{$windata})
    {
	if (defined $window->{name})
	{
	    $self->debug("\t$id - " . $window->{name});
	}
	next unless (
	    $window->{desk} == $args{desk}
	    and $window->{page_nx} == $args{pagex}
	    and $window->{page_ny} == $args{pagey}
	);
	next unless $self->check_interest(window=>$id);

	$page_windows{$id} = $window;
    }
    return %page_windows;
} # get_page_windows

=head1 REQUIRES

    FVWM::Module
    Class::Base

=head1 INSTALLATION

To install this module, run the following commands:

    perl Build.PL
    ./Build
    ./Build test
    ./Build install

Or, if you're on a platform (like DOS or Windows) that doesn't like the
"./" notation, you can do this:

   perl Build.PL
   perl Build
   perl Build test
   perl Build install

In order to install somewhere other than the default, such as
in a directory under your home directory, like "/home/fred/perl"
go

   perl Build.PL --install_base /home/fred/perl

as the first step instead.

This will install the files underneath /home/fred/perl.

You will then need to make sure that you alter the PERL5LIB variable to
find the modules.

Therefore you will need to change the PERL5LIB variable to add
/home/fred/perl/lib

	PERL5LIB=/home/fred/perl/lib:${PERL5LIB}

=head1 SEE ALSO

perl(1).
fvwm(1)

=head1 BUGS

Please report any bugs or feature requests to the author.

=head1 AUTHOR

    Kathryn Andersen (RUBYKAT)
    perlkat AT katspace dot org

=head1 COPYRIGHT AND LICENCE

Copyright (c) 2009-2011 by Kathryn Andersen

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of FvwmPiazza::Tiler
__END__
