#!/usr/bin/perl

use strict;
use lib '../lib';
use Data::Dumper;
$Data::Dumper::Indent = 1;

use Gtk2;
use Gtk2::Ex::FormFactory;

main: {
	Gtk2->init;

	$Gtk2::Ex::FormFactory::DEBUG = 0;

	my $database = My::Database->new (
		discs => [
		    My::Disc->new(
			artist => "Michael Oldfield",
			album  => "Tubular Bells",
			titles => [ "Part I", "Part II", "Part III" ],
			broken_jewel_case => 0,
			genre => "instrumental",
			quality => 2,
		    ),
		    My::Disc->new(
			artist => "Jamiroquai",
			album  => "A Funk Odyssey",
			titles => [ "Bla", "Foo", "Baz" ],
			broken_jewel_case => 1,
			genre => "soul",
			quality => 1,
			cover_filename => "cover.jpg",
		    ),
		],
		selected_discs_idx => [ 1 ],
	);

	my $gui_state = My::GuiState->new(
	    selected_page => 4,
	);

	my $context = Gtk2::Ex::FormFactory::Context->new;

	$context->add_object (
		name	=> "database",
		buffered => 0,
		object	=> undef,
		attr_accessors_href => {
			get_discs => sub {
				my $self = shift;
				my (@slist_data);
				push @slist_data, [ $_->get_artist, $_->get_album ]
					for @{$self->get_discs};
				return \@slist_data;
			},
		},
		attr_depends_href => {
			selected_disc => "selected_discs_idx",
		}
	);

	$context->add_object (
		name	=> "disc",
		buffered => 0,
		aggregated_by => "database.selected_disc",
		attr_accessors_href => {
			get_titles => sub {
				my $self = shift;
				my (@slist_data, $i);
				push @slist_data, [ ++$i, $_ ]
					for @{$self->get_titles};
				return \@slist_data;
			},
			set_titles => sub {
				my $self = shift;
				my ($slist_data) = @_;
				my @titles;
				push @titles, $_->[1] for @{$slist_data};
				return $self->set_titles(\@titles);
			},
		},
		attr_activity_href => {
			album => sub {
				$_[0]->get_artist ne 'Michael Oldfield';
			},
		},
		attr_depends_href => {
			album => "disc.artist",
		},
	);
	
	$context->add_object (
		name 	=> "gui_state",
		object	=> $gui_state,
	);
	
	$context->add_object (
		name 	=> "disabled",
		object	=> undef,
	);
	
	$context->set_object( database => $database);

	my @table_childs;
	for ( 1..11 ) {
		push @table_childs, Gtk2::Ex::FormFactory::Button->new (
			label => "Child $_",
		);
	}

	my $ff;

	push @table_childs, Gtk2::Ex::FormFactory::VBox->new (
		expand  => 1,
		title   => "Child $_",
		content => [
			Gtk2::Ex::FormFactory::Button->new (
				label => "Change Cursor",
				clicked_hook => sub {
					$ff->change_mouse_cursor("watch");
					sleep 1;
					$ff->change_mouse_cursor();
					1;
				},
			),
			Gtk2::Ex::FormFactory::Button->new (
				label => "Extend NB",
				clicked_hook => sub {
					extend_nb($ff);
				},
			),
			Gtk2::Ex::FormFactory::Button->new (
				label => "Reduce NB",
				clicked_hook => sub {
					reduce_nb($ff);
				},
			),
		],
	);
	
	foreach my $nr ( 1 ) {
	  $ff = Gtk2::Ex::FormFactory->new (
	    context => $context,
	    sync    => 1,
	    content => [
	      Gtk2::Ex::FormFactory::Window->new (
		name    => "window_$nr",
		title   => "FormFactory Test Application",
		content => [
		  menu => {
		    menu_tree => [
		      _File => {
			item_type => '<Branch>',
			children => [
			  _New => {
			    item_type   => '<StockItem>',
			    extra_data  => 'gtk-new',
			    callback    => sub { print "new\n" },
			    accelerator => '<ctrl>N',
			  },
			  _Save => {
			    item_type   => '<StockItem>',
			    extra_data  => 'gtk-save',
			    callback    => sub { print "save\n" },
			    accelerator => '<ctrl>S',
			    object      => "disabled",
			  },
			  _Quit => {
			    item_type   => '<StockItem>',
			    extra_data  => 'gtk-quit',
			    callback    => sub {
			    	print "quit\n";
				$ff->close;
				Gtk2->main_quit;
			    },
			    accelerator => '<ctrl>Q',
			  },
			],
		      },
		    ],
		  },
	          Gtk2::Ex::FormFactory::Notebook->new (
		    name    => "notebook",
		    attr    => "gui_state.selected_page",
		    expand  => 1,
		    content => [
		      Gtk2::Ex::FormFactory::VBox->new (
			title   => "Select Album",
			content => [
		          Gtk2::Ex::FormFactory::VBox->new (
			    expand  => 1,
			    content => [
			      Gtk2::Ex::FormFactory::List->new (
			      	name	    => "discs",
			        expand      => 1,
				attr        => "database.discs",
				attr_select => "database.selected_discs_idx",
				label       => "Album Selection",
				tip         => "Select an entry for modification",
				columns     => [ "Artist", "Album" ],
				types       => [ "text",   "text"  ],
				selection_mode   => "multiple",
				properties  => {
				    'enable-search' => 1,
				},
			      ),
			    ],
			  ),
			],
		      ),
		      Gtk2::Ex::FormFactory::VBox->new (
			title   => "Edit Album",
			content => [
		          Gtk2::Ex::FormFactory::Form->new (
			    content => [
			      Gtk2::Ex::FormFactory::Entry->new (
				attr   => "disc.artist",
				label  => "Artist",
				tip    => "Name of the artist",
				rules  => "not-empty",
				width  => 100,
			      ),
			      Gtk2::Ex::FormFactory::Label->new (
				attr   => "disc.artist",
				label  => "Artist",
			      ),
			      Gtk2::Ex::FormFactory::Combo->new (
				attr   => "disc.album",
				label  => "Album",
				tip    => "Name of the album, 1st view",
				rules  => "not-empty",
			      ),
			      Gtk2::Ex::FormFactory::Entry->new (
				attr   => "disc.album",
				label  => "Album 2nd view",
				tip    => "Name of the album, 2nd view",
				rules  => "not-empty",
				inactive => "invisible",

			      ),
			      Gtk2::Ex::FormFactory::YesNo->new (
				attr   => "disc.broken_jewel_case",
				label  => "State of jewel case",
				tip    => "Indicates whether the jewel ".
					  "case is broken or not",
				true_label  => "Broken",
				false_label => "Intact",
			      ),
			      Gtk2::Ex::FormFactory::Expander->new (
			        label => "Alternative jewel case widgets",
				content => [
				  Gtk2::Ex::FormFactory::Form->new (
				    content => [
				      Gtk2::Ex::FormFactory::ToggleButton->new (
					attr   => "disc.broken_jewel_case",
					label  => "State of jewel case",
					tip    => "Indicates whether the jewel ".
						  "case is broken or not",
					true_label  => "Broken",
					false_label => "Intact",
				      ),
				      Gtk2::Ex::FormFactory::CheckButton->new (
					attr   => "disc.broken_jewel_case",
					label  => "Jewel case is broken",
					detach_label => 1,
					tip    => "Indicates whether the jewel ".
						  "case is broken or not",
				      ),
				      Gtk2::Ex::FormFactory::CheckButton->new (
					attr   => "disc.broken_jewel_case",
					label  => "Broken",
					tip    => "Indicates whether the jewel ".
						  "case is broken or not",
				      ),
				    ],
				  ),
				],
			      ),
			      Gtk2::Ex::FormFactory::Popup->new (
				attr   => "disc.genre",
				label  => "Genre",
				tip    => "Select to which genre this album belongs",
			      ),
			      Gtk2::Ex::FormFactory::Popup->new (
				attr   => "disc.quality",
				label  => "Quality",
				tip    => "Your opinion about the quality of this album",
			      ),
			      Gtk2::Ex::FormFactory::HBox->new (
			        label => "Quality again",
				content => [
				  Gtk2::Ex::FormFactory::RadioButton->new (
				    attr   => "disc.quality",
				    label  => "Bad",
				    value  => 0,
				  ),
				  Gtk2::Ex::FormFactory::RadioButton->new (
				    attr   => "disc.quality",
				    label  => "Medium",
				    value  => 1,
				  ),
				  Gtk2::Ex::FormFactory::RadioButton->new (
				    attr   => "disc.quality",
				    label  => "Good",
				    value  => 2,
				  ),
				],
			      ),
                              Gtk2::Ex::FormFactory::Label->new (
                                label   => "Active for Jamiroquai",
                                active_cond => sub {
                                    $context->get_object("disc")->get_artist =~ /Jam/;
                                },
                                active_depends => "disc.artist",
                              ),
			    ],
			  ),
			],
		      ),
		      Gtk2::Ex::FormFactory::VBox->new (
			title   => "Edit Titles",
			content => [
		          Gtk2::Ex::FormFactory::Form->new (
			    content => [
			      Gtk2::Ex::FormFactory::List->new (
				attr     => "disc.titles",
				label    => "Titles",
				tip      => "List of all tracks on this album",
				columns  => [ "Nr",  "Title" ],
				types    => [ "int", "text"  ],
				editable => [ 0,     1       ],
			      ),
			    ],
			  ),
			],
		      ),
		      Gtk2::Ex::FormFactory::VBox->new (
			title   => "Disc Cover",
			content => [
		          Gtk2::Ex::FormFactory::Form->new (
			    expand  => 1,
			    content => [
			      Gtk2::Ex::FormFactory::Image->new (
				attr         => "disc.cover_filename",
				tip          => "Cover of this album",
				expand_h     => 1,
				expand_v     => 1,
				with_frame   => 1,
				scale_to_fit => 1,
				max_width    => 500,
				max_height   => 500,
				bgcolor      => "#111155",
			      ),
			    ],
			  ),
			],
		      ),
		      Gtk2::Ex::FormFactory::VBox->new (
			title   => "Table Test",
			content => [
		          Gtk2::Ex::FormFactory::Table->new (
			    expand => 1,
layout => "
+[-------------+>>>>>>>>>>>]+---+
| 1            |            |   |
+[-------------+          2 |   |
|   ** 4 **    |            |   |
+-------+------+------------+   |
|       ^ 6    ^    ***     |   |
|       ^      ^  ** 7 **   |   |
|       ^      ^    ***     |   |
|       ~      +-----%------+   |
|       ^      ^     *      |   |
|       ^      ~    *8*     |   |
_ 5     ^      ^     *      |   |
+-------+------+------------+   |
|       |      ^     **     |   |
|       |      ^  ** 10 **  |   |
|       |      ^     **     |   |
~ 9     |      +------------+   |
|       |      |  ** 11 **  |   |
|       +------+-----------]+   |
|       |                12 _ 3 |
+-------+-------------------+---+
",
			    content => \@table_childs,
			  ),
			],
		      ),
		    ],
		  ),
		  Gtk2::Ex::FormFactory::DialogButtons->new (
		  	buttons => { ok => 1, apply => 1 },
		  	clicked_hook_before => sub {
			  my ($button) = @_;
			  print "User hit button '$button'\n";
			  return 1;
			},
		  	clicked_hook_after => sub {
			  my ($button) = @_;
			  if ( $button eq 'ok' or $button eq 'cancel' ) {
			    print Dumper($database, $gui_state);
			    Gtk2->main_quit;
			  }
			  return 1;
			},
		  ),
		],
	      ),
	    ],
	  );

	  $ff->open;
	  $ff->update;
	}

	Gtk2->main;
}

