package Foo;

use Gtk2;
use POE;
use base qw(Glade2::Widget);

sub new {
   my ($class) = @_;

   my $file = 'widget.glade';
   my $widget_name = 'vbox1';
   $class->SUPER::new (file => $file, widget => $widget_name);
}

sub on_button1_clicked {
   print "click\n";
}

package Bar;

use Gtk2;
use POE;
use POE::Session::GladeXML2;

sub new {
   my ($class) = @_;

   my $self = {};
   bless $self, $class;
   my $s = POE::Session::GladeXML2->create (
	       glade_object => $self,
	       glade_file => 'testwidget.glade',
	    );
   my $win = $s->gladexml->get_widget ('window1');
   $poe_kernel->signal_ui_destroy ($win);

   $self->{'session'} = $s;
   return $self;
}

package main;

use Gtk2;
use Gtk2::GladeXML;
use POE;

my $bar = Bar->new;
POE::Kernel->run;
