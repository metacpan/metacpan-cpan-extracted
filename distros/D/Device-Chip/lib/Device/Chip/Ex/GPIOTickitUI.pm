#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2016 -- leonerd@leonerd.org.uk

package Device::Chip::Ex::GPIOTickitUI;

use strict;
use warnings;

use Tickit;
use Tickit::Widgets qw( GridBox Button CheckButton Static );

Tickit::Style->load_style( <<'EOSTYLE' );
Button {
  bg: "black"; fg: "white";
}
Button:current {
  bg: "white"; fg: "black";
}
Button:read {
  bg: "red"; fg: "black";
}
EOSTYLE

my %dirbuttons;
my %levelbuttons;

sub make_buttons
{
   my ( $gpio, $proto ) = @_;

   my $check;
   my @buttons;
   @{ $levelbuttons{$gpio} } = @buttons = map {
      my $hi = ( $_ eq "HI" );

      Tickit::Widget::Button->new(
         label    => $_,
         on_click => sub {
            my $self = shift;
            return if $check->is_active;

            $proto->write_gpios( { $gpio => $hi ? 0xFF : 0 } )->get;

            $_->set_style_tag( current => 0 ) for @buttons;
            $self->set_style_tag( current => 1 );
         },
      )
    } qw( HI LO );

    $dirbuttons{$gpio} = $check = Tickit::Widget::CheckButton->new(
       label => "read",
       on_toggle => sub {
          my $self = shift;
          if( $self->is_active ) {
             $_->set_style_tag( current => 0 ) for @buttons;
             $proto->tris_gpios( [ $gpio ] )->get;
          }
          else {
             $_->set_style_tag( read => 0 ) for @buttons;
             $proto->write_gpios( { $gpio =>  0 } )->get;
          }
       },
    );

    return @buttons, $check;
}

sub update_buttons
{
   my ( $proto ) = @_;

   my @read_gpios = grep { $dirbuttons{$_}->is_active } $proto->list_gpios;

   $proto->read_gpios( \@read_gpios )->on_done( sub {
      my ( $vals ) = @_;

      foreach my $gpio ( keys %$vals ) {
         next unless $dirbuttons{$gpio}->is_active;
         my $bitval = $vals->{$gpio};

         # HI
         $levelbuttons{$gpio}[0]->set_style_tag(
            read => !!$bitval,
         );
         # LO
         $levelbuttons{$gpio}[1]->set_style_tag(
            read =>  !$bitval,
         );
      }
   });
}

sub run
{
   shift;
   my ( $adapter ) = @_;

   my $proto = $adapter->make_protocol( "GPIO" )->get;

   my @GPIOs = $proto->list_gpios;

   my $grid = Tickit::Widget::GridBox->new(
       style => {
           row_spacing => 1,
           col_spacing => 1,
       },
   );

   $grid->add( 0, 0,
      Tickit::Widget::CheckButton->new(
         label => "power",
         on_toggle => sub {
            my $self = shift;
            $proto->power( $self->is_active )->get;
         },
      )
   );

   foreach my $idx ( 0 .. int( ( $#GPIOs + 7 ) / 8 ) ) {
       my $row = $grid->rowcount;

       foreach my $col ( 0 .. 7 ) {
           my $gpio = $GPIOs[$idx*8 + $col] or next;

           $grid->add( $row, $col,
               Tickit::Widget::Static->new( text => $gpio )
           );

           my ( $hi, $lo, $read ) = make_buttons( $gpio, $proto );

           $grid->add( $row+1, $col, $hi );
           $grid->add( $row+2, $col, $lo );
           $grid->add( $row+3, $col, $read );

           $read->activate;
       }
   }

   # All pins inputs
   $proto->tris_gpios( [ @GPIOs ] )->get;

   my $tickit = Tickit->new( root => $grid );

   my $read_pins;
   $read_pins = sub {
      update_buttons( $proto )->get;

      $tickit->timer( after => 0.05, $read_pins );
   };

   $read_pins->();

   $tickit->run;
}

0x55AA;
