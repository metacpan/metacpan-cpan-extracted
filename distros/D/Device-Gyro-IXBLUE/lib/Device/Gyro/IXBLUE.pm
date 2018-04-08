package Device::Gyro::IXBLUE;

use Data::Dumper; 

use 5.010001;
#use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# This allows declaration   use Device::Gyro::IXBLUE ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
    
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
    
);

our $VERSION = '1.0';

sub new 
{
    my $class = shift;
    my $arg_ref = shift;

    my $self = $arg_ref;
    bless $self, $class;

    $self->{'NMEADATA'} = {};
    $self->{'err_msg'} = '';

    $self;
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub get_nmea_buf
{
  my $self   = shift @_; 
  $self->{'NMEADATA'} = {};
  $self->{'sentence_fnd'} = {};
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub clr_nmea_buf
{
  my $self   = shift @_; 
  $self->{'NMEADATA'} = {};
  $self->{'sentence_fnd'} = {};
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub process_paragraph
{
  my $self   = shift @_; 
  my @ln_lst = @{shift @_}; 

  $self->{err_msg_paragraph}=[];
  $self->{'NMEADATA'}= {};
  
  foreach my $ln ( @ln_lst ) 
  {
    my $rtn = $self->process_sentence($ln); 
    
    unless ( $rtn ) { push @{ $self->{err_msg_paragraph} }, $self->{err_msg} }
  } 

  return $self->{'NMEADATA'}; 
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
sub process_sentence {
    my($self, $line) = @_;

    # Remove trailing chars
    chomp($line); $line =~ s/\r//g;

    # Test checksum
    if ($line =~  s/\*(\w\w)$//) {
       my $csum = $1;
       $csum_calc = $self->checksum($line);

      if ( $csum ne $csum_calc ) { 
        $self->{err_msg} = "Checksum fail";
        return undef 
      }
    }
    else { 
        $self->{err_msg} = "Improper formed sentence";
        return undef 
    }
    
    $line =~ s/^\$//; 
    my @cmd_lst = split ',',$line;

    my $func = $cmd_lst[0];
    
    if ( $cmd_lst[0] eq 'PIXSE' ) {
       $func = "$cmd_lst[0]_$cmd_lst[1]"; 
    }

    print "COMMAND: $func\n" if $self->{verbose};
    if ($self->can($func)) {
        $self->$func(@cmd_lst);  # Calling via symbolic reference... where the work is done
      $self->{sentence_fnd}->{$func} = 1 ;
    } 
    elsif ($self->{verbose}) {  print "Can't handle $func\n"; } 

    return $self->{'NMEADATA'}; 
}



# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
sub sentences_fnd
{
    my $self = shift @_;

    return $self->{'sentences_fnd'};
}


sub nmea_data_dump {
    #dumps data received
    my $self = shift;
    my $d = $self->{NMEADATA};
    print map {"$_ => $$d{$_}\n"} sort keys %{$self->{NMEADATA}};
}

# Calculate the checksum
#
sub checksum {
    my ($self,$line) = @_;
    my $csum = 0;
    $csum ^= unpack("C",(substr($line,$_,1))) for(1..length($line)-1);

    print "Checksum: $csum\n" if $self->{verbose};
    return (sprintf("%2.2X",$csum));
}


####################### NMEA MESSAGE HANDLERS ######################
#  IXBLUE Stuff 
#################################################################### 


# $HEHDT,105.325,T*2F
#
# $HEHDT,xxx.xxx,T*hh<CR><LF>

# 1) x.xx heading degrees 
# 2) T - true heading 

sub HEHDT {
    my $self = shift;
    $self->{NMEADATA} = {} unless ref($self->{NMEADATA});
    my $d = $self->{NMEADATA};

    (undef,
     $$d{heading},
    ) = @_;
    1;
}

# $PIXSE,ATITUD,-0.035,0.445*4C
#
# $PIXSE,ATITUD,xxx.xxx,xxx.xxx*hh<CR><LF>

# 1) xx.xx roll degrees 
# 2) xx.xx pitch degrees 
sub PIXSE_ATITUD {
    my $self = shift;
    $self->{NMEADATA} = {} unless ref($self->{NMEADATA});
    my $d = $self->{NMEADATA};

    (undef,undef,
     $$d{roll},
     $$d{pitch},
    ) = @_;
    1;
}

# $PIXSE,POSITI,47.98095919,243.43224120,445.497*54
#
# $PIXSE,POSITI,xxx.xxx,xxx.xxx,xx.xxx*hh<CR><LF>

# 1) xx.xx Lat degrees 
# 2) xx.xx Long degrees 
# 3) xx.xx Long degrees 
sub PIXSE_POSITI {
    my $self = shift;
    $self->{NMEADATA} = {} unless ref($self->{NMEADATA});
    my $d = $self->{NMEADATA};

    (undef,undef,
     $$d{lat},
     $$d{long},
     $$d{alt},
    ) = @_;
    1;
}

# $PIXSE,SPEED_,-0.017,0.004,-0.000*63
#
# $PIXSE,SPEED,xxx.xxx,xxx.xxx,xx.xxx*hh<CR><LF>

# 1) x.xxx Speed XEast in m/s (East speed)
# 2) y.yyy Speed XNorth in m/s (North speed)
# 3) z.zzz Speed XUP in m/s (Sign “+” towards up side)
sub PIXSE_SPEED_ {
    my $self = shift;
    $self->{NMEADATA} = {} unless ref($self->{NMEADATA});
    my $d = $self->{NMEADATA};

    (undef,undef,
     $$d{v_east},
     $$d{v_north},
     $$d{v_up},
    ) = @_;
    1;
}

# $PIXSE,HEAVE_,0.000,-0.000,-0.002*7B
#
# $PIXSE,HEAVE_,x.xxx,y.yyy,z.zzz*hh<CR><LF>
#
# x.xxx surge in meters (signed)
# y.yyy sway in meters (signed)
# z.zzz heave in meters (signed)
sub PIXSE_HEAVE_ {
    my $self = shift;
    $self->{NMEADATA} = {} unless ref($self->{NMEADATA});
    my $d = $self->{NMEADATA};

    (undef,undef,
     $$d{surge},
     $$d{sway},
     $$d{heave},
    ) = @_;
    1;
}

# $PIXSE,TIME__,220419.809135*66
#
# $TIME__, hhmmss.ssssss*hh<CR><LF>
# hhmmss.ssssss
#
# UTC time reference frame if available otherwise in the system
# time reference frame. 
sub PIXSE_TIME__ {
    my $self = shift;
    $self->{NMEADATA} = {} unless ref($self->{NMEADATA});
    my $d = $self->{NMEADATA};

    (undef,undef,
     $$d{gyro_time},
    ) = @_;
    1;
}

# $PIXSE,STDHRP,0.150,0.009,0.009*74
#
# $PIXSE,STDHRP,x.xxx,y.yyy,z.zzz*hh<CR><LF>
# x.xxx heading std dev (degrees)
# y.yyy roll std dev (degrees)
# z.zzz pitch std dev (degrees)
sub PIXSE_STDHRP {
    my $self = shift;
    $self->{NMEADATA} = {} unless ref($self->{NMEADATA});
    my $d = $self->{NMEADATA};

    (undef,undef,
     $$d{std_heading},
     $$d{std_roll},
     $$d{std_pitch}
    ) = @_;
    1;
}

# $PIXSE,STDPOS,2383.07,2395.77,50.00*73
#
# $PIXSE,STDPOS,x.xx,y.yy,z.zz*hh<CR><LF>
# x.xx  latitude std dev (meters)
# y.yy  longitude std dev (meters)
# z.zz  altitude std dev (meters)
sub PIXSE_STDPOS {
    my $self = shift;
    $self->{NMEADATA} = {} unless ref($self->{NMEADATA});
    my $d = $self->{NMEADATA};

    (undef,undef,
     $$d{std_north},
     $$d{std_east},
     $$d{std_up}
    ) = @_;
    1;
}
 
# $PIXSE,ALGSTS,00000045,00034000*63
#
# $PIXSE,ALGSTS,hhhhhhhh,llllllll *hh<CR><LF>
# INS Algo status (see Table V.5 and Table V.6 Part5 Library Interface)
# hhhhhhhh hexadecimal value of INS Algo status1 (LSB)
# llllllll hexadecimal value of INS Algo status 2 (MSB)
sub PIXSE_ALGSTS {
    my $self = shift;
    $self->{NMEADATA} = {} unless ref($self->{NMEADATA});
    my $d = $self->{NMEADATA};

    (undef,undef,
     $$d{algo_stat_lsb},
     $$d{algo_stat_msb},
    ) = @_;
    1;
}

# $PIXSE,STATUS,00000000,00001000*6E
#
# $PIXSE,STATUS,hhhhhhhh,llllllll *hh<CR><LF>
# INS System status (see Table V.3 and Table V.4 Part4 Library Interface)
#
# hhhhhhhh hexadecimal value of INS System status 1 (LSB)
# llllllll hexadecimal value of INS System status 2 (MSB)
sub PIXSE_STATUS {
    my $self = shift;
    $self->{NMEADATA} = {} unless ref($self->{NMEADATA});
    my $d = $self->{NMEADATA};

    (undef,undef,
     $$d{stat_lsb},
     $$d{stat_msb},
    ) = @_;
    1;
}

#$PIXSE,UTMWGS,T,11,532255.081,5314274.311,445.497*13
#
# $PIXSE,UTMWGS,c,nn,x.xxx,y.yyy,z.zzz*hh<CR><LF>
# C      latitude UTM zone (character)
# nn     longitude UTM zone (integer)
# x.xxx  east UTM position in meter
# y.yyy  north UTM position in meter
# z.zzz  altitude in meters
sub PIXSE_UTMWGS {
    my $self = shift;
    $self->{NMEADATA} = {} unless ref($self->{NMEADATA});
    my $d = $self->{NMEADATA};

    (undef,undef,
     $$d{utm_lat_zone},
     $$d{utm_long_zone},
     $$d{utm_east},
     $$d{utm_north},
     $$d{utm_up},
    ) = @_;
    1;
}

# $PIXSE,HT_STS,7FFD5551*37
#
# $PIXSE,HT_STS,hhhhhhhh *hh<CR><LF>
# hhhhhhhh hexadecimal value of PHINS High Level status
sub PIXSE_HT_STATUS{
    my $self = shift;
    $self->{NMEADATA} = {} unless ref($self->{NMEADATA});
    my $d = $self->{NMEADATA};

    (undef,undef,
     $$d{ht_status},
    ) = @_;
    1;
}

# $INDYN,47.97790727,243.43950595,626.987,323.498,0.152,0.404,-0.002,0.000,-0.002,0.060*61
# $INDYN,47.97797975,243.43961208,626.991,323.489,0.152,0.402,-0.003,0.002,-0.000,0.042*6E
#
# $INDYN,x.xxxxxxxx,y.yyyyyyyy,z.zzz,h.hhh,r.rrr,p.ppp,a.aaa,b.bbb,c.ccc,s.sss*hh<CR><LF>
# 
# 1) x.xxxxxxxx is the latitude in degrees
# 2) y.yyyyyyyy is the longitude in degrees
# 3) z.zzz is the altitude in meters
# 4) h.hhh is the heading in degrees
# 5) r.rrr is the roll in degrees (positive for port up)
# 6) p.ppp is the pitch in degrees (positive when bow down)
# 7) a.aaa is the heading rate in °/s
# 8) b.bbb is the roll rate in °/s (positive when roll increase)
# 9) c.ccc is the pitch rate in °/s (positive when pitch increase)
# 10) s.sss Speed XV1 in m/s (positive towards the bow)
# 11) hh is the checksum
sub INDYN {
    my $self = shift;
    $self->{NMEADATA} = {} unless ref($self->{NMEADATA});
    my $d = $self->{NMEADATA};

    (undef,
     $$d{lat_indyn},
     $$d{long_idyn},
     $$d{alt_idyn},
     $$d{heading_idyn},
     $$d{roll_idyn},
     $$d{pitch_idyn},
     $$d{heading_rate},
     $$d{roll_rate},
     $$d{pitch_rate},
     $$d{XV1}    
    ) = @_;
        
    1;
}


__END__

=head1 NAME

Device::Gyro::IXBLUE - Perl module to interface with a IXBLUE Gyro

=head1 SYNOPSIS

  use Device::Gyro::IXBLUE;
  
  # Get list of NMEA strings 
  $line_lst = read_strings(); 
  
  my $data_ref = $Ixblue_obj->process_paragraph($line_lst);
  

=head1 DESCRIPTION

Device::Gyro::IXBLUE parses the NMEA strings returned from the 
IXBLUE Gyro 

=head2 EXPORT

=head1 SEE ALSO


=head1 AUTHOR

Steve Troxel 

=head1 COPYRIGHT AND LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
