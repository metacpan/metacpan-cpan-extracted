#!/usr/bin/perl
# $Id$
use strict;

=head1 NAME

tk-itunes.pl - a Tk interface to iTunes

=head1 SYNPOSIS

% tk-itunes.pl

=head1 DESCRIPTION

The script creates a Tk interface to iTunes.  You need a Mac
with an AppleScript-aware version of iTunes to use this script,
a Tk installation, and an X Windows server.

=head1 CONFIGURATION

The script looks for a "tkitunes.rc" file in the current working
directory (for now).

=head2 Directives

=over 4

=item title

The title of the TkiTunes window.  [TkiTunes]

=item list_color

The highlight color, in RGB format, for the track listing
selection. [ 00cccc ]

=back

=head1 TO DO

* how do I refresh the playlist menu?

* how do I figure out the currently playing song, select
the right playlist, and highlight the song in the track 
listing?

* add skin support.  I just need to add colors to
everything, and make that configurable.


=head1 SEE ALSO

L<Mac::iTunes>

=head1 AUTHOR

brian d foy, E<lt>bdfoy@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2002, brian d foy, All rights reserved

You may use this software under the same terms as Perl itself.

=cut

$|++;

use vars qw( $Verbose );

use ConfigReader::Simple;
use Data::Dumper;
use Mac::iTunes;
use Mac::iTunes::AppleScript qw(:state);
use Tk;

########################################################################
my $Current    = '--> player stopped <--';
my $Time       = 0;
my @Tracks     = ();
my @Playlists  = ();
my $Playlist   = 'Library';
my $List       = '';

my $Config     = ConfigReader::Simple->new( "tkitunes.rc" );

die "Could not read configuration file!"
	unless UNIVERSAL::isa( $Config, 'ConfigReader::Simple' );
print Data::Dumper::Dumper( $Config ) if $Config->verbose > 1;
	
my $Verbose    = $Config->verbose || 0;

my $Actions    = _make_actions();

my $mw         = _make_window();
		
MainLoop;

########################################################################
sub _make_window
	{	
	my $mw = MainWindow->new( );
	$mw->resizable( 0, 0 );
	$mw->title( $Config->title || 'TikiTunes' );
	 
	my $scale_value = 0;
	my $volume = 0;
	
	my $menubar     = _menubar( $mw );
	
	my $vol_frame   = _make_frame( $mw, 'left' );
	my $left_frame  = _make_frame( $mw, 'left'  );
	my $right_frame = _make_frame( $mw, 'left' );
		
	my $volume      = _make_volume( $vol_frame, \$volume );
	
	my $buttons     = _buttons( $left_frame );
	
	my $label       = _current_label( $right_frame, \$Current  );
	my $play        = _current_label( $right_frame, \$Playlist );

	my $scale       = _scale( $right_frame, \$scale_value );

	$List           = _track_list_box( $right_frame );
	
	tie @Tracks, 'Tk::Listbox', $List;
	
	my $repeat		= _repeat( $mw, \$scale_value   );
    
	return $mw;
	}

