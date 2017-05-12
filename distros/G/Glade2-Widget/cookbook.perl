package Counter;

use Gtk2;
use POE;
use base qw(Glade2::Widget);

sub new {
   my ($class, $name, undef, undef, $inc, undef) = @_;

   my $file = 'cookbookwidget.glade';
   my $widget_name = 'counter';
   my $self = $class->SUPER::new (
	 file => $file,
	 widget => $widget_name,
	 name => $name,
	 states => [qw(
	    increase_counter
	 )],
      );
   $self->{'inc'} = $inc;
   $self->yield ('increase_counter');

   return $self;
}

sub increase_counter {
   my ($self, $kernel) = @_[OBJECT, KERNEL];

   my $label = $self->{'xml'}->get_widget ('counter_label');
   $self->{'counter'} += $self->{'inc'};
   $label->set_text ($self->{'counter'});
   my $name = $self->{'name'};
   $self->yield ('increase_counter');
}

sub clear_counter {
   my ($self) = $_[OBJECT];

   $self->{'counter'} = 0;
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
	       glade_file => 'cookbook.glade',
	       glade_mainwin => 'window1',
	    );

   return $self;
}

package main;

use Gtk2;
use Gtk2::GladeXML;
use POE;

my $bar = Bar->new;
POE::Kernel->run;
