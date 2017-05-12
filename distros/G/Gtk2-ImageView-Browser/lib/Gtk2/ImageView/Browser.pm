package Gtk2::ImageView::Browser;

use warnings;
use strict;
use Gtk2;
use Gtk2::ImageView;
use Gtk2::Ex::Simple::List;
use File::MimeInfo::Magic;
use Gtk2::Gdk::Keysyms;
use Cwd ('abs_path', 'getcwd');
use Image::Size;

=head1 NAME

Gtk2::ImageView::Browser - A image browser and widget based off of 'Gtk2::ImageView'

=head1 VERSION

Version 0.0.0

=cut

our $VERSION = '0.0.0';


=head1 SYNOPSIS

    use Gtk2::ImageView::Browser;

    my $ivb = Gtk2::ImageView::Browser->new();
    ...

=head1 METHODES

=head2 new

    my $ivb = = Gtk2::ImageView::Browser->new();

=cut

sub new {
	my $self={error=>undef, errorString=>undef, widgets=>{}, dotfiles=>0,
			  zoom=>'w'};
	bless $self;

	return $self;
}

=head2 dirchanged

A internal function that is called when a directory is double clicked on.

=cut

sub dirchanged{
	my ($sl, $path, $column, $self) = @_;

	my @sel = $sl->get_selected_indices;
	my $dir=$sl->{data}[$sel[0]][0];

	#sets the directory
	$self->{dir}=$self->{dir}.'/'.$dir;

	#set it to the absolute path
	$self->{dir}=abs_path($self->{dir});

	$self->setdir($self->{dir});
}

=head2 dotfiles

Determines if it should show files matching /^./ or not.

If a arguement is given, it will set it to that. The value
is a perl boolean.

With out an arguement, it gets the current setting.

When the object is originally created, this defaults to 0.

    #don't displat dot files
    $ivb->dotfiles(0);

    #displat dot files
    $ivb->dotfiles(0);

    my $dotfiles=$ivb->dotfiles();

=cut

sub dotfiles{
	my $self=$_[0];
	my $dotfiles=$_[1];

	if (defined($dotfiles)) {
		$self->{dotfiles}=$dotfiles
	}

	return $self->{dotfiles};
}

=head2 filechangedA

A internal function that is called when a file is double clicked on.

=cut

sub filechangedA{
	my ($sl, $path, $column, $self) = @_;

	my @sel = $sl->get_selected_indices;
	my $file=$sl->{data}[$sel[0]][0];

	$self->{file}=$self->{dir}.'/'.$file;

	$self->{widgets}{pixbuf}=Gtk2::Gdk::Pixbuf->new_from_file($self->{file});
	$self->{widgets}{view}->set_pixbuf($self->{widgets}{pixbuf}, 1);
	$self->zoomset;
}

=head2 filechangedC

A internal function that is called when a file selection is changed.

=cut

sub filechangedC{
	my ($sl, $self) = @_;

	my @sel = $sl->get_selected_indices;
	my $file=$sl->{data}[$sel[0]][0];

	$self->{file}=$self->{dir}.'/'.$file;

	$self->{widgets}{pixbuf}=Gtk2::Gdk::Pixbuf->new_from_file($self->{file});
	$self->{widgets}{view}->set_pixbuf($self->{widgets}{pixbuf}, 1);
	$self->zoomset;
}

=head2 fullscreen

Minimizes the sidebar, by setting HPaned to a
position of 1. If the position of the the HPaned
is greater than 1, it sets it to 1, else it sets
it to a position of 230.

   $ivb->fullscreen;

=cut

sub fullscreen{
	my $self=$_[0];

	my $pos=$self->{widgets}{hpaned}->get_position;
print "test\n";
	if ($pos > 1) {
		$self->{widgets}{hpaned}->set_position(1);
	}else {
		$self->{widgets}{hpaned}->set_position(230);
	}
}

=head2 fullscreenA

Called by the 'f' button.

=cut

sub fullscreenA{
	my $widget=$_[0];
	my $self=$_[1];

	$self->fullscreen;
}

=head2 next