########################################################################
sub _make_actions
	{
	my $C = Mac::iTunes->controller;
	
	my %Actions = (
		pause        => sub { $C->pause                                },
		back_track   => sub { $C->back_track                           },
		'next'       => sub { $C->next                                 },
		previous     => sub { $C->previous                             },
		stop         => sub { $C->stop                                 },

		reset_time   => sub { $Time = $C->current_track_finish         },
		track_name   => sub { $C->current_track_name                   },
		quit         => sub { $C->stop; exit                           },

		update_ui    => sub { 1 },
		playlist     => sub { $Playlist  = $_[0]; $C->set_playlist( $_[0] )  },
		position     => sub { $C->player_position                      },
		get_state    => sub { $C->player_state                         },
		
		bleat        => sub { print STDERR "Debug level is $Verbose\n" },
		debug_more   => sub { $Verbose++ % 3                           },
		debug_less   => sub { $Verbose > 0 ? $Verbose-- : 0            },

		get_tracks   => sub { 
			@Tracks = @{ $C->get_track_names_in_playlist( $_[0] || $Playlist ) }; 
			[ @Tracks ] },

		playlists    => sub { 
			@Playlists = @{ $C->get_playlists }; 
			[ @Playlists ] },
		);
	
	$Actions{volume} = sub {
		defined $_[0] ?
			$C->volume( $_[0] ) : $C->volume };
				
	$Actions{play} = sub { 
		$C->play; 
		$Actions{reset_time}->(); 
		};

	$Actions{play_track} = sub { 
		my $selected =  ( $List->curselection )[0];
		$selected = defined $selected ? $selected + 1 : 1;
		$C->play_track( $selected, $Playlist ); 
		$Actions{reset_time}->(); 
		};
	
	$Actions{refresh} = sub { 
		$Actions->{get_tracks}->($Playlist); $Actions->{playlists}->(); 
		};

	$Actions{set_playlist} = sub { 
		$Playlist = $_[0];
		$Actions->{get_tracks}->($Playlist); $Actions->{playlists}->(); 
		};
		
	$SIG{INT} = $Actions{quit};
	
	return \%Actions;
	}

sub _make_frame
	{
	my $mw   = shift;
	my $side = shift;
	
	my $frame = $mw->Frame->pack(
		-anchor => 'n',
		-side   => $side,
		);

	return $frame;
	}

sub _make_volume
	{
	my $frame = shift;
	my $value = shift;
	
	my $scale = $frame->Scale(
		-sliderlength => 10,
		-length       => 220,
		-from         => 0,
		-to           => -100,
		-orient       => 'vertical',
		-variable     => $value,
		-showvalue    => 0,
		-relief       => 'flat',
		-takefocus    => 0,
		-width        => 15,
		-troughcolor  => '#FFFF00',
		-borderwidth  => 1,
		-foreground   => '#000000',
		)->pack(
			-anchor => 'e',
			-side   => 'top',
			-fill   => 'y',
			);
	
	$scale->configure( -command => sub {
		my $level = $scale->get() + 100;
		$Actions->{volume}->( $level );
		} );
		
	return $scale;
	}

sub _buttons
	{
	my $frame = shift;
	
	my @Buttons = ( 
		[ 'Play',    '00ff00',  [ qw(play_track)       ], ],
		[ 'Pause',   'ffcc00',  [ qw(pause)            ], ],
		[ 'Stop',    'ff0000',  [ qw(stop)             ], ],
		[ 'Restart', '00ffff',  [ qw(back_track)       ], ],
		[ 'Next >>', '00ffff',  [ qw(next play       ) ], ],
		[ '<< Prev', '00ffff',  [ qw(previous play   ) ], ],
		[ 'Debug++', 'cccccc',  [ qw(debug_more bleat) ], ],
		[ 'Debug--', 'cccccc',  [ qw(debug_less bleat) ], ],
		);
						
	foreach my $pair ( @Buttons ) { _button( $frame, @$pair ) }
	
	return scalar @Buttons;	
	}
			
sub _button
	{
	my $frame     = shift;
	my $title     = shift;
	my $color     = shift;
	my $actions   = shift;
	
	my $sub = sub { 
		foreach my $action ( @$actions ) 
			{
			print STDERR "Calling $action action\n" if $Verbose > 1;
			eval { $Actions->{$action}->() } if exists $Actions->{$action};
			}  
		};
		
	return $frame->Button(
		-text                => $title,
		-command             => $sub,
		-background          => "#$color",
		-activebackground    => "#$color",
		-activeforeground    => "#FFFFFF",
		)->pack(
			-anchor  => 'w',
			-side    => 'top',
			-fill    => 'both',
			);
		
	}

