package Gimp::UI;

use Gimp ('__');
use Gimp::Fu;
use POSIX qw(locale_h);
my $locale;
BEGIN { $locale = setlocale(LC_NUMERIC); setlocale(LC_NUMERIC, "C"); }
use Gtk2;
BEGIN { setlocale(LC_NUMERIC, $locale); }
use IO::All;
use List::Util qw(min);
use strict;
use warnings;

our (@ISA, $VERSION);
BEGIN {
   no locale;
   $VERSION = "2.38";
   eval {
      require XSLoader;
      XSLoader::load Gimp::UI $VERSION;
   } or do {
      require DynaLoader;
      @ISA = qw(DynaLoader);
      bootstrap Gimp::UI $VERSION;
   };
}

# shows the properties of a glib object
#d# just to debug
sub info {
   my ($idx, $obj) = @_;
   my %seen;
   return if $seen{$idx}++;
   print "\n$idx\n";
   for ($obj->list_properties) {
      printf "%-16s %-24s %-24s %s\n", $_->{name}, $_->{type}, (join ":", @{$_->{flags}}), $_->{descr};
   }
}

@Gimp::UI::Combo::Image::ISA   =qw(Gimp::UI::Combo);
@Gimp::UI::Combo::Layer::ISA   =qw(Gimp::UI::Combo);
@Gimp::UI::Combo::Channel::ISA =qw(Gimp::UI::Combo);
@Gimp::UI::Combo::Drawable::ISA=qw(Gimp::UI::Combo);

package Gimp::UI::Combo;

use Gimp ('__');
our @ISA = 'Gtk2::ComboBox';

sub image_name { $_[0]->get_filename || "Untitled-".${$_[0]}; }

sub Gimp::UI::Combo::Image::_items {
  +{ map { (image_name($_) => $_) } Gimp::Image->list }
}

sub Gimp::UI::Combo::Layer::_items {
  +{
    map {
      my $i = $_;
      map { (image_name($i)."/".$_->get_name => $_) } $i->get_layers;
    } Gimp::Image->list
  }
}

sub Gimp::UI::Combo::Channel::_items {
  +{
    map {
      my $i = $_;
      map { (image_name($i)."/".$_->get_name => $_) } $i->get_channels;
    } Gimp::Image->list
  }
}

sub Gimp::UI::Combo::Drawable::_items {
  +{ %{Gimp::UI::Combo::Channel->_items}, %{Gimp::UI::Combo::Layer->_items} }
}

sub new($) {
  my ($class,$var)=@_;
  my $self = bless $class->SUPER::new_text, $class;
  $self->{GIMPUI_text2scalar} = {};
  $self->reload;
  $self;
}

sub get_active_scalar {
  my $self = shift;
  $self->{GIMPUI_text2scalar}->{$self->get_active_text};
}

sub reload {
  warn __PACKAGE__ . "::reload(@_)" if $Gimp::verbose >= 2;
  my ($self) = @_;
  my $count = keys %{ $self->{GIMPUI_text2scalar} };
  $self->remove_text(0) while $count--;
  my $t2s = $self->_items;
  my @items = keys %$t2s;
  $t2s = { '(none)' => undef } unless @items;
  for my $t (keys %$t2s) { $self->append_text($t); }
  $self->{GIMPUI_text2scalar} = $t2s;
  $self->set_active(0);
}

package Gimp::UI::PreviewSelect;

# Parent widget that handles a generic preview selection.
#
# pure virtual methods (must be implemented by child):
#                  ->get_list
#                  ->get_title
#                  ->get_pixbuf
#TODO: Add preview (or portion of preview) directly to button

use Gtk2::SimpleList;

our @ISA = 'Glib::Object';

Glib::Type->register (
  'Gtk2::Button', __PACKAGE__,
  signals => {},
  properties => [
    Glib::ParamSpec->string(
      'active',
      'Active',
      'The active child',
      '',
      [qw/readable writable/]
    ),
  ],
);

sub SET_PROPERTY {
  my ($self, $pspec, $newval) = @_;
  return unless $pspec->get_name eq 'active';
  $self->{active} = $newval;
  $self->set_label($newval);
}

sub GET_PROPERTY {
  my ($self, $pspec) = @_;
  if ($pspec->get_name eq 'active') {
    return $self->{active};
  }
}

