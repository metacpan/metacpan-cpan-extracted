#!/usr/bin/perl

# $Id: music.pl,v 1.8 2005/07/31 11:22:19 joern Exp $

use strict;

use lib '../lib';
use Gtk2::Ex::FormFactory;

require "config.pm";

main:  {
	Gtk2->init;
	Music::GUI->new->build_main_window;
	Gtk2->main;
}

package Music::GUI;

sub get_config			{ shift->{config}			}
sub get_context			{ shift->{context}			}
sub get_form_factory		{ shift->{form_factory}			}
sub get_config_form_factory	{ shift->{config_form_factory}		}
sub get_selected_genre_id	{ shift->{selected_genre_id}		}
sub get_selected_artist_id	{ shift->{selected_artist_id}		}
sub get_selected_album_id	{ shift->{selected_album_id}		}
sub get_selected_song_id	{ shift->{selected_song_id}		}

sub set_config			{ shift->{config}		= $_[1]	}
sub set_context			{ shift->{context}		= $_[1]	}
sub set_form_factory		{ shift->{form_factory}		= $_[1]	}
sub set_config_form_factory	{ shift->{config_form_factory}	= $_[1]	}
sub set_selected_genre_id	{ shift->{selected_genre_id}	= $_[1]	}

sub set_selected_artist_id	{
	my $self = shift;
	my ($id) = @_;
	$self->{selected_artist_id} = $id;
	$self->set_selected_album_id(undef);
	$id;
}
sub set_selected_album_id	{
	my $self = shift;
	my ($id) = @_;
	$self->{selected_album_id} = $id;
	$self->set_selected_song_id(undef);
	$id;
}

sub set_selected_song_id	{ shift->{selected_song_id}	= $_[1]	}

sub new {
	my $class = shift;
	
	my $config = Music::Config->new;
	
	return bless { config => $config }, $class;
}

sub create_context {
	my $self = shift;
	
	my $config = $self->get_config;
	$config->test_db_connection;

	my $context = Gtk2::Ex::FormFactory::Context->new;

	$context->add_object (
	    name   => "config",
	    object => $config,
	    attr_accessors_href => {
	        get_dbi_source_presets => [ "dbi:mysql:gtk2ff" ],
	    },
	);

	$context->add_object (
	    name   => "db",
	    object => ($config->get_db_connection_ok ? 1 : undef),
	);

	$context->add_object (
	    name	=> "gui",
	    object	=> $self,
	    attr_accessors_href => {
	        get_artists => sub {
		    my $self = shift;
		    return if !$self->get_config->get_db_connection_ok;
		    my @artist_data;
		    my $iter = Music::Artist->search_like ( name => '%', { order_by => 'name' });
		    while ( my $artist = $iter->next ) {
			push @artist_data, [ $artist->get_id, $artist->get_name ],
		    }
		    return \@artist_data;
		},
	        get_genre_list => sub {
		    return if !$self->get_config->get_db_connection_ok;
		    my @genre_data;
		    my $iter = Music::Genre->search_like ( name => '%', { order_by => 'name' });
		    while ( my $genre = $iter->next ) {
			push @genre_data, [ $genre->get_id, $genre->get_name ],
		    }
		    return \@genre_data;
		},
	        set_genre_list => sub {
		    my ($db, $data) = @_;
		    my $list  = $self->get_config_form_factory->lookup_widget("genre_list");
		    my $genre = $context->get_object("genre");
		    return if not $genre;
		    my $genre_id = $genre->get_id;
		    my $row = 0;
		    ++$row while $data->[$row][0] != $genre_id;
		    $genre->set_name($data->[$row][1]);
		    1;
		},
		get_selected_artist => sub {
		    my $artist_id = $self->get_selected_artist_id ? 
		    	            $self->get_selected_artist_id->[0] : return;
		    Music::Artist->retrieve($artist_id);
		},
		get_selected_genre => sub {
		    my $genre_id = $self->get_selected_genre_id ? 
		    	           $self->get_selected_genre_id->[0] : return;
		    Music::Genre->retrieve($genre_id);
		},
	    },
	    attr_depends_href => {
		selected_genre  => "gui.selected_genre_id",
	        selected_artist => "gui.selected_artist_id",
	    },
	);

	$context->add_object (
	    name          => "genre",
	    aggregated_by => "gui.selected_genre",
	);

	$context->add_object (
	    name		=> "artist",
	    aggregated_by	=> "gui.selected_artist",
	    attr_accessors_href => {
	        get_albums => sub {
		    my $self = shift;
		    my @album_data;
		    my $iter = $self->albums;
		    while ( my $album = $iter->next ) {
			push @album_data, [ $album->get_id, $album->get_title ],
		    }
		    return \@album_data;
		},
		get_selected_album => sub {
		    my $album_id = $self->get_selected_album_id ? 
		    	           $self->get_selected_album_id->[0] : return;
		    Music::Album->retrieve($album_id);
		},
	    },
	    attr_depends_href => {
	        selected_album  => "gui.selected_album_id",
	    },
	);

	$context->add_object (
	    name		=> "album",
	    aggregated_by	=> "artist.selected_album",
	    attr_accessors_href => {
	        get_songs => sub {
		    my $self = shift;
		    my @song_data;
		    my $iter = $self->songs;
		    while ( my $song = $iter->next ) {
			push @song_data, [ $song->get_id, $song->get_nr, $song->get_title ],
		    }
		    return \@song_data;
		},
		get_selected_song => sub {
		    my $song_id = $self->get_selected_song_id ? 
		    	          $self->get_selected_song_id->[0] : return;
		    Music::Song->retrieve($song_id);
		},
		get_genre_list => sub { $context->get_proxy("gui")->get_attr("genre_list") },
	    },
	    attr_depends_href => {
	        selected_song   => "gui.selected_song_id",
	    },
	);

	$context->add_object (
	    name		=> "song",
	    aggregated_by	=> "album.selected_song",
	);

	return $self->set_context($context);
}