my $added;
my @added;
sub extend_nb {
	my ($ff) = @_;
	
	my $ff_notebook = $ff->get_widget("notebook");

	++$added;

	my $new_form = Gtk2::Ex::FormFactory::Form->new (
	    name    => "new_form_$added",
	    title   => "Added $added",
	    content => [
	        Gtk2::Ex::FormFactory::Entry->new (
		    attr  => "disc.artist",
		    label => "A test entry [$added]",
		),
	    ],
	);

	$ff_notebook->add_child_widget($new_form);

	push @added, $new_form;

	1;
}

sub reduce_nb {
	my ($ff) = @_;

	return unless $added;

	my $ff_notebook = $ff->get_widget("notebook");
	
	--$added;

	$ff_notebook->remove_child_widget(pop @added);
	
	1;
}

package My::Database;

sub get_discs			{ shift->{discs}			}
sub get_selected_discs_idx	{ shift->{selected_discs_idx}		}

sub set_discs			{ shift->{discs}		= $_[1]	}
sub set_selected_discs_idx	{ shift->{selected_discs_idx}	= $_[1]	}

sub new {
	my $class = shift;
	my %par = @_;
	my ($discs, $selected_discs_idx) = @par{'discs','selected_discs_idx'};

	$selected_discs_idx ||= [];

	my $self = bless {
		discs			=> $discs,
		selected_discs_idx	=> $selected_discs_idx,
	}, $class;
	
	return $self;
}