sub INIT_INSTANCE {
  my ($self) = @_;
  $self->signal_connect("clicked", \&preview_dialog);
  my $lbl = new Gtk2::Label $self->get("active");
  $self->add($lbl);
}

sub preview_dialog {
  my ($self) = @_;
  my $w = new Gtk2::Dialog;
  $w->set_title($self->get_title);
  $w->set_default_size(400,300);
  $w->action_area->set_border_width(2);
  $w->action_area->set_homogeneous(0);
  (my $h=new Gtk2::HBox 0,0)->show;
  $w->vbox->pack_start($h,1,1,0);
  (my $s=new Gtk2::ScrolledWindow undef,undef)->show;
  $s->set_policy(-automatic, -automatic);
  $s->set_size_request(200,300);
  $h->pack_start($s,1,1,0);
  my $datalist = new Gtk2::SimpleList (
    'Name' => 'text',
    'Preview' => 'pixbuf',
  );
  for(sort $self->get_list) {
    my $listname = $_;
    my $pixbuf = $self->new_pixbuf($listname);
    push @{$datalist->{data}}, [ $listname, $pixbuf ];
  }
  $datalist->get_selection->set_mode('single');
  $datalist->get_selection->unselect_all;
  $s->add($datalist);
  $datalist->show;
  my $hbbox = new Gtk2::HButtonBox;
  $hbbox->set_spacing(2);
  $w->action_area->pack_end($hbbox,0,0,0);
  show $hbbox;
  my $button = new Gtk2::Button->new_from_stock('gtk-cancel');
  signal_connect $button clicked => sub {hide $w};
  $hbbox->pack_start($button,0,0,0);
  can_default $button 1;
  show $button;
  $button = new Gtk2::Button->new_from_stock('gtk-ok');
  signal_connect $button clicked => sub {
    my @sel = $datalist->get_selected_indices;
    my @row =  $datalist->{data}[$sel[0]];
    $self->set( active => scalar($row[0][0]) );
    hide $w;
  };
  $hbbox->pack_start($button,0,0,0);
  can_default $button 1;
  grab_default $button;
  show $button;
  show $w;
}

package Gimp::UI::PatternSelect;

our @ISA = 'Glib::Object';

Glib::Type->register (
   'Gimp::UI::PreviewSelect', __PACKAGE__,
   signals => {},
   properties => [],
);

sub get_title { Gimp::__"Pattern Selection Dialog" }
sub get_list { Gimp::Patterns->get_list("") }

sub new_pixbuf {
   my ($w,$h,$bpp,$mask)=Gimp::Pattern->get_pixels ($_);
   my $has_alpha = ($bpp==2 || $bpp==4);
   if ($bpp==1) {
      my @graydat = unpack "C*", $mask;
      my @rgbdat;
      foreach (@graydat) {
	 push @rgbdat, $_; push @rgbdat, $_; push @rgbdat, $_;
      }
      $mask = pack "C*", @rgbdat;
   } elsif($bpp == 3) {
      $mask = pack "C*", @{$mask};
   } elsif($bpp == 4) {
      $mask = pack "C*", @{$mask}[0..2];
   }
   # TODO: Add code/test for handling GRAYA; don't have any GRAYA to test
   # with currently though.
   Gtk2::Gdk::Pixbuf->new_from_data(
      $mask,'rgb', $has_alpha?1:0, 8, $w, $h, $has_alpha?$w*4:$w*3
   );
}

package Gimp::UI::BrushSelect;

our @ISA = 'Glib::Object';

Glib::Type->register (
   'Gimp::UI::PreviewSelect', __PACKAGE__,
   signals => {},
   properties => [],
);

sub get_title { Gimp::__"Brush Selection Dialog" }
sub get_list { Gimp::Brushes->get_list("") }

sub new_pixbuf {
   my ($w,$h,$mask_bpp,$mask,$color_bpp,$color_data) = Gimp::Brush->get_pixels($_);
   my @rgbdat;
   # color bitmaps seem broken from gimp's side, but I'm leaving it in here.
   # if you notice this and care, let me know and I may fix the gimp side.
   if ($color_bpp == 3) {
      @rgbdat = @{$color_data} ;
   } elsif ($color_bpp == 0) {
     my @graydat = @{$mask};
     foreach (@graydat) {
        $_ = 255 - $_;
        push @rgbdat, $_; push @rgbdat, $_; push @rgbdat, $_;
     }
   }
   Gtk2::Gdk::Pixbuf->new_from_data(pack("C*", @rgbdat),'rgb',0,8,$w,$h,$w*3);
}

