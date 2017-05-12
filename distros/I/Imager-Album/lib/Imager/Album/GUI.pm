package Imager::Album::GUI;

use Imager;
use Gtk;
use Gtk::Gdk;

use strict;

# Where in gods name do I put this!?!?

init Gtk;
init Gtk::Gdk::Rgb;

use vars qw ( $red $blue $yellow $green $gray);

$red    = Gtk::Gdk::Color->parse_color("red");
$blue   = Gtk::Gdk::Color->parse_color("blue");
$green  = Gtk::Gdk::Color->parse_color("green");
$yellow = Gtk::Gdk::Color->parse_color("yellow");
$gray   = Gtk::Gdk::Color->parse_color("gray");



sub new {
  my $class = shift;
  my $self  = {};
  bless $self, $class;

  $self->{'parent'} = shift;
  $self->{'images'} = $self->{'parent'}->{'images'};

  $self->{'gui_info'}  = {}; # store references to labels
  $self->{'selection'} = {}; # current selection

  my $window = new Gtk::Window "toplevel";
  $window->set_usize(700,300);
  $window->set_title( "Imager::Album v".$Imager::Album::VERSION );
  $window->signal_connect( "destroy", sub { Gtk->exit( 0 ); } ); # XXX
  $window->show;

  my $timg = $self->{'images'};
  $self->{'ordering'} = $self->{'parent'}->{'ordering'};

  my $gdkwindow = $window->window;
  my $gc        = Gtk::Gdk::GC->new($gdkwindow);

  my $imagelist = $self->make_imagelist();

  my $hbox = new Gtk::HBox 0, 0;
  my $ltb  = new Gtk::VBox 0, 0;
  $hbox->pack_start( $ltb, 0, 1, 0);

  $ltb->pack_start( $imagelist, 1, 1, 0);

  my $commands = $self->make_commands(@{$self->{'parent'}->{'commands'}});
  $ltb->pack_start( $commands, 0, 1, 0);

  my $previewer = $self->make_previewer();
  $hbox->pack_end( $previewer->{'scroller'}, 1, 1, 0);
  $hbox->show();
  $ltb->show();
  $window->add( $hbox );
  $window->show();

  $self->{'window'}    = $window;
  $self->{'gdkwindow'} = $gdkwindow;
  $self->{'gc'}        = $gc;
  $self->{'previewer'} = $previewer;
  $self->{'imagelist'} = $imagelist;
  $self->{'parent'}->{'gui'} = $self;

  #  $pixmap->show;
  $self->previewer_update($previewer);
}


sub boot {
  main Gtk;
  exit( 0 );
}


sub shutdown {
  my $self = shift;
  $self->{'window'}->destroy();
}


sub get_selection {
  my $self = shift;
  my %rev;
  my @images = @{$self->{'ordering'}};
  @rev{@images} = 0..$#images;
  my @selection = keys %{$self->{'selection'}};
  @selection = sort { $rev{$a}<=>$rev{$b} } @selection;
  return @selection;
}

sub make_commands {
  my $self = shift;
  my @commands = @_;
  my $vbox = new Gtk::VBox 0,0;

  for (@commands) {
    my $button = new Gtk::Button($_->[0]);
    my $code = $_->[1];
    $button->signal_connect('clicked',
			    sub {
			      $code->($self->{'parent'}, $self->get_selection() );
			      $self->previewer_update();
			    });
    $vbox->pack_start($button, 1, 1, 0);
    $button->show();
  }

  $vbox->show();
  return $vbox;
}



sub make_imagelist {
  my $self = shift;
  my %images = %{$self->{'images'}};

  my $scroller = new Gtk::ScrolledWindow(undef, undef);
  my $list     = Gtk::CList->new_with_titles( "File", "Title" );

  $list->set_reorderable(1);
  $scroller->set_policy('never', 'always');
  $scroller->border_width(0);

  $list->set_column_width( 0, 100 );
  $list->set_column_width( 1, 100 );
  $list->set_selection_mode(-extended);

  $list->signal_connect( "select_row"   => sub { $self->set_image(@_);   } );
  $list->signal_connect( "unselect_row" => sub { $self->unset_image(@_); } );

  $list->signal_connect( "row_move" => sub { my ($list, $f, $t) = @_;
					     my $parent = $self->{'parent'};
					     $parent->change_order($f, $t);
					     $self->previewer_update(); }
		       );

  $scroller->add($list);

  $scroller -> show();
  $list     -> show();

  my @iorder = @{$self->{'ordering'}};
  for (@iorder) {
      $list->append( $images{$_}->{'path'}, $images{$_}->{'name'});
  }
  return $scroller;
}


