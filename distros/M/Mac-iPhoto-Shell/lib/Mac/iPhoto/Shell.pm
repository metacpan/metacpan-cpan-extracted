#!env perl

package Mac::iPhoto::Shell;

use strict;
use warnings;

=head1 NAME

iphoto - a command line shell for iPhoto

=head1 SYNOPSIS

	# start the shell
	% iphoto
	
	# run a single command
	% iphoto merge album1 album2

	
=head1 DESCRIPTION

THIS IS EXPERIMENTAL SOFTWARE! USE AT YOUR OWN RISK!

=====================================================================
             This module is looking for a maintainer!

No one is maintaining this module, but you can take up its care
and feeding by requesting CPAN persmissions from modules@perl.org.

This version is assigned to the ADOPTME CPAN user and hosted in
GitHub:

	https://github.com/CPAN-Adopt-Me/mac-iphoto-shell

=====================================================================

This script provides a shell for iPhoto. Make a backup of your photo
library, or use a test library, to play with this script.

I last tested this with iPhoto 6.

=head1 COMMANDS

These commands interact with iPhoto, and some of them will change your
iPhoto library, including deleting photos forever.

The "show" command makes iPhoto display something, while the "print"
command makes the shell display something.  For instance, "show boat"
will tell iPhoto to display the album "boat" just as if you had selected
it from iPhoto's albums pane.  The command "print albums" will print on
the terminal (not the printer!) the list of albums.

Although some photos may disappear from albums or the photo library, they
are simply in the Trash library, and you do not delete them until you use
the "empty" command.  However, since I am still developing this script,
I have disabled that command.  You can still use the command, but it
will not empty the trash.  To enable the "empty" command, find the
"empty_trash" subroutine and modify the source according to the comment
in the subroutine. 

=over 4

=item debug

turn on extra output

=item empty

empty the trash (you cannot recover these photos).

=item help

display available commands

=item make ALBUM_NAME

make an album named ALBUM_NAME

=item merge ALBUM1 ALBUM2

move everything from ALBUM2 to ALBUM1, and remove ALBUM2

=item move ALBUM

move the selected photos to ALBUM

=item quit

stop the shell

=item print [ album | albums | photo | photos | selection ]

Rrint information about the specified object.  What these actually
print changes everytime I look at the source, so you have to try
them to see.

=item remove ALBUM

Remove the album. The photos stay in the photo library.

=item show ALBUM

Tell iPhoto to display ALBUM

=item trash

Put the selected photos in the trash

=item version

Print the shell version

=item view [ import | organize | edit | book ]

Change the view.  The default is "organize", and using any unknown
view changes it to "organize".

=back

=head1 SOURCE AVAILABILITY

This source is in Github:

	https://github.com/CPAN-Adopt-Me/mac-iphoto-shell

=head1 AUTHOR

  =====================================================================
             This module is looking for a maintainer!

No one is maintaining this module, but you can take up its care
and feeding by requesting CPAN persmissions from modules@perl.org.

This version is assigned to the ADOPTME CPAN user and hosted in
GitHub:

	https://github.com/CPAN-Adopt-Me/mac-iphoto-shell

  =====================================================================

brian d foy, C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2004-2008, brian d foy, All rights reserved.

You may use this program under the same terms as Perl itself.

=cut

use File::Spec;
use FindBin;
use Mac::Glue qw(:all);
use Text::ParseWords;
use UNIVERSAL qw(isa);

our $VERSION = '1.17';

my $command = shift @ARGV;

my $iPhoto = Mac::Glue->new( "iPhoto" );
my $Debug  = 1;

my %Commands = (
	debug     => sub { &_debug           },
	empty     => sub { &_empty_trash     },
	'exists'  => sub { &_album_exists    },
	help      => sub { &_help            },
	keyword   => {
		list   => sub { &_keyword_list   },
		add    => sub { &_keyword_add    },
		remove => sub { &_keyword_remove },
		},
	make      => sub { &_make_albums     },
	merge     => sub { &_merge_albums    },
	move      => sub { &_move_selection  },
#	prompt    => sub { &_set_prompt      },
	quit      => sub { exit             },
	'print'   => {
		album     => sub { &_print_album     },
		albums    => sub { &_print_albums    },
		photo     => sub { &_print_photo     },
		photos    => sub { &_print_photos    },
		selection => sub { &_print_selection },
		view      => sub { &_print_view      },
		},
	reload    => sub { &_restart_script  }, # broken
	remove    => sub { &_remove_album    },
#	remove    => sub { &_remove_photo    },
	'select'  => sub { &_select          },
	show      => sub { &_show_album      },
	slideshow => sub { &_slideshow       }, # broken
	trash     => sub { &__trash_selection },
	version   => sub { &__version         },
	view      => sub { &__view            }, # broken
	);
	
