package Geo::Formatter;

use warnings;
use strict;
use Carp;

use version; our $VERSION = qv('0.0.1');
use vars qw(@ISA @EXPORT);
use Exporter;
@ISA = qw(Exporter);
@EXPORT      = qw(latlng2format format2latlng alias_format);
use Class::Inspector;
use UNIVERSAL::require;

our %logic  = ();
# our @search = ();

sub import {
    my $pkg     = shift;
    my @formats = @_;

    $pkg->add_format("Degree","DMS",@_);
    $pkg->export_to_level(1, $pkg);
}

sub add_format {
    my $pkg     = shift;

    foreach my $format (@_) {
        my $class = "Geo::Formatter::Format::$format";

        unless( Class::Inspector->loaded($class) ) {
            if ($class->require) {
                $class->import;
            } else {
                croak "Cannot load format : $format";
            }
        }
    }
}

sub __formatter {
    my $dir    = shift;
    my $format = shift;

    my $code;

    if ($logic{$format} && $logic{$format}->{$dir}) {
        $code = $logic{$format}->{$dir};
    }# else {
#        foreach my $search (@search) {
#            last if ($code = $search->match($format,$dir));
#        }
#    }
    if ($code) {
        return $code->(@_);
    } else {
        croak "Cannot $dir $format format";
    }
}

sub latlng2format {
    __formatter("encode",@_);
}

sub format2latlng {
    __formatter("decode",@_);
}

sub alias_format {
    my $format  = shift;
    my $base    = shift;
    my $opt     = shift;

    my $base_setting = $logic{$base} or croak("Cannot find base format: $base");
    $logic{$format} = {} unless ($logic{$format});

    foreach my $dir ("encode","decode") {
        my %dir_opt = $opt ?  
                      (
                          %{$opt},
                          ($opt->{$dir} ? %{$opt->{$dir}} : ()),
                      ) :
                      ();
        delete @dir_opt{qw(decode encode)};

        my $code = $base_setting->{$dir} ? 
                   %dir_opt ?
        sub {
            my %opt = ref($_[$#_]) eq 'HASH' ? %{ pop() } : ();
            %opt = (
                %dir_opt,
                %opt,
            );
            $base_setting->{$dir}->(@_,\%opt);
        } : 
        $base_setting->{$dir} :
        undef;

        $logic{$format}->{$dir} = $code;
    }
}

1; # Magic true value required at end of module
__END__

=head1 NAME

Geo::Formatter - Encode / decode latitude & longitude in degree to / from other format 


=head1 SYNOPSIS

  use Geo::Formatter;
  # Export 3 functions, latlng2format, format2latlng, and alias_format.
  
  # Encode:
  
  # Degree format with 6 digits under the decimal point.
  my ($lat,$lng) = latlng2format("degree",35,135); 
  # 35.000000, 135.000000
  
  # Signed degree format with 4 digits under the decimal point.
  my ($lat,$lng) = latlng2format("degree",35,135,{sign => 1,under_decimal => 4}); 
  # +35.0000, +135.0000
  
  # Dms format with 3 digits under the decimal point in second part.
  my ($lat,$lng) = latlng2format("dms",35,135); 
  # 35.0.0.000, 135.0.0.000
  
  # Dms format with zerofill and 0 digits under the decimal point in second part.
  my ($lat,$lng) = latlng2format("dms",35,135,{zerofill => 1,under_decimal => 0}); 
  # 35.00.00, 135.00.00
  
  # Signed dms format with "/" as devider.
  my ($lat,$lng) = latlng2format("dms",35,135,{devider => "/",sign => 1}); 
  # +35/0/0.000, +135/0/0.000
  
  # Decode:
  
  # Dms format.
  my ($lat,$lng) = format2latlng("dms","35.0.0.000","135.0.0.000"); 
  # 35, 135
  
  # Dms format with "/" as devider.
  my ($lat,$lng) = format2latlng("dms","+35/00/00.000","+135/00/00.000",{devider => "/"}); 
  # 35, 135
  
  # Alias:
  # You can alias any format to other name with default option
  
  alias_format("degree8","degree",{encode =>{under_decimal => 8}});
  my ($lat,$lng) = latlng2format("degree8",35,135); 
  # 35.00000000, 135.00000000
  
  alias_format("dms2","dms",{encode =>{devider=>"/",zerofill=>1},decode =>{devider=>"/"}});
  my ($lat,$lng) = latlng2format("dms2",35,135); 
  # 35/00/00.000, 135/00/00.000
  my ($lat,$lng) = format2latlng("dms2","35/00/00.000","135/00/00.000"); 
  # 35, 135


=head1 DESCRIPTION

This module provides framework of encoding/decoding latlong in degree to/from other format.
Default module provide only degree and dms formats, but you can extend other formats with
Geo::Formatter::Format::XXX type modules.


=head1 EXPORT

3 functions are exported.

=over 4

=item * latlng2format( [FORMAT],[LATITUDE],[LONGITUDE],[OPTION] )

Return values are different by FORMAT type.
If FORMAT type is single string value, function returns scalar.
If FORMAT type is latitude/longitude type, function returns array (in wantarray case) or array reference.
LATITUDE and LONGITUDE are latitude/longitude value in degree.
OPTION is optional, and it must be hash reference.
Effective OPTIONs are different by each FORMATs.

=item * format2latlng( [FORMAT],[FORMAT_STR],[OPTION] )

=item * format2latlng( [FORMAT],[FORMAT_LAT],[FORMAT_LNG],[OPTION] )

Arguments are different by FORMAT type.
If FORMAT type is single string value, arguments need formatted string, [FORMAT_STR].
If FORMAT type is latitude/longitude type, arguments need formatted latitude/longitude, [FORMAT_LAT] and [FORMAT_LNG].
OPTION is optional, and it must be hash reference.
Effective OPTIONs are different by each FORMATs.

Return values are latitude/longitude in degree, at array (in wantarray case) or array reference.

=item * alias_format( [ALIAS],[FORMAT],[OPTION] )

Arguments are different by FORMAT type.
If FORMAT type is single string value, arguments need formatted string, [FORMAT_STR].
If FORMAT type is latitude/longitude type, arguments need formatted latitude/longitude, [FORMAT_LAT] and [FORMAT_LNG].
OPTION is optional, and it must be hash reference.
Effective OPTIONs are different by each FORMATs.

Return values are latitude/longitude in degree, at array (in wantarray case) or array reference.

=back


=head1 CLASS METHOD

=over 4

=item * add_format( [FORMAT_CLASS_NAME1](,[FORMAT_CLASS_NAME2],...) )

Add new format class to handle new format.
If you want to set Geo::Formatter::Format::XXX, you should set XXX as
[FORMAT_CLASS_NAME].


=back


=head1 DEPENDENCIES

Exporter
Class::Inspector
UNIVERSAL::require


=head1 AUTHOR

OHTSUKA Ko-hei  C<< <nene@kokogiko.net> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2008, OHTSUKA Ko-hei C<< <nene@kokogiko.net> >>. 

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