# Called when nothing is removed or added

sub imagelist_update_names {
  my $self = shift;
  my $list = $self->{'imagelist'}->child();
  my %images = %{$self->{'images'}};

  my $rows = $list->rows();
  my @iorder = @{$self->{'ordering'}};

  for (0..$rows-1) {
    $list->set_text($_, 0, $images{$iorder[$_]}->{'path'});
    $list->set_text($_, 1, $images{$iorder[$_]}->{'name'});
  }
}


sub imagelist_update {
  my $self = shift;
  my $list = $self->{'imagelist'}->child();

  $list -> clear();

  my %images = %{$self->{'images'}};

  my @iorder = @{$self->{'ordering'}};
  for (@iorder) {
    $list->append( $images{$_}->{'path'}, $images{$_}->{'name'});
  }
}





sub make_previewer {
  my $previewer = {};
  my $scroller = new Gtk::ScrolledWindow(undef, undef);

  $scroller->set_policy('automatic', 'always');
  $scroller->border_width(0);

  my $vbox  = new Gtk::VBox 0,0;
  $scroller -> add_with_viewport($vbox);

  $vbox     -> show();
  $scroller -> show();

  $previewer->{scroller} = $scroller;
  $previewer->{vbox}     = $vbox;
  return $previewer;
}



sub previewer_update {
  my $self      = shift;
  my $previewer = $self->{'previewer'};
  my $album     = $self->{'parent'};
  my $vbox      = $previewer->{'vbox'};

  # This nukes everything in the boxes
  {
    my @tt;
    $vbox->foreach(sub { my $hbox = shift;
			 $hbox->foreach(sub {
					  my @t = ();
					  my $tb = shift;
					  $tb->foreach(sub { push(@t, shift); });
					  $tb->remove($_) for @t;
					});
			 push(@tt, $hbox);
		       });
    $vbox->remove($_) for @tt;
  }

  my %images = %{$self->{'images'}};
  my @prelist = @{$self->{'ordering'}};

  for (@prelist) {
    if (!$self->{'images'}->{$_}->{'valid'}) {
      delete $self->{'images'}->{$_}->{'gdk_preview'};
    }
  }

  $album->update_previews();

  my $rows = int((3+@prelist)/4);
  my $count = 0;
  my $row;
  for $row (0..$rows-1) {
    my $hbox = new Gtk::HBox 0,0;
    my $col;
    for $col (0..3) {
      next if $count >= @prelist;
      my $imageno = $prelist[$count];
      my $image = $album->get_image($imageno);
      my $gdkim;

      if (! exists $image->{gdk_preview}) {
	$gdkim = $self->read_image( $album->get_preview_path($imageno) );
	$image->{gdk_preview} = $gdkim;
      } else {
	$gdkim = $image->{gdk_preview};
      }
      $gdkim->show();
      my $tbox = new Gtk::VBox 0,0;
#      my $button = new Gtk::Button($imageno." :: ".$image->{'name'});
      my $button = new Gtk::Button($image->{'name'});
      $self->{'gui_info'}->{$imageno} = $button;
      if (exists $self->{'selection'}->{$imageno}) {
	my $tstyle = $button->get_style()->copy();
	$tstyle->bg('normal', $yellow);
	$tstyle->bg('prelight', $yellow);
	$button->set_style($tstyle);
      }
      my $t = $count; # this must be done so closures don't all refer to
                      # same variable
      $button->signal_connect('clicked', sub {
				my $list = $self->{'imagelist'}->child();
				if (exists $self->{'selection'}->{$imageno}) {
				  $list->unselect_row($t,0);
				} else {
				  $list->select_row($t,0);
				}
			      });
      $tbox->pack_start( $gdkim,  0, 0, 0);
      $tbox->pack_start( $button, 0, 0, 0);
      $button->show();
      $hbox->pack_start( $tbox, 0, 0, 3);
      $tbox->show();
      $count++;
    }
    $vbox->pack_start($hbox, 0, 0, 2);
    $hbox->show();
  }
  $vbox->show();
}






