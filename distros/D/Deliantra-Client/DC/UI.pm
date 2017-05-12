package DC::UI;

use common::sense;

use List::Util ();

use Guard ();

use DC;
use DC::Pod;
use DC::Texture;

our ($FOCUS, $HOVER, $GRAB); # various widgets

our $LAYOUT;
our $ROOT;
our $TOOLTIP;
our $BUTTON_STATE;

our %WIDGET; # all widgets, weak-referenced

our $TOOLTIP_WATCHER = EV::timer_ns 0, 0.03, sub {
   $_[0]->stop;

   if (!$GRAB) {
      for (my $widget = $HOVER; $widget; $widget = $widget->{parent}) {
         if (length $widget->{tooltip}) {
            if ($TOOLTIP->{owner} != $widget) {
               $TOOLTIP->{owner}->emit ("tooltip_hide") if $TOOLTIP->{owner};
               $TOOLTIP->hide;

               $TOOLTIP->{owner} = $widget;
               $TOOLTIP->{owner}->emit ("tooltip_show") if $TOOLTIP->{owner};

               return if $ENV{CFPLUS_DEBUG} & 8;

               $TOOLTIP->set_tooltip_from ($widget);
               $TOOLTIP->show;
            }

            return;
         }
      }
   }

   $TOOLTIP->hide;
   $TOOLTIP->{owner}->emit ("tooltip_hide") if $TOOLTIP->{owner};
   delete $TOOLTIP->{owner};
};

sub get_layout {
   my $layout;

   for (grep { $_->{name} } values %WIDGET) {
      my $win = $layout->{$_->{name}} = { };
      
      $win->{x} = ($_->{x} + $_->{w} * 0.5) / $::WIDTH   if $_->{x} =~ /^[0-9.]+$/;
      $win->{y} = ($_->{y} + $_->{h} * 0.5) / $::HEIGHT  if $_->{y} =~ /^[0-9.]+$/;
      $win->{w} = $_->{w} / $::WIDTH                     if defined $_->{w};
      $win->{h} = $_->{h} / $::HEIGHT                    if defined $_->{h};

      $win->{show} = $_->{visible} && $_->{is_toplevel};
   }

   $layout
}

sub set_layout {
   my ($layout) = @_;

   $LAYOUT = $layout;
}

# class methods for events
sub feed_sdl_key_down_event { 
   $FOCUS->emit (key_down => $_[0])
      if $FOCUS;
}

sub feed_sdl_key_up_event {
   $FOCUS->emit (key_up => $_[0])
      if $FOCUS;
}

sub check_hover {
   my ($widget) = @_;

   if ($widget != $HOVER) {
      my $hover = $HOVER; $HOVER = $widget;

      $hover->update if $hover && $hover->{can_hover};
      $HOVER->update if $HOVER && $HOVER->{can_hover};

      $TOOLTIP_WATCHER->again;
   }
}

sub feed_sdl_button_down_event {
   my ($ev) = @_;
   my ($x, $y) = ($ev->{x}, $ev->{y});

   $BUTTON_STATE |= 1 << ($ev->{button} - 1);

   unless ($GRAB) {
      my $widget = $ROOT->find_widget ($x, $y);

      $GRAB = $widget;
      $GRAB->update if $GRAB;

      $TOOLTIP_WATCHER->invoke;
   }

   if ($GRAB) {
      if ($ev->{button} == 4 || $ev->{button} == 5) {
         # mousewheel
         my $delta = $ev->{button} * 2 - 9;
         my $shift = $ev->{mod} & DC::KMOD_SHIFT;

         $ev->{dx} = $shift ? $delta : 0;
         $ev->{dy} = $shift ? 0 : $delta;

         $GRAB->emit (mouse_wheel => $ev);
      } else {
         $GRAB->emit (button_down => $ev)
      }
   }
}

sub feed_sdl_button_up_event {
   my ($ev) = @_;

   my $widget = $GRAB || $ROOT->find_widget ($ev->{x}, $ev->{y});

   $BUTTON_STATE &= ~(1 << ($ev->{button} - 1));

   $GRAB->emit (button_up => $ev)
      if $GRAB && $ev->{button} != 4 && $ev->{button} != 5;

   unless ($BUTTON_STATE) {
      my $grab = $GRAB; undef $GRAB;
      $grab->update if $grab;
      $GRAB->update if $GRAB;

      check_hover $widget;
      $TOOLTIP_WATCHER->invoke;
   }
}

sub feed_sdl_motion_event {
   my ($ev) = @_;
   my ($x, $y) = ($ev->{x}, $ev->{y});

   my $widget = $GRAB || $ROOT->find_widget ($x, $y);

   check_hover $widget;

   $HOVER->emit (mouse_motion => $ev)
      if $HOVER;
}

# convert position array to integers
sub harmonize {
   my ($vals) = @_;

   my $rem = 0;

   for (@$vals) {
      my $i = int $_ + $rem;
      $rem += $_ - $i;
      $_ = $i;
   }
}

sub full_refresh {
   # make a copy, otherwise for complains about freed values.
   my @widgets = values %WIDGET;

   $_->update
      for @widgets;
}

sub reconfigure_widgets {
   # make a copy, otherwise C<for> complains about freed values.
   my @widgets = values %WIDGET;

   $_->reconfigure
      for @widgets;
}

# call when resolution changes etc.
sub rescale_widgets {
   my ($sx, $sy) = @_;

   for my $widget (values %WIDGET) {
      if ($widget->{is_toplevel} || $widget->{c_rescale}) {
         $widget->{x} += int $widget->{w} * 0.5 if $widget->{x} =~ /^[0-9.]+$/;
         $widget->{y} += int $widget->{h} * 0.5 if $widget->{y} =~ /^[0-9.]+$/;

         $widget->{x}       = int 0.5 + $widget->{x}        * $sx if $widget->{x} =~ /^[0-9.]+$/;
         $widget->{w}       = int 0.5 + $widget->{w}        * $sx if exists $widget->{w};
         $widget->{force_w} = int 0.5 + $widget->{force_w}  * $sx if exists $widget->{force_w};
         $widget->{y}       = int 0.5 + $widget->{y}        * $sy if $widget->{y} =~ /^[0-9.]+$/;
         $widget->{h}       = int 0.5 + $widget->{h}        * $sy if exists $widget->{h};
         $widget->{force_h} = int 0.5 + $widget->{force_h}  * $sy if exists $widget->{force_h};

         $widget->{x} -= int $widget->{w} * 0.5 if $widget->{x} =~ /^[0-9.]+$/;
         $widget->{y} -= int $widget->{h} * 0.5 if $widget->{y} =~ /^[0-9.]+$/;

      }
   }

   reconfigure_widgets;
}

#############################################################################

package DC::UI::Event;

sub xy {
   $_[1]->coord2local ($_[0]{x}, $_[0]{y})
}

#############################################################################

package DC::UI::Base;

use common::sense;

use DC::OpenGL;

sub new {
   my $class = shift;

   my $self = bless {
      x          => "center",
      y          => "center",
      z          => 0,
      w          => undef,
      h          => undef,
      can_events => 1,
      @_
   }, $class;

   DC::weaken ($DC::UI::WIDGET{$self+0} = $self);

   for (keys %$self) {
      if (/^on_(.*)$/) {
         $self->connect ($1 => delete $self->{$_});
      }
   }

   if (my $layout = $DC::UI::LAYOUT->{$self->{name}}) {
      $self->{x}       = $layout->{x} * $DC::UI::ROOT->{alloc_w} if exists $layout->{x};
      $self->{y}       = $layout->{y} * $DC::UI::ROOT->{alloc_h} if exists $layout->{y};
      $self->{force_w} = $layout->{w} * $DC::UI::ROOT->{alloc_w} if exists $layout->{w};
      $self->{force_h} = $layout->{h} * $DC::UI::ROOT->{alloc_h} if exists $layout->{h};

      $self->{x} -= $self->{force_w} * 0.5 if exists $layout->{x};
      $self->{y} -= $self->{force_h} * 0.5 if exists $layout->{y};

      $self->show if $layout->{show};
   }

   $self
}

sub destroy {
   my ($self) = @_;

   $self->hide;
   $self->emit ("destroy");
   %$self = ();
}

sub TO_JSON {
   { "\fw" => $_[0]{s_id} }
}

sub show {
   my ($self) = @_;

   return if $self->{parent};

   $DC::UI::ROOT->add ($self);
}

sub set_visible {
   my ($self) = @_;

   return if $self->{visible};

   $self->{parent} && $self->{parent}{root}#d#
      or return ::clienterror ("set_visible called without parent ($self->{parent}) or root\n" => 1);

   $self->{root}    = $self->{parent}{root};
   $self->{visible} = $self->{parent}{visible} + 1;

   $self->emit (visibility_change => 1);

   $self->realloc if !exists $self->{req_w};

   $_->set_visible for $self->visible_children;
}

sub set_invisible {
   my ($self) = @_;

   return unless $self->{visible};

   $_->set_invisible for $self->children;

   delete $self->{visible};
   delete $self->{root};

   undef $GRAB  if $GRAB  == $self;
   undef $HOVER if $HOVER == $self;

   $DC::UI::TOOLTIP_WATCHER->invoke
      if $TOOLTIP->{owner} == $self;

   $self->emit ("focus_out");
   $self->emit (visibility_change => 0);
}

sub set_visibility {
   my ($self, $visible) = @_;

   return if $self->{visible} == $visible;

   $visible ? $self->show
            : $self->hide;
}

sub toggle_visibility {
   my ($self) = @_;

   $self->{visible}
      ? $self->hide
      : $self->show;
}

sub hide {
   my ($self) = @_;

   $self->set_invisible;

   # extra $parent copy for 5.8.8+ bug workaround
   # (otherwise $_[0] in remove gets freed
   if (my $parent = $self->{parent}) {
      $parent->remove ($self);
   }
}

sub move_abs {
   my ($self, $x, $y, $z) = @_;

   $self->{x} = List::Util::max 0, List::Util::min $self->{root}{w} - $self->{w}, int $x;
   $self->{y} = List::Util::max 0, List::Util::min $self->{root}{h} - $self->{h}, int $y;
   $self->{z} = $z if defined $z;

   $self->update;
}

sub set_size {
   my ($self, $w, $h) = @_;

   $self->{force_w} = $w;
   $self->{force_h} = $h;

   $self->realloc;
}

# traverse the widget chain up to find the maximum "physical" size constraints
sub get_max_wh {
   my ($self) = @_;

   my ($w, $h) = @$self{qw(max_w max_h)};

   if ($w <= 0 || $h <= 0) {
      my ($mw, $mh) = $self->{parent}
         ? $self->{parent}->get_max_wh
         : ($::WIDTH, $::HEIGHT);

      $w = $mw if $w <= 0;
      $h = $mh if $h <= 0;
   }

   ($w, $h)
}

sub size_request {
   require Carp;
   Carp::confess "size_request is abstract";
}

sub baseline_shift {
   0
}

sub configure {
   my ($self, $x, $y, $w, $h) = @_;

   if ($self->{aspect}) {
      my ($ow, $oh) = ($w, $h);

      $w = List::Util::min $w, DC::ceil $h * $self->{aspect};
      $h = List::Util::min $h, DC::ceil $w / $self->{aspect};

      # use alignment to adjust x, y

      $x += int 0.5 * ($ow - $w);
      $y += int 0.5 * ($oh - $h);
   }

   if ($self->{x} ne $x || $self->{y} ne $y) {
      $self->{x} = $x;
      $self->{y} = $y;
      $self->update;
   }

   if ($self->{alloc_w} != $w || $self->{alloc_h} != $h) {
      return unless $self->{visible};

      $self->{alloc_w} = $w;
      $self->{alloc_h} = $h;

      $self->{root}{size_alloc}{$self+0} = $self;
   }
}

sub children {
   # nop
}

sub visible_children {
   $_[0]->children
}

sub set_max_size {
   my ($self, $w, $h) = @_;

   $self->{max_w} = int $w if defined $w;
   $self->{max_h} = int $h if defined $h;

   $self->realloc;
}

sub set_tooltip {
   my ($self, $tooltip) = @_;

   $tooltip =~ s/^\s+//;
   $tooltip =~ s/\s+$//;

   return if $self->{tooltip} eq $tooltip;

   $self->{tooltip} = $tooltip;

   if ($DC::UI::TOOLTIP->{owner} == $self) {
      delete $DC::UI::TOOLTIP->{owner};
      $DC::UI::TOOLTIP_WATCHER->invoke;
   }
}

# translate global coordinates to local coordinate system
sub coord2local {
   my ($self, $x, $y) = @_;

   return (undef, undef) unless $self->{parent};

   $self->{parent}->coord2local ($x  - $self->{x}, $y - $self->{y})
}

# translate local coordinates to global coordinate system
sub coord2global {
   my ($self, $x, $y) = @_;

   return (undef, undef) unless $self->{parent};

   $self->{parent}->coord2global ($x + $self->{x}, $y + $self->{y})
}

sub invoke_focus_in {
   my ($self) = @_;

   return if $FOCUS == $self;
   return unless $self->{can_focus};

   $FOCUS = $self;

   $self->update;

   0
}

sub invoke_focus_out {
   my ($self) = @_;

   return unless $FOCUS == $self;

   undef $FOCUS;

   $self->update;

   $::MAPWIDGET->grab_focus #d# focus mapwidget if no other widget has focus
      unless $FOCUS;

   0
}

sub grab_focus {
   my ($self) = @_;

   $FOCUS->emit ("focus_out") if $FOCUS;
   $self->emit ("focus_in");
}

sub invoke_mouse_motion { 0 }
sub invoke_button_up    { 0 }
sub invoke_key_down     { 0 }
sub invoke_key_up       { 0 }
sub invoke_mouse_wheel  { 0 }

sub invoke_button_down {
   my ($self, $ev, $x, $y) = @_;

   $self->grab_focus;

   0
}

sub connect {
   my ($self, $signal, $cb) = @_;

   push @{ $self->{signal_cb}{$signal} }, $cb;

   defined wantarray and Guard::guard {
      @{ $self->{signal_cb}{$signal} } = grep $_ != $cb,
         @{ $self->{signal_cb}{$signal} };
   }
}

sub disconnect_all {
   my ($self, $signal) = @_;

   delete $self->{signal_cb}{$signal};
}

my %has_coords = (
   button_down  => 1,
   button_up    => 1,
   mouse_motion => 1,
   mouse_wheel  => 1,
);

