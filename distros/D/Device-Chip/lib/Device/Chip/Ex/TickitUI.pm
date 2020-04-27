#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2016-2018 -- leonerd@leonerd.org.uk

package Device::Chip::Ex::TickitUI;

use strict;
use warnings;
use utf8;

use Syntax::Keyword::Try;

use Device::Chip::Ex::GPIOTickitBox;
use Device::Chip::Ex::SPITickitBox;

use Tickit;
use Tickit::Widgets qw( VBox CheckButton Tabbed );

Tickit::Style->load_style( <<'EOSTYLE' );
Entry {
  bg: "green"; fg: "black";
}
Choice {
  bg: "green"; fg: "black";
}
EOSTYLE

sub run
{
   shift;
   my ( $adapter, %args ) = @_;

   my $vbox = Tickit::Widget::VBox->new(
      style => {
         spacing => 1,
      },
   );

   my $protocol;

   $vbox->add(
      Tickit::Widget::CheckButton->new(
         label => "power",
         on_toggle => sub {
            my $self = shift;
            $protocol->power( $self->is_active )->get;
         },
      )
   );

   $vbox->add(
      my $tabbed = Tickit::Widget::Tabbed->new,
      expand => 1,
   );

   my $updatesub;
   my $initialtab;

   foreach my $protoname (qw( GPIO SPI )) {
      my $tab = $tabbed->add_tab( Tickit::Widget::VBox->new,
         label => $protoname,
      );

      $tab->set_on_activated( my $activatesub = sub {
         my ( $tab ) = @_;
         my $vbox = $tab->widget;

         try {
            $protocol = $adapter->make_protocol( $protoname )->get;
         }
         catch {
            $vbox->add( Tickit::Widget::Static->new(
               text => "$protoname is not supported",
               align => "centre",
               style => {
                  bg => "red",
               },
            ) );
            return;
         }

         my $method = "activate_$protoname";
         __PACKAGE__->$method( $protocol, $vbox, \$updatesub );
      } );

      $tab->set_on_deactivated( sub {
         my ( $tab ) = @_;
         my $widget = $tab->widget;

         $widget->remove( $_ ) for $widget->children;
         undef $updatesub;
      } );

      if( $protoname eq $args{startmode} ) {
         $tabbed->activate_tab( $tab->index );
         $activatesub->( $tab ) if !$tab->index; # ->activate_tab(0) won't run this
      }
   }

   my $tickit = Tickit->new( root => $vbox );
   $tickit->term->await_started( 0.5 );

   my $update;
   $update = sub {
      $updatesub and $updatesub->();
      $tickit->timer( after => 0.05, $update );
   };

   $update->();

   $tickit->run;
}

sub activate_GPIO
{
   shift;
   my ( $protocol, $vbox, $updateref ) = @_;

   $vbox->add( my $gpiobox = Device::Chip::Ex::GPIOTickitBox->new( $protocol ) );

   $$updateref = sub { $gpiobox->update };
}

sub activate_SPI
{
   shift;
   my ( $protocol, $vbox, $updateref ) = @_;

   $vbox->add( my $spibox = Device::Chip::Ex::SPITickitBox->new( $protocol ) );
}

0x55AA;
