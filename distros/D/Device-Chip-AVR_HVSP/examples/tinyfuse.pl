#!/usr/bin/perl

use v5.26;
use warnings;

use Tickit;
use Tickit::Widgets qw( VBox HBox Button Static GridBox CheckButton Choice );
use Tickit::ContainerWidget 0.59; # ->add returns $self

use Device::BusPirate;
use Getopt::Long;

Tickit::Style->load_style( <<'EOF' );
HBox { spacing: 1; }

CheckButton:active { fg: "green"; check-fg: "green"; }
EOF

GetOptions(
   'p|pirate=s' => \my $PIRATE,
   'b|baud=i'   => \my $BAUD,
   'n|no-chip'  => \my $NO_CHIP,
   'f|fuses=s'  => \my $FUSEVALUES,
) or exit 1;

my $avr;
unless( $NO_CHIP ) {
   my $pirate = Device::BusPirate->new(
      serial => $PIRATE,
      baud   => $BAUD,
   );
   END { $pirate and $pirate->stop; }

   $avr = $pirate->mount_chip( "AVR_HVSP" )->get;

   $avr->start->get;
   END { $avr and $avr->stop->get; }

   # Powerdown after initial read
   $avr->all_power(0)->get;
}

my $partname = $avr ? $avr->partname : "ATtiny841";
my $fuseinfo = $avr ? $avr->fuseinfo : Device::BusPirate::Chip::AVR_HVSP::FuseInfo->for_part( "ATtiny841" );
my $has_efuse = grep { $_->offset > 1 } $fuseinfo->fuses;

my $tickit = Tickit->new(
   root => Tickit::Widget::VBox->new( spacing => 1 )
      ->add( Tickit::Widget::HBox->new( spacing => 2 )
         ->add( Tickit::Widget::Static->new(
              text => "Device: " . $partname
         ), expand => 1 )
         ->add( my $fuselabel = Tickit::Widget::Static->new(
              text => "Fuses: "
         ), expand => 1 )
      )
      ->add( Tickit::Widget::HBox->new( spacing => 2 )
         ->add( Tickit::Widget::Button->new(
               label => "Default",
               on_click => \&default_fuses,
            ), expand => 1 )
         ->add( Tickit::Widget::Button->new(
               label => "Read",
               on_click => \&read_fuses,
            ), expand => 1 )
         ->add( Tickit::Widget::Button->new(
               label => "Write",
               on_click => \&write_fuses,
            ), expand => 1 )
      )
      ->add( my $fusegrid = Tickit::Widget::GridBox->new(
            col_spacing => 2,
         ), expand => 1 )
);

my %fuses; # $name => [ $value, $on_read ]

sub def_fuse
{
   my ( $name ) = @_;

   my $row = $fusegrid->rowcount;
   $fusegrid->add( $row, 0,
      Tickit::Widget::Static->new(
         text => $name,
      )
   );

   return $row;
}

sub def_boolfuse
{
   my ( $name, $caption ) = @_;
   my $row = def_fuse( $name );

   $fusegrid->add( $row, 1,
      my $check = Tickit::Widget::CheckButton->new(
         label => $caption,
         on_toggle => sub {
            $fuses{$name}[0] = !$_[1];
            render_fuse_label();
         },
      )
   );

   $fuses{$name}[1] = sub { $_[0] ? $check->deactivate : $check->activate };
}

sub def_intfuse
{
   my ( $name, $caption, $values ) = @_;
   my $row = def_fuse( $name );

   $fusegrid->add( $row, 1, Tickit::Widget::Static->new( text => $caption ) );

   $fusegrid->add( $row+1, 1,
      my $choice = Tickit::Widget::Choice->new
   );

   foreach my $val ( @$values ) {
      $choice->push_choice( $val->value => $val->caption );
   }

   $choice->set_on_changed( sub {
      my ( undef, $value ) = @_;
      $fuses{$name}[0] = $value;
      render_fuse_label();
   });

   $fuses{$name}[1] = sub {
      eval { $choice->choose_by_value( $_[0] ) };
   };
}

foreach my $fuse ( $fuseinfo->fuses ) {
   if( my $values = $fuse->values ) {
      def_intfuse $fuse->name, $fuse->caption, $values;
   }
   else {
      def_boolfuse $fuse->name, $fuse->caption;
   }
}

our $LOADING;

sub render_fuse_label
{
   return if $LOADING;

   my $fusebytes = $fuseinfo->pack( map { $_ => $fuses{$_}[0] } keys %fuses );
   $fuselabel->set_text( sprintf "Fuses: %v02x", $fusebytes );
}

sub default_fuses
{
   # These from the ATtiny24/44/84 data sheet
   my %fusevals = (
      SELFPRGEN => 1,
      RSTDISBL  => 1,
      DWEN      => 1,
      SPIEN     => 0,
      WDTON     => 1,
      EESAVE    => 1,
      BODLEVEL  => 0x07,
      CKDIV8    => 0,
      CKOUT     => 1,
      SUT       => 0x02,
      CKSEL     => 0x02,
   );

   $fuses{$_}[0] = $fusevals{$_} for keys %fusevals;

   foreach my $name ( keys %fusevals ) {
      $fuses{$name}[1]->( $fusevals{$name} ) if $fuses{$name}[1];
   }
}

sub read_fuses
{
   my $lfuse;
   my $hfuse;
   my $efuse;

   if( $avr ) {
      $avr->all_power(1)->get;

      $lfuse = $avr->read_lfuse->get,
      $hfuse = $avr->read_hfuse->get,
      $efuse = ( $has_efuse ? $avr->read_efuse->get : "" ),

      $avr->all_power(0)->get;
   }
   else {
      ( $lfuse, $hfuse, $efuse ) = map { chr hex } split m/:/, $FUSEVALUES;
   }

   my %fusevals = $fuseinfo->unpack( join "", $lfuse, $hfuse, $efuse );

   $fuselabel->set_text( sprintf "Fuses: %v02x", $lfuse.$hfuse.$efuse );
   $fuses{$_}[0] = $fusevals{$_} for keys %fusevals;

   local $LOADING = 1;

   foreach my $name ( keys %fusevals ) {
      $fuses{$name}[1]->( $fusevals{$name} ) if $fuses{$name}[1];
   }
}

sub write_fuses
{
   $avr->all_power(1)->get;

   my $fusebytes = $fuseinfo->pack( map { $_ => $fuses{$_}[0] } keys %fuses );

   $avr->write_lfuse( substr $fusebytes, 0, 1 )->get;
   $avr->write_hfuse( substr $fusebytes, 1, 1 )->get;
   $avr->write_efuse( substr $fusebytes, 2, 1 )->get if $has_efuse;

   $avr->all_power(0)->get;
}

$tickit->run;
