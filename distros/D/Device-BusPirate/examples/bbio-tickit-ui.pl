#!/usr/bin/perl

use strict;
use warnings;

use Tickit;
use Tickit::Widgets 0.30 qw( GridBox Button Static VBox CheckButton );
use Device::BusPirate;
use Getopt::Long;

GetOptions(
   'p|pirate=s' => \my $PIRATE,
   'b|baud=i'   => \my $BAUD,
) or exit 1;

my $pirate = Device::BusPirate->new(
   serial => $PIRATE,
   baud   => $BAUD,
);

my $bb = $pirate->enter_mode( "BB" )->get;

my $tickit = Tickit->new(
   root => my $grid = Tickit::Widget::GridBox->new(
      style => {
         row_spacing => 1,
         col_spacing => 2,
      },
   )->append_row( [ Tickit::Widget::Static->new( text => "Line", heading => 1 ) ] ),
);
$tickit->term->await_started( 0.05 );

Tickit::Style->load_style( <<'EOSTYLE' );
Static.heading {
  b: 1;
}

Static.miso { bg: "brown";  fg: "white"; }
Static.cs   { bg: "red";    fg: "white"; }
Static.mosi { bg: "orange"; fg: "black"; }
Static.clk  { bg: "yellow"; fg: "black"; }
Static.aux  { bg: "green";  fg: "black"; }

Button {
  bg: "black"; fg: "white";
}
Button:current {
  bg: "white"; fg: "black";
}

Button.miso:input { bg: "brown";  fg: "white"; }
Button.cs  :input { bg: "red";    fg: "white"; }
Button.mosi:input { bg: "orange"; fg: "black"; }
Button.clk :input { bg: "yellow"; fg: "black"; }
Button.aux :input { bg: "green";  fg: "black"; }

EOSTYLE

my %buttons;

my %pin_keys = (
   power => 'p',
   aux   => 'a',
   clk   => 'c',
   mosi  => 'o',
   cs    => 's',
   miso  => 'i'
);
foreach my $pin (qw( power aux clk mosi cs miso )) {
   my $row = $grid->rowcount;
   my $key = $pin_keys{$pin};

   $grid->add( $row, 0,
      Tickit::Widget::Static->new( text => "\U$pin\E\n\U$key\E / $key",
         class => $pin,
      ),
      row_expand => 1,
   );

   $grid->add( $row, 1,
      my $btn_on = $buttons{$pin}[1] = Tickit::Widget::Button->new( label => "on",
         class => $pin,
         on_click => sub { set_pin( $pin, 1 ) }
      ),
      col_expand => 1,
      row_expand => 1,
   );

   $grid->add( $row, 2,
       my $btn_off = $buttons{$pin}[0] = Tickit::Widget::Button->new( label => "off",
         class => $pin,
         on_click => sub { set_pin( $pin, 0 ) }
      ),
      col_expand => 1,
      row_expand => 1,
   );

   # Key bindings
   $tickit->bind_key( lc $key => sub { $btn_off->click } );
   $tickit->bind_key( uc $key => sub { $btn_on->click  } );

   if( $pin eq "power" ) {
      # Power can't be set to read mode
      $btn_off->set_style_tag( current => 1 );
      next;
   }

   $grid->add( $row, 3,
      my $btn_read = $buttons{$pin}[2] = Tickit::Widget::Button->new( label => "read",
         on_click => sub { set_pin_input( $pin ) }
      ),
      col_expand => 1,
      row_expand => 1,
   );

   # Initial states - all are read
   $btn_read->set_style_tag( current => 1 );
}

# Stick a couple of checkbuttons in the spare 'power' slot

$grid->add( 1, 3, Tickit::Widget::VBox->new
   ->add(
      Tickit::Widget::CheckButton->new(
         label => "Pullup",
         on_toggle => sub {
            my ( undef, $pullup ) = @_;
            $bb->pullup( $pullup )->get;
         },
      )
   )
   ->add(
      Tickit::Widget::CheckButton->new(
         label => "Open-drain",
         on_toggle => sub {
            my ( undef, $opendrain ) = @_;
            $bb->configure( open_drain => $opendrain )->get;
         },
      )
   )
);

sub _tick
{
   my $pins = $bb->read->get;
   foreach my $pin ( keys %$pins ) {
      my $val = !!$pins->{$pin};
      $buttons{$pin}[$_]->set_style_tag( input => not( $val ^ $_ ) ) for 0 .. 1;
   }

   $tickit->timer( after => 0.05, \&_tick );
}

_tick;
$tickit->run;

END {
   $pirate and $pirate->stop;
}

sub set_pin
{
   my ( $pin, $val ) = @_;

   $bb->$pin( $val )->get;

   $buttons{$pin}[0]->set_style_tag( current =>  !$val );
   $buttons{$pin}[1]->set_style_tag( current => !!$val );
   $buttons{$pin}[2]->set_style_tag( current =>      0 ) if $buttons{$pin}[2];
   $buttons{$pin}[$_]->set_style_tag( input => 0 ) for 0 .. 1;
}

sub set_pin_input
{
   my ( $pin ) = @_;

   $bb->${\"read_$pin"}()->get; # Ignore it for now

   $buttons{$pin}[0]->set_style_tag( current => 0 );
   $buttons{$pin}[1]->set_style_tag( current => 0 );
   $buttons{$pin}[2]->set_style_tag( current => 1 );
}
