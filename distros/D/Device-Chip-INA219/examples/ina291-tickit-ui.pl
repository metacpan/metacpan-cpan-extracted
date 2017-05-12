#!/usr/bin/perl

use strict;
use warnings;

use Device::Chip::INA219;
use Device::Chip::Adapter;
use Getopt::Long;
use Tickit;
use Tickit::Widgets qw( HBox VBox Static SegmentDisplay );
Tickit::Widget::SegmentDisplay->VERSION( '0.03' ); # seven-dp, symbols

GetOptions(
   'adapter|A=s' => \( my $ADAPTER = "BusPirate" ),
   'mount|M=s'   => \( my $MOUNTPARAMS ),
) or exit 1;

my $ina = Device::Chip::INA219->new;

$ina->mount_from_paramstr(
   Device::Chip::Adapter->new_from_description( $ADAPTER ),
   $MOUNTPARAMS,
)->get;

$ina->protocol->power(1)->get;

$ina->change_config(
   BADC => 4,
   SADC => 4,
   PG   => "80mV",
)->get;

$SIG{TERM} = $SIG{INT} = sub { exit };

my $tickit = Tickit->new(
   root => my $vbox = Tickit::Widget::VBox->new,
);

$vbox->add(
   my $display_v = LEDDisplay->new( digits => 4, units => "V" ),
   expand => 1,
);
$vbox->add(
   my $display_i = LEDDisplay->new( digits => 3, units => "mA" ),
   expand => 1,
);

sub tick
{
   my $vbus = $ina->read_bus_voltage->get / 1000;
   $display_v->set_value( sprintf "%.3f", $vbus );

   my $vshunt = $ina->read_shunt_voltage->get;
   # Module has a 0.1ohm shunt resistor
   my $ishunt = $vshunt / 0.1;

   $display_i->set_value( sprintf "% 3.1f", $ishunt / 1000 );

   $tickit->timer( after => 0.1, \&tick );
}

tick();

$tickit->run;

END {
   $ina->protocol->power(0)->get if $ina;
}

package LEDDisplay {
   use base qw( Tickit::Widget::Box );

   use constant DIGIT_HEIGHT =>  9;
   use constant DIGIT_WIDTH  => 10;

   sub new
   {
      my $class = shift;
      my %params = @_;

      my $n_digits = delete $params{digits};
      my $units    = delete $params{units};

      my $self = $class->SUPER::new(
         %params,
         child => my $hbox = Tickit::Widget::HBox->new,
         # Force the size of the digits so they look nice
         child_lines => DIGIT_HEIGHT,
         child_cols  => ( $n_digits + length $units ) * ( DIGIT_WIDTH + 2 ), # +2 for DP
      );

      my @digits = map { Tickit::Widget::SegmentDisplay->new(
         type => "seven_dp",
      ) } 1 .. $n_digits;

      $self->{digits} = \@digits;
      $hbox->add( $_, expand => 1 ) for @digits;

      $hbox->add( Tickit::Widget::SegmentDisplay->new(
         type  => "symb",
         value => $_
      ), expand => 1 ) for split m//, $units;

      return $self;
   }

   sub set_value
   {
      my $self = shift;
      my ( $value ) = @_;

      my $idx = 0;
      my $digits = $self->{digits};

      foreach my $v ( $value =~ m/(.\.?)/g ) {
         $digits->[$idx++]->set_value( $v );
         last if $idx == scalar @$digits;
      }
   }
}