my %Print = (
	album     => sub { &__print_album     },
	albums    => sub { &__print_albums    },
	photo     => sub { &__print_photo     },
	photos    => sub { &__print_photos    },
	selection => sub { &__print_selection },
	view      => sub { &__print_view      },
	);

_run() unless caller;

sub _run 
	{
	if( @ARGV ) { _command( @ARGV ) }
	else        { _shell()          }
	}
	
sub _shell
	{
	my $prompt = "iPhoto> ";
	
	while( 1 )
		{
		print "$prompt";
		my $answer = <STDIN>;
		chomp( $answer );
		
		my @bits = quotewords('\s+', 0, $answer );
		
		_command( @bits );
		}
	
	}

sub _selection
	{
	my $selection = $iPhoto->prop( "selection" );
	
	unless( defined $selection )
		{
		_print_warn( "No photos selected." );
		return;
		}

	my $count = $selection->count( each => 'item' );
	_print_debug( "Selection has $count items" );
	return $selection;
	}
	
# get command
# is it a key?
# are there more arguments?
	# NO  - is there a null sub? use it
	# YES - is the value a hash? repeat


sub _get_subroutine
	{
	my $hash    = \%Commands;
	my @commands = ();
		
	while( 1 )
		{
		if( isa( $hash, 'HASH' ) )
			{
			if( exists $hash->{ $_[0] } )
				{
				$hash = $hash->{ $_[0] };
				push @commands, shift;
				redo;
				}
			else { last }
			}
		else { last }
		}
		
	_print_debug( "commands are @commands" );
	
	require Data::Dumper;
	print Data::Dumper::Dumper( $hash );
		
	return ( $hash, @_ );
	}
	
sub _command
	{
	my $original = @_;
	my( $subroutine, @args ) = _get_subroutine( @_ );
	
	eval { $subroutine->( @args ) };

	if( $@ )
		{
		_print_warn( "error in $command: $@" );
		_print_normal( "continuing" );
		}
	}
	
sub _select
	{
	my @numbers = @_;
				
	$iPhoto->select( $iPhoto->obj( photo => "every" ) );
	}

sub _album_exists
	{
	my $name = shift;
	
	my $album = $iPhoto->obj( 
		album => whose( name => equals => $name ) 
		);

	my $exists = $iPhoto->exists( $album );
		
	print "Album [$name] " , $exists ? '' : 'does not ', "exist",
		$exists ? 's' : '', "\n";
		
	$exists;
	}
	
sub _view
	{
	my $next = shift;
	
	my $view = $iPhoto->prop( "view" );
	
	my $current = $view->get;
	_print_normal( "Current view is $current" );
	
	$view->set( to => enum( $next ) );
	
	my $now = $view->get;
	_print_normal( "View is now $now" );
	}
	
sub _version #
	{
	my $script = File::Spec->catfile( $FindBin::Bin, $FindBin::Script );

	_print_normal( "0.10" );
	}
	
sub _restart_script
	{
	require FindBin;
	my $script = File::Spec->catfile( $FindBin::Bin, $FindBin::Script );
	_print_debug( "Script is $script" ) if $Debug;
	{ exec "perl", qq|$script| };
	_print_warn( "Could not reload: $!" );
	}
	
sub _help #
	{
	_print_help( sort keys %Commands );
	}
	
sub _debug #
	{
	my $value = lc shift;
	
	_print_help( "debug [on|off]" ) unless( $value =~ m/on|off/i );

	if( $value eq 'on' )     { $Debug = 1 }
	elsif( $value eq 'off' ) { $Debug = 0 }
	
	_print_normal( "debug is " . ( $Debug ? "on" : "off" ) );
	}
	