sub emit {
   my ($self, $signal, @args) = @_;

   # I do not really like this solution, but I do not like duplication
   # and needlessly verbose code, either.
   my @append
      = $has_coords{$signal}
        ? $args[0]->xy ($self)
        : ();

   #warn +(caller(1))[3] . "emit $signal on $self (parent $self->{parent})\n";#d#

   for my $cb (
      @{$self->{signal_cb}{$signal} || []},		# before
      ($self->can ("invoke_$signal") || sub { 1 }),	# closure
   ) {
      return $cb->($self, @args, @append) || next;
   }

   # parent
   $self->{parent} && $self->{parent}->emit ($signal, @args)
}

#sub find_widget {
# in .xs

sub set_parent {
   my ($self, $parent) = @_;

   DC::weaken ($self->{parent} = $parent);
   $self->set_visible if $parent->{visible};
}

sub realloc {
   my ($self) = @_;

   if ($self->{visible}) {
      return if $self->{root}{realloc}{$self+0};

      $self->{root}{realloc}{$self+0} = $self;
      $self->{root}->update;
   } else {
      delete $self->{req_w};
      delete $self->{req_h};
   }
}

sub update {
   my ($self) = @_;

   $self->{parent}->update
      if $self->{parent};
}

sub reconfigure {
   my ($self) = @_;

   $self->realloc;
   $self->update;
}

# using global variables seems a bit hacky, but passing through all drawing
# functions seems pointless.
our ($draw_x, $draw_y, $draw_w, $draw_h); # screen rectangle being drawn

#sub draw {
#CFPlus.xs

sub _draw {
   my ($self) = @_;

   warn "no draw defined for $self\n";
}

sub DESTROY {
   my ($self) = @_;

   return if DC::in_destruct;

   local $@;
   eval { $self->destroy };
   warn "exception during widget destruction: $@" if $@ & $@ != /during global destruction/;

   delete $WIDGET{$self+0};
}

#############################################################################

package DC::UI::DrawBG;

our @ISA = DC::UI::Base::;

use common::sense;

use DC::OpenGL;

sub new {
   my $class = shift;

   $class->SUPER::new (
      #bg        => [0, 0, 0, 0.2],
      #active_bg => [1, 1, 1, 0.5],
      @_
   )
}

sub set_bg {
   my ($self, $bg) = @_;

   $self->{bg} = $bg;
   $self->update;
}

sub _draw {
   my ($self) = @_;

   my $color = $FOCUS == $self
             ? $self->{active_bg} || $self->{bg}
             : $self->{bg};

   if ($color && (@$color < 4 || $color->[3])) {
      my ($w, $h) = @$self{qw(w h)};

      glEnable GL_BLEND;
      glBlendFunc GL_ONE, GL_ONE_MINUS_SRC_ALPHA;
      glColor_premultiply @$color;
      glRect 0, 0, $w, $h;
      glDisable GL_BLEND;
   }
}

#############################################################################

package DC::UI::Empty;

our @ISA = DC::UI::Base::;

sub new {
   my ($class, %arg) = @_;
   $class->SUPER::new (can_events => 0, %arg);
}

sub size_request {
   my ($self) = @_;

   ($self->{w} + 0, $self->{h} + 0)
}

sub draw { }

#############################################################################

package DC::UI::Container;

our @ISA = DC::UI::Base::;

sub new {
   my ($class, %arg) = @_;

   my $children = delete $arg{children};

   my $self = $class->SUPER::new (
      children   => [],
      can_events => 0,
      %arg,
   );

   $self->add (@$children)
      if $children && @$children;

   $self
}

sub realloc {
   my ($self) = @_;

   $self->{force_realloc} = 1;
   $self->{force_size_alloc} = 1;
   $self->SUPER::realloc;
}

sub add {
   my ($self, @widgets) = @_;

   $_->set_parent ($self)
      for @widgets;

   # TODO: only do this in widgets that need it, e.g. root, fixed
   use sort 'stable';

   $self->{children} = [
      sort { $a->{z} <=> $b->{z} }
         @{$self->{children}}, @widgets
   ];

   $self->realloc;

   $self->emit (c_add => \@widgets);

   map $_+0, @widgets
}

sub children {
   @{ $_[0]{children} }
}

sub remove {
   my ($self, @widgets) = @_;

   $self->emit (c_remove => \@widgets);

   for my $child (@widgets) {
      delete $child->{parent};
      $child->hide;
      $self->{children} = [ grep $_ != $child, @{ $self->{children} } ];
   }

   $self->realloc;
}

sub clear {
   my ($self) = @_;

   my $children = $self->{children};
   $self->{children} = [];

   for (@$children) {
      delete $_->{parent};
      $_->hide;
   }

   $self->realloc;
}

sub find_widget {
   my ($self, $x, $y) = @_;

   $x -= $self->{x};
   $y -= $self->{y};

   my $res;

   for (reverse $self->visible_children) {
      $res = $_->find_widget ($x, $y)
         and return $res;
   }

   $self->SUPER::find_widget ($x + $self->{x}, $y + $self->{y})
}

sub _draw {
   my ($self) = @_;

   $_->draw for $self->visible_children;
}

#############################################################################

package DC::UI::Bin;

our @ISA = DC::UI::Container::;

sub new {
   my ($class, %arg) = @_;

   my $child = (delete $arg{child}) || new DC::UI::Empty::;

   $class->SUPER::new (children => [$child], %arg)
}

sub add {
   my ($self, $child) = @_;

   $self->clear;
   $self->SUPER::add ($child);
}

sub remove {
   my ($self, $widget) = @_;

   $self->SUPER::remove ($widget);

   $self->{children} = [new DC::UI::Empty]
      unless @{$self->{children}};
}

sub child { $_[0]->{children}[0] }

sub size_request {
   $_[0]{children}[0]->size_request
}

sub invoke_size_allocate {
   my ($self, $w, $h) = @_;

   $self->{children}[0]->configure (0, 0, $w, $h);

   1
}

#############################################################################
# back-buffered drawing area

package DC::UI::Window;

our @ISA = DC::UI::Bin::;

use DC::OpenGL;

sub new {
   my ($class, %arg) = @_;

   my $self = $class->SUPER::new (%arg);
}

sub update {
   my ($self) = @_;

   $ROOT->on_post_alloc ($self => sub { $self->render_child });
   $self->SUPER::update;
}

sub invoke_size_allocate {
   my ($self, $w, $h) = @_;

   $self->update;

   $self->SUPER::invoke_size_allocate ($w, $h)
}

sub _render {
   my ($self) = @_;

   $self->{children}[0]->draw;
}

sub render_child {
   my ($self) = @_;

   $self->{texture} = new_from_opengl DC::Texture $self->{w}, $self->{h}, sub {
      glClearColor 0, 0, 0, 0;
      glClear GL_COLOR_BUFFER_BIT;

      {
         package DC::UI::Base;

         local ($draw_x, $draw_y, $draw_w, $draw_h) =
            (0, 0, $self->{w}, $self->{h});

         $self->_render;
      }
   };
}

sub _draw {
   my ($self) = @_;

   my $tex = $self->{texture}
      or return;

   glEnable GL_TEXTURE_2D;
   glTexEnv GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_REPLACE;
   glColor 0, 0, 0, 1;

   $tex->draw_quad_alpha_premultiplied (0, 0);

   glDisable GL_TEXTURE_2D;
}

#############################################################################

package DC::UI::ViewPort;

use List::Util qw(min max);

our @ISA = DC::UI::Window::;

sub new {
   my $class = shift;

   $class->SUPER::new (
      scroll_x => 0,
      scroll_y => 1,
      @_,
   )
}

sub size_request {
   my ($self) = @_;

   my ($w, $h) = @{$self->child}{qw(req_w req_h)};

   $w = 1 if $self->{scroll_x};
   $h = 1 if $self->{scroll_y};

   ($w, $h)
}

sub invoke_size_allocate {
   my ($self, $w, $h) = @_;

   my $child = $self->child;

   $w = $child->{req_w} if $self->{scroll_x} && $child->{req_w};
   $h = $child->{req_h} if $self->{scroll_y} && $child->{req_h};

   $self->child->configure (0, 0, $w, $h);
   $self->update;

   1
}

sub set_offset {
   my ($self, $x, $y) = @_;

   my $x = max 0, min $self->child->{w} - $self->{w}, int $x;
   my $y = max 0, min $self->child->{h} - $self->{h}, int $y;

   if ($x != $self->{view_x} or $y != $self->{view_y}) {
      $self->{view_x} = $x;
      $self->{view_y} = $y;

      $self->emit (changed => $x, $y);
      $self->update;
   }
}

sub set_center {
   my ($self, $x, $y) = @_;

   $self->set_offset ($x - $self->{w} * .5, $y - $self->{h} * .5);
}

sub make_visible {
   my ($self, $x, $y, $border) = @_;

   if (  $x < $self->{view_x} + $self->{w} * $border
      || $x > $self->{view_x} + $self->{w} * (1 - $border)
      || $y < $self->{view_y} + $self->{h} * $border
      || $y > $self->{view_y} + $self->{h} * (1 - $border)
   ) {
      $self->set_center ($x, $y);
   }
}

# hmm, this does not work for topleft of $self... but we should not ask for that
sub coord2local {
   my ($self, $x, $y) = @_;

   $self->SUPER::coord2local ($x + $self->{view_x}, $y + $self->{view_y})
}

sub coord2global {
   my ($self, $x, $y) = @_;

   $x = List::Util::min $self->{w}, $x - $self->{view_x};
   $y = List::Util::min $self->{h}, $y - $self->{view_y};

   $self->SUPER::coord2global ($x, $y)
}

sub find_widget {
   my ($self, $x, $y) = @_;

   if (   $x >= $self->{x} && $x < $self->{x} + $self->{w}
       && $y >= $self->{y} && $y < $self->{y} + $self->{h}
   ) {
      $self->child->find_widget ($x + $self->{view_x}, $y + $self->{view_y})
   } else {
      $self->DC::UI::Base::find_widget ($x, $y)
   }
}

sub _render {
   my ($self) = @_;

   local $DC::UI::Base::draw_x = $DC::UI::Base::draw_x - $self->{view_x};
   local $DC::UI::Base::draw_y = $DC::UI::Base::draw_y - $self->{view_y};

   DC::OpenGL::glTranslate -$self->{view_x}, -$self->{view_y};

   $self->SUPER::_render;
}

#############################################################################

package DC::UI::ScrolledWindow;

our @ISA = DC::UI::Table::;

sub new {
   my ($class, %arg) = @_;

   my $child = delete $arg{child};

   my $self;

   my $hslider = new DC::UI::Slider
      c_col      => 0,
      c_row      => 1,
      vertical   => 0,
      range      => [0, 0, 1, 0.01], # HACK fix
      on_changed => sub {
         $self->{hpos} = $_[1];
         $self->{vp}->set_offset ($self->{hpos}, $self->{vpos});
      },
   ;

   my $vslider = new DC::UI::Slider
      c_col      => 1,
      c_row      => 0,
      vertical   => 1,
      range      => [0, 0, 1, 0.01], # HACK fix
      on_changed => sub {
         $self->{vpos} = $_[1];
         $self->{vp}->set_offset ($self->{hpos}, $self->{vpos});
      },
   ;

   $self = $class->SUPER::new (
      scroll_x   => 0,
      scroll_y   => 1,
      can_events => 1,
      hslider    => $hslider,
      vslider    => $vslider,
      col_expand => [1, 0],
      row_expand => [1, 0],
      %arg,
   );

   $self->{vp} = new DC::UI::ViewPort
      c_col      => 0,
      c_row      => 0,
      expand     => 1,
      scroll_x   => $self->{scroll_x},
      scroll_y   => $self->{scroll_y},
      on_changed => sub {
         my ($vp, $x, $y) = @_;

         $vp->{parent}{hslider}->set_value ($x);
         $vp->{parent}{vslider}->set_value ($y);

         0
      },
      on_size_allocate => sub {
         my ($vp, $w, $h) = @_;
         $vp->{parent}->update_slider;
         0
      },
   ;

   $self->SUPER::add ($self->{vp});

   $self->add ($child) if $child;

   $self
}

sub add {
   my ($self, $widget) = @_;

   $self->{vp}->add ($self->{child} = $widget);
}

sub set_offset   { shift->{vp}->set_offset   (@_) }
sub set_center   { shift->{vp}->set_center   (@_) }
sub make_visible { shift->{vp}->make_visible (@_) }

sub update_slider {
   my ($self) = @_;

   my $child = ($self->{vp} or return)->child;

   if ($self->{scroll_x}) {
      my ($w1, $w2) = ($child->{req_w}, $self->{vp}{w});
      $self->{hslider}->set_range ([$self->{hslider}{range}[0], 0, $w1, $w2, 1]);

      my $visible = $w1 > $w2;
      if ($visible != $self->{hslider_visible}) {
         $self->{hslider_visible} = $visible;
         $visible ? $self->SUPER::add ($self->{hslider})
                  : $self->SUPER::remove ($self->{hslider});
      }
   }

   if ($self->{scroll_y}) {
      my ($h1, $h2) = ($child->{req_h}, $self->{vp}{h});
      $self->{vslider}->set_range ([$self->{vslider}{range}[0], 0, $h1, $h2, 1]);

      my $visible = $h1 > $h2;
      if ($visible != $self->{vslider_visible}) {
         $self->{vslider_visible} = $visible;
         $visible ? $self->SUPER::add ($self->{vslider})
                  : $self->SUPER::remove ($self->{vslider});
      }
   }
}

sub start_dragging {
   my ($self, $ev) = @_;

   $self->grab_focus;

   my $ox = $self->{vp}{view_x};
   my $oy = $self->{vp}{view_y};
   
   $self->{motion} = sub {
      my ($ev, $x, $y) = @_;

      $ox -= $ev->{xrel};
      $oy -= $ev->{yrel};

      $self->{vp}->set_offset ($ox, $oy);
   };
}

sub invoke_mouse_wheel {
   my ($self, $ev) = @_;

   $self->{vslider}->emit (mouse_wheel => $ev) if $self->{vslider_visible};
   $self->{hslider}->emit (mouse_wheel => $ev) if $self->{hslider_visible};

   1
}

sub invoke_button_down {
   my ($self, $ev, $x, $y) = @_;

   if ($ev->{button} == 2) {
      $self->start_dragging ($ev);
      return 1;
   }

   0
}