package Gimp::UI::GradientSelect;

our @ISA = 'Glib::Object';

Glib::Type->register (
   'Gimp::UI::PreviewSelect', __PACKAGE__,
   signals => {},
   properties => [],
);

sub get_title { Gimp::__"Gradient Selection Dialog" }
sub get_list { Gimp::Gradients->get_list("") }

sub new_pixbuf {
   use POSIX;
   my @grad_row = map { $_ = abs(ceil($_*255 - 0.5)) }
                   Gimp::Gradient->get_uniform_samples ($_,100,0);
# make it 16 tall; there's bound to be a better way to do this? (it's slow)
   push @grad_row, @grad_row, @grad_row, @grad_row,
        @grad_row, @grad_row, @grad_row, @grad_row,
        @grad_row, @grad_row, @grad_row, @grad_row,
        @grad_row, @grad_row, @grad_row, @grad_row;
   my $pb = Gtk2::Gdk::Pixbuf->new_from_data(
      pack "C*", @grad_row,'rgb',1,8,100,8,100*4
   );
}

package Gimp::UI;

sub _new_adjustment {
   my @adj = eval { @{$_[1]} };
   $adj[2] ||= ($adj[1] - $adj[0]) * 0.01;
   $adj[3] ||= ($adj[1] - $adj[0]) * 0.01;
   $adj[4] ||= 0;
   new Gtk2::Adjustment $_[0], @adj;
}

# find a suitable value for the "digits" value
sub _find_digits {
   my $adj = shift;
   my $digits = log ($adj->step_increment || 1) / log(0.1);
   $digits > 0 ? int $digits + 0.9 : 0;
}

sub help_window(\$$$$) {
   my ($helpwin, $parent, $title, $blurb) = @_;
   unless ($$helpwin) {
      $$helpwin = new Gtk2::Dialog sprintf(__"Help for %s", $title), $parent, [];
      $$helpwin->action_area->set_border_width (2);
      my $tophelp = new Gtk2::Label $blurb;
      $tophelp->set_alignment(0.5,0.5);
      $tophelp->set_line_wrap(1);
      $$helpwin->vbox->pack_start($tophelp,0,1,3);
      my $sw = new Gtk2::ScrolledWindow undef,undef;
      $sw->set_policy (-automatic, -automatic);
      $sw->set_size_request(500,600);
      require Gtk2::Ex::PodViewer;
      my $pv = new Gtk2::Ex::PodViewer;
      require FindBin;
      $pv->load("$FindBin::RealBin/$FindBin::RealScript");
      $pv->show;
      $sw->add($pv);
      $$helpwin->vbox->add($sw);
      my $button = Gtk2::Button->new_from_stock('gtk-ok');
      signal_connect $button clicked => sub { hide $$helpwin };
      $$helpwin->action_area->add ($button);
      $$helpwin->signal_connect (destroy => sub { undef $$helpwin });
   }
   $$helpwin->show_all;
   $$helpwin->run;
   $$helpwin->hide;
}

sub _instrument {
  return unless $Gimp::verbose >= 2;
  my $obj = shift;
  my $class = ref $obj;
  my %sig2done;
  map {
    my $c = $_;
    map {
#warn "$c:$_->{signal_name}\n";
      my $s = $_->{signal_name};
      $obj->signal_connect(
	$s => sub { warn "SIG:$s(@_)\n";0 }
      ) unless $sig2done{$s};
      $sig2done{$s} = 1;
    } Glib::Type->list_signals($c);
  } Glib::Type->list_ancestors($class);
}

sub drawable_box {
  my $class = shift;
  my $a = Gtk2::HBox->new(0,5);
  my $b = $class->new;
  $a->pack_start($b, 1, 1, 0);
  my $c = Gtk2::Button->new("Refresh");
  $c->signal_connect("clicked", sub {$b->reload});
  $a->pack_start($c, 1, 1, 0);
  ($a, sub { }, sub { $b->get_active_scalar });
}