sub build_main_window {
	my $self = shift;
	
	my $context = $self->create_context;

	my $ff = Gtk2::Ex::FormFactory->new (
	    context => $context,
	    sync    => 1,
	    content => [
	    	Gtk2::Ex::FormFactory::Window->new (
		    title   => "Music database - Gtk2::Ex::FormFactory example",
		    properties => {
		    	default_width  => 640,
			default_height => 640,
		    },
		    quit_on_close => 1,
		    content => [
		        $self->build_menu,
		    	Gtk2::Ex::FormFactory::Table->new (
			    expand => 1,
			    layout => "
+----------------------------------------------------+
| Buttons                                            |
+----------------------------------------------------+
| Sep                                                |
+----------------+>----------------------------------+
^ Artist list    | Artist Form                       |
|                +-----------------------------------+
|                | Album List                        |
|                +-----------------------------------+
|                | Album Form                        |
|                +-----------------------------------+
|                ^ Song List                         |
|                +-----------------------------------+
|                | Song Form                         |
+----------------+-----------------------------------+
",
			    content => [
				$self->build_buttons,
				Gtk2::Ex::FormFactory::HSeparator->new(),
			    	$self->build_artist_list,
				$self->build_artist_form,
				$self->build_album_list,
				$self->build_album_form,
				$self->build_song_list,
				$self->build_song_form,
			    ],
			),
		    ],
		),
	    ],
	);
	
	$ff->open;
	$ff->update;
	
	$self->set_form_factory($ff);
	
	if ( !$self->get_config->get_db_connection_ok ) {
		$self->open_preferences;
	}
	
	1;
}

sub build_menu {
	my $self = shift;

        return Gtk2::Ex::FormFactory::Menu->new (
            menu_tree => [
                "_File" => {
                    item_type => '<Branch>',
                    children => [
                        "_Exit"	=> {
			    item_type   => '<StockItem>',
			    extra_data  => 'gtk-quit',
			    callback    => sub {
			        $self->get_form_factory->close;
				Gtk2->main_quit;
			    },
			    accelerator => '<ctrl>q',
                        },
                    ],
                },
                "_Edit" => {
                    item_type => '<Branch>',
                    children  => [
		    	"_Preferences" => {
			    item_type   => '<StockItem>',
			    extra_data  => 'gtk-preferences',
			    callback    => sub { $self->open_preferences },
			    accelerator => '<ctrl>p',
                        },
                        "sep1"	=> {
                            item_type	=> '<Separator>',
			},
		    	"Add _artist" => {
			    object      => "db",
			    callback    => sub { $self->add_artist },
			    accelerator => '<ctrl>a',
                        },
		    	"Ad_d album" => {
			    object      => "artist",
			    callback    => sub { $self->add_album },
			    accelerator => '<ctrl>d',
                        },
		    	"Add _song" => {
			    object      => "album",
			    callback    => sub { $self->add_song },
			    accelerator => '<ctrl>s',
                        },
                        "sep2"	=> {
                            item_type	=> '<Separator>',
			},
		    	"_Delete selected artist" => {
			    object      => "artist",
			    callback    => sub { $self->delete_artist },
			    accelerator => '<ctrl><alt>a',
                        },
		    	"D_elete selected album" => {
			    object      => "album",
			    callback    => sub { $self->delete_album },
			    accelerator => '<ctrl><alt>d',
                        },
		    	"De_lete selected song" => {
			    object      => "song",
			    callback    => sub { $self->delete_song },
			    accelerator => '<ctrl><alt>s',
                        },
                    ],
                },
	    ],
	);
}