sub image_to_row {
  my ($self, $imageno) = @_;
  my @images = @{$self->{'ordering'}};
  my %rev;
  @rev{@images} = 0..$#images;
  return $rev{$imageno};
}


sub row_to_image {
  my ($self, $row) = @_;
  my @images = @{$self->{'ordering'}};
  return $images[$row];
}





sub set_image {
  my ($self, $list, $row) = @_;

  my $imageno = $self->row_to_image($row);
  $self->{'selection'}->{$imageno} = 1;

  my $button = $self->{'gui_info'}->{$imageno};
  my $tstyle = $button->get_style()->copy();
  $tstyle->bg('normal', $yellow);
  $tstyle->bg('prelight', $yellow);

  $button->set_style($tstyle);
}



sub unset_image {
  my ($self, $list, $row) = @_;

  my $imageno = $self->row_to_image($row);
  delete $self->{'selection'}->{$imageno};

  my $button = $self->{'gui_info'}->{$imageno};
  my $tstyle = $button->get_style()->copy();
  $tstyle->bg('normal', $gray);
  $tstyle->bg('prelight', $gray);
  $button->set_style($tstyle);

}



sub remove_images {
  my $self = shift;
  my @imagenos = @_;
  $self->{'parent'}->remove_images(@imagenos);
  $self->{'selection'} = {};
  $self->previewer_update();
  $self->imagelist_update();
}



sub export_gallery {
  my $self = shift;
  $self->export();
}




sub label {
  my $self = shift;
  my @imagenos = @_;

  #  print "@imagenos\n";
  my @images = map { $self->{'images'}->{$_} } @imagenos;

  my $window = new Gtk::Window "toplevel";
  $window->set_usize(600,400);
  $window->set_title( "Image-Caption" );
  $window->set_modal( 1 );

  my $vbox = new Gtk::VBox 0,0;

  # Image at top
  my $imbox = new Gtk::HBox 0,0;
  $vbox->pack_start( $imbox, 0, 1, 0 );

  # image name
  my $fname_label = new Gtk::Label "Filename";
  $vbox->pack_start( $fname_label, 0, 1, 0 );

  # image name
  my $namentry = new Gtk::Entry;

  # caption next
  my $capentry = new Gtk::Entry;

  # button strip
  my $strip = new Gtk::HBox 0,0;


  $vbox->pack_end( $_, 0, 1, 0 ) for ($strip, $capentry, $namentry);

  my $prev_image = new Gtk::Button "previous image";
  $strip->pack_start( $prev_image, 0, 1, 0);

  my $next_image = new Gtk::Button "next image";
  $strip->pack_start( $next_image, 0, 1, 0);

  my $done = new Gtk::Button "done";
  $strip->pack_start( $done, 0, 1, 0);

  $window->add($vbox);


  $_->show() for ($done, $prev_image, $next_image,
		  $strip, $capentry, $namentry,
		  $fname_label, $imbox, $vbox, $window);


  my $gdkwindow = $window->window;

  my %scaleopts = (xpixels=>400, ypixels=>300, qtype=>'preview', type=>'min');

  my $ino = 0;

  my $imset = sub {
    my $img = Imager->new();
    my $ihash = $images[$ino];
    my %sopts = %scaleopts;
    $img->read(file=>$ihash->{'path'}) or die $img->errstr;

    if ($ihash->{'rotated'} % 2) {
      my $t = $sopts{'xpixels'};
      $sopts{'xpixels'}  = $sopts{'ypixels'};
      $sopts{'ypixels'}  = $t;
    }

    $img = $img->scale(%sopts);

    if ($ihash->{'rotated'}) {
      $img = $img->rotate(degrees=>$ihash->{'rotated'}*90);
    }

    my $gdkim = img_to_pix2($img, $gdkwindow);
    $gdkim->show;

    empty_box($imbox);
    $imbox->pack_start($gdkim, 1, 1, 1);


    $fname_label->set_text( ($ino+1)."/".@images." :: ".$ihash->{'path'});

    $namentry->set_text($ihash->{'name'});
    $capentry->set_text($ihash->{'caption'});
  };

  my $imstore = sub {
    my $ihash = $images[$ino];
    $ihash->{'name'} = $namentry->get_text();
    $ihash->{'caption'} = $capentry->get_text();
  };


  $imset->();


  $prev_image->signal_connect('clicked', sub {
				$imstore->();
				$ino = ($ino+@images-1)%(0+@images);
				$imset->();
			      });

  $next_image->signal_connect('clicked', sub {
				$imstore->();
				$ino = ($ino+1)%(0+@images);
				$imset->();
			      });


  $done->signal_connect('clicked', sub {
			  $imstore->();
			  $window->destroy();
			  $self->previewer_update();
			  $self->imagelist_update_names();
			});



}