sub _remove_album #
	{
	my @albums = @_;
	
	foreach my $name ( @albums )
		{
		my $album = $iPhoto->obj( 
			album => whose( name => equals => $name ) 
			);
		
		_print_normal( qq|Removing album "$name"| );
		$album->remove;
		}
	}

sub _make_albums #
	{
	my @albums = @_;
	
	foreach my $album ( @albums )
		{
		my $exists = _album_exists( $album );

		if( $exists )
			{
			_print_normal( "Skipping [$album], album exists" );
			return;
			}
		
		_print_normal( qq|Creating album "$album"| );
		$iPhoto->new_album( name => $album );
		}
	}
	
sub _merge_albums #
	{
	my @albums = @_;
	
	my $name = shift @albums;
	my $exists = _album_exists( $name );
	unless( $exists )
		{
		_print_normal( "Merge command cancelled. " .
			"Create album [$name] first" );
		return;
		}
	
	my $target = $iPhoto->obj( 
		album => whose( name => equals => $name ) 
		);
	_print_debug( "Target album is $name" ) if $Debug;
		
	foreach my $name ( @albums )
		{
		my $album = $iPhoto->obj( 
			album => whose( name => equals => $name ) 
			);

		my $count = $album->prop( "photos" )->count;
		_print_normal( qq|Found $count photos in "$name"| );
		
		for( my $index = $count; $index > 0; $index-- )
			{
			my $photo  = $album->obj( photo => $index );
			$iPhoto->add( $photo => to => $target );
			}
		
		_print_normal( qq|Removing album "$name"| );
		$album->remove;		
		}
	}
		
sub _print_album #
	{
	my $albums = $iPhoto->prop( "albums" );
	
	my $current = $iPhoto->prop( "current album" );
	my $name    = $iPhoto->prop( "name" )->get;
	my $count   = $current->prop( "photos" )->count;
	
	_print_normal( "Album $name has $count photos" );	
	}

sub _print_albums #
	{
	my $albums = $iPhoto->prop( "albums" );
	
	my $current = $iPhoto->prop( "current album" )->prop( "name" )->get;

	my $count = $albums->count;
	_print_normal( "Found $count albums" );	
	
	for( my $index = 1; $index <= $count; $index++ )
		{
		my $album = $albums->obj( item => $index );
		my $name  = $album->prop( "name" )->get;
		
		my $arrow = $name eq $current ? "  <---" : '';
		
		_print_normal( $name . $arrow );
		}
	}
	
sub _print_photo #
	{
	my $selection = _selection();
	return unless defined $selection;
		
	foreach my $photo ( $selection->get )
		{
		warn( "Looking at a photo" );
		my $new_photo = _new_photo( $photo );
		my $title     = $new_photo->prop( "title" )->get;
		my $comment   = $new_photo->prop( "comment" )->get;
		my $date      = $new_photo->prop( "date" )->get;
		my $height    = $new_photo->prop( "height" )->get;
		my $width     = $new_photo->prop( "width" )->get;
		my $filename  = $new_photo->prop( "image_filename" )->get;
		my $path      = $new_photo->prop( "image_path" )->get;
		
		my $size      = -s $path;
		
		$size =~ s/(^[-+]?\d+?(?=(?>(?:\d{3})+)(?!\d))|\G\d{3}(?=\d))/$1,/g;
		
		$comment ||= "(no comment)";
		
		no warnings;
		
		_print_normal( <<"HERE" );
	$title
	$date
	$width x $height
	$size bytes
	
	$comment
HERE
		}
	}
	
sub _print_photos #
	{
	my $album = $iPhoto->prop( "current_album" );
	my $name  = $album->prop( "name" )->get;
	
	my $photos = $album->prop( "photos" );
	my $count  = $photos->count;
	_print_normal( qq|Found $count photos in "$name"| );

	for( my $index = 1; $index <= $count; $index++ )
		{
		my $photo = $album->obj( photo => $index );
		my $title = $photo->prop( "title" )->get;
		my $date  = $photo->prop( "date" )->get;
		_print_normal( "$title --- $date" );
		}
	}

sub _print_selection #
	{
	my $selection = _selection();
	return unless defined $selection;

	foreach my $photo ( $selection->get )
		{
		my $new_photo = _new_photo( $photo );
		my $title = $new_photo->prop( "title" )->get;
		_print_normal( $title );
		}
	}