sub build_artist_list {
	my $self = shift;
	
	return Gtk2::Ex::FormFactory::VBox->new (
	    object  => "db",
	    title   => "Select an artist",
	    content => [
		Gtk2::Ex::FormFactory::List->new (
		    name	       => "artist_list",
		    expand             => 1,
		    attr               => "gui.artists",
		    attr_select        => "gui.selected_artist_id",
		    attr_select_column => 0,
		    scrollbars         => [ "never", "automatic" ],
		    columns            => [ "id", "Artists" ],
		    visible            => [ 0,    1         ],
		    selection_mode     => "single",
		    no_header          => 1,
		    changed_hook_after => sub {
		        $self->get_form_factory
			     ->lookup_widget("album_list")
			     ->get_gtk_widget->select(0);
		    },
		),
	    ],
	);
}

sub build_artist_form {
	my $self = shift;
	
	return Gtk2::Ex::FormFactory::Form->new (
	    object  => "artist",
	    title   => "Edit selected artist",
	    content => [
	        Gtk2::Ex::FormFactory::Entry->new (
		    label => "Name",
		    attr  => "artist.name",
		    changed_hook_after => sub {
		        my ($artist) = @_;
		        my $list = $self->get_form_factory->lookup_widget("artist_list");
			$list->get_data->[$list->get_selected_rows->[0]]->[1] = $artist->get_name;
		    },
		),
	        Gtk2::Ex::FormFactory::TextView->new (
		    label => "Notes",
		    attr  => "artist.notes",
		),
	    ],
	);
}

sub build_album_list {
	my $self = shift;
	
	return Gtk2::Ex::FormFactory::VBox->new (
	    object  => "artist",
	    title   => "Select an album",
	    content => [
		Gtk2::Ex::FormFactory::List->new (
		    name	       => "album_list",
		    expand             => 1,
		    attr               => "artist.albums",
		    attr_select        => "gui.selected_album_id",
		    attr_select_column => 0,
		    scrollbars         => [ "never", "automatic" ],
		    columns            => [ "id", "Albums" ],
		    visible            => [ 0,    1         ],
		    selection_mode     => "single",
		    no_header          => 1,
		    height	       => 80,
		    changed_hook_after => sub {
		        $self->get_form_factory
			     ->lookup_widget("song_list")
			     ->get_gtk_widget->select(0);
		    },
		),
	    ],
	);
}

sub build_album_form {
	my $self = shift;
	
	return Gtk2::Ex::FormFactory::Form->new (
	    object  => "album",
	    title   => "Edit selected album",
	    content => [
	        Gtk2::Ex::FormFactory::Entry->new (
		    label => "Title",
		    attr  => "album.title",
		    changed_hook_after => sub {
		        my ($album) = @_;
		        my $list = $self->get_form_factory->lookup_widget("album_list");
			$list->get_data->[$list->get_selected_rows->[0]]->[1] = $album->get_title;
		    },
		),
	        Gtk2::Ex::FormFactory::Entry->new (
		    label => "Year",
		    attr  => "album.year",
		    width => 60,
		    expand_h => 0,
		),
		Gtk2::Ex::FormFactory::Popup->new (
		    attr     => "album.genre",
		    label    => "Genre",
		    width    => 150,
		    expand_h => 0,
		),
	        Gtk2::Ex::FormFactory::TextView->new (
		    label => "Notes",
		    attr  => "album.notes",
		),
	    ],
	);

	return Gtk2::Ex::FormFactory::Label->new (
	    label => "build_album_form"
	);
}