sub invoke_button_up {
   my ($self, $ev, $x, $y) = @_;

   if (delete $self->{motion}) {
      return 1;
   }

   0
}

sub invoke_mouse_motion {
   my ($self, $ev, $x, $y) = @_;

   if ($self->{motion}) {
      $self->{motion}->($ev, $x, $y);
      return 1;
   }

   0
}

sub invoke_size_allocate {
   my ($self, $w, $h) = @_;

   $self->update_slider;
   $self->SUPER::invoke_size_allocate ($w, $h)
}

#############################################################################

package DC::UI::Frame;

our @ISA = DC::UI::Bin::;

use DC::OpenGL;

sub new {
   my $class = shift;

   $class->SUPER::new (
      bg => undef,
      @_,
   )
}

sub _draw {
   my ($self) = @_;

   if ($self->{bg}) {
      my ($w, $h) = @$self{qw(w h)};

      glEnable GL_BLEND;
      glBlendFunc GL_ONE, GL_ONE_MINUS_SRC_ALPHA;
      glColor_premultiply @{ $self->{bg} };
      glRect 0, 0, $w, $h;
      glDisable GL_BLEND;
   }

   $self->SUPER::_draw;
}

#############################################################################

package DC::UI::FancyFrame;

our @ISA = DC::UI::Bin::;

use DC::OpenGL;

sub new {
   my ($class, %arg) = @_;

   if ((exists $arg{label}) && !ref $arg{label}) {
      $arg{label} = new DC::UI::Label
         align    => 1,
         valign   => 0.5,
         text     => $arg{label},
         fontsize => ($arg{border} || 0.8) * 0.75;
   }

   my $self = $class->SUPER::new (
      # label     => "",
      fg          => undef,
      border      => 0.8,
      style       => 'single',
      %arg,
   );

   $self
}

sub add {
   my ($self, @widgets) = @_;

   $self->SUPER::add (@widgets);
   $self->DC::UI::Container::add ($self->{label}) if $self->{label};
}

sub border {
   int $_[0]{border} * $::FONTSIZE
}

sub size_request {
   my ($self) = @_;

   ($self->{label_w}, undef) = $self->{label}->size_request
      if $self->{label};

   my ($w, $h) = $self->SUPER::size_request;

   (
      $w + $self->border * 2,
      $h + $self->border * 2,
   )
}

sub invoke_size_allocate {
   my ($self, $w, $h) = @_;

   my $border = $self->border;

   $w -= List::Util::max 0, $border * 2;
   $h -= List::Util::max 0, $border * 2;

   if (my $label = $self->{label}) {
      $label->{w} = List::Util::max 0, List::Util::min $self->{label_w}, $w - $border * 2;
      $label->{h} = List::Util::min $h, $border;
      $label->invoke_size_allocate ($label->{w}, $label->{h});
   }

   $self->child->configure ($border, $border, $w, $h);

   1
}

sub _draw {
   my ($self) = @_;

   my $child = $self->{children}[0];

   my $border = $self->border;
   my ($w, $h) = ($self->{w}, $self->{h});

   $child->draw;

   glColor @{$self->{fg} || $DC::THEME{fancyframe}};
   glBegin GL_LINE_STRIP;
   glVertex $border * 1.5      , $border * 0.5 + 0.5;
   glVertex $border * 0.5 + 0.5, $border * 0.5 + 0.5;
   glVertex $border * 0.5 + 0.5, $h - $border * 0.5 + 0.5;
   glVertex $w - $border * 0.5 + 0.5, $h - $border * 0.5 + 0.5;
   glVertex $w - $border * 0.5 + 0.5, $border * 0.5 + 0.5;
   glVertex $self->{label} ? $border * 2 + $self->{label}{w} : $border * 1.5, $border * 0.5 + 0.5;
   glEnd;

   if ($self->{label}) {
      glTranslate $border * 2, 0;
      $self->{label}->_draw;
   }
}

#############################################################################

package DC::UI::Toplevel;

our @ISA = DC::UI::Bin::;

use DC::OpenGL;

my $bg = 
      new_from_resource DC::Texture "d1_bg.png",
         mipmap => 1, wrap => 1;

my @border = 
      map { new_from_resource DC::Texture $_, mipmap => 1 }
         qw(d1_border_top.png d1_border_right.png d1_border_left.png d1_border_bottom.png);

my @icon =
      map { new_from_resource DC::Texture $_, mipmap => 1 }
         qw(x1_move.png x1_resize.png);

sub new {
   my ($class, %arg) = @_;

   my $self = $class->SUPER::new (
      bg          => [1, 1, 1, 1],
      border_bg   => [1, 1, 1, 1],
      border      => 0.8,
      can_events  => 1,
      min_w       => 64,
      min_h       => 32,
      %arg,
   );

   $self->{title_widget} = new DC::UI::Label
      align    => 0.5,
      valign   => 1,
      text     => $self->{title},
      fontsize => $self->{border},
         if exists $self->{title};

   if ($self->{has_close_button}) {
      $self->{close_button} =
         new DC::UI::ImageButton
            path        => 'x1_close.png',
            on_activate => sub { $self->emit ("delete") };

      $self->DC::UI::Container::add ($self->{close_button});
   }

   $self
}

sub add {
   my ($self, @widgets) = @_;

   $self->SUPER::add (@widgets);
   $self->DC::UI::Container::add ($self->{close_button}) if $self->{close_button};
   $self->DC::UI::Container::add ($self->{title_widget}) if $self->{title_widget};
}

sub border {
   int $_[0]{border} * $::FONTSIZE
}

sub get_max_wh {
   my ($self) = @_;

   return ($self->{w}, $self->{h})
      if $self->{visible} && $self->{w};

   $self->SUPER::get_max_wh
}

sub size_request {
   my ($self) = @_;

   $self->{title_widget}->size_request
      if $self->{title_widget};

   $self->{close_button}->size_request
      if $self->{close_button};

   my ($w, $h) = $self->SUPER::size_request;

   (
      $w + $self->border * 2,
      $h + $self->border * 2,
   )
}

sub invoke_size_allocate {
   my ($self, $w, $h) = @_;

   if ($self->{title_widget}) {
      $self->{title_widget}{w} = $w;
      $self->{title_widget}{h} = $h;
      $self->{title_widget}->invoke_size_allocate ($w, $h);
   }

   my $border = $self->border;

   $h -= List::Util::max 0, $border * 2;
   $w -= List::Util::max 0, $border * 2;

   $self->child->configure ($border, $border, $w, $h);

   $self->{close_button}->configure ($self->{w} - $border, 0, $border, $border)
      if $self->{close_button};

   1
}

sub invoke_delete {
   my ($self) = @_;

   $self->hide;
   
   1
}

sub invoke_button_down {
   my ($self, $ev, $x, $y) = @_;

   my ($w, $h) = @$self{qw(w h)};
   my $border = $self->border;

   my $lr = ($x >= 0 && $x < $border) || ($x > $w - $border && $x < $w);
   my $td = ($y >= 0 && $y < $border) || ($y > $h - $border && $y < $h);

   if ($lr & $td) {
      my ($wx, $wy) = ($self->{x}, $self->{y});
      my ($ox, $oy) = ($ev->{x}, $ev->{y});
      my ($bw, $bh) = ($self->{w}, $self->{h});

      my $mx = $x < $border;
      my $my = $y < $border;

      $self->{motion} = sub {
         my ($ev, $x, $y) = @_;

         my $dx = $ev->{x} - $ox;
         my $dy = $ev->{y} - $oy;

         $self->{force_w} = $bw + $dx * ($mx ? -1 : 1);
         $self->{force_h} = $bh + $dy * ($my ? -1 : 1);

         $self->move_abs ($wx + $dx * $mx, $wy + $dy * $my);
         $self->realloc;
      };

   } elsif ($lr ^ $td) {
      my ($ox, $oy) = ($ev->{x}, $ev->{y});
      my ($bx, $by) = ($self->{x}, $self->{y});

      $self->{motion} = sub {
         my ($ev, $x, $y) = @_;

         ($x, $y) = ($ev->{x}, $ev->{y});

         $self->move_abs ($bx + $x - $ox, $by + $y - $oy);
         # HACK: the next line is required to enforce placement
         $self->{parent}->invoke_size_allocate ($self->{parent}{w}, $self->{parent}{h});
      };
   } else {
      return 0;
   }

   1
}

sub invoke_button_up {
   my ($self, $ev, $x, $y) = @_;

   ! ! delete $self->{motion}
}

sub invoke_mouse_motion {
   my ($self, $ev, $x, $y) = @_;

   $self->{motion}->($ev, $x, $y) if $self->{motion};

   ! ! $self->{motion}
}

sub invoke_visibility_change {
   my ($self, $visible) = @_;

   delete $self->{motion} unless $visible;

   0
}

sub _draw {
   my ($self) = @_;

   my $child = $self->{children}[0];

   my ($w,  $h ) = ($self->{w}, $self->{h});
   my ($cw, $ch) = ($child->{w}, $child->{h});

   glEnable GL_TEXTURE_2D;
   glTexEnv GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE;

   my $border = $self->border;

   if ($border) {
      glColor @{ $self->{border_bg} };
      $border[0]->draw_quad_alpha (           0,            0, $w, $border);
      $border[1]->draw_quad_alpha (           0,      $border, $border, $ch);
      $border[2]->draw_quad_alpha ($w - $border,      $border, $border, $ch);
      $border[3]->draw_quad_alpha (           0, $h - $border, $w, $border);

      # move
      my $w2 = ($w - $border) * .5;
      my $h2 = ($h - $border) * .5;
      $icon[0]->draw_quad_alpha (           0,          $h2, $border, $border);
      $icon[0]->draw_quad_alpha ($w - $border,          $h2, $border, $border);
      $icon[0]->draw_quad_alpha ($w2         , $h - $border, $border, $border);

      # resize
      $icon[1]->draw_quad_alpha (           0,            0, $border, $border);
      $icon[1]->draw_quad_alpha ($w - $border,            0, $border, $border)
         unless $self->{has_close_button};
      $icon[1]->draw_quad_alpha (           0, $h - $border, $border, $border);
      $icon[1]->draw_quad_alpha ($w - $border, $h - $border, $border, $border);
   }

   if (@{$self->{bg}} < 4 || $self->{bg}[3]) {
      glColor @{ $self->{bg} };

      # TODO: repeat texture not scale
      # solve this better(?)
      $bg->{s} = $cw / $bg->{w};
      $bg->{t} = $ch / $bg->{h};
      $bg->draw_quad_alpha ($border, $border, $cw, $ch);
   }

   glDisable GL_TEXTURE_2D;

   $child->draw;

   if ($self->{title_widget}) {
      glTranslate 0, $border - $self->{h};
      $self->{title_widget}->_draw;

      glTranslate 0, - ($border - $self->{h});
   }

   $self->{close_button}->draw
      if $self->{close_button};
}

#############################################################################

package DC::UI::Table;

our @ISA = DC::UI::Container::;

use List::Util qw(max sum);

use DC::OpenGL;

sub new {
   my $class = shift;

   $class->SUPER::new (
      col_expand => [],
      row_expand => [],
      @_,
   )
}

sub add {
   my ($self, @widgets) = @_;

   for my $child (@widgets) {
      $child->{c_rowspan} ||= 1;
      $child->{c_colspan} ||= 1;
   }

   $self->SUPER::add (@widgets);
}

sub add_at {
   my $self = shift;

   my @widgets;

   while (@_) {
      my ($col, $row, $child) = splice @_, 0, 3, ();

      $child->{c_row} = $row;
      $child->{c_col} = $col;

      push @widgets, $child;
   }

   $self->add (@widgets);
}

sub get_wh {
   my ($self) = @_;

   my (@w, @h);

   my @children = $self->children;

   # first pass, columns
   for my $widget (sort { $a->{c_colspan} <=> $b->{c_colspan} } @children) {
      my ($c, $w, $cs) = @$widget{qw(c_col req_w c_colspan)};

      my $sw = sum @w[$c .. $c + $cs - 1];

      if ($w > $sw) {
         $_ += ($w - $sw) / ($_ ? $sw / $_ : $cs) for @w[$c .. $c + $cs - 1];
      }
   }

   # second pass, rows
   for my $widget (sort { $a->{c_rowspan} <=> $b->{c_rowspan} } @children) {
      my ($r, $h, $rs) = @$widget{qw(c_row req_h c_rowspan)};

      my $sh = sum @h[$r .. $r + $rs - 1];

      if ($h > $sh) {
         $_ += ($h - $sh) / ($_ ? $sh / $_ : $rs) for @h[$r .. $r + $rs - 1];
      }
   }

   (\@w, \@h)
}

sub size_request {
   my ($self) = @_;

   my ($ws, $hs) = $self->get_wh;

   (
      (sum @$ws),
      (sum @$hs),
   )
}