# function($name,$desc,$default,$extra,$value) returns $widget,\&setval,\&getval
my %PF2INFO = (
  &PF_STRING => sub {
    my $e = new Gtk2::Entry;
    ($e, sub { set_text $e $_[0] // "" }, sub { get_text $e });
  },
  &PF_SLIDER => sub {
    my ($name,$desc,$default,$extra,$value) = @_;
    my $adj = _new_adjustment ($value, $extra);
    my $a = new Gtk2::HScale $adj;
    $a->set_digits (_find_digits $adj);
    $a->set_size_request(120,-1);
    ($a, sub { $adj->set_value($_[0]) }, sub { $adj->get_value });
  },
  &PF_SPINNER => sub {
    my ($name,$desc,$default,$extra,$value) = @_;
    my $adj = _new_adjustment ($value, $extra);
    my $a = new Gtk2::SpinButton $adj, 1, 0;
    $a->set_digits (_find_digits $adj);
    ($a, sub { $adj->set_value($_[0]) }, sub { $adj->get_value });
  },
);
%PF2INFO = (
  %PF2INFO,
  &PF_FLOAT => $PF2INFO{&PF_STRING},
  &PF_FILE => sub {
    my ($name,$desc,$default,$extra,$value) = @_;
    my ($a, $set, $get) = $PF2INFO{&PF_STRING}->();
    my $s = $a;
    $a = new Gtk2::HBox 0,5;
    $a->add ($s);
    my $b = new Gtk2::Button __"Browse";
    $a->add ($b);
    $b->signal_connect(clicked => sub {
      my $f = new Gtk2::FileChooserDialog
	sprintf(__"Choose %s", $name),
	undef, 'save', 'gtk-cancel' => 'cancel', 'gtk-ok' => 'ok';
      $f->set_filename('.');
      $f->set_current_name($s->get_text);
      $f->show_all;
      $s->set_text($f->get_filename) if $f->run eq 'ok';
      $f->destroy;
      1;
    });
    ($a, $set, $get);
  },
  &PF_ADJUSTMENT => sub {
    my ($name,$desc,$default,$extra,$value) = @_;
    my (@x)=@$default;
    $value=shift @x;
    $PF2INFO{pop(@x) ? &PF_SPINNER : &PF_SLIDER}->(
      $name, $desc, $default, [@x], $value,
    );
  },
  &PF_INT8 => sub { $PF2INFO{&PF_SLIDER}->(@_[0..2], [ 0, 255, 1 ], $_[4]); },
  &PF_INT16 => sub {
    my $max = 1 << 15;
    $PF2INFO{&PF_SPINNER}->(@_[0..2], [ -$max, $max - 1, 1 ], $_[4]);
  },
  &PF_INT32 => sub {
    my $max = 1 << 31;
    $PF2INFO{&PF_SPINNER}->(@_[0..2], [ -$max, $max - 1, 1 ], $_[4]);
  },
  &PF_FONT => sub {
    my ($name,$desc,$default,$extra,$value) = @_;
    $default = 'Sans' unless $default;
    $value = $default unless $value;
    my ($a, $s, $g);
    if ($Gimp::interface_pkg ne 'Gimp::Net') {
      $a = new Gimp::UI::FontSelectButton $desc, $default;
      $s = sub { $a->set_font($_[0] || 'Arial') };
      $g = sub { $a->get_font };
#      _instrument($a);
    } else {
      # no GIMP ui available, use Gtk2 equivalent
      my $fs = new Gtk2::FontSelectionDialog sprintf __"Font Selection Dialog (%s)", $desc;
      my $val;
      my $l = new Gtk2::Label "!error!";
      my $setval = sub {
	$val = shift // '';
	$val =~ s#\s*(Bold)?\s*(Italic)?\s*\d+$##; # vim highlighter
	unless (defined $val && $fs->set_font_name ("$val 10")) {
	  warn sprintf __"Illegal default font description: %s\n", $val
	    if defined $val;
	  $val = $default;
	  $fs->set_font_name ("$val 10");
	}
	$l->set (label => " $val ");
      };
      $fs->ok_button->signal_connect (clicked => sub {$setval->($fs->get_font_name); $fs->hide});
      $fs->cancel_button->signal_connect (clicked => sub {$fs->hide});
      $s = $setval;
      $g = sub { $val };
      $a = new Gtk2::Button;
      $a->add ($l);
      $a->signal_connect (clicked => sub { show $fs });
    }
    ($a, $s, $g);
  },
  &PF_COLOR => sub {
    my ($name,$desc,$default,$extra,$value) = @_;
    my ($a, $s, $g);
    if ($Gimp::interface_pkg eq 'Gimp::Net') {
      $a = Gtk2::ColorButton->new;
      $s = sub {
	my $colour = Gimp::canonicalize_color(shift // [0.8,0.6,0.1]);
	my @rgb = map { $_ * ((1<<16)-1) } @$colour[0..2];
	$a->set_color(Gtk2::Gdk::Color->new(@rgb));
      };
      $g = sub {
	my $gc = $a->get_color;
	my @c = map { $_ / ((1<<16)-1) } $gc->red, $gc->green, $gc->blue;
	\@c;
      };
    } else {
      $default = Gimp::canonicalize_color($default // [0.8,0.6,0.1]);
      $a = new Gimp::UI::ColorButton $desc, 90, 14, $default, 'small-checks';
#      _instrument($a);
      $s = sub {
	$a->set_color(Gimp::canonicalize_color(shift // [0.8,0.6,0.1]));
      };
      $g = sub { $a->get_color };
    }
    ($a, $s, $g);
  },
  &PF_TOGGLE => sub {
    my $a = new Gtk2::CheckButton;
    ($a, sub{ $a->set (active => $_[0] ? 1 : 0)}, sub{ $a->get("active") });
  },
  &PF_RADIO => sub {
    my ($name,$desc,$default,$extra,$value) = @_;
    my $b = new Gtk2::HBox 0,5;
    my ($r,$prev);
    my $prev_sub = sub { $r = $_[0] };
    while (@$extra) {
      my $label = shift @$extra;
      my $value = shift @$extra;
      my $radio = new Gtk2::RadioButton undef, $label;
      $radio->set_group ($prev) if $prev;
      $b->pack_start ($radio, 1, 0, 5);
      $radio->signal_connect (clicked => sub { $r = $value });
      my $prev_sub_my = $prev_sub;
      $prev_sub = sub { $radio->set_active ($_[0] eq $value); &$prev_sub_my };
      $prev = $radio;
    }
    $a = new Gtk2::Frame;
    $a->add($b);
    ($a, $prev_sub, sub { $r });
  },
  &PF_IMAGE => sub {
    my ($name,$desc,$default,$extra,$value) = @_;
    my $a = Gtk2::HBox->new(0,5);
    my $b = Gimp::UI::Combo::Image->new;
    $a->pack_start ($b,1,1,0);
    my $load = Gtk2::Button->new('Browse');
    $a->pack_start ($load,1,1,0);
    $load->signal_connect (clicked => sub {
      my $f = new Gtk2::FileChooserDialog
	sprintf(__"Load %s", $name),
	undef, 'open', 'gtk-cancel' => 'cancel', 'gtk-open' => 'ok';
      $f->set_filename ('.');
      $f->show_all;
      my $result = $f->run;
      if ($result eq 'ok') {
	my $i = Gimp->file_load($f->get_filename, $f->get_filename);
	eval { Gimp::Display->new($i); };
	$b->reload;
      }
      $f->destroy;
      1;
    });
    my $c = Gtk2::Button->new("Refresh");
    $c->signal_connect("clicked", sub {$b->reload});
    $a->pack_start ($c,1,1,0);
    ($a, sub { }, sub { $b->get_active_scalar });
  },
  &PF_LAYER => sub { drawable_box('Gimp::UI::Combo::Layer'); },
  &PF_CHANNEL => sub { drawable_box('Gimp::UI::Combo::Channel'); },
  &PF_DRAWABLE => sub { drawable_box('Gimp::UI::Combo::Drawable'); },
  &PF_PATTERN => sub {
    my ($name,$desc,$default,$extra,$value) = @_;
    my $a=new Gimp::UI::PatternSelect;
    ($a,
      sub { $a->set('active', $value // (Gimp::Context->get_pattern)[0]) },
      sub { $a->get('active') });
  },
  &PF_BRUSH => sub {
    my ($name,$desc,$default,$extra,$value) = @_;
    my $a=new Gimp::UI::BrushSelect;
    ($a,
      sub{ $a->set('active', $value // (Gimp::Context->get_brush)[0]) },
      sub{ $a->get('active') });
  },
  &PF_GRADIENT => sub {
    my ($name,$desc,$default,$extra,$value) = @_;
    $a=new Gimp::UI::GradientSelect;
    ($a,
      sub { $a->set('active', $value // (Gimp::Gradients->get_list(""))[0]) },
      sub { $a->get('active') });
  },
  &PF_CUSTOM => sub { goto &{$_[3]}; },
  &PF_TEXT => sub {
    my ($name,$desc,$default,$extra,$value) = @_;
    my $a = new Gtk2::Frame;
    my $h = new Gtk2::VBox 0,5;
    $a->add($h);
    my $b = new Gtk2::TextBuffer;
    my $e = new_with_buffer Gtk2::TextView $b;
    $e->set_size_request(300,200);
    $e->set_wrap_mode('GTK_WRAP_WORD');
    $e->set_editable (1);
    $h->add ($e);
    my $buttons = new Gtk2::HBox 1,5;
    $h->add ($buttons);
    my $sv = sub { $b->set_text ($_[0]); };
    my $gv = sub {$b->get_text ($b->get_start_iter, $b->get_end_iter, 0);};
    my $load = Gtk2::Button->new_from_stock('gtk-open');
    my $save = Gtk2::Button->new_from_stock('gtk-save');
    my $edit = Gtk2::Button->new_from_stock('gimp-edit');
    $buttons->add ($load);
    $buttons->add ($save);
    $buttons->add ($edit);
    $edit->signal_connect (clicked => sub {
      my $tmp = Gimp->temp_name("txt");
      io($tmp)->utf8->print(&$gv);
      system 'gedit', $tmp;
      $sv->(io($tmp)->utf8->all);
    });
    $load->signal_connect (clicked => sub {
      my $f = new Gtk2::FileChooserDialog
	sprintf(__"Load %s", $name),
	undef, 'open', 'gtk-cancel' => 'cancel', 'gtk-open' => 'ok';
      $f->set_filename ('.');
      $f->show_all;
      $sv->(io($f->get_filename)->utf8->all) if $f->run eq 'ok';
      $f->destroy;
      1;
    });
    $save->signal_connect (clicked => sub {
      my $f = new Gtk2::FileChooserDialog
	sprintf(__"Save %s", $name),
	undef, 'save', 'gtk-cancel' => 'cancel', 'gtk-save' => 'ok';
      $f->set_filename ('.');
      $f->show_all;
      io($f->get_filename)->utf8->print(&$gv) if $f->run eq 'ok';
      $f->destroy;
      1;
    });
    ($a, $sv, $gv);
  },
);

sub interact {
  warn __PACKAGE__ . "::interact(@_)" if $Gimp::verbose >= 2;
  my ($function, $blurb, $help, $params, $menupath, $code) = splice @_, 0, 6;
  my ($silent_vals, $start_vals) = @_;
  my (@getvals, @setvals, @lastvals, @defaults);
  my $helpwin;

  Gimp::gtk_init;
  my $exception_text;
  my $exception = sub { $exception_text = $_[0]; Gtk2->main_quit; };
  Glib->install_exception_handler($exception);
  Glib::Log->set_handler(
    'GLib-GObject', [
      qw(G_LOG_FATAL_MASK G_LOG_LEVEL_CRITICAL G_LOG_LEVEL_ERROR
      G_LOG_FLAG_FATAL G_LOG_LEVEL_WARNING)
    ], $exception
  );

  my $t = new Gtk2::Tooltips;
  my $title = $menupath;
  $title =~ s#.*/##; $title =~ s#[_\.]##g;
  my $w = new Gtk2::Dialog "Perl-Fu: $title", undef, [];
  $w->set_border_width(3); # sets border on inside because it's a window
  $w->action_area->set_spacing(2);
  $w->action_area->set_homogeneous(0);
  my $topblurb = new Gtk2::Label $blurb;
  $topblurb->set_alignment(0.5,0.5);
  $w->vbox->pack_start($topblurb,0,1,3);
  my $table = new Gtk2::Table scalar @$params,2,0;
  $table->set(border_width => 4);
  my $row = 0;
  for(@$params) {
    my ($type,$name,$desc,$default,$extra)=@$_;
    my ($value)=shift @$start_vals;
    $value=$default unless defined $value;
    die sprintf __"Unsupported argumenttype %s for %s\n", $type, $name
      unless $PF2INFO{$type};
    my ($a, $sv, $gv) = $PF2INFO{$type}->($name,$desc,$default,$extra,$value);
    push @setvals, $sv;
    push @getvals, $gv;
    push @lastvals, $value;
    push @defaults, $default;
    $sv->($value);
    my $label = new Gtk2::Label "$desc: ";
    $label->set_alignment(1.0,0.5);
    $table->attach($label, 0, 1, $row, $row+1, ["expand","fill"], ["expand","fill"], 4, 2);
    my $halign = new Gtk2::HBox 0,0;
    $halign->pack_start($a,0,0,0);
    $table->attach($halign, 1, 2, $row, $row+1, ["expand","fill"], ["expand","fill"], 4, 2);
    $row++;
  }
  my $sw = new Gtk2::ScrolledWindow undef,undef;
  $sw->set_policy (-automatic, -automatic);
  $sw->add_with_viewport($table);
  $w->vbox->add($sw);

  my $mainloop = Glib::MainLoop->new;
  my $button = $w->add_button('gtk-help', 3);
  $button->signal_connect(clicked => sub {
    help_window($helpwin, $w, $title, $blurb);
  });
  $button = $w->add_button('gimp-reset', 2);
  $button->signal_connect(clicked => sub {
    map { $setvals[$_]->($defaults[$_]); } (0..$#defaults)
  });
  set_tip $t $button,__"Reset all values to their default";
  my $res = 0;
  $button = $w->add_button('gtk-cancel', 0);
  $button->signal_connect(clicked => sub {
    $mainloop->quit;
  });
  can_default $button 1;
  $button = $w->add_button('gtk-ok', 1);
  $button->signal_connect(clicked => sub {
    $res = 1;
    $mainloop->quit;
  });
  can_default $button 1;
  grab_default $button;
  $w->signal_connect(destroy => sub { $mainloop->quit; });
  set_transient($w);

  show_all $table;
  show_all $sw;
  $sw->set_size_request(
    min(0.75*$sw->get_screen->get_width, $table->size_request->width + 30),
    min(0.6*$sw->get_screen->get_height, $table->size_request->height + 5)
  );
  show_all $w;
  $mainloop->run;
  die $exception_text if $exception_text;
  my @input_vals = map {&$_} @getvals if $res;
  my @return_vals = $code->(@$silent_vals, @input_vals) if $res and $code;
  $w->destroy;
  return (0, \@input_vals, []) unless $res;
  return (1, \@input_vals, \@return_vals);
}

1;
__END__

=head1 NAME

Gimp::UI - Programming interface to libgimpui, plus Gtk widgets for other
parameter types.

=head1 SYNOPSIS

  use Gimp::UI;

=head1 DESCRIPTION

If you use L<Gimp::Fu> in your script, a GUI will be taken care of
for you. However, for an example of implementing your own UI, see
C<examples/example-no-fu>.

=over 4

 $combo_box = new Gimp::UI::Combo::Image;
 $combo_box = new Gimp::UI::Combo::Layer;

 $button = new Gimp::UI::PatternSelect;
 $button = new Gimp::UI::BrushSelect;
 $button = new Gimp::UI::GradientSelect;

 # if $code = undef, just run the UI and return the Ok/Cancel and values
 ($result, \@input_vals, \@return_vals) = Gimp::UI::interact(
   $functionname, $blurb, $help, $params, $menupath, $code,
   \@silent_vals, # don't show in UI or return in \@input_vals
   \@start_vals, # do show in UI and return in \@input_vals
 ); # $result = true if "Ok", false if "Cancel"

=back

=head1 AUTHOR

Marc Lehmann <pcg@goof.com>, Seth Burgess <sjburges@gimp.org>

=head1 SEE ALSO

perl(1), L<Gimp>.