sub build_song_list {
	my $self = shift;
	
	return Gtk2::Ex::FormFactory::VBox->new (
	    object  => "album",
	    title   => "Select a song",
	    content => [
		Gtk2::Ex::FormFactory::List->new (
		    name	       => "song_list",
		    expand             => 1,
		    attr               => "album.songs",
		    attr_select        => "gui.selected_song_id",
		    attr_select_column => 0,
		    scrollbars         => [ "never", "automatic" ],
		    columns            => [ "id", "Nr", "Title" ],
		    visible            => [ 0,    1         ],
		    selection_mode     => "single",
		    no_header          => 1,
		)
	    ],
	);
}

sub build_song_form {
	my $self = shift;
	
	return Gtk2::Ex::FormFactory::Form->new (
	    object  => "song",
	    title   => "Edit selected song",
	    content => [
	        Gtk2::Ex::FormFactory::Entry->new (
		    label => "Title",
		    attr  => "song.title",
		    changed_hook_after => sub {
		        my ($song) = @_;
		        my $list = $self->get_form_factory->lookup_widget("song_list");
			$list->get_data->[$list->get_selected_rows->[0]]->[2] = $song->get_title;
		    },
		),
	    ],
	);
}

sub build_buttons {
	my $self = shift;

	return Gtk2::Ex::FormFactory::HBox->new (
	    content => [
	        Gtk2::Ex::FormFactory::Button->new (
		    label   => "Add artist",
		    object  => "db",
		    clicked_hook => sub { $self->add_artist },
		),
	        Gtk2::Ex::FormFactory::Button->new (
		    label  => "Add album",
		    object => "artist",
		    clicked_hook => sub { $self->add_album },
		),
	        Gtk2::Ex::FormFactory::Button->new (
		    label => "Add song",
		    object => "album",
		    clicked_hook => sub { $self->add_song },
		),
	        Gtk2::Ex::FormFactory::Button->new (
		    label   => "Delete artist",
		    object  => "artist",
		    clicked_hook => sub { $self->delete_artist },
		),
	        Gtk2::Ex::FormFactory::Button->new (
		    label  => "Delete album",
		    object => "album",
		    clicked_hook => sub { $self->delete_album },
		),
	        Gtk2::Ex::FormFactory::Button->new (
		    label => "Delete song",
		    object => "song",
		    clicked_hook => sub { $self->delete_song },
		),
	    ],
	);
}

sub add_artist {
	my $self = shift;
	
	my $artist = Music::Artist->create ({ name => "Unnamed" });
	$self->get_context->update_object_widgets("gui");

        my $list = $self->get_form_factory->lookup_widget("artist_list");
	$list->select_row_by_attr($artist->get_id);
	
	1;
}

sub add_album {
	my $self = shift;
	
	my $artist = $self->get_context->get_object("artist");
	my $album  = $artist->add_to_albums ({ title => "Unnamed" });
	$self->get_context->update_object_widgets("artist");

        my $list = $self->get_form_factory->lookup_widget("album_list");
	$list->select_row_by_attr($album->get_id);
	
	1;
}

sub add_song {
	my $self = shift;
	
	my $album = $self->get_context->get_object("album");
	my @songs = $album->songs;
	
	my $nr = @songs ? $songs[-1]->get_nr + 1 : 1;
	
	my $song = $album->add_to_songs ({ title => "Unnamed", nr => $nr });
	$self->get_context->update_object_widgets("album");

        my $list = $self->get_form_factory->lookup_widget("song_list");
	$list->select_row_by_attr($song->get_id);
	
	1;
}

sub add_genre {
	my $self = shift;
	
	my $genre = Music::Genre->create({ name => "Unnamed" });
	$self->get_context->update_object_attr_widgets("gui.genre_list");

        my $list = $self->get_config_form_factory->lookup_widget("genre_list");
	$list->select_row_by_attr($genre->get_id);
	
	1;
}

sub delete_artist {
	my $self = shift;

	my $context = $self->get_context;

	my $artist = $context->get_object("artist");
	$artist->delete;

	$context->set_object_attr("gui.selected_artist_id", undef);
	$context->update_object_widgets("gui");
	
	1;
}

sub delete_album {
	my $self = shift;

	my $context = $self->get_context;

	my $album = $context->get_object("album");
	$album->delete;
	
	$context->set_object_attr("gui.selected_album_id", undef);
	$context->update_object_widgets("artist");
	
	1;
}