sub _print_view #
	{
	my $view = $iPhoto->prop( "view" )->get;

	_print_normal( "View is $view" );
	}
	
sub _show_album #
	{
	my $name = shift;

	my $exists = _album_exists( $name );
	return unless $exists;
	
	my $album = $iPhoto->obj( 
		album => whose( name => equals => $name ) 
		);
	
	$iPhoto->select( $album );
	}
	
sub _move_selection #
	{
	my $name = shift;

	my $target = $iPhoto->obj( 
		album => whose( name => equals => $name ) 
		);
	
	my $selection = _selection;
	return unless defined $selection;
	
	my $current   = $iPhoto->prop( "current album" );
			
	foreach my $photo ( $selection->get )
		{		
		my $new_photo = _new_photo( $photo );
		$iPhoto->add( $new_photo => to => $target );
		$iPhoto->remove( $new_photo => from => $current );
		}
	}

sub _remove_selection
	{
	my $selection = _selection;
	return unless defined $selection;

	my $trash = $iPhoto->prop( "trash album" );
	
	foreach my $photo ( $selection->get )
		{		
		my $new_photo = _new_photo( $photo );
		$iPhoto->remove( $new_photo );
		}
	}

sub _empty_trash #
	{
	my $trash = $iPhoto->prop( "trash album" );
	my $count = $trash->prop( "photos" )->count;
	
	_print_normal( "Trash has $count photos" );
	
	_print_normal( "Emptying trash" . 
		( $Debug ? ' (not really, debugging)' : '' ) );
		
	print "I won't empty the trash because you did not modify the source\n";
	#uncomment the next line line to activate this feature.
	#$iPhoto->empty_trash unless $Debug;
	}
		
sub _trash_selection
	{
	my $selection = _selection;
	return unless defined $selection;
	
	my $count = $selection->count( each => 'item' );
	_print_normal( "Selection has $count photos" );
	my $trash = $iPhoto->prop( "trash album" );
	
	foreach my $photo ( map { _get_photo_from_selection( $_ ) } $selection->get )
		{		
		$iPhoto->move( $photo => from => $trash );
		}
	}

sub _slideshow
	{
	my $command = shift;
	
	unless( $command =~ m/start|stop/ )
		{
		_print_warn( "Use: slideshow [start|stop]" );
		return;
		}
	
	$command = "${command}_slideshow";
	$iPhoto->$command;	
	}

sub _keyword
	{
	my $selection = _selection();
	return unless defined $selection;

	my $command  = shift;
	my @keywords = @_;
	
	if( not defined $command or $command eq "list" )
		{
		foreach my $photo ( $selection->get )
			{
			my $new_photo = _new_photo( $photo );

			my @keywords  = $new_photo->prop( "keyword" )->prop( "name" )->get;
			my $title     = $new_photo->prop( "title" )->get;
			
			local $" = ", ";
			_print_normal( "$title: @keywords" );
			}	
		}
	elsif( $command eq "add" )
		{
		my $keyword = $iPhoto->obj(
			keyword => whose( name => equals => $keywords[0] )
			);
		
		my $name = $keyword->prop( "name" )->get;
		
		_print_normal( "keyword name is $name" );
			
		foreach my $photo ( $selection->get )
			{
			my $new_photo = _new_photo( $photo );
			my $title = $new_photo->prop( "name" )->get;
			_print_debug( "Processing photo: $title keyword: $keywords[0]" );
			$photo->assign_keyword( string => $keywords[0] );
			}
		}
	elsif( $command eq "remove" )
		{
		}
	}
	
sub _print { chomp( my @s = @_ ); my $s = shift @s; for (@s){print "$s $_\n"} }

sub _print_help   { _print( '...', @_ ) }
sub _print_warn   { _print( '!!!', @_ ) }
sub _print_debug  { _print( '---', @_ ) }
sub _print_normal { _print( '+++', @_ ) }

	
# this is a work around		
sub _new_photo
	{
	my $photo = shift;
	
	my $id = $photo->getdata; # get data in usable form

	my $new_photo = $iPhoto->obj(
		photo => obj_form(formUniqueID, typeFloat, $id)
		);
			
	return $new_photo;
	}

1;