sub _menubar
	{
	my $mw      = shift;

	$mw->configure( -menu => my $menubar = $mw->Menu );
	my $file_items = [
		[qw( command ~Quit -accelerator Ctrl-q -command ) => $Actions->{quit} ]
		];
	my( $edit_items, $help_items, $play_items, $refresh_items ) = ( [], [], [] );
	foreach my $playlist ( @{ $Actions->{'playlists'}->() } )
		{
		push @$play_items, [ 'command', $playlist, 
			'-command' => sub { $Playlist = $playlist;
				@Tracks = @{ $Actions->{get_tracks}->( $playlist ) } } ];
		}

	$refresh_items = [
		[ 'command', 'Playlists', -command => $Actions->{playlists}  ],
		[ 'command', 'Tracks',    -command => $Actions->{get_tracks} ],
		];
		
	my $file = _menu( $menubar, "~File",     $file_items );
	my $edit = _menu( $menubar, "~Edit",     $edit_items );
	my $play = _menu( $menubar, "~Playlist", $play_items );		
	my $help = _menu( $menubar, "~Refresh",  $refresh_items );
	my $help = _menu( $menubar, "~Help",     $help_items );
	
	return $menubar;
	}
	
sub _menu
	{
	my $menubar = shift;
	my $title   = shift;
	my $items   = shift;
	
	my $menu = $menubar->cascade( 
		-label     => $title, 
		-menuitems => $items,
		-tearoff   => 0,
		 );
		 
	return $menu;
	};

sub _current_label
	{
	my $frame = shift;
	my $value = shift;
	
	my $label = $frame->Label(
		-textvariable => $value,
		-relief       => 'flat',
		-width        => 32,
		)->pack(
			-anchor => 'e',
			-side   => 'top',
			-fill   => 'x',
			);

	return $label;
	}
	
sub _scale
	{
	my $frame = shift;
	my $value = shift;
	
	my $scale = $frame->Scale(
		-sliderlength => 5,
		-length       => 150,
		-from         => 0,
		-to           => 100,
		-orient       => 'horizontal',
		-variable     => $value,
		-showvalue    => 0,
		-relief       => 'flat',
		-state        => 'disabled',
		-takefocus    => 0,
		-width        => 5,
		-troughcolor  => '#FFFFFF',
		-borderwidth  => 1,
		-foreground   => '#000000',
		)->pack(
			-anchor => 'e',
			-side   => 'top',
			-fill   => 'x',
			);
	
	return $scale;
	}
	
sub _track_list_box
	{
	my $frame  = shift;
	
	my $color = $Config->list_color || '00cccc';
	
	my $list = $frame->Scrolled('Listbox',
		-scrollbars          => 're',
		-selectbackground    => "#$color",
		-selectmode          => "single",
		)->pack(
			-fill   => 'y', 
			-fill   => 'x', 
			-expand => 1, 
			);
		
	my $tracks = $Actions->{get_tracks}->( 'Library' );
	
	$list->bind( '<Double-Button-1>', sub { $Actions->{play_track}->() } );
		
	foreach my $track ( @$tracks )
		{
		$list->insert( 'end', $track );
		}
				
	return $list;
	}
	
sub _repeat
	{
	my $mw    = shift;
	my $scale = shift;
	
	$mw->repeat( 4_000, 
		sub { 
			my $state  = $Actions->{get_state}->();
			my $volume = $Actions->{volume}->();
			
			if( $state eq PLAYING )
				{
				my $name = $Actions->{track_name}->();
				if( length $name > 32 )
					{
					$name = substr( $name, 0, 32 ) . '...';
					}
				$Current = $name;
				
				my $pos = $Actions->{position}->();
				
				$$scale = eval { $pos * 100 / $Time };
				}
			elsif( $state eq STOPPED )
				{
				# this is a hack because iTunes does not
				# correctly report pause
				if( $Actions->{position}->() == 0 )
					{
					$$scale = 0;
					$Current = '---> stopped <---';
					}
				}
			} );
	}
	
BEGIN { @ARGV = qw( -geometry 325x260+30+30 ) }
