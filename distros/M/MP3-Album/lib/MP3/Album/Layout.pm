package MP3::Album::Layout;

use strict;

our $VERSION = '0.01';

sub new {
  my $s = shift;

  my $b = {
	title     => 'unknown',
	artist    => 'unknown',
	genre     => 'unknown',
	year      => '',
	comment   => '',
	location  => '',
	tracks    => []
  };

  return bless $b, $s;
}

sub edit_track {
   my $s = shift;
   my %a = @_;

   unless ($a{position}) {
   	$@ = "missing param position";
	return undef;
   }

   unless ($a{artist} || $a{title}) {
	$@ = "missing param title or artist";
   }

   $s->{tracks}->[$a{position}+1]->{artist} = $a{artist} if $a{artist};
   $s->{tracks}->[$a{position}+1]->{artist} = $a{title}  if $a{title};
   
   return 1;
}

sub info {
   my $s = shift;

   return $s;
}

sub add_track {
   my $s = shift;
   my %a = @_;

   push @{$s->{tracks}}, {  'artist'  => $a{artist}, 
   			    'title'   => $a{title}, 
			    'lenght'  => $a{lenght} 
			 };

   return 1; 
}

sub artist {
   my $s = shift;
   
   $s->{artist} = $_[0] if @_;
   return $s->{artist};
}

sub genre {
   my $s = shift;
   
   $s->{genre} = $_[0] if @_;
   return $s->{genre};
}

sub comment {
   my $s = shift;
   
   $s->{comment} = $_[0] if @_;
   return $s->{comment};
}

sub title {
   my $s = shift;
   $s->{title} = $_[0] if @_;

   return $s->{title};
}
1;