sub get_selected_disc {
	my $self = shift;
	my $selected_discs_idx = $self->get_selected_discs_idx;
	return if @{$selected_discs_idx} == 0;
	return $self->get_discs->[$selected_discs_idx->[0]];
}

package My::Disc;

sub get_artist			{ shift->{artist}			}
sub get_album			{ shift->{album}			}
sub get_titles			{ shift->{titles}			}
sub get_broken_jewel_case	{ shift->{broken_jewel_case}		}
sub get_genre			{ shift->{genre}			}
sub get_quality			{ shift->{quality}			}
sub get_cover_filename		{ shift->{cover_filename}		}

sub set_artist			{ shift->{artist}		= $_[1]	}
sub set_album			{ shift->{album}		= $_[1]	}
sub set_titles			{ shift->{titles}		= $_[1]	}
sub set_broken_jewel_case	{ shift->{broken_jewel_case}	= $_[1]	}
sub set_genre			{ shift->{genre}		= $_[1]	}
sub set_quality			{ shift->{quality}		= $_[1]	}
sub set_cover_filename		{ shift->{cover_filename}	= $_[1]	}

sub get_album_presets {
    $_[0]->get_artist =~ /Oldfield/i ?
    [
	"Amarok",
	"Crisis",
	"Tubular Bells",
	"Tubular Bells II",
	"Tubular Bells III",
    ]:
    [
	"A Funk Odyssey",
	"Emergency On Planet Earth",
	"Synkronized",
    ];
}

sub get_genre_list {{
	dance        => "Dance",
	techno       => "Techno",
	country      => "Country",
	soul         => "Soul",
	instrumental => "Instrumental",
}}

sub get_quality_list {[
	"Bad",
	"Medium",
	"Good",
]}

sub new {
	my $class = shift;
	my %par = @_;
	my  ($artist, $album, $titles, $broken_jewel_case, $genre) =
	@par{'artist','album','titles','broken_jewel_case','genre'};
	my  ($quality, $cover_filename) =
	@par{'quality','cover_filename'};

	my $self = bless {
		artist			=> $artist,
		album			=> $album,
		titles			=> $titles,
		broken_jewel_case	=> $broken_jewel_case,
		genre			=> $genre,
		quality			=> $quality,
		cover_filename		=> $cover_filename,
	}, $class;
	
	return $self;
}

package My::GuiState;

sub get_selected_page		{ shift->{selected_page}		}
sub set_selected_page		{ shift->{selected_page}	= $_[1]	}

sub new {
	my $class = shift;
	my %par = @_;
	my ($selected_page) = $par{'selected_page'};

	my $self = bless {
		selected_page => $selected_page,
	}, $class;

	return $self;
}

1;