sub export {
  my $self = shift;

  my $window = new Gtk::Window "toplevel";
#  $window->set_usize(600,400);
  $window->set_title( "Image-Caption" );
  $window->set_modal( 1 );

  my $vbox = new Gtk::VBox 0,0;

  # path name
  my $hbox = new Gtk::HBox 0,0;
  my $dir_label = new Gtk::Label "Directory to export to:";
  my $dir_entry = new Gtk::Entry;

  $hbox->pack_start( $dir_label, 0, 1, 0);
  $hbox->pack_end(   $dir_entry, 0, 1, 0);
  $vbox->pack_start( $hbox, 0, 1, 0 );
  $_->show() for ($hbox, $dir_label, $dir_entry);

  # gallery name
  $hbox = new Gtk::HBox 0,0;
  my $gallery_label = new Gtk::Label "Name of gallery:";
  my $gallery_entry = new Gtk::Entry;

  $hbox->pack_start( $gallery_label, 0, 1, 0);
  $hbox->pack_end(   $gallery_entry, 0, 1, 0);
  $vbox->pack_start( $hbox, 0, 1, 0 );
  $_->show() for ($hbox, $gallery_label, $gallery_entry);

  # button strip
  $hbox = new Gtk::HBox 0,0;
  my $ok = new Gtk::Button "Ok";
  my $cancel = new Gtk::Button "Cancel";

  $hbox->pack_start( $ok, 0, 1, 0);
  $hbox->pack_start( $cancel, 0, 1, 0);
  $vbox->pack_end( $hbox, 0, 1, 0 );
  $_->show() for ($hbox, $ok, $cancel);

  $window->add($vbox);

  $_->show() for ($vbox, $window);

  $ok->signal_connect('clicked', sub {
			my $gallery = $gallery_entry->get_text();
			my $dir = $dir_entry->get_text();
			$self->{'parent'}->export($dir, $gallery);
			$window->destroy();
		      });

  $cancel->signal_connect('clicked', sub {
			    $window->destroy();
			  });
}










# Technically these don't have to be methods
# but it's just simpler

sub read_image {
  my ($self, $file) = @_;

  my $img = Imager->new();
  $img->read(file=>$file) or die $img->errstr;
  my $pixmap = $self->img_to_pix($img);
  return $pixmap;
}




sub img_to_pix {
  my ($self, $img) = @_;

  my $gc = $self->{'gc'};
  my $gdkwindow = $self->{'gdkwindow'};

  my $width  = $img->getwidth;
  my $height = $img->getheight;
  my $data   = Imager::i_img_getdata($img->{IMG});

  my ($gdk_pixmap, $gdk_mask) = new Gtk::Gdk::Pixmap($gdkwindow, $width, $height, -1);
  $gdk_pixmap->draw_rgb_image($gc, 0, 0, $width, $height, 0, $data, $width*3);
  my $pixmap = new Gtk::Pixmap($gdk_pixmap, $gdk_mask);
  return $pixmap;
}



sub img_to_pix2 {
  my ($img, $gdkwindow) = @_;

  my $gc        = Gtk::Gdk::GC->new($gdkwindow);

  my $width  = $img->getwidth;
  my $height = $img->getheight;
  my $data   = Imager::i_img_getdata($img->{IMG});

  my ($gdk_pixmap, $gdk_mask) = new Gtk::Gdk::Pixmap($gdkwindow, $width, $height, -1);
  $gdk_pixmap->draw_rgb_image($gc, 0, 0, $width, $height, 0, $data, $width*3);
  my $pixmap = new Gtk::Pixmap($gdk_pixmap, $gdk_mask);
  return $pixmap;
}



sub empty_box {
  my $box = shift;
  my @widgets;
  $box->foreach(sub { push @widgets, shift; });
  $box->remove($_) for @widgets;
}



1;