sub invoke_size_allocate {
   my ($self, $w, $h) = @_;

   my ($ws, $hs) = $self->get_wh;

   my $req_w = (sum @$ws) || 1;
   my $req_h = (sum @$hs) || 1;

   # now linearly scale the rows/columns to the allocated size
   my @col_expand = @{$self->{col_expand}};
   @col_expand = (1) x @$ws unless @col_expand;
   my $col_expand = (sum @col_expand) || 1;

   $ws->[$_] += $col_expand[$_] / $col_expand * ($w - $req_w) for 0 .. $#$ws;

   DC::UI::harmonize $ws;

   my @row_expand = @{$self->{row_expand}};
   @row_expand = (1) x @$ws unless @row_expand;
   my $row_expand = (sum @row_expand) || 1;

   $hs->[$_] += $row_expand[$_] / $row_expand * ($h - $req_h) for 0 .. $#$hs;

   DC::UI::harmonize $hs;

   my @x; for (0 .. $#$ws) { $x[$_ + 1] = $x[$_] + $ws->[$_] }
   my @y; for (0 .. $#$hs) { $y[$_ + 1] = $y[$_] + $hs->[$_] }

   for my $widget ($self->children) {
      my ($r, $c, $w, $h, $rs, $cs) = @$widget{qw(c_row c_col req_w req_h c_rowspan c_colspan)};

      $widget->configure (
         $x[$c], $y[$r],
         $x[$c + $cs] - $x[$c], $y[$r + $rs] - $y[$r],
      );
   }

   1
}

#############################################################################

package DC::UI::Fixed;

use List::Util qw(min max);

our @ISA = DC::UI::Container::;

sub _scale($$$) {
   my ($rel, $val, $max) = @_;

   $rel ? $val * $max : $val
}

sub size_request {
   my ($self) = @_;

   my ($x1, $y1, $x2, $y2) = (0, 0, 0, 0);

   # determine overall size by querying abs widgets
   for my $child ($self->visible_children) {
      unless ($child->{c_rel}) {
         my $x = $child->{c_x};
         my $y = $child->{c_y};

         $x1 = min $x1, $x; $x2 = max $x2, $x + $child->{req_w};
         $y1 = min $y1, $y; $y2 = max $y2, $y + $child->{req_h};
      }
   }

   my $W = $x2 - $x1;
   my $H = $y2 - $y1;

   # now layout remaining widgets
   for my $child ($self->visible_children) {
      if ($child->{c_rel}) {
         my $x = _scale $child->{c_rel}, $child->{c_x}, $W;
         my $y = _scale $child->{c_rel}, $child->{c_y}, $H;

         $x1 = min $x1, $x; $x2 = max $x2, $x + $child->{req_w};
         $y1 = min $y1, $y; $y2 = max $y2, $y + $child->{req_h};
      }
   }

   my $W = $x2 - $x1;
   my $H = $y2 - $y1;

   ($W, $H)
}

sub invoke_size_allocate {
   my ($self, $W, $H) = @_;

   for my $child ($self->visible_children) {
      my $x = _scale $child->{c_rel}, $child->{c_x}, $W;
      my $y = _scale $child->{c_rel}, $child->{c_y}, $H;

      $x += $child->{c_halign} * $child->{req_w};
      $y += $child->{c_valign} * $child->{req_h};

      $child->configure (int $x, int $y, $child->{req_w}, $child->{req_h});
   }

   1
}

#############################################################################

package DC::UI::Box;

our @ISA = DC::UI::Container::;

sub size_request {
   my ($self) = @_;

   my @children = $self->visible_children;

   $self->{vertical}
      ?  (
            (List::Util::max map $_->{req_w}, @children),
            (List::Util::sum map $_->{req_h}, @children),
         )
      :  (
            (List::Util::sum map $_->{req_w}, @children),
            (List::Util::max map $_->{req_h}, @children),
         )
}

sub invoke_size_allocate {
   my ($self, $w, $h) = @_;

   my $space = $self->{vertical} ? $h : $w;
   my @children = $self->visible_children;

   my @req;

   if ($self->{homogeneous}) {
      @req = ($space / (@children || 1)) x @children;
   } else {
      @req = map $_->{$self->{vertical} ? "req_h" : "req_w"}, @children;
      my $req = List::Util::sum @req;

      if ($req > $space) {
         # ah well, not enough space
         $_ *= $space / $req for @req;
      } else {
         my $expand = (List::Util::sum map $_->{expand}, @children) || 1;
         
         $space = ($space - $req) / $expand; # remaining space to give away

         $req[$_] += $space * $children[$_]{expand}
            for 0 .. $#children;
      }
   }

   DC::UI::harmonize \@req;

   my $pos = 0;
   for (0 .. $#children) {
      my $alloc = $req[$_];
      $children[$_]->configure ($self->{vertical} ? (0, $pos, $w, $alloc) : ($pos, 0, $alloc, $h));

      $pos += $alloc;
   }

   1
}

#############################################################################

package DC::UI::HBox;

our @ISA = DC::UI::Box::;

sub new {
   my $class = shift;

   $class->SUPER::new (
      vertical => 0,
      @_,
   )
}

#############################################################################

package DC::UI::VBox;

our @ISA = DC::UI::Box::;

sub new {
   my $class = shift;

   $class->SUPER::new (
      vertical => 1,
      @_,
   )
}

#############################################################################

package DC::UI::Label;

our @ISA = DC::UI::DrawBG::;

use DC::OpenGL;

sub new {
   my ($class, %arg) = @_;

   my $self = $class->SUPER::new (
      fg         => [1, 1, 1],
      #bg        => none
      #active_bg => none
      #font      => default_font
      #text      => initial text
      #markup    => initial narkup
      #max_w     => maximum pixel width
      #style     => 0, # render flags
      ellipsise  => 3, # end
      layout     => (new DC::Layout),
      fontsize   => 1,
      align      => 0.5,
      valign     => 0.5,
      padding_x  => 4,
      padding_y  => 2,
      can_events => 0,
      %arg
   );

   if (exists $self->{template}) {
      my $layout = new DC::Layout;
      $layout->set_text (delete $self->{template});
      $self->{template} = $layout;
   }

   if (exists $self->{markup}) {
      $self->set_markup (delete $self->{markup});
   } else {
      $self->set_text (delete $self->{text});
   }

   $self
}

sub update {
   my ($self) = @_;

   delete $self->{texture};
   $self->SUPER::update;
}

sub realloc {
   my ($self) = @_;

   delete $self->{ox};
   $self->SUPER::realloc;
}

sub clear {
   my ($self) = @_;

   $self->set_text ("");
}

sub set_text {
   my ($self, $text) = @_;

   return if $self->{text} eq "T$text";
   $self->{text} = "T$text";

   $self->{layout}->set_text ($text);

   delete $self->{size_req};
   $self->realloc;
   $self->update;
}

sub set_markup {
   my ($self, $markup) = @_;

   return if $self->{text} eq "M$markup";
   $self->{text} = "M$markup";

   my $rgba = $markup =~ /span.*(?:foreground|background)/;

   $self->{layout}->set_markup ($markup);

   delete $self->{size_req};
   $self->realloc;
   $self->update;
}

sub size_request {
   my ($self) = @_;

   $self->{size_req} ||= do {
      my ($max_w, $max_h) = $self->get_max_wh;

      $self->{layout}->set_font ($self->{font}) if $self->{font};
      $self->{layout}->set_width ($max_w);
      $self->{layout}->set_ellipsise ($self->{ellipsise});
      $self->{layout}->set_single_paragraph_mode ($self->{ellipsise});
      $self->{layout}->set_height ($self->{fontsize} * $::FONTSIZE);

      my ($w, $h) = $self->{layout}->size;

      if (exists $self->{template}) {
         $self->{template}->set_font ($self->{font}) if $self->{font};
         $self->{template}->set_width ($max_w);
         $self->{template}->set_height ($self->{fontsize} * $::FONTSIZE);

         my ($w2, $h2) = $self->{template}->size;

         $w = List::Util::max $w, $w2;
         $h = List::Util::max $h, $h2;
      }

      [$w, $h]
   };

   @{ $self->{size_req} }
}

sub baseline_shift {
   $_[0]{layout}->descent
}

sub invoke_size_allocate {
   my ($self, $w, $h) = @_;

   delete $self->{ox};

   delete $self->{texture}
      unless $w >= $self->{req_w} && $self->{old_w} >= $self->{req_w};

   1
}

sub set_fontsize {
   my ($self, $fontsize) = @_;

   $self->{fontsize} = $fontsize;
   delete $self->{size_req};
   delete $self->{texture};

   $self->realloc;
}

sub reconfigure {
   my ($self) = @_;

   delete $self->{size_req};
   delete $self->{texture};

   $self->SUPER::reconfigure;
}

sub _draw {
   my ($self) = @_;

   $self->SUPER::_draw; # draw background, if applicable

   my $size = $self->{texture} ||= do {
      $self->{layout}->set_foreground (@{$self->{fg}});
      $self->{layout}->set_font ($self->{font}) if $self->{font};
      $self->{layout}->set_width ($self->{w});
      $self->{layout}->set_ellipsise ($self->{ellipsise});
      $self->{layout}->set_single_paragraph_mode ($self->{ellipsise});
      $self->{layout}->set_height ($self->{fontsize} * $::FONTSIZE);

      [$self->{layout}->size]
   };

   unless (exists $self->{ox}) {
      $self->{ox} = $self->{padding_x} + int $self->{align}  * ($self->{w} - $size->[0] - $self->{padding_x} * 2);
      $self->{oy} = $self->{padding_y} + int $self->{valign} * ($self->{h} - $size->[1] - $self->{padding_y} * 2);

      $self->{layout}->render ($self->{ox}, $self->{oy}, $self->{style});
   };

#   unless ($self->{list}) {
#      $self->{list} = DC::OpenGL::glGenList;
#      DC::OpenGL::glNewList $self->{list};
#      $self->{layout}->render ($self->{ox}, $self->{oy}, $self->{style});
#      DC::OpenGL::glEndList;
#   }
#   
#   DC::OpenGL::glCallList $self->{list};

   $self->{layout}->draw;
}

#sub destroy {
#   my ($self) = @_;
#
#   DC::OpenGL::glDeleteList delete $self->{list} if $self->{list};
#
#   $self->SUPER::destroy;
#}

#############################################################################

package DC::UI::EntryBase;

our @ISA = DC::UI::Label::;

use DC::OpenGL;

sub new {
   my $class = shift;

   $class->SUPER::new (
      fg         => [1, 1, 1],
      bg         => [0, 0, 0, 0.2],
      outline    => undef,
      active_bg  => [0, 0,  1, .2],
      active_fg  => [1, 1,  1],
      active_outline => [1, 1, 0],
      can_hover  => 1,
      can_focus  => 1,
      align      => 0,
      valign     => 0.5,
      can_events => 1,
      ellipsise  => 0,
      padding_x  => 4,
      padding_y  => 2,
      #text      => ...
      #hidden    => "*",
      @_
   )
}

sub _set_text {
   my ($self, $text) = @_;

   delete $self->{cur_h};

   return if $self->{text} eq $text;

   $self->{last_activity} = $::NOW;
   $self->{text} = $text;

   $text =~ s/./*/g if $self->{hidden};
   $self->{layout}->set_text ("$text ");
   delete $self->{size_req};

   $self->emit (changed => $self->{text});

   $self->realloc;
   $self->update;
}

sub set_text {
   my ($self, $text) = @_;

   $self->{cursor} = length $text;
   $self->_set_text ($text);
}

sub get_text {
   $_[0]{text}
}

sub size_request {
   my ($self) = @_;

   my ($w, $h) = $self->SUPER::size_request;

   ($w + 1, $h) # add 1 for cursor
}

sub invoke_key_down {
   my ($self, $ev) = @_;

   my $mod = $ev->{mod};
   my $sym = $ev->{sym};
   my $uni = $ev->{unicode};

   my $text = $self->get_text;

   $self->{cursor} = List::Util::max 0, List::Util::min $self->{cursor}, length $text;

   if ($sym == DC::SDLK_BACKSPACE) {
      substr $text, --$self->{cursor}, 1, "" if $self->{cursor};
   } elsif ($sym == DC::SDLK_DELETE) {
      substr $text, $self->{cursor}, 1, "";
   } elsif ($sym == DC::SDLK_LEFT) {
      --$self->{cursor} if $self->{cursor};
   } elsif ($sym == DC::SDLK_RIGHT) {
      ++$self->{cursor} if $self->{cursor} < length $self->{text};
   } elsif ($sym == DC::SDLK_HOME) {
      # what a hack
      $self->{cursor} =
         (substr $self->{text}, 0, $self->{cursor}) =~ /^(.*\012)/
            ? length $1
            : 0;
   } elsif ($sym == DC::SDLK_END) {
      # uh, again
      $self->{cursor} =
         (substr $self->{text}, $self->{cursor}) =~ /^([^\012]*)\012/
            ? $self->{cursor} + length $1
            : length $self->{text};
   } elsif ($uni == 21) { # ctrl-u
      $text = "";
      $self->{cursor} = 0;
   } elsif ($uni == 27) {
      $self->emit ('escape');
   } elsif ($uni == 0x0d) {
      substr $text, $self->{cursor}++, 0, "\012";
   } elsif ($uni >= 0x20) {
      substr $text, $self->{cursor}++, 0, chr $uni;
   } else {
      return 0;
   }

   $self->_set_text ($text);

   $self->realloc;
   $self->update;

   1
}

sub invoke_focus_in {
   my ($self) = @_;

   $self->{last_activity} = $::NOW;

   $self->SUPER::invoke_focus_in
}

sub invoke_button_down {
   my ($self, $ev, $x, $y) = @_;

   $self->SUPER::invoke_button_down ($ev, $x, $y);

   my $idx = $self->{layout}->xy_to_index ($x, $y);

   # byte-index to char-index
   my $text = $self->{text};
   utf8::encode $text; $text = substr $text, 0, $idx; utf8::decode $text;
   $self->{cursor} = length $text;

   $self->_set_text ($self->{text});
   $self->update;
   
   1
}

sub invoke_mouse_motion {
   my ($self, $ev, $x, $y) = @_;
#   printf "M %d,%d %d,%d\n", $ev->motion_x, $ev->motion_y, $x, $y;#d#

   1
}

sub _draw {
   my ($self) = @_;

   local $self->{fg} = $self->{fg};

   if ($FOCUS == $self) {
      glColor_premultiply @{$self->{active_bg}};
      $self->{fg} = $self->{active_fg};
   } else {
      glColor_premultiply @{$self->{bg}};
   }

   glEnable GL_BLEND;
   glBlendFunc GL_ONE, GL_ONE_MINUS_SRC_ALPHA;
   glRect 0, 0, $self->{w}, $self->{h};
   glDisable GL_BLEND;

   $self->SUPER::_draw;

   #TODO: force update every cursor change :(
   if ($FOCUS == $self && (($::NOW - $self->{last_activity}) & 1023) < 600) {

      unless (exists $self->{cur_h}) {
         my $text = substr $self->{text}, 0, $self->{cursor};
         utf8::encode $text;

         @$self{qw(cur_x cur_y cur_h)} = $self->{layout}->cursor_pos (length $text);
      }

      glColor_premultiply @{$self->{active_fg}};
      glBegin GL_LINES;
      glVertex $self->{cur_x} + $self->{ox} + .5, $self->{cur_y} + $self->{oy};
      glVertex $self->{cur_x} + $self->{ox} + .5, $self->{cur_y} + $self->{oy} + $self->{cur_h};
      glEnd;

      glLineWidth 3;
      glColor @{$self->{active_outline}};
      glRect_lineloop 1.5, 1.5, $self->{w} - 1.5, $self->{h} - 1.5;
      glLineWidth 1;

   } else {
      glColor @{$self->{outline} || $DC::THEME{entry_outline}};
      glBegin GL_LINE_STRIP;
      glVertex              .5, $self->{h} *  .5;
      glVertex              .5, $self->{h} - 2.5;
      glVertex $self->{w} - .5, $self->{h} - 2.5;
      glVertex $self->{w} - .5, $self->{h} *  .5;
      glEnd;
   }
}

#############################################################################

package DC::UI::Entry;

our @ISA = DC::UI::EntryBase::;

use DC::OpenGL;

sub new {
   my $class = shift;

   $class->SUPER::new (
      history_pointer => -1,
      @_
   )
}


sub invoke_key_down {
   my ($self, $ev) = @_;

   my $sym = $ev->{sym};

   if ($ev->{uni} == 0x0d || $sym == 13) {
      unshift @{$self->{history}},
         my $txt = $self->get_text;

      $self->{history_pointer} = -1;
      $self->{history_saveback} = '';
      $self->emit (activate => $txt);
      $self->update;

   } elsif ($sym == DC::SDLK_UP) {
      if ($self->{history_pointer} < 0) {
         $self->{history_saveback} = $self->get_text;
      }
      if (@{$self->{history} || []} > 0) {
         $self->{history_pointer}++;
         if ($self->{history_pointer} >= @{$self->{history} || []}) {
            $self->{history_pointer} = @{$self->{history} || []} - 1;
         }
         $self->set_text ($self->{history}->[$self->{history_pointer}]);
      }

   } elsif ($sym == DC::SDLK_DOWN) {
      $self->{history_pointer}--;
      $self->{history_pointer} = -1 if $self->{history_pointer} < 0;

      if ($self->{history_pointer} >= 0) {
         $self->set_text ($self->{history}->[$self->{history_pointer}]);
      } else {
         if (defined $self->{history_saveback}) {
            $self->set_text ($self->{history_saveback});
            $self->{history_saveback} = undef;
         }
      }

   } else {
      return $self->SUPER::invoke_key_down ($ev)
   }

   1
}

#############################################################################

package DC::UI::TextEdit;

our @ISA = DC::UI::EntryBase::;

use DC::OpenGL;

sub new {
   my $class = shift;

   $class->SUPER::new (
      padding_y  => 4,

      @_
   )
}

sub move_cursor_ver {
   my ($self, $dy) = @_;

   my ($line, $x) = $self->{layout}->index_to_line_x ($self->{cursor});

   $line += $dy;

   if (defined (my $index = $self->{layout}->line_x_to_index ($line, $x))) {
      $self->{cursor} = $index;
      delete $self->{cur_h};
      $self->update;
      return;
   }
}

sub invoke_key_down {
   my ($self, $ev) = @_;

   my $sym = $ev->{sym};

   if ($sym == DC::SDLK_UP) {
      $self->move_cursor_ver (-1);
   } elsif ($sym == DC::SDLK_DOWN) {
      $self->move_cursor_ver (+1);
   } else {
      return $self->SUPER::invoke_key_down ($ev)
   }

   1
}

#############################################################################

package DC::UI::ButtonBin;

our @ISA = DC::UI::Bin::;

use DC::OpenGL;

my @tex =
      map { new_from_resource DC::Texture $_, mipmap => 1 }
         qw(b1_button_inactive.png b1_button_active.png);

sub new {
   my $class = shift;

   $class->SUPER::new (
      can_hover  => 1,
      align      => 0.5,
      valign     => 0.5,
      can_events => 1,
      @_
   )
}

sub invoke_button_up {
   my ($self, $ev, $x, $y) = @_;

   $self->emit ("activate")
      if $x >= 0 && $x < $self->{w}
         && $y >= 0 && $y < $self->{h};

   1
}

sub _draw {
   my ($self) = @_;

   glEnable GL_TEXTURE_2D;
   glTexEnv GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_REPLACE;
   glColor 0, 0, 0, 1;

   my $tex = $tex[$GRAB == $self];
   $tex->draw_quad_alpha (0, 0, $self->{w}, $self->{h});

   glDisable GL_TEXTURE_2D;

   $self->SUPER::_draw;
}

#############################################################################

package DC::UI::Button;

our @ISA = DC::UI::Label::;

use DC::OpenGL;

my @tex =
      map { new_from_resource DC::Texture $_, mipmap => 1 }
         qw(b1_button_inactive.png b1_button_active.png);

sub new {
   my $class = shift;

   $class->SUPER::new (
      padding_x  => 8,
      padding_y  => 4,
      fg         => [1.0, 1.0, 1.0],
      active_fg  => [0.8, 0.8, 0.8],
      can_hover  => 1,
      align      => 0.5,
      valign     => 0.5,
      can_events => 1,
      @_
   )
}

sub invoke_button_up {
   my ($self, $ev, $x, $y) = @_;

   $self->emit ("activate")
      if $x >= 0 && $x < $self->{w}
         && $y >= 0 && $y < $self->{h};

   1
}

sub _draw {
   my ($self) = @_;

   local $self->{fg} = $GRAB == $self ? $self->{active_fg} : $self->{fg};

   glEnable GL_TEXTURE_2D;
   glTexEnv GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_REPLACE;
   glColor 0, 0, 0, 1;

   my $tex = $tex[$GRAB == $self];
   $tex->draw_quad_alpha (0, 0, $self->{w}, $self->{h});

   glDisable GL_TEXTURE_2D;

   $self->SUPER::_draw;
}

#############################################################################

package DC::UI::CheckBox;

our @ISA = DC::UI::DrawBG::;

my @tex =
      map { new_from_resource DC::Texture $_, mipmap => 1 }
         qw(c1_checkbox_bg.png c1_checkbox_active.png);

use DC::OpenGL;

sub new {
   my $class = shift;

   $class->SUPER::new (
      fontsize  => 1,
      padding_x => 2,
      padding_y => 2,
      fg        => [1, 1, 1],
      active_fg => [1, 1, 0],
      bg        => [0, 0, 0, 0.2],
      active_bg => [1, 1, 1, 0.5],
      state     => 0,
      can_hover => 1,
      @_
   )
}

sub size_request {
   my ($self) = @_;

   ($self->{fontsize} * $::FONTSIZE) x 2
}

sub toggle {
   my ($self) = @_;

   $self->{state} = !$self->{state};
   $self->emit (changed => $self->{state});
   $self->update;
}

sub invoke_button_down {
   my ($self, $ev, $x, $y) = @_;

   if ($x >= $self->{padding_x} && $x < $self->{w} - $self->{padding_x}
       && $y >= $self->{padding_y} && $y < $self->{h} - $self->{padding_y}) {
      $self->toggle;
   } else {
      return 0
   }

   1
}

sub _draw {
   my ($self) = @_;

   $self->SUPER::_draw;

   glTranslate $self->{padding_x}, $self->{padding_y}, 0;

   my ($w, $h) = @$self{qw(w h)};

   my $s = List::Util::min $w - $self->{padding_x} * 2, $h - $self->{padding_y} * 2;

   glColor @{ $FOCUS == $self ? $self->{active_fg} : $self->{fg} };

   my $tex = $self->{state} ? $tex[1] : $tex[0];

   glEnable GL_TEXTURE_2D;
   $tex->draw_quad_alpha (0, 0, $s, $s);
   glDisable GL_TEXTURE_2D;
}

#############################################################################

package DC::UI::Image;

our @ISA = DC::UI::DrawBG::;

use DC::OpenGL;

our %texture_cache;

sub new {
   my $class = shift;

   my $self = $class->SUPER::new (
      can_events => 0,
      scale      => 1,
      @_,
   );

   $self->{path} || $self->{tex}
      or Carp::croak "'path' or 'tex' attributes required";

   $self->{tex} ||= $texture_cache{$self->{path}} ||=
      new_from_resource DC::Texture $self->{path}, mipmap => 1;

   DC::weaken $texture_cache{$self->{path}};

   $self->{aspect} ||= $self->{tex}{w} / $self->{tex}{h};

   $self
}

sub STORABLE_freeze {
   my ($self, $cloning) = @_;

   $self->{path}
      or die "cannot serialise DC::UI::Image on non-loadable images\n";

   $self->{path}
}

sub STORABLE_attach {
   my ($self, $cloning, $path) = @_;

   $self->new (path => $path)
}

sub set_texture {
   my ($self, $tex) = @_;

   $self->{tex} = $tex;
   $self->update;
}

sub size_request {
   my ($self) = @_;

   (int $self->{tex}{w} * $self->{scale}, int $self->{tex}{h} * $self->{scale})
}

sub _draw {
   my ($self) = @_;

   $self->SUPER::_draw;

   my $tex = $self->{tex};

   my ($w, $h) = ($self->{w}, $self->{h});

   if ($self->{rot90}) {
      glRotate 90, 0, 0, 1;
      glTranslate 0, -$self->{w}, 0;

      ($w, $h) = ($h, $w);
   }

   glEnable GL_TEXTURE_2D;
   glTexEnv GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_REPLACE;

   $tex->draw_quad_alpha (0, 0, $w, $h);

   glDisable GL_TEXTURE_2D;
}

#############################################################################

package DC::UI::ImageButton;

our @ISA = DC::UI::Image::;

use DC::OpenGL;

sub new {
   my $class = shift;

   my $self = $class->SUPER::new (
      padding_x  => 4,
      padding_y  => 4,
      fg         => [1, 1, 1],
      active_fg  => [0, 0, 1],
      can_hover  => 1,
      align      => 0.5,
      valign     => 0.5,
      can_events => 1,
      @_
   );
}

sub invoke_button_down {
   my ($self, $ev, $x, $y) = @_;

   1
}

sub invoke_button_up {
   my ($self, $ev, $x, $y) = @_;

   $self->emit ("activate")
      if $x >= 0 && $x < $self->{w}
         && $y >= 0 && $y < $self->{h};

   1
}

#############################################################################

package DC::UI::VGauge;

our @ISA = DC::UI::Base::;

use List::Util qw(min max);

use DC::OpenGL;

my %tex = (
   food => [
      map { new_from_resource DC::Texture $_, mipmap => 1 }
         qw/g1_food_gauge_empty.png g1_food_gauge_full.png/
   ],
   grace => [
      map { new_from_resource DC::Texture $_, mipmap => 1 }
         qw/g1_grace_gauge_empty.png g1_grace_gauge_full.png g1_grace_gauge_overflow.png/
   ],
   hp => [
      map { new_from_resource DC::Texture $_, mipmap => 1 }
         qw/g1_hp_gauge_empty.png g1_hp_gauge_full.png/
   ],
   mana => [
      map { new_from_resource DC::Texture $_, mipmap => 1 }
         qw/g1_mana_gauge_empty.png g1_mana_gauge_full.png g1_mana_gauge_overflow.png/
   ],
);

# eg. VGauge->new (gauge => 'food'), default gauge: food
sub new {
   my $class = shift;

   my $self = $class->SUPER::new (
      type  => 'food',
      @_
   );

   $self->{aspect} = $tex{$self->{type}}[0]{w} / $tex{$self->{type}}[0]{h};

   $self
}

sub size_request {
   my ($self) = @_;

   #my $tex = $tex{$self->{type}}[0];
   #@$tex{qw(w h)}
   (0, 0)
}

sub set_max {
   my ($self, $max) = @_;

   return if $self->{max_val} == $max;

   $self->{max_val} = $max;
   $self->update;
}

sub set_value {
   my ($self, $val, $max) = @_;

   $self->set_max ($max)
      if defined $max;

   return if $self->{val} == $val;

   $self->{val} = $val;
   $self->update;
}

sub _draw {
   my ($self) = @_;

   my $tex = $tex{$self->{type}};
   my ($t1, $t2, $t3) = @$tex;

   my ($w, $h) = ($self->{w}, $self->{h});

   if ($self->{vertical}) {
      glRotate 90, 0, 0, 1;
      glTranslate 0, -$self->{w}, 0;

      ($w, $h) = ($h, $w);
   }

   my $ycut = $self->{val} / ($self->{max_val} || 1);

   my $ycut1 = max 0, min 1, $ycut;
   my $ycut2 = max 0, min 1, $ycut - 1;

   my $h1 = $self->{h} * (1 - $ycut1);
   my $h2 = $self->{h} * (1 - $ycut2);
   my $h3 = $self->{h};

   $_ = $_ * (284-4)/288 + 4/288 for ($h1, $h2, $h3);

   glEnable GL_BLEND;
   glBlendFuncSeparate GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA,
                       GL_ONE, GL_ONE_MINUS_SRC_ALPHA;
   glEnable GL_TEXTURE_2D;
   glTexEnv GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_REPLACE;

   glBindTexture GL_TEXTURE_2D, $t1->{name};
   glBegin GL_QUADS;
   glTexCoord 0       , 0;                       glVertex 0 , 0;
   glTexCoord 0       , $t1->{t} * (1 - $ycut1); glVertex 0 , $h1;
   glTexCoord $t1->{s}, $t1->{t} * (1 - $ycut1); glVertex $w, $h1;
   glTexCoord $t1->{s}, 0;                       glVertex $w, 0;
   glEnd;

   my $ycut1 = List::Util::min 1, $ycut;
   glBindTexture GL_TEXTURE_2D, $t2->{name};
   glBegin GL_QUADS;
   glTexCoord 0       , $t2->{t} * (1 - $ycut1); glVertex 0 , $h1;
   glTexCoord 0       , $t2->{t} * (1 - $ycut2); glVertex 0 , $h2;
   glTexCoord $t2->{s}, $t2->{t} * (1 - $ycut2); glVertex $w, $h2;
   glTexCoord $t2->{s}, $t2->{t} * (1 - $ycut1); glVertex $w, $h1;
   glEnd;

   if ($t3) {
      glBindTexture GL_TEXTURE_2D, $t3->{name};
      glBegin GL_QUADS;
      glTexCoord 0       , $t3->{t} * (1 - $ycut2); glVertex 0 , $h2;
      glTexCoord 0       , $t3->{t};                glVertex 0 , $h3;
      glTexCoord $t3->{s}, $t3->{t};                glVertex $w, $h3;
      glTexCoord $t3->{s}, $t3->{t} * (1 - $ycut2); glVertex $w, $h2;
      glEnd;
   }

   glDisable GL_BLEND;
   glDisable GL_TEXTURE_2D;
}

#############################################################################

package DC::UI::Progress;

our @ISA = DC::UI::Label::;

use DC::OpenGL;

sub new {
   my ($class, %arg) = @_;

   my $self = $class->SUPER::new (
      padding_x  => 2,
      padding_y  => 2,
      fg         => [1, 1, 1],
      bg         => [0, 0, 1, 0.2],
      bar        => [0.7, 0.5, 0.1, 0.8],
      outline    => [0.4, 0.3, 0],
      fontsize   => 0.9,
      valign     => 0.5,
      align      => 0.5,
      can_events => 1,
      ellipsise  => 1,
      label      => "%d%%",
      %arg,
   );

   $self->set_value ($arg{value} || -1);

   $self
}

sub set_label {
   my ($self, $label) = @_;

   return if $self->{label} eq $label;
   $self->{label} = $label;

   $self->DC::UI::Progress::set_value (0 + delete $self->{value});
}

sub set_value {
   my ($self, $value) = @_;

   if ($self->{value} ne $value) {
      $self->{value} = $value;

      if ($value < 0) {
         $self->set_text ("-");
      } else {
         $self->set_text (sprintf $self->{label}, $value * 100);
      }

      $self->update;
   }
}

sub _draw {
   my ($self) = @_;

   glEnable GL_BLEND;
   glBlendFunc GL_ONE, GL_ONE_MINUS_SRC_ALPHA;

   my $px = $self->{padding_x};
   my $py = $self->{padding_y};

   if ($self->{value} >= 0) {
      my $s = int $px + ($self->{w} - $px * 2) * $self->{value};

      glColor_premultiply @{$self->{bar}};
      glRect $px, $py,               $s, $self->{h} - $py;
      glColor_premultiply @{$self->{bg}};
      glRect $s , $py, $self->{w} - $px, $self->{h} - $py;
   }

   glColor_premultiply @{$self->{outline}};

   $px -= .5;
   $py -= .5;

   glRect_lineloop $px, $py, $self->{w} - $px, $self->{h} - $py;

   glDisable GL_BLEND;

   {
      local $self->{bg}; # do not draw background
      $self->SUPER::_draw;
   }
}

#############################################################################

package DC::UI::ExperienceProgress;

our @ISA = DC::UI::Progress::;

sub new {
   my ($class, %arg) = @_;

   my $tt = exists $arg{tooltip} ? "$arg{tooltip}\n\n" : "";

   my $self = $class->SUPER::new (
      %arg,
      tooltip => sub {
         my ($self) = @_;

         sprintf "%slevel %d\n%s points\n%s next level\n%s to go, %d%% done",
            $tt,
            $self->{lvl},
            ::formsep ($self->{exp}),
            ::formsep ($self->{nxt}),
            ::formsep ($self->{nxt} - $self->{exp}),
            $self->_percent * 100,
      },
   );

   $::CONN->{on_exp_update}{$self+0} = sub { $self->set_value ($self->{value}) }
      if $::CONN;

   $self
}

sub DESTROY {
   my ($self) = @_;

   delete $::CONN->{on_exp_update}{$self+0}
      if $::CONN;

   $self->SUPER::DESTROY;
}

sub _percent {
   my ($self) = @_;

   my $table = $::CONN && $::CONN->{exp_table}
      or return -1;

   my $l0 = $table->[$self->{lvl} - 1];
   my $l1 = $table->[$self->{lvl}];

   $self->{nxt} = $l1;

   ($self->{exp} - $l0) / ($l1 - $l0)
}

sub set_value {
   my ($self, $lvl, $exp) = @_;

   $self->{lvl} = $lvl;
   $self->{exp} = $exp;

   $self->SUPER::set_value ($self->_percent);
}

#############################################################################

package DC::UI::Gauge;

our @ISA = DC::UI::VBox::;

sub new {
   my ($class, %arg) = @_;

   my $self = $class->SUPER::new (
      tooltip    => $arg{type},
      can_hover  => 1,
      can_events => 1,
      %arg,
   );

   $self->add ($self->{value} = new DC::UI::Label valign => 1, align => 0.5, template => "999");
   $self->add ($self->{gauge} = new DC::UI::VGauge type => $self->{type}, expand => 1, can_hover => 1);
   $self->add ($self->{max}   = new DC::UI::Label valign => 0, align => 0.5, template => "999");

   $self
}

sub set_fontsize {
   my ($self, $fsize) = @_;

   $self->{value}->set_fontsize ($fsize);
   $self->{max}  ->set_fontsize ($fsize);
}

sub set_max {
   my ($self, $max) = @_;

   $self->{gauge}->set_max ($max);
   $self->{max}->set_text ($max);
}

sub set_value {
   my ($self, $val, $max) = @_;

   $self->set_max ($max)
      if defined $max;

   $self->{gauge}->set_value ($val, $max);
   $self->{value}->set_text ($val);
}

#############################################################################

package DC::UI::Slider;

use common::sense;

use DC::OpenGL;

our @ISA = DC::UI::DrawBG::;

my @tex =
      map { new_from_resource DC::Texture $_ }
         qw(s1_slider.png s1_slider_bg.png);

sub new {
   my $class = shift;

   # range [value, low, high, page, unit]

   # TODO: 0-width page
   # TODO: req_w/h are wrong with vertical
   # TODO: calculations are off
   my $self = $class->SUPER::new (
      fg        => [1, 1, 1],
      active_fg => [0, 0, 0],
      bg        => [0, 0, 0, 0.2],
      active_bg => [1, 1, 1, 0.5],
      range     => [0, 0, 100, 10, 0],
      min_w     => $::WIDTH / 80,
      min_h     => $::WIDTH / 80,
      vertical  => 0,
      can_hover => 1,
      inner_pad => 0.02,
      @_
   );

   $self->set_value ($self->{range}[0]);
   $self->update;

   $self
}

sub set_range {
   my ($self, $range) = @_;

   ($range, $self->{range}) = ($self->{range}, $range);

   if ("@$range" ne "@{$self->{range}}") {
      $self->update;
      $self->set_value ($self->{range}[0]);
   }
}

sub set_value {
   my ($self, $value) = @_;

   my ($old_value, $lo, $hi, $page, $unit) = @{$self->{range}};

   $hi = $lo if $hi < $lo;

   $value = $hi - $page if $value > $hi - $page;
   $value = $lo         if $value < $lo;

   $value = $lo + $unit * int +($value - $lo + $unit * 0.5) / $unit
      if $unit;

   @{$self->{range}} = ($value, $lo, $hi, $page, $unit);

   if ($value != $old_value) {
      $self->emit (changed => $value);
      $self->update;
   }
}

sub size_request {
   my ($self) = @_;

   ($self->{req_w}, $self->{req_h})
}

sub invoke_button_down {
   my ($self, $ev, $x, $y) = @_;

   $self->SUPER::invoke_button_down ($ev, $x, $y);

   $self->{click} = [$self->{range}[0], $self->{vertical} ? $y : $x];
   
   $self->invoke_mouse_motion ($ev, $x, $y);

   1
}

sub invoke_mouse_motion {
   my ($self, $ev, $x, $y) = @_;

   if ($GRAB == $self) {
      my ($x, $w) = $self->{vertical} ? ($y, $self->{h}) : ($x, $self->{w});

      my (undef, $lo, $hi, $page) = @{$self->{range}};

      $x = ($x - $self->{click}[1]) / ($w * $self->{scale});

      $self->set_value ($self->{click}[0] + $x * ($hi - $page - $lo));
   } else {
      return 0;
   }

   1
}

sub invoke_mouse_wheel {
   my ($self, $ev) = @_;

   my $delta = $self->{vertical} ? $ev->{dy} : $ev->{dx};

   my $pagepart = $ev->{mod} & DC::KMOD_SHIFT ? 1 : 0.2;

   $self->set_value ($self->{range}[0] + $delta * $self->{range}[3] * $pagepart);

   1
}

sub update {
   my ($self) = @_;

   delete $self->{knob_w};
   $self->SUPER::update;
}

sub _draw {
   my ($self) = @_;

   unless ($self->{knob_w}) {
      $self->set_value ($self->{range}[0]);

      my ($value, $lo, $hi, $page, $unit) = @{$self->{range}};
      my $range = ($hi - $page - $lo) || 1e-10;

      my $knob_w = List::Util::min 1, $page / (($hi - $lo) || 1e-10) || 24 / $self->{w};

      $self->{offset} = List::Util::max $self->{inner_pad}, $knob_w * 0.5;
      $self->{scale} = 1 - 2 * $self->{offset} || 1e-100;

      $value = ($value - $lo) / $range;
      $value = $value * $self->{scale} + $self->{offset};

      $self->{knob_x} = $value - $knob_w * 0.5;
      $self->{knob_w} = $knob_w;
   }

   $self->SUPER::_draw ();

   glScale $self->{w}, $self->{h};

   if ($self->{vertical}) {
      # draw a vertical slider like a rotated horizontal slider
 
      glTranslate 1, 0, 0;
      glRotate 90, 0, 0, 1;
   }

   my $fg = $FOCUS == $self ? $self->{active_fg} : $self->{fg};
   my $bg = $FOCUS == $self ? $self->{active_bg} : $self->{bg};

   glEnable GL_TEXTURE_2D;
   glTexEnv GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_REPLACE;

   # draw background
   $tex[1]->draw_quad_alpha (0, 0, 1, 1);

   # draw handle
   $tex[0]->draw_quad_alpha ($self->{knob_x}, 0, $self->{knob_w}, 1);

   glDisable GL_TEXTURE_2D;
}

#############################################################################

package DC::UI::ValSlider;

our @ISA = DC::UI::HBox::;

sub new {
   my ($class, %arg) = @_;

   my $range = delete $arg{range};

   my $self = $class->SUPER::new (
      slider     => (new DC::UI::Slider expand => 1, range => $range),
      entry      => (new DC::UI::Label text => "", template => delete $arg{template}),
      to_value   => sub { shift },
      from_value => sub { shift },
      %arg,
   );

   $self->{slider}->connect (changed => sub {
      my ($self, $value) = @_;
      $self->{parent}{entry}->set_text ($self->{parent}{to_value}->($value));
      $self->{parent}->emit (changed => $value);
   });

#   $self->{entry}->connect (changed => sub {
#      my ($self, $value) = @_;
#      $self->{parent}{slider}->set_value ($self->{parent}{from_value}->($value));
#      $self->{parent}->emit (changed => $value);
#   });

   $self->add ($self->{slider}, $self->{entry});

   $self->{slider}->emit (changed => $self->{slider}{range}[0]);

   $self
}

sub set_range { shift->{slider}->set_range (@_) }
sub set_value { shift->{slider}->set_value (@_) }

#############################################################################

package DC::UI::TextScroller;

our @ISA = DC::UI::HBox::;

use DC::OpenGL;

sub new {
   my $class = shift;

   my $self = $class->SUPER::new (
      fontsize   => 1,
      can_events => 1,
      indent     => 0,
      #font      => default_font
      @_,
                 
      layout     => (new DC::Layout),
      par        => [],
      max_par    => 0,
      height     => 0,
      children   => [
         (new DC::UI::Empty expand => 1),
         (new DC::UI::Slider vertical => 1),
      ],
   );

   $self->{children}[1]->connect (changed => sub { $self->update });

   $self
}

sub set_fontsize {
   my ($self, $fontsize) = @_;

   $self->{fontsize} = $fontsize;
   $self->reflow;
}

sub size_request {
   my ($self) = @_;

   my ($empty, $slider) = $self->visible_children;

   local $self->{children} = [$empty, $slider];
   $self->SUPER::size_request
}

sub invoke_size_allocate {
   my ($self, $w, $h) = @_;

   my ($empty, $slider, @other) = @{ $self->{children} };
   $_->configure (@$_{qw(x y req_w req_h)}) for @other;

   $self->{layout}->set_font ($self->{font}) if $self->{font};
   $self->{layout}->set_height ($self->{fontsize} * $::FONTSIZE);
   $self->{layout}->set_width ($empty->{w});
   $self->{layout}->set_indent ($self->{fontsize} * $::FONTSIZE * $self->{indent});

   $self->reflow;

   local $self->{children} = [$empty, $slider];
   $self->SUPER::invoke_size_allocate ($w, $h)
}

sub invoke_mouse_wheel {
   my ($self, $ev) = @_;

   return 0 unless $ev->{dy}; # only vertical movements

   $self->{children}[1]->emit (mouse_wheel => $ev);

   1
}

sub get_layout {
   my ($self, $para) = @_;

   my $layout = $self->{layout};

   $layout->set_font ($self->{font}) if $self->{font};
   $layout->set_foreground (@{$para->{fg}});
   $layout->set_height ($self->{fontsize} * $::FONTSIZE);
   $layout->set_width ($self->{children}[0]{w} - $para->{indent});
   $layout->set_indent ($self->{fontsize} * $::FONTSIZE * $self->{indent});
   $layout->set_markup ($para->{markup});

   $layout->set_shapes (
      map
         +(0, $_->baseline_shift + $_->{padding_y} - $_->{h}, $_->{w}, $_->{h}),
         @{$para->{widget}}
   );

   $layout
}

sub reflow {
   my ($self) = @_;

   $self->{need_reflow}++;
   $self->update;
}

sub set_offset {
   my ($self, $offset) = @_;

   # todo: base offset on lines or so, not on pixels
   $self->{children}[1]->set_value ($offset);
}

sub current_paragraph {
   my ($self) = @_;

   $self->{top_paragraph} - 1
}

sub scroll_to {
   my ($self, $para) = @_;

   $para = List::Util::max 0, List::Util::min $#{$self->{par}}, $para;

   $self->{scroll_to} = $para;
   $self->update;
}

sub clear {
   my ($self) = @_;

   my (undef, undef, @other) = @{ $self->{children} };
   $self->remove ($_) for @other;

   $self->{par} = [];
   $self->{height} = 0;
   $self->{children}[1]->set_range ([0, 0, 0, 1, 1]);
}

sub add_paragraph {
   my $self = shift;

   for my $para (@_) {
      $para = {
         fg      => [1, 1, 1, 1],
         indent  => 0,
         markup  => "",
         widget  => [],
         ref $para ? %$para : (markup => $para),
         w       => 1e10,
         wrapped => 1,
      };

      $self->add (@{ $para->{widget} }) if @{ $para->{widget} };
      push @{$self->{par}}, $para;
   }

   if (my $max = $self->{max_par}) {
      shift @{$self->{par}} while @{$self->{par}} > $max;
   }

   $self->{need_reflow}++;
   $self->update;
}

sub scroll_to_bottom {
   my ($self) = @_;

   $self->{scroll_to} = $#{$self->{par}};
   $self->update;
}

sub force_uptodate {
   my ($self) = @_;

   if (delete $self->{need_reflow}) {
      my ($W, $H) = @{$self->{children}[0]}{qw(w h)};

      my $height = 0;

      for my $para (@{$self->{par}}) {
         if ($para->{w} != $W && ($para->{wrapped} || $para->{w} > $W)) {
            my $layout = $self->get_layout ($para);
            my ($w, $h) = $layout->size;

            $para->{w}       = $w + $para->{indent};
            $para->{h}       = $h;
            $para->{wrapped} = $layout->has_wrapped;
         }

         $para->{y} = $height;
         $height += $para->{h};
      }

      $self->{height} = $height;
      $self->{children}[1]->set_range ([$self->{children}[1]{range}[0], 0, $height, $H, 1]);

      delete $self->{texture};
   }

   if (my $paridx = delete $self->{scroll_to}) {
      $self->{children}[1]->set_value ($self->{par}[$paridx]{y});
   }
}

sub update {
   my ($self) = @_;

   $self->SUPER::update;

   return unless $self->{h} > 0;

   delete $self->{texture};

   $ROOT->on_post_alloc ($self => sub {
      $self->force_uptodate;

      my ($W, $H) = @{$self->{children}[0]}{qw(w h)};

      $self->{texture} ||= new_from_opengl DC::Texture $W, $H, sub {
         glClearColor 0, 0, 0, 0;
         glClear GL_COLOR_BUFFER_BIT;

         package DC::UI::Base;
         local ($draw_x, $draw_y, $draw_w, $draw_h) =
            (0, 0, $self->{w}, $self->{h});

         my $top = int $self->{children}[1]{range}[0];

         my $paridx = 0;
         my $top_paragraph;
         my $top = int $self->{children}[1]{range}[0];

         my $y0 = $top;
         my $y1 = $top + $H;

         for my $para (@{$self->{par}}) {
            my $h = $para->{h};
            my $y = $para->{y};

            if ($y0 < $y + $h && $y < $y1) {
               my $layout = $self->get_layout ($para);

               $layout->render ($para->{indent}, $y - $y0);
               $layout->draw;

               if (my @w = @{ $para->{widget} }) {
                  my @s = $layout->get_shapes;

                  for (@w) {
                     my ($dx, $dy) = splice @s, 0, 2, ();

                     $_->{x} = $dx + $para->{indent};
                     $_->{y} = $dy + $y - $y0;

                     $_->draw;
                  }
               }
            }

            $paridx++;
            $top_paragraph ||= $paridx if $y >= $top;
         }

         $self->{top_paragraph} = $top_paragraph;
      };
   });
}

sub reconfigure {
   my ($self) = @_;

   $self->SUPER::reconfigure;

   $_->{w} = 1e10 for @{ $self->{par} };
   $self->reflow;
}

sub _draw {
   my ($self) = @_;

   glEnable GL_TEXTURE_2D;
   glTexEnv GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_REPLACE;
   glColor 0, 0, 0, 1;
   $self->{texture}->draw_quad_alpha_premultiplied (0, 0, $self->{children}[0]{w}, $self->{children}[0]{h});
   glDisable GL_TEXTURE_2D;

   $self->{children}[1]->draw;
}

#############################################################################

package DC::UI::Animator;

use DC::OpenGL;

our @ISA = DC::UI::Bin::;

sub moveto {
   my ($self, $x, $y) = @_;

   $self->{moveto} = [$self->{x}, $self->{y}, $x, $y];
   $self->{speed}  = 0.001;
   $self->{time}   = 1;
   
   ::animation_start $self;
}

sub animate {
   my ($self, $interval) = @_;

   $self->{time} -= $interval * $self->{speed};
   if ($self->{time} <= 0) {
      $self->{time} = 0;
      ::animation_stop $self;
   }

   my ($x0, $y0, $x1, $y1) = @{$self->{moveto}};
      
   $self->{x} = $x0 * $self->{time} + $x1 * (1 - $self->{time});
   $self->{y} = $y0 * $self->{time} + $y1 * (1 - $self->{time});
}

sub _draw {
   my ($self) = @_;

   glPushMatrix;
   glRotate $self->{time} * 1000, 0, 1, 0;
   $self->{children}[0]->draw;
   glPopMatrix;
}

#############################################################################

package DC::UI::Flopper;

our @ISA = DC::UI::Button::;

sub new {
   my $class = shift;

   my $self = $class->SUPER::new (
      state       => 0,
      on_activate => \&toggle_flopper,
      @_
   );

   $self
}

sub toggle_flopper {
   my ($self) = @_;

   $self->{other}->toggle_visibility;
}

#############################################################################

package DC::UI::Tooltip;

our @ISA = DC::UI::Bin::;

use DC::OpenGL;

sub new {
   my $class = shift;

   $class->SUPER::new (
      @_,
      can_events => 0,
   )
}

sub set_tooltip_from {
   my ($self, $widget) = @_;

   my $tip = $widget->{tooltip};
   $tip = $tip->($widget) if "CODE" eq ref $tip;
               
   $tip = DC::Pod::section_label tooltip => $1
      if $tip =~ /^#(.*)$/;

   if ($ENV{CFPLUS_DEBUG} & 2) {
      $tip .= "\n\n" . (ref $widget) . "\n"
            . "$widget->{x} $widget->{y} $widget->{w} $widget->{h}\n"
            . "req $widget->{req_w} $widget->{req_h}\n"
            . "visible $widget->{visible}";
   }

   $tip =~ s/^\n+//;
   $tip =~ s/\n+$//;

   $self->add (new DC::UI::Label
      fg        => $DC::THEME{tooltip_fg},
      markup    => $tip,
      max_w     => ($widget->{tooltip_width} || 0.25) * $::WIDTH,
      align     => 0,
      fontsize  => 0.8,
      style     => $DC::THEME{tooltip_style}, # FLAG_INVERSE
      ellipsise => 0,
      font      => ($widget->{tooltip_font} || $::FONT_PROP),
   );
}

sub size_request {
   my ($self) = @_;

   my ($w, $h) = @{$self->child}{qw(req_w req_h)};

   ($w + 4, $h + 4)
}

sub invoke_size_allocate {
   my ($self, $w, $h) = @_;

   $self->SUPER::invoke_size_allocate ($w - 4, $h - 4)
}

sub invoke_visibility_change {
   my ($self, $visible) = @_;

   return unless $visible;

   $self->{root}->on_post_alloc ("move_$self" => sub {
      my $widget = $self->{owner}
         or return;

      if ($widget->{visible}) {
         my ($x, $y) = $widget->coord2global ($widget->{w}, 0);

         ($x, $y) = $widget->coord2global (-$self->{w}, 0)
            if $x + $self->{w} > $self->{root}{w};

         $self->move_abs ($x, $y);
      } else {
         $self->hide;
      }
   });
}

sub _draw {
   my ($self) = @_;

   my ($w, $h) = @$self{qw(w h)};

   glColor @{ $DC::THEME{tooltip_bg} };
   glRect 0, 0, $w, $h;
   
   glColor @{ $DC::THEME{tooltip_border} };
   glRect_lineloop .5, .5, $w + .5, $h + .5;
   
   glTranslate 2, 2;

   $self->SUPER::_draw;
}

#############################################################################

package DC::UI::Face;

our @ISA = DC::UI::DrawBG::;

use DC::OpenGL;

sub new {
   my $class = shift;

   my $self = $class->SUPER::new (
      size_w     => 32,
      size_h     => 8,
      aspect     => 1,
      can_events => 0,
      @_,
   );

   $self->update_anim;
   
   $self
}

sub update_timer {
   my ($self) = @_;

   return unless $self->{timer};

   if ($self->{visible}) {
      $self->{timer}->start;
   } else {
      $self->{timer}->stop;
   }
}

sub update_face {
   my ($self) = @_;

   if ($::CONN) {
      if (my $anim = $::CONN->{anim}[$self->{anim}]) {
         if ($anim && @$anim) {
            $self->{face} = $anim->[ $self->{frame} % @$anim ];
            delete $self->{face_change_cb};

            if (my $tex = $self->{tex} = $::CONN->{texture}[ $::CONN->{face}[$self->{face}]{id} ]) {
               unless ($tex->{name} || $tex->{loading}) {
                  $tex->upload (sub { $self->reconfigure });
               }
            }
         }
      }
   }
}

sub update_anim {
   my ($self) = @_;

   if ($self->{anim} && $self->{animspeed}) {
      DC::weaken (my $widget = $self);

      $self->{animspeed} = List::Util::max 0.05, $self->{animspeed};
      $self->{timer} = EV::periodic_ns 0, $self->{animspeed}, undef, sub {
         return unless $::CONN;

         my $w = $widget
            or return;

         ++$w->{frame};
         $w->update_face;

         # somehow, $widget can go away
         $w->update;
         $w->update_timer;
      };

      $self->update_face;
      $self->update_timer;
   } else {
      delete $self->{timer};
   }
}

sub size_request {
   my ($self) = @_;

   if ($::CONN) {
      if (my $faceid = $::CONN->{face}[$self->{face}]{id}) {
         if (my $tex = $self->{tex} = $::CONN->{texture}[$faceid]) {
            if ($tex->{name}) {
               return ($self->{size_w} || $tex->{w}, $self->{size_h} || $tex->{h});
            } elsif (!$tex->{loading}) {
               $tex->upload (sub { $self->reconfigure });
            }
         }

         $self->{face_change_cb} ||= $::CONN->on_face_change ($self->{face}, sub { $self->reconfigure });
      }
   }

   ($self->{size_w} || 8, $self->{size_h} || 8)
}

sub update {
   my ($self) = @_;

   return unless $self->{visible};

   $self->SUPER::update;
}

sub set_face {
   my ($self, $face) = @_;

   $self->{face} = $face;
   $self->reconfigure;
}

sub set_anim {
   my ($self, $anim) = @_;

   $self->{anim} = $anim;
   $self->update_anim;
}

sub set_animspeed {
   my ($self, $animspeed) = @_;

   $self->{animspeed} = $animspeed;
   $self->update_anim;
}

sub invoke_visibility_change {
   my ($self) = @_;

   $self->update_timer;

   0
}

sub _draw {
   my ($self) = @_;

   $self->SUPER::_draw;

   if (my $tex = $self->{tex}) {
      glEnable GL_TEXTURE_2D;
      glTexEnv GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_REPLACE;
      glColor 0, 0, 0, 1;
      $tex->draw_quad_alpha (0, 0, $self->{w}, $self->{h});
      glDisable GL_TEXTURE_2D;
   }
}

sub destroy {
   my ($self) = @_;

   (delete $self->{timer})->cancel
      if $self->{timer};

   $self->SUPER::destroy;
}

#############################################################################

package DC::UI::Buttonbar;

our @ISA = DC::UI::HBox::;

# TODO: should actually wrap buttons and other goodies.

#############################################################################

package DC::UI::Menu;

our @ISA = DC::UI::Toplevel::;

use DC::OpenGL;

sub new {
   my $class = shift;

   my $self = $class->SUPER::new (
      items => [],
      z     => 100,
      @_,
   );

   $self->add ($self->{vbox} = new DC::UI::VBox);

   for my $item (@{ $self->{items} }) {
      my ($widget, $cb, $tooltip) = @$item;

      # handle various types of items, only text for now
      if (!ref $widget) {
         if ($widget =~ /\t/) {
            my ($left, $right) = split /\t/, $widget, 2;

            $widget = new DC::UI::HBox
               can_hover  => 1,
               can_events => 1,
               tooltip    => $tooltip,
               children   => [
                  (new DC::UI::Label markup => $left , align => 0, expand => 1),
                  (new DC::UI::Label markup => $right, align => 1),
               ],
            ;

         } else {
            $widget = new DC::UI::Label
               can_hover  => 1,
               can_events => 1,
               align      => 0,
               markup     => $widget,
               tooltip    => $tooltip;
         }
      }

      $self->{item}{$widget} = $item;

      $self->{vbox}->add ($widget);
   }

   $self
}

# popup given the event (must be a mouse button down event currently)
sub popup {
   my ($self, $ev) = @_;

   $self->emit ("popdown");

   # maybe save $GRAB? must be careful about events...
   $GRAB = $self;
   $self->{button} = $ev->{button};

   $self->show;

   my $x = $ev->{x};
   my $y = $ev->{y};

   $self->{root}->on_post_alloc ($self => sub {
      $self->move_abs ($x - $self->{w} * 0.25, $y - $self->{border} * $::FONTSIZE * .5);
   });

   1 # so it can be used inside event handlers
}

sub invoke_mouse_motion {
   my ($self, $ev, $x, $y) = @_;

   # TODO: should use vbox->find_widget or so
   $HOVER = $ROOT->find_widget ($ev->{x}, $ev->{y});
   $self->{hover} = $self->{item}{$HOVER};

   0
}

sub invoke_button_up {
   my ($self, $ev, $x, $y) = @_;

   if ($ev->{button} == $self->{button}) {
      undef $GRAB;
      $self->hide;

      $self->emit ("popdown");
      $self->{hover}[1]->() if $self->{hover};
   } else {
      return 0
   }

   1
}

#############################################################################

package DC::UI::Multiplexer;

our @ISA = DC::UI::Container::;

sub new {
   my $class = shift;

   my $self = $class->SUPER::new (
      @_,
   );

   $self->set_current_page (0);

   $self
}

sub add {
   my ($self, @widgets) = @_;

   $self->SUPER::add (@widgets);

   $self->set_current_page (0)
      if @widgets == @{ $self->{children} };
}

sub get_current_page {
   my ($self) = @_;

   $self->{current}
}

sub set_current_page {
   my ($self, $page_or_widget) = @_;

   my $widget = ref $page_or_widget
                   ? $page_or_widget
                   : $self->{children}[$page_or_widget];

   $self->{current}->set_invisible if $self->{current} && $self->{visible};

   if (($self->{current} = $widget)) {
      $self->{current}->set_visible if $self->{current} && $self->{visible};
      $self->{current}->configure (0, 0, $self->{w}, $self->{h});

      $self->emit (page_changed => $self->{current});
   }

   $self->realloc;
}

sub visible_children {
   $_[0]{current} || ()
}

sub size_request {
   my ($self) = @_;

   $self->{current}
      ? $self->{current}->size_request
      : (0, 0)
}

sub invoke_size_allocate {
   my ($self, $w, $h) = @_;

   $self->{current}->configure (0, 0, $w, $h)
     if $self->{current};

   1
}

sub _draw {
   my ($self) = @_;

   $self->{current}->draw
      if $self->{current};
}

#############################################################################

package DC::UI::Notebook;

use DC::OpenGL;

our @ISA = DC::UI::VBox::;

sub new {
   my $class = shift;

   my $self = $class->SUPER::new (
      buttonbar      => (new DC::UI::Buttonbar),
      multiplexer    => (new DC::UI::Multiplexer expand => 1),
      active_outline => [.7, .7, 0.2],
      # filter => # will be put between multiplexer and $self
      @_,
   );

   $self->{filter}->add ($self->{multiplexer}) if $self->{filter};
   $self->SUPER::add ($self->{buttonbar}, $self->{filter} || $self->{multiplexer});

   {
      Scalar::Util::weaken (my $wself = $self);

      $self->{multiplexer}->connect (c_add => sub {
         my ($mplex, $widgets) = @_;

         for my $child (@$widgets) {
            Scalar::Util::weaken $child;
            $child->{c_tab_} ||= do {
               my $tab =
                  (UNIVERSAL::isa $child->{c_tab}, "DC::UI::Base")
                     ? $child->{c_tab}
                     : new DC::UI::Button markup => $child->{c_tab}[0], tooltip => $child->{c_tab}[1];

               $tab->connect (activate => sub {
                  $wself->set_current_page ($child);
               });

               $tab
            };

            $self->{buttonbar}->add ($child->{c_tab_});
         }
      });

      $self->{multiplexer}->connect (c_remove => sub {
         my ($mplex, $widgets) = @_;

         for my $child (@$widgets) {
            $wself->{buttonbar}->remove ($child->{c_tab_});
         }
      });
   }

   $self
}

sub add {
   my ($self, @widgets) = @_;

   $self->{multiplexer}->add (@widgets)
}

sub remove {
   my ($self, @widgets) = @_;

   $self->{multiplexer}->remove (@widgets)
}

sub pages {
   my ($self) = @_;
   $self->{multiplexer}->children
}

sub page_index {
   my ($self, $widget) = @_;

   my $i = 0;
   for ($self->pages) {
      if ($_ eq $widget) { return $i };
      $i++;
   }

   undef
}

sub add_tab {
   my ($self, $title, $widget, $tooltip) = @_;

   $title = [$title, $tooltip] unless ref $title;
   $widget->{c_tab} = $title;

   $self->add ($widget);
}

sub get_current_page {
   my ($self) = @_;

   $self->{multiplexer}->get_current_page
}

sub set_current_page {
   my ($self, $page) = @_;

   $self->{multiplexer}->set_current_page ($page);
   $self->emit (page_changed => $self->{multiplexer}{current});
}

sub _draw {
   my ($self) = @_;

   $self->SUPER::_draw ();

   if (my $cur = $self->{multiplexer}{current}) {
      if ($cur = $cur->{c_tab_}) {
         glTranslate $self->{buttonbar}{x} + $cur->{x},
                     $self->{buttonbar}{y} + $cur->{y};
         glLineWidth 3;
         #glEnable GL_BLEND;
         #glBlendFunc GL_ONE, GL_ONE_MINUS_SRC_ALPHA;
         glColor @{$self->{active_outline}};
         glRect_lineloop 1.5, 1.5, $cur->{w} - 1.5, $cur->{h} - 1.5;
         glLineWidth 1;
         #glDisable GL_BLEND;
      }
   }
}

#############################################################################

package DC::UI::Selector;

use utf8;

our @ISA = DC::UI::Button::;

sub new {
   my $class = shift;

   my $self = $class->SUPER::new (
      options => [], # [value, title, longdesc], ...
      value   => undef,
      @_,
   );

   $self->_set_value ($self->{value});

   $self
}

sub invoke_button_down {
   my ($self, $ev) = @_;

   my @menu_items;

   for (@{ $self->{options} }) {
      my ($value, $title, $tooltip) = @$_;

      push @menu_items, [$tooltip || $title, sub { $self->set_value ($value) }];
   }

   DC::UI::Menu->new (items => \@menu_items)->popup ($ev);
}

sub _set_value {
   my ($self, $value) = @_;

   my ($item) = grep $_->[0] eq $value, @{ $self->{options} };
   $item ||= $self->{options}[0]
      or return;

   $self->{value} = $item->[0];
   $self->set_markup ("$item->[1] ⇓");
#   $self->set_tooltip ($item->[2]);
}

sub set_value {
   my ($self, $value) = @_;

   return unless $self->{value} ne $value;

   $self->_set_value ($value);
   $self->emit (changed => $value);
}

sub set_options {
   my ($self, $options) = @_;

   $self->{options} = $options;
   $self->_set_value ($self->{value});
}

#############################################################################

package DC::UI::Statusbox;

our @ISA = DC::UI::VBox::;

sub new {
   my $class = shift;

   my $self = $class->SUPER::new (
      fontsize => 0.8,
      @_,
   );

   DC::weaken (my $this = $self);

   $self->{timer} = EV::timer 1, 1, sub { $this->reorder };

   $self
}

sub reorder {
   my ($self) = @_;
   my $NOW = EV::time;

   # freeze display when hovering over any label
   return if $DC::UI::TOOLTIP->{owner}
             && grep $DC::UI::TOOLTIP->{owner} == $_->{label},
                   values %{ $self->{item} };

   while (my ($k, $v) = each %{ $self->{item} }) {
      delete $self->{item}{$k} if $v->{timeout} < $NOW;
   }

   $self->{timer}->set (1, 1);

   my @widgets;

   my @items = sort {
                  $a->{pri} <=> $b->{pri}
                     or $b->{id} <=> $a->{id}
               } values %{ $self->{item} };

   my $count = 10 + 1;
   for my $item (@items) {
      last unless --$count;

      my $label = $item->{label} ||= do {
         # TODO: doesn't handle markup well (read as: at all)
         my $short = $item->{count} > 1
                     ? "<b>$item->{count} ×</b> $item->{text}"
                     : $item->{text};

         for ($short) {
            s/^\s+//;
            s/\s+/ /g;
         }

         new DC::UI::Label
            markup        => $short,
            tooltip       => $item->{tooltip},
            tooltip_font  => $::FONT_PROP,
            tooltip_width => 0.67,
            fontsize      => $item->{fontsize} || $self->{fontsize},
            max_w         => $::WIDTH * 0.44,
            align         => 0,
            fg            => [@{ $item->{fg} }],
            can_events    => 1,
            can_hover     => 1
      };

      if ((my $diff = $item->{timeout} - $NOW) < 2) {
         $label->{fg}[3] = ($item->{fg}[3] || 1) * $diff / 2;
         $label->update;
         $label->set_max_size (undef, $label->{req_h} * $diff)
            if $diff < 1;
         $self->{timer}->set (1/30, 1/30);
      } else {
         $label->{fg}[3] = $item->{fg}[3] || 1;
      }

      push @widgets, $label;
   }

   my $hash = join ",", @widgets;
   return if $hash eq $self->{last_widget_hash};
   $self->{last_widget_hash} = $hash;

   $self->clear;
   $self->SUPER::add (reverse @widgets);
}

sub add {
   my ($self, $text, %arg) = @_;

   $text =~ s/^\s+//;
   $text =~ s/\s+$//;

   return unless $text;

   my $timeout = (int time) + ((delete $arg{timeout}) || 60);

   my $group = exists $arg{group} ? $arg{group} : ++$self->{id};

   if (my $item = $self->{item}{$group}) {
      if ($item->{text} eq $text) {
         $item->{count}++;
      } else {
         $item->{count} = 1;
         $item->{text} = $item->{tooltip} = $text;
      }
      $item->{id} += 0.2;#d#
      $item->{timeout} = $timeout;
      delete $item->{label};
   } else {
      $self->{item}{$group} = {
         id       => ++$self->{id},
         text     => $text,
         timeout  => $timeout,
         tooltip  => $text,
         fg       => [0.8, 0.8, 0.8, 0.8],
         pri      => 0,
         count    => 1,
         %arg,
      };
   }

   $ROOT->on_refresh (reorder => sub {
      $self->reorder;
   });
}

sub reconfigure {
   my ($self) = @_;

   delete $_->{label}
      for values %{ $self->{item} || {} };

   $self->reorder;
   $self->SUPER::reconfigure;
}

sub destroy {
   my ($self) = @_;

   $self->{timer}->cancel;

   $self->SUPER::destroy;
}

#############################################################################

package DC::UI::Root;

our @ISA = DC::UI::Container::;

use List::Util qw(min max);

use DC::OpenGL;

sub new {
   my $class = shift;

   my $self = $class->SUPER::new (
      visible => 1,
      @_,
   );

   DC::weaken ($self->{root} = $self);

   $self
}

sub size_request {
   my ($self) = @_;

   ($self->{w}, $self->{h})
}

sub _to_pixel {
   my ($coord, $size, $max) = @_;

   $coord =
      $coord eq "center" ? ($max - $size) * 0.5
    : $coord eq "max"    ? $max
    :                      $coord;

   $coord = 0            if $coord < 0;
   $coord = $max - $size if $coord > $max - $size;

   int $coord + 0.5
}

sub invoke_size_allocate {
   my ($self, $w, $h) = @_;

   for my $child ($self->children) {
      my ($X, $Y, $W, $H) = @$child{qw(x y req_w req_h)};

      $X = $child->{force_x} if exists $child->{force_x};
      $Y = $child->{force_y} if exists $child->{force_y};

      $X = _to_pixel $X, $W, $self->{w};
      $Y = _to_pixel $Y, $H, $self->{h};

      $child->configure ($X, $Y, $W, $H);
   }

   1
}

sub coord2local {
   my ($self, $x, $y) = @_;

   ($x, $y)
}

sub coord2global {
   my ($self, $x, $y) = @_;

   ($x, $y)
}

sub update {
   my ($self) = @_;

   $::WANT_REFRESH = 1;
}

sub add {
   my ($self, @children) = @_;

   $_->{is_toplevel} = 1
      for @children;

   $self->SUPER::add (@children);
}

sub remove {
   my ($self, @children) = @_;

   $self->SUPER::remove (@children);

   delete $self->{is_toplevel}
      for @children;

   while (@children) {
      my $w = pop @children;
      push @children, $w->children;
      $w->set_invisible;
   }
}

sub on_refresh {
   my ($self, $id, $cb) = @_;

   $self->{refresh_hook}{$id} = $cb;
}

sub on_post_alloc {
   my ($self, $id, $cb) = @_;

   $self->{post_alloc_hook}{$id} = $cb;
}

sub draw {
   my ($self) = @_;

   while ($self->{refresh_hook}) {
      $_->()
         for values %{delete $self->{refresh_hook}};
   }

   while ($self->{realloc}) {
      my %queue;
      my @queue;
      my $widget;

      outer:
      while () {
         if (my $realloc = delete $self->{realloc}) {
            for $widget (values %$realloc) {
               $widget->{visible} or next; # do not resize invisible widgets

               $queue{$widget+0}++ and next; # duplicates are common

               push @{ $queue[$widget->{visible}] }, $widget;
            }
         }

         while () {
            @queue or last outer;

            $widget = pop @{ $queue[-1] || [] }
               and last;
            
            pop @queue;
         }

         delete $queue{$widget+0};

         my ($w, $h) = $widget->size_request;

         $w += $widget->{padding_x} * 2;
         $h += $widget->{padding_y} * 2;

         $w = max $widget->{min_w}, $w;
         $h = max $widget->{min_h}, $h;

         $w = min $widget->{max_w}, $w if exists $widget->{max_w};
         $h = min $widget->{max_h}, $h if exists $widget->{max_h};

         $w = $widget->{force_w} if exists $widget->{force_w};
         $h = $widget->{force_h} if exists $widget->{force_h};

         if ($widget->{req_w} != $w || $widget->{req_h} != $h
             || delete $widget->{force_realloc}) {
            $widget->{req_w} = $w;
            $widget->{req_h} = $h;

            $self->{size_alloc}{$widget+0} = $widget;

            if (my $parent = $widget->{parent}) {
               $self->{realloc}{$parent+0} = $parent
                  unless $queue{$parent+0};

               $parent->{force_size_alloc} = 1;
               $self->{size_alloc}{$parent+0} = $parent;
            }
         }

         delete $self->{realloc}{$widget+0};
       }

      while (my $size_alloc = delete $self->{size_alloc}) {
         my @queue = sort { $a->{visible} <=> $b->{visible} }
                          values %$size_alloc;

         while () {
            my $widget = pop @queue || last;

            my ($w, $h) = @$widget{qw(alloc_w alloc_h)};

            $w = max $widget->{min_w}, $w;
            $h = max $widget->{min_h}, $h;

#         $w = min $self->{w} - $widget->{x}, $w if $self->{w};
#         $h = min $self->{h} - $widget->{y}, $h if $self->{h};

            $w = min $widget->{max_w}, $w if exists $widget->{max_w};
            $h = min $widget->{max_h}, $h if exists $widget->{max_h};

            $w = int $w + 0.5;
            $h = int $h + 0.5;

            if ($widget->{w} != $w || $widget->{h} != $h || delete $widget->{force_size_alloc}) {
               $widget->{old_w} = $widget->{w};
               $widget->{old_h} = $widget->{h};

               $widget->{w} = $w;
               $widget->{h} = $h;

               $widget->emit (size_allocate => $w, $h);
            }
         }
      }
   }

   while ($self->{post_alloc_hook}) {
      $_->()
         for values %{delete $self->{post_alloc_hook}};
   }

   glViewport 0, 0, $::WIDTH, $::HEIGHT;
   glClearColor +($::CFG->{fow_intensity}) x 3, 1;
   glClear GL_COLOR_BUFFER_BIT;

   glMatrixMode GL_PROJECTION;
   glLoadIdentity;
   glOrtho 0, $::WIDTH, $::HEIGHT, 0, -10000, 10000;
   glMatrixMode GL_MODELVIEW;
   glLoadIdentity;

   {
      package DC::UI::Base;

      local ($draw_x, $draw_y, $draw_w, $draw_h) =
         (0, 0, $self->{w}, $self->{h});

      $self->_draw;
   }
}

#############################################################################

package DC::UI;

$ROOT    = new DC::UI::Root;
$TOOLTIP = new DC::UI::Tooltip z => 900;

1