This causes it to move to the next image. If there is no
next image, it goes back to the first one.

    $ivb->next;

=cut

sub next{
	my $self=$_[0];

	my @sel = $self->{widgets}{files}->get_selected_indices;
	my $index=$sel[0] + 1;

	#go back to the beginning when we reach the end...
	if (!defined($self->{widgets}{files}->{data}[$index])) {
		$index=0;
	}

	$self->{widgets}{files}->select($index);
	my $file=$self->{widgets}{files}->{data}[$index][0];

	$self->{file}=$self->{dir}.'/'.$file;

	$self->{widgets}{pixbuf}=Gtk2::Gdk::Pixbuf->new_from_file($self->{file});
	$self->{widgets}{view}->set_pixbuf($self->{widgets}{pixbuf}, 1);
	$self->zoomset;
}

=head2 nextA

This is called by the 'n' button.

=cut

sub nextA{
	my $widget=$_[0];
	my $self=$_[1];

	$self->next;
}

=head2 resize

This is called by various things when it is resized.

=cut

sub resize{
	my $widget=$_[0];
	my $self=$_[1];

	$self->zoomset;
}

=head2 run

This calls invokes the windows methode and runs it.

    #starts it in the current directory
    my $ivb->run;

    #starts it in a different directory
    my $ivb->run('/arc/pics');

=cut

sub run{
	my $self=$_[0];
	my $dir=$_[1];

	$self->errorblank;

	Gtk2->init;

	my $window=$self->window($dir);

	$window->signal_connect('delete-event'=>\&quit);

	Gtk2->main;
}

=head2 prev

This causes it to move to the previous image.

    $ivb->prev;

=cut

sub prev{
	my $self=$_[0];

	my @sel = $self->{widgets}{files}->get_selected_indices;
	my $index=$sel[0] - 1;

	#go back to the beginning when we reach the end...
	if (!defined($self->{widgets}{files}->{data}[$index])) {
		$index=$#{$self->{widgets}{files}->{data}};
		$index--;
	}

	$self->{widgets}{files}->select($index);
	my $file=$self->{widgets}{files}->{data}[$index][0];

#	print $#{$self->{widgets}{files}->{data}}."\n";

	$self->{file}=$self->{dir}.'/'.$file;

	$self->{widgets}{pixbuf}=Gtk2::Gdk::Pixbuf->new_from_file($self->{file});
	$self->{widgets}{view}->set_pixbuf($self->{widgets}{pixbuf}, 1);
	$self->zoomset;
}

=head2 prevA

This is called by the 'p' button.

=cut

sub prevA{
	my $widget=$_[0];
	my $self=$_[1];

	$self->prev;
}

=head2 setdir

This sets the directory to the specified one.

    $ivb->setdir('/arc/pics');
    if($self->{error}){
        print "Error!\n";
    }

=cut

sub setdir{
	my $self=$_[0];
	my $dir=$_[1];

	$self->errorblank;

	if (!-d $dir) {
		warn('Gtk2-ImageView-Browser setdir:1: The directory "'.
			 $dir.'" does not exist or ist not a directory');
		$self->{error}=1;
		$self->{errorString}='The directory "'.$dir
		                     .'" does not exist or ist not a directory';
		return undef;
	}

	#sets the directory
	$self->{dir}=$dir;

	$self->{widgets}{direntry}->set_text($self->{dir});

	opendir(READDIR, $self->{dir});
	my @direntries=readdir(READDIR);
	closedir(READDIR);

	if (!$self->{dotfiles}) {
		@direntries=grep(!/^\./, @direntries);
		push(@direntries, '..');
	}

	@direntries=sort(@direntries);

	my @dirs;
	my @files;

	my $int=0;
	while(defined($direntries[$int])) {
		if (-d $self->{dir}.'/'.$direntries[$int]) {
			push(@dirs, [$direntries[$int]]);
		}
		if (-f $self->{dir}.'/'.$direntries[$int]) {
			my $type=mimetype($self->{dir}.'/'.$direntries[$int]);
			if ($type=~/^image\//) {
				push(@files, [$direntries[$int]]);
			}
		}

		$int++;
	}

	@{$self->{widgets}{dirs}->{data}}=@dirs;
	@{$self->{widgets}{files}->{data}}=@files;

	if (!defined($files[0][0])) {
		return undef;
	}

	#if we don't set this here, when it becomes unselected
	#when this is called next and prev will not work
	$self->{widgets}{files}->select(0);

	$self->{widgets}{pixbuf}=Gtk2::Gdk::Pixbuf->new_from_file($self->{dir}.
															  '/'.$files[0][0]);
	$self->{widgets}{view}->set_pixbuf($self->{widgets}{pixbuf}, 1);

	$self->zoomset;

	return 1;
}