sub delete_song {
	my $self = shift;

	my $context = $self->get_context;

	my $song = $context->get_object("song");
	$song->delete;

	$context->set_object_attr("gui.selected_song_id", undef);
	$context->update_object_widgets("album");
	
	1;
}

sub delete_genre {
	my $self = shift;

	my $context = $self->get_context;

	my $genre = $context->get_object("genre");
	$genre->delete;

	$context->set_object_attr("gui.selected_genre_id", undef);
	$self->get_context->update_object_attr_widgets("gui.genre_list");
	
	1;
}

sub open_preferences {
	my $self = shift;
	
	my $config  = $self->get_config;
	my $context = $self->get_context;

	my $pref_ff = Gtk2::Ex::FormFactory->new (
	    parent_ff => $self->get_form_factory,
	    sync      => 1,
	    context   => $context,
	    content   => [
	        Gtk2::Ex::FormFactory::Window->new (
		    title   => "Music database: Preferences",
		    properties => {
		        modal          => 1,
		    	default_width  => 350,
			default_height => 350,
		    },
		    content => [
		        Gtk2::Ex::FormFactory::Form->new (
		            title   => "Database settings",
			    content => [
			        Gtk2::Ex::FormFactory::Combo->new (
				    attr  => "config.dbi_source",
				    label => "DBI source",
				),
			        Gtk2::Ex::FormFactory::Entry->new (
				    attr  => "config.dbi_username",
				    label => "Username",
				),
			        Gtk2::Ex::FormFactory::Entry->new (
				    attr  => "config.dbi_password",
				    label => "Password",
				    properties => { visibility => 0 },
				),
				Gtk2::Ex::FormFactory::HBox->new (
				    content => [
			        	Gtk2::Ex::FormFactory::Button->new (
					    label        => "Test settings",
					    expand_h     => 0,
					    clicked_hook => sub {
						$self->test_db_connection;
					    },
					),
			        	Gtk2::Ex::FormFactory::Button->new (
					    label        => "Create database",
					    expand_h     => 0,
					    clicked_hook => sub {
				        	$self->create_database;
					    },
					),
			        	Gtk2::Ex::FormFactory::Button->new (
					    object       => "db",
					    label        => "Fill database",
					    tip          => "Inserts some example entries",
					    expand_h     => 0,
					    clicked_hook => sub {
				        	$self->fill_database;
					    },
					),
				    ],
				),
				Gtk2::Ex::FormFactory::HSeparator->new,
			        Gtk2::Ex::FormFactory::Label->new (
				    label       => "Message",
				    attr        => "config.dbi_test_message",
				    with_markup => 1,
				),
			    ],
		        ),
		        Gtk2::Ex::FormFactory::VBox->new (
			    object  => "db",
		            title   => "Manage genres",
			    expand  => 1,
			    content => [
			        Gtk2::Ex::FormFactory::List->new (
				    name       		=> "genre_list",
				    attr       		=> "gui.genre_list",
				    attr_select		=> "gui.selected_genre_id",
				    attr_select_column	=> 0,
				    expand     		=> 1,
				    scrollbars 		=> [ "never", "automatic" ],
				    columns    		=> [ "id", "Name" ],
				    visible    		=> [ 0,    1,     ],
				    editable   		=> [ 0,    1,     ],
				    selection_mode      => 'single',
				    no_header  		=> 1,
				    tip                 => "List is editable, change names here",
				),
				Gtk2::Ex::FormFactory::HBox->new (
				    content => [
			        	Gtk2::Ex::FormFactory::Button->new (
					    object => "db",
					    label  => "Add",
					    clicked_hook => sub { $self->add_genre },
					),
			        	Gtk2::Ex::FormFactory::Button->new (
					    object => "genre",
					    label => "Delete",
					    clicked_hook => sub { $self->delete_genre },
					),
				    ],
				),
			    ],
		        ),
			Gtk2::Ex::FormFactory::DialogButtons->new (
			    clicked_hook_after => sub {
			    	$self->test_db_connection;
				$config->save;
				$context->update_object_attr_widgets("album.genre");
			    },
			),
		    ],
		),
	    ],
	);
	
	$self->set_config_form_factory($pref_ff);
	
	$pref_ff->open;
	$pref_ff->update;
	
	1;
}

