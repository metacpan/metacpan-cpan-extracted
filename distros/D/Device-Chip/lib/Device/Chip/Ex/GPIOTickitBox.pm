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

Tickit::Style->load_style( <<'EOSTYLE' );
Button.gpio {
  bg: "black"; fg: "white";
}
Button.gpio:current {
  bg: "white"; fg: "black";
}
Button.gpio:read {
  bg: "red"; fg: "black";
}
GridBox.gpio {
  row_spacing: 1;
  col_spacing: 1;
}
EOSTYLE

sub new
{
   my $class = shift;
   my ( $proto, %args ) = @_;

   my @classes = defined $args{class}   ? ( $args{class} ) :
                 defined $args{classes} ? @{ $args{classes} } : ();
   push @classes, "gpio";

   my $self = $class->SUPER::new( classes => \@classes );

   $self->{protocol} = $proto;

   # Depend on this as a required method now
   my @GPIOs = $proto->meta_gpios;

   foreach my $idx ( 0 .. int( ( $#GPIOs + 7 ) / 8 ) ) {
      my $row = $self->rowcount;

      foreach my $col ( 0 .. 7 ) {
         my $def = $GPIOs[$idx*8 + $col] or next;

         $self->add( $row, $col,
            Tickit::Widget::Static->new(
               text    => $def->name,
               classes => [ $self->style_classes ],
            )
         );

         my ( $hi, $lo, $read ) = $self->make_buttons( $proto, $def );

         $self->add( $row+1, $col, $hi );
         $self->add( $row+2, $col, $lo );
         $self->add( $row+3, $col, $read ) if $read;

         $read->activate if $read;
      }
   }

   # All pins inputs
   $proto->tris_gpios( [ map { $_->name } @GPIOs ] )->get;

   return $self;
}

sub make_buttons
{
   my $self = shift;
   my ( $proto, $def ) = @_;

   my $gpio = $def->name;
   my $dir  = $def->dir;

   my $levelbuttons = $self->{levelbuttons} //= {};
   my $readmode = $self->{readmode} //= {};

   my $check;
   my @buttons;
   @{ $levelbuttons->{$gpio} } = @buttons = map {
      my $hi = ( $_ eq "HI" );

      Tickit::Widget::Button->new(
         label    => $_,
         classes => [ $self->style_classes ],
         on_click => sub {
            my $self = shift;
            return if $readmode->{$gpio};

            $proto->write_gpios( { $gpio => $hi ? 0xFF : 0 } )->get;

            $_->set_style_tag( current => 0 ) for @buttons;
            $self->set_style_tag( current => 1 );
         },
      )
    } qw( HI LO );

    $check = Tickit::Widget::CheckButton->new(
       label => "read",
       classes => [ $self->style_classes ],
       on_toggle => sub {
          my $self = shift;
          if( $self->is_active ) {
             $readmode->{$gpio} = 1;
             $_->set_style_tag( current => 0 ) for @buttons;
             $proto->tris_gpios( [ $gpio ] )->get;
          }
          else {
             $readmode->{$gpio} = 0;
             $_->set_style_tag( read => 0 ) for @buttons;
             $proto->write_gpios( { $gpio =>  0 } )->get;
          }
       },
    ) if $dir eq "rw";

    $readmode->{$gpio} = 1 if $dir eq "r";

    return @buttons, $check;
}

sub update
{
   my $self = shift;

   my $proto = $self->{protocol};

   my $readmode     = $self->{readmode};
   my $levelbuttons = $self->{levelbuttons};

   my @read_gpios = grep { $readmode->{$_} } $proto->list_gpios;

   $proto->read_gpios( \@read_gpios )->on_done( sub {
      my ( $vals ) = @_;

      foreach my $gpio ( keys %$vals ) {
         next unless $readmode->{$gpio};
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
