package Location::GeoTool::Plugin::Locapoint;

use 5.008;
use strict;
use warnings;
no strict 'refs';
no warnings 'redefine';
use Location::GeoTool;
use Math::Round qw(nhimult);
use Carp;

our $VERSION = '0.02';

sub import {
    __PACKAGE__->setup();
}

my @devider = (1757600,67600,6760,260,10);

sub int2code
{
  my ($value,$count) = @_;
  my $this = int($value / $devider[$count]);
  my $low = $value % $devider[$count];
  $this = pack "C", 65 + $this if ($count != 2); 
  if ($count == 4)
  {
    $this .= $low;
  }
  else
  {
    $this .= int2code($low,$count+1);
  }
  return $this;
}

sub code2int
{
  my ($value,$count) = @_;
  my $this = substr($value,0,1);
  my $low = substr($value,1);
  $this = unpack("C",$this) - 65 if ($this =~ /^[A-Z]$/);
  $this *= $devider[$count];
  if ($count == 4)
  {
    $this += $low;
  }
  else
  {
    $this += code2int($low,$count+1);
  }
  return $this;
}

sub setup {
    Location::GeoTool->_make_accessors(qw(cache_locapo));

    my $createcoord_3d = \&Location::GeoTool::create_coord3d;
    *{"Location::GeoTool\::create_coord3d"} = sub 
    {
        my $self = shift;
        $self = &$createcoord_3d($self,@_);
        $self->{cache_locapo} = undef;
        return $self;
    };

    Location::GeoTool->set_original_code(
        "locapoint",
        [
            sub {
                my $self = shift;
                my $locapo = shift;
  
                $locapo =~ /^([A-Z][A-Z][0-9])\.([A-Z][A-Z][0-9])(\.([A-Z][A-Z][0-9])\.([A-Z][A-Z][0-9]))$/ or croak "Argument $locapo is not locapoint!!";
                my $lat = $1.($4 || 'NA0');
                my $long = $2.($5 || 'NA0');

                foreach ($lat,$long)
                {    
                    $_ = code2int($_,0);
                }

                $lat = nhimult(.000001,$lat * 9 / 2284880 - 90);
                $long = nhimult(.000001,$long * 9 / 1142440 - 180);

                $self = $self->create_coord($lat,$long,"wgs84","degree");
                $self->{cache_locapo} = $locapo;
                return $self;
            },
            sub {
                my $self = shift;
                return $self->cache_locapo if ($self->cache_locapo);
                my ($lat,$long) = $self->datum_wgs84->format_degree->array;

                $lat = int(($lat + 90) * 2284880 / 9);
                $long = int(($long + 180) *1142440 / 9);

                foreach ($lat,$long)
                {
                    while (($_ < 0) || ($_ > 45697599))
                    {
                        $_ = $_ < 0 ? $_ + 45697600 : $_ - 45697600;
                    }    
                    $_ = int2code($_,0);
                }
  
                $self->{cache_locapo} = sprintf("%s.%s.%s.%s",substr($lat,0,3),substr($long,0,3),substr($lat,3,3),substr($long,3,3));
                return $self->cache_locapo;
            },
        ]
    );
}

1;
__END__

=head1 NAME

Location::GeoTool::Plugin::Locapoint - Plugin for Location::GeoTool to access Locapoint GIS data format

=head1 SYNOPSIS

  use Location::GeoTool qw/Locapoint/;
  
  my $loc = Location::GeoTool->create_locapoint('SD7.XC0.GF5.TT8');
  my ($lat,$long) = $loc->format_degree->array;
  # $lat => 35.606954, $long => 139.567109

  # or inverse:

  my $loc = Location::GeoTool->create_coord(35.606954,139.567109,'wgs84','degree');
  my ($locapo) = $loc->get_locapoint;
  # $locapo => 'SD7.XC0.GF5.TT8'

=head1 DESCRIPTION

Location::GeoTool::Plugin::Locapoint is a extension plugin for Location::GeoTool module.
This gives two methods: create_locapoint and get_locapoint to Location::GeoTool.
Please see SYNOPSIS to know how to use.

=head2 EXPORT

None.

=head1 SEE ALSO

Location::GeoTool

Locapoint official site: http://www.locapoint.com/

Specification of Locapoint: http://www.locapoint.com/en/spec.htm

Support this module in Kokogiko web site : http://kokogiko.net/

=head1 AUTHOR

OHTSUKA Ko-hei, E<lt>nene@kokogiko.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005-2007 by Kokogiko!

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
