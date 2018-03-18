#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2018 -- leonerd@leonerd.org.uk

package Device::Chip::Ex::GPIOTickitBox;

use strict;
use warnings;

use base 'Tickit::Widget::GridBox';

use Tickit;
use Tickit::Widgets qw( GridBox Button CheckButton Static );

sub new
{
   my $class = shift;
   my ( $proto ) = @_;

   my $self = $class->SUPER::new(
      style => {
         row_spacing => 1,
         col_spacing => 1,
      },
   );

   $self->{protocol} = $proto;

   my @GPIOs = $proto->list_gpios;

   foreach my $idx ( 0 .. int( ( $#GPIOs + 7 ) / 8 ) ) {
      my $row = $self->rowcount;

      foreach my $col ( 0 .. 7 ) {
         my $gpio = $GPIOs[$idx*8 + $col] or next;

         $self->add( $row, $col,
            Tickit::Widget::Static->new( text => $gpio )
         );

         my ( $hi, $lo, $read ) = $self->make_buttons( $gpio, $proto );

         $self->add( $row+1, $col, $hi );
         $self->add( $row+2, $col, $lo );
         $self->add( $row+3, $col, $read );

         $read->activate;
      }
   }

   # All pins inputs
   $proto->tris_gpios( [ @GPIOs ] )->get;

   return $self;
}

sub make_buttons
{
   my $self = shift;
   my ( $gpio, $proto ) = @_;

   my $levelbuttons = $self->{levelbuttons} //= {};

   my $check;
   my @buttons;
   @{ $levelbuttons->{$gpio} } = @buttons = map {
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

    my $dirbuttons = $self->{directionbuttons} //= {};

    $dirbuttons->{$gpio} = $check = Tickit::Widget::CheckButton->new(
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

sub update
{
   my $self = shift;

   my $proto = $self->{protocol};

   my $dirbuttons   = $self->{directionbuttons};
   my $levelbuttons = $self->{levelbuttons};

   my @read_gpios = grep { $dirbuttons->{$_}->is_active } $proto->list_gpios;

   $proto->read_gpios( \@read_gpios )->on_done( sub {
      my ( $vals ) = @_;

      foreach my $gpio ( keys %$vals ) {
         next unless $dirbuttons->{$gpio}->is_active;
         my $bitval = $vals->{$gpio};

         # HI
         $levelbuttons->{$gpio}[0]->set_style_tag(
            read => !!$bitval,
         );
         # LO
         $levelbuttons->{$gpio}[1]->set_style_tag(
            read =>  !$bitval,
         );
      }
   })->get; # Yes, synchronous
}

0x55AA;
