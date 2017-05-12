#! perl

package main;

our $cfg;
our $state;
our $app;
our $dbh;

package EB::Wx::Shell::Window;

use strict;
use warnings;

use Wx qw[
	  wxACCEL_CTRL
	  wxACCEL_NORMAL
	  wxID_CLOSE
	  wxTHICK_FRAME
       ];

sub sizepos_save {
    my ($self, $posonly) = @_;
    my $config = Wx::ConfigBase::Get;

    my ( $x, $y  ) = $self->GetPositionXY;
    $config->WriteInt( "windows/".$self->{mew}."/xpos", $x );
    $config->WriteInt( "windows/".$self->{mew}."/ypos", $y );

    unless ( $posonly ) {
	($x, $y) = ( Wx::wxMAC )
	           ? $self->GetClientSizeWH
	           : $self->GetSizeWH ;
	$config->WriteInt( "windows/".$self->{mew}."/xwidth", $x );
	$config->WriteInt( "windows/".$self->{mew}."/ywidth", $y );
    }
}

sub sizepos_restore {
    my ($self, $mew, $posonly) = @_;
    $self->{mew} = $mew if defined $mew;
    my $config = Wx::ConfigBase::Get;

    my $x = $config->ReadInt( "windows/".$self->{mew}."/xpos", -1 );
    my $y = $config->ReadInt( "windows/".$self->{mew}."/ypos", -1 );
    $self->Move( $x, $y ) if $x >= 0 && $y >= 0;

    unless ( $posonly ) {
	$x = $config->ReadInt( "windows/".$self->{mew}."/xwidth", -1 );
	$y = $config->ReadInt( "windows/".$self->{mew}."/ywidth", -1 );
	if ( $x >= 0 && $y >= 0 ) {
	    $self->SetSize( $x, $y );
	    $self->SetClientSize([$x, $y]) if Wx::wxMAC();
	}
	else {
	    $self->SetSize(0, 0, $self->GetSizeWH);
	    $self->Center;
	}
    }

    # For convenience: CLOSE on Ctrl-W and Esc.
    # (Doesn't work on GTK, yet).
    $self->SetAcceleratorTable
      (Wx::AcceleratorTable->new
       ( [wxACCEL_CTRL, ord 'w', wxID_CLOSE],
	 [wxACCEL_NORMAL, 27, wxID_CLOSE],
       ));

}

#### Override
sub init {
    shift->refresh(@_);
}

#### Override
sub refresh {
}

# wxGlade insists on generating these.
sub Wx::wxTHICK_FRAME() { 0 }		# removed 2.x
sub Wx::wxADJUST_MINSIZE() { 0 }	# bogus 2.8, removed in 2.9

1;
