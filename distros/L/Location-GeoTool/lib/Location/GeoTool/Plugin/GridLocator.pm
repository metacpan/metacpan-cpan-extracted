package Location::GeoTool::Plugin::GridLocator;

use strict;
no strict 'refs';
no warnings 'redefine';
use vars qw($VERSION);
$VERSION = 0.02000;
use Location::GeoTool;
use Carp;

sub import {
    __PACKAGE__->setup();
}

# Thanks for site:
# http://www.jarl.or.jp/Japanese/1_Tanoshimo/1-2_Award/gl.htm

sub setup {
    Location::GeoTool->set_original_code(
        "gridlocator",
        [
            sub {
                croak("Cannot create Location::GeoTool object from GridLocator");
            },
            sub {
                my $self = shift;
                my ($lat,$long) = $self->format_degree->array;
                my @res;

                $lat = ($lat+90)/10;
                $long = ($long+180)/20;

                $res[1] = pack "C", 65+int($lat);
                $res[0] = pack "C", 65+int($long);

                $res[3] = int($lat*10) % 10;
                $res[2] = int($long*10) % 10;

                $res[5] = pack "C", 65+int(($lat*10 - int($lat*10)) * 24);
                $res[4] = pack "C", 65+int(($long*10 - int($long*10)) * 24);

                join "",@res;
            },
        ]
    );
}

1;
__END__

=head1 NAME

Location::GeoTool::Plugin::GridLocator - Extension for Location::GeoTool

=head1 SYNOPSIS

  use Location::GeoTool qw/GridLocator/;
  
  my $geo = Location::GeoTool->create_coord('354345.000','1394437.000',"wgs84", "dmsn");
  
  my $gl = $geo->get_gridlocator;  # PM95UR

=head1 DESCRIPTION

Location::GeoTool::Ex::GridLocator extends the Location::GeoTool module.

=head1 FUNCTIONS

If you use this module in your program, it add get_gridlocator method 
to Location::GeoTool.

Please see the way to use this, please see upper SYNOPSIS part.
It contains the way to use this.

=head1 NOTICE

This extension calcurates Grid Locator based on datum of Location::GeoTool
object.
So, if you want to make object by Tokyo datum but get Grid Locator in wgs84,
do like below:

  my $geo = Location::GeoTool->create_coord('354345.000','1394437.000',"tokyo", "dmsn");
  
  my $gl = $geo->datum_wgs84->get_gridlocator;

=head2 EXPORT

None.

=head1 SEE ALSO

Location::GeoTool

Support this module in Kokogiko web site : http://kokogiko.net/

=head1 AUTHOR

OHTSUKA Ko-hei, E<lt>nene@kokogiko.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005-2007 by Kokogiko!

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