sub test_db_connection {
	my $self = shift;

	my $config  = $self->get_config,
	my $context = $self->get_context;

	$config->test_db_connection;

	if ( $config->get_db_connection_ok ) {
	    $context->set_object( db => 1 );
	    $self->get_form_factory->update_all;
	    $self->get_config_form_factory->update_all;
	} else {
	    $context->set_object( db     => undef );
	    $context->set_object( artist => undef );
	    $context->set_object( album  => undef );
	    $context->set_object( song   => undef );
	    $context->update_object_widgets("gui");
	}

	$self->get_context->update_object_attr_widgets(
	    "config.dbi_test_message",
	);

	1;
}

sub create_database {
	my $self = shift;
	
	my @connection_data = $self->get_config->get_connection_data;
	my ($db_name) = $connection_data[0] =~ /^dbi:mysql:([^;]*)/;
	$db_name ||= "gtk2ff";
	$connection_data[0] = "dbi:mysql:";

	eval {
		my $dbh = DBI->connect(
		    @connection_data,
		    { RaiseError => 1, PrintError => 0 }
		);
		open (SQL, "music.sql") or die "can't read music.sql";
		$dbh->do("create database $db_name");
		$dbh->do("use $db_name");
		my $command;
		while (<SQL>) {
			$command .= $_;
			if ( $command =~ /;\s*$/ ) {
				$dbh->do($command);
				$command = "";
			}
		}
		close SQL;
	};
	if ( $@ ) {
		my $msg = $@;
		$msg =~ s/&/&amp;/;
		$msg =~ s/</&lt;/;
		$self->get_config_form_factory->open_message_window (
			message => $msg,
			type    => "warning",
		);
	} else {
		$self->get_config_form_factory->open_message_window (
			message => "Database successfully created",
		);
		$self->test_db_connection;
	}

	1;
}

sub fill_database {
	my $self = shift;

	Music::Genre->find_or_create({ name => "Unknown" });
	Music::Genre->find_or_create({ name => "Electronic" });
	Music::Genre->find_or_create({ name => "Rock" });
	Music::Genre->find_or_create({ name => "Pop" });
	Music::Genre->find_or_create({ name => "Jazz" });
	Music::Genre->find_or_create({ name => "Instrumental" });
	my $genre = Music::Genre->find_or_create({ name => "NuJazz" });

	Music::Artist->find_or_create({ name => 'Mike Oldfield' });
	Music::Artist->find_or_create({ name => 'Beanfield' });

	my $bugge = Music::Artist->find_or_create({ name => 'Bugge Wesseltoft' });
	
	if ( ! Music::Album->search ( { artist => $bugge->get_id, title => 'Moving' } ) ) {
	    my $moving = $bugge->add_to_albums({
		    title  => 'Moving',
		    year   => '2001',
		    genre  => $genre,
	    });

	    $moving->add_to_songs({ nr => 1, title => 'Change' });
	    $moving->add_to_songs({ nr => 2, title => 'Gare Du Nord' });
	    $moving->add_to_songs({ nr => 3, title => 'Yellow Is The Colour' });
	    $moving->add_to_songs({ nr => 4, title => 'Lone' });
	    $moving->add_to_songs({ nr => 5, title => 'Moving' });
	    $moving->add_to_songs({ nr => 6, title => 'South' });
	}

	my $nils = Music::Artist->find_or_create({ name => 'Nils Petter Molvaer' });
	
	if ( ! Music::Album->search ( { artist => $nils->get_id, title => 'NP3' } ) ) {
	    my $np3 = $nils->add_to_albums ({
		    title  => 'NP3',
		    year   => '2002',
		    genre  => $genre,
	    });

	    $np3->add_to_songs({ nr => 1, title => 'Tabula Rasa' });
	    $np3->add_to_songs({ nr => 2, title => 'Axis Of Ignorance' });
	    $np3->add_to_songs({ nr => 3, title => 'Hurry Slowly' });
	    $np3->add_to_songs({ nr => 4, title => 'Marrow' });
	    $np3->add_to_songs({ nr => 5, title => 'Frozen' });
	    $np3->add_to_songs({ nr => 6, title => 'Presence' });
	    $np3->add_to_songs({ nr => 7, title => 'Simply So' });
	    $np3->add_to_songs({ nr => 8, title => 'Little Indian' });
	    $np3->add_to_songs({ nr => 9, title => 'Nebulizer' });
	}

	$self->get_form_factory->update_all;
	$self->get_config_form_factory->update_all;

	1;
}

1;