=head2 quit

This is called by the window created by run when it is closed.

=cut

sub quit{
	exit 0;
}

=head2 widget

This returns the widget that contains it all.

If this is called manually, you will need to add the accel stuff
to the windows you use for the hot keys to work.

    #starts it in the current directory
    my $widget=$ivb->widget();

    #starts it in '/arc/pics'
    my $widget=$ivb->widget('/arc/pics');
    
    #adds the accel stuff to the window for the hot keys to work.
    $window->add($ivb->{widget});
	$window->add_accel_group($ivb->{widgets}{accels});

=cut

sub widget{
	my $self=$_[0];
	my $dir=$_[1];

	$self->errorblank;

	if (!defined($dir)) {
		$dir=getcwd;
	}

	my $file;
	if (-f $dir) {
		$file=$dir;
		my $int=1;
		my @ds=split(/\//, $dir);
		$dir='';
		while ($int < $#ds) {
			$dir=$dir.'/'.$ds[$int];
			$int++;
		}
	}

	if (! -d $dir ) {
		warn('Gtk2-ImageView-Browser widget:1: The directory "'.$dir.'" does not exist');
		$self->{error}=1;
		$self->{errorString}='The directory "'.$dir.'" does not exist';
		return undef;
	}

	#save the dir for later use
	$self->{dir}=$dir;

	#meh
	$self->{widgets}{hpaned}=Gtk2::HPaned->new;
	$self->{widgets}{hpaned}->show;

	#tip stuff
	$self->{widgets}{tips}=Gtk2::Tooltips->new;

	#hot key stuff..
	$self->{widgets}{accels}=Gtk2::AccelGroup->new;

	#this will hold the hpaned and dir entry area
	$self->{widgets}{vbox}=Gtk2::VBox->new;
	$self->{widgets}{vbox}->show;

	#sets up the button hbox
	$self->{widgets}{bhbox}=Gtk2::HBox->new;
	$self->{widgets}{bhbox}->show;
	$self->{widgets}{vbox}->pack_start($self->{widgets}{bhbox}, 0, 0, 0);

	#sets the zoom button
	$self->{widgets}{zoombutton}=Gtk2::Button->new();
	$self->{widgets}{zoombutton}->show;
	$self->{widgets}{zoomlabel}=Gtk2::Label->new("z=w");
	$self->{widgets}{zoomlabel}->show;
	$self->{widgets}{zoombutton}->add($self->{widgets}{zoomlabel});
	$self->{widgets}{bhbox}->pack_start($self->{widgets}{zoombutton}, 0, 0, 0);
	$self->{widgets}{zoombutton}->signal_connect("clicked" => \&zoomchange, $self);
	$self->{widgets}{tips}->set_tip($self->{widgets}{zoombutton},
									"change zoom type...\n".
									"w = zoom to width\n".
									"f = fit image to window\n".
									"1 = zoom level set to 1");
	$self->{widgets}{zoombutton}->add_accelerator('clicked', $self->{widgets}{accels},
												  $Gtk2::Gdk::Keysyms{z},
												  'control-mask', 'visible');

	#sets the zoom reset, 'zr', button
	$self->{widgets}{zrbutton}=Gtk2::Button->new();
	$self->{widgets}{zrbutton}->show;
	$self->{widgets}{zrlabel}=Gtk2::Label->new("zr");
	$self->{widgets}{zrlabel}->show;
	$self->{widgets}{zrbutton}->add($self->{widgets}{zrlabel});
	$self->{widgets}{bhbox}->pack_start($self->{widgets}{zrbutton}, 0, 0, 0);
	$self->{widgets}{zrbutton}->signal_connect("clicked" => \&zoomreset, $self);
	$self->{widgets}{tips}->set_tip($self->{widgets}{zrbutton}, 'zoom reset');
	$self->{widgets}{zrbutton}->add_accelerator('clicked', $self->{widgets}{accels},
												  $Gtk2::Gdk::Keysyms{r},
												  'control-mask', 'visible');

	#sets the zoom reset, 'n', button
	$self->{widgets}{nbutton}=Gtk2::Button->new();
	$self->{widgets}{nbutton}->show;
	$self->{widgets}{nlabel}=Gtk2::Label->new("n");
	$self->{widgets}{nlabel}->show;
	$self->{widgets}{nbutton}->add($self->{widgets}{nlabel});
	$self->{widgets}{bhbox}->pack_start($self->{widgets}{nbutton}, 0, 0, 0);
	$self->{widgets}{nbutton}->signal_connect("clicked" => \&nextA, $self);
	$self->{widgets}{tips}->set_tip($self->{widgets}{nbutton}, 'next');
	$self->{widgets}{nbutton}->add_accelerator('clicked', $self->{widgets}{accels},
												  $Gtk2::Gdk::Keysyms{Down},
												  'control-mask', 'visible');

	#sets the zoom reset, 'p', button
	$self->{widgets}{pbutton}=Gtk2::Button->new();
	$self->{widgets}{pbutton}->show;
	$self->{widgets}{plabel}=Gtk2::Label->new("p");
	$self->{widgets}{plabel}->show;
	$self->{widgets}{pbutton}->add($self->{widgets}{plabel});
	$self->{widgets}{bhbox}->pack_start($self->{widgets}{pbutton}, 0, 0, 0);
	$self->{widgets}{pbutton}->signal_connect("clicked" => \&prevA, $self);
	$self->{widgets}{tips}->set_tip($self->{widgets}{pbutton}, 'prev');
	$self->{widgets}{pbutton}->add_accelerator('clicked', $self->{widgets}{accels},
												  $Gtk2::Gdk::Keysyms{Up},
												  'control-mask', 'visible');

	#sets the zoom reset, 'f', button
	$self->{widgets}{fbutton}=Gtk2::Button->new();
	$self->{widgets}{fbutton}->show;
	$self->{widgets}{flabel}=Gtk2::Label->new("f");
	$self->{widgets}{flabel}->show;
	$self->{widgets}{fbutton}->add($self->{widgets}{flabel});
	$self->{widgets}{bhbox}->pack_start($self->{widgets}{fbutton}, 0, 0, 0);
	$self->{widgets}{fbutton}->signal_connect("clicked" => \&fullscreenA, $self);
	$self->{widgets}{tips}->set_tip($self->{widgets}{fbutton}, 'fullscreen');
	$self->{widgets}{fbutton}->add_accelerator('clicked', $self->{widgets}{accels},
												  $Gtk2::Gdk::Keysyms{f},
												  'control-mask', 'visible');

	#allows and shows the current directory
	$self->{widgets}{direntry}=Gtk2::Entry->new;
	$self->{widgets}{direntry}->show;
	$self->{widgets}{vbox}->pack_start($self->{widgets}{direntry}, 0, 0, 0);

	#create and add the image view
	$self->{widgets}{view}=Gtk2::ImageView->new;
	$self->{widgets}{view}->show;
	$self->{widgets}{hpaned}->add2($self->{widgets}{view});

	#create and add the hbox that will contain directory and files
	$self->{widgets}{vpaned}=Gtk2::VPaned->new;
	$self->{widgets}{vpaned}->show;
	$self->{widgets}{hpaned}->add1($self->{widgets}{vbox});

	#adds the vpaned to the vbox
	$self->{widgets}{vbox}->pack_start($self->{widgets}{vpaned}, 1, 1, 0);

	#adds what will hold the directory stuff
	$self->{widgets}{dirs}=Gtk2::Ex::Simple::List->new('Directories'=>'text');
	$self->{widgets}{dirs}->show;
	$self->{widgets}{dirsscroll}=Gtk2::ScrolledWindow->new;
	$self->{widgets}{dirsscroll}->show;
	$self->{widgets}{dirsscroll}->add($self->{widgets}{dirs});
	$self->{widgets}{vpaned}->add1($self->{widgets}{dirsscroll});

	#adds what will hold the images
	$self->{widgets}{files}=Gtk2::Ex::Simple::List->new('Images'=>'text');
	$self->{widgets}{files}->show;
	$self->{widgets}{filesscroll}=Gtk2::ScrolledWindow->new;
	$self->{widgets}{filesscroll}->show;
	$self->{widgets}{filesscroll}->add($self->{widgets}{files});
	$self->{widgets}{vpaned}->add2($self->{widgets}{filesscroll});

	#sets the position to something useful for the panned stuff
	$self->{widgets}{hpaned}->set_position(230);
	$self->{widgets}{vpaned}->set_position(160);

	#connect the change signals
	$self->{widgets}{files}->signal_connect(row_activated =>\&filechangedA, $self);
	$self->{widgets}{files}->signal_connect('cursor-changed'=>\&filechangedC, $self);
	$self->{widgets}{dirs}->signal_connect(row_activated =>\&dirchanged, $self);

	#none of these work...
#	$self->{widgets}{hpaned}->signal_connect('move-handle'=>\&resize, $self);
#	$self->{widgets}{hpaned}->signal_connect('toggle-handle-focus'=>\&resize, $self);
#	$self->{widgets}{hpaned}->signal_connect('accept-position'=>\&resize, $self);
#	$self->{widgets}{hpaned}->signal_connect('check-resize'=>\&resize, $self);

	#sets it to the proper directory
	$self->setdir($self->{dir});

	#if there is a file specified, view it...
	if (defined($file)) {
		$self->{file}=$file;
		$self->{widgets}{pixbuf}=Gtk2::Gdk::Pixbuf->new_from_file($file);
		$self->{widgets}{view}->set_pixbuf($self->{widgets}{pixbuf}, 1);
	}

	return $self->{widgets}{hpaned};
}

=head2 window

This retuns a window with the widget in it.

    #starts it in the current direcotry
    my $window=$ivb->window();
    
    #starts it in '/arc/pics'
    my $window=$ivb->window('/arc/pics');

=cut

sub window{
	my $self=$_[0];
	my $dir=$_[1];

	$self->errorblank;

	$self->{widget}=$self->widget($dir);

	$self->{widgets}{window}=Gtk2::Window->new();
	#picked as it will fit with in a EEE PC with out using the entire screen
	$self->{widgets}{window}->resize(700,410);
	$self->{widgets}{window}->show;
	$self->{widgets}{window}->add($self->{widget});

	$self->{widgets}{window}->add_accel_group($self->{widgets}{accels});

#	$self->{widgets}{window}->signal_connect('check-resize'=>\&resize, $self);

	#we call this here as when we create the widget, it wont
	#zoom as this has not been called yet
	$self->zoomset;

	return $self->{widgets}{window};
}

=head2 zoomchange

This is called when the zoom button is clicked.

=cut

sub zoomchange{
	my $widget=$_[0];
	my $self=$_[1];

	my @types=('w', 'f', '1');

	my $int=0;
	my $matched=undef;
	while (defined($types[$int])) {
		if ($types[$int] eq $self->{zoom}) {
			$matched=$int;
		}

		$int++;
	}

	$matched++;

	if (!defined($types[$matched])) {
		$matched=0;
	}

	$self->{zoom}=$types[$matched];

	$self->{widgets}{zoomlabel}->set_label('z='.$self->{zoom});

	$self->zoomset($self->{zoom});
}


=head2 zoomreset

This is called by the 'zr' button for resetting the zoom.

=cut

sub zoomreset{
	my $widget=$_[0];
	my $self=$_[1];

	$self->zoomset();
}

=head2 zoomget

This returns the current zoom type.

    my $zoom=$ivb->zoomget;

=cut

sub zoomget{
	my $self=$_[0];

	return $self->{zoom};
}

=head2 zoomset

This sets the zoom to a desired type.

    #sets the zoom type to fit it to width
    $ivb->zoomset('w')
    #this only happens if you set it to something it does not support
    if($ivb->{error}){
        print "Error!\n";
    }

    #reset the zoom of the current image to
    $ivb->zoomset;

=cut

sub zoomset{
	my $self=$_[0];
	my $zoom=$_[1];

	$self->errorblank;

	#only do the following if zoom is not set
	if (defined($zoom)) {
		my @types=('w', 'f', '1');
		
		my $int=0;
		my $matched=undef;
		while (defined($types[$int])) {
			if ($types[$int] eq $zoom) {
				$matched=$int;
			}
			
			$int++;
		}
		
		if (!defined($matched)) {
			warn('Gtk2-ImageView-Browse zoomset:2: Invalid zoom type');
			$self->{error}=2;
			$self->{errorString}='Invalid zoom type.';
			return undef;
		}
		
		$self->{zoom}=$types[$matched];
	}

	#if there is no file defined, return... otherwise this errors later on
	if (!defined($self->{file})) {
		return 1;
	}

	if ($self->{zoom} eq '1') {
		$self->{widgets}{view}->set_zoom(1.0);
		return 1;
	}

	#this is used by w and f
	if (!defined($self->{widgets}{window})) {
		print "windows undef\n";
		return undef;
	}

	my ($windowX, $windowY) = $self->{widgets}{window}->get_size;
	my ($imageX, $imageY)=imgsize($self->{file});
	my $widgetX=$windowX - $self->{widgets}{hpaned}->get_position;

	$widgetX=$widgetX - 5;

	my $zoomX=$widgetX/$imageX;
	my $zoomY=$windowY/$imageY;
	
	if ($self->{zoom} eq 'w') {
		if (!defined($self->{widgets}{window})) {
			return undef;
		}

		$self->{widgets}{view}->set_zoom($zoomX);
		return 1;
	}

	if ($self->{zoom} eq 'f') {
		if (($zoomX > 1) && ($zoomY > 1)) {
			if ($zoomX >= $zoomY) {
				$self->{widgets}{view}->set_zoom($zoomY);
			}else {
				$self->{widgets}{view}->set_zoom($zoomX);
			}
			return 1;
		}

		$self->{widgets}{pixbuf}=Gtk2::Gdk::Pixbuf->new_from_file($self->{file});
		$self->{widgets}{view}->set_pixbuf($self->{widgets}{pixbuf}, 1);
		return 1;
	}

}

=head2 errorblank

This blanks the error storage and is only meant for internal usage.

It does the following.

    $self->{error}=undef;
    $self->{errorString}="";

=cut

#blanks the error flags
sub errorblank{
        my $self=$_[0];

        $self->{error}=undef;
        $self->{errorString}="";

        return 1;
}

=head1 ERROR CODES

=head2 1

The file path specified does not exist.

=head2 2

Invalid zoom type.

=head1 HOT KEYS

=head2 control+f

Toggle minimizing of the sidebar.

=head2 control+r

Resize the image to what the zoom level should be.

=head2 control+z

Cycle zoom types.

=head2 control+up

Go to the previous image.

=head2 control+down

Go to the next image.

=head1 ZOOM TYPES

The current level will be displayed to the right of the equals sign
on the zoom button or may be fetched using '$ivb->zoomget'.

=head2 w

This zooms it to the width of the image.

=head2 f

This zooms the image to fit the window.

=head2 1

This sets the zoom to 1.

=head1 AUTHOR

Zane C. Bowers, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-gtk2-imageview-browser at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Gtk2-ImageView-Browser>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Gtk2::ImageView::Browser


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Gtk2-ImageView-Browser>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Gtk2-ImageView-Browser>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Gtk2-ImageView-Browser>

=item * Search CPAN

L<http://search.cpan.org/dist/Gtk2-ImageView-Browser/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Zane C. Bowers, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Gtk2::ImageView::Browser
