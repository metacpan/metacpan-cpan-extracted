package HTTP::MobileAgent::Plugin::Location::Support;

use warnings;
use strict;
use Carp;
use HTTP::MobileAgent;

use version; our $VERSION = qv('0.0.3');
use vars qw($GPSModels);

my $denv    = $ENV{"DOCOMO_GPSMODELS"};
my $senv    = $ENV{"SOFTBANK_GPSMODELS"};

$GPSModels = {
    map { $_ => 1 } ($denv ? split(/\n/,$denv) : qw(
        F661i
        F505iGPS
        D905i
        F905i
        N905i
        P905i
        SH905i
        SO905i
        N905imyu
        F883iES
        F883iESS
        D904i
        F904i
        N904i
        P904i
        SH904i
        D903i
        F903i
        F903iBSC
        N903i
        P903i
        SO903i
        SH903i
        SA800i
        F801i
        SO905iCS
    )),
    map { $_ => 1 } ($senv ? split(/\n/,$senv) : qw(
        910T
        810T
        811T
        812T
        813T
        911T
        912T
        923SH
        921P
        921T
        920P
        920T
        824T
        823T
        821T
        820T
        V903T
        V904T
        V904SH
    )),
    map { $_ => 0 } qw(V703N V702NK2 V702NK V802N V702sMO V702MO),
};

##########################################
# Base Module

package # hide from PAUSE
       HTTP::MobileAgent;

sub support_location{
    my $self = shift;
    return $self->support_gps || $self->support_sector || $self->support_area;
}

sub support_gps{
    $HTTP::MobileAgent::Plugin::Location::Support::GPSModels->{$_[0]->model} ? 1 : 0;
}

sub support_sector{ 0 }

sub support_area{ 0 }

##########################################
# DoCoMo Module

package # hide from PAUSE
       HTTP::MobileAgent::DoCoMo;

sub support_gps{
    my $model = $_[0]->model;
    return 1 if ( $model =~ /90[5-9]/ && $model !~ /TV/ );
    return 1 if ( $model =~ /88[4-9]/ );
    return $_[0]->SUPER::support_gps(@_);
}

sub support_sector {
    $_[0]->is_foma && (!$_[0]->html_version || $_[0]->html_version >= 5.0) ? 1 : 0
}

sub support_area{ 1 }

##########################################
# EZWeb Module

package # hide from PAUSE
       HTTP::MobileAgent::EZweb;

sub multimedia_location {
    my $dev = $_[0]->get_header('x-up-devcap-multimedia') or return 999;
    return (split(//,$dev))[1];
}

sub support_gps {
    $_[0]->multimedia_location > 1 ? 1 : 0;
}

sub support_sector {
    $_[0]->multimedia_location ? 1 : 0;
}

##########################################
# SoftBank Module

package # hide from PAUSE
       HTTP::MobileAgent::Vodafone;

sub support_sector{
    my $self = shift;

    if ($self->is_type_3gc) {
        my $dat = $HTTP::MobileAgent::Plugin::Location::Support::GPSModels->{$self->model};
        return (defined($dat) && $dat == 0) ? 0 : 1;
    } else {
        my $version = $self->version;

        return 0 if ($version >= 5.0); 	# VGS is not support Station
        return 1 if ($version > 3.0); 	# Browser version more than 3.0 is support Station
        return 0 if ($version < 3.0); 	# Browser version less than 3.0 is not support Station
        return 1 if ($self->get_header('x-jphone-java'));
                                        # All {browser 3.0 and support Java} are support Station

        return 0 if ($self->model =~ /^((J-N03)|(J-SH05)|(J-SH04B)|(J-SH04)|(J-PE03)|(J-D03)|(J-K03))/);
        return 1;
    }
}

##########################################
# WILLCOM Module

package # hide from PAUSE
       HTTP::MobileAgent::AirHPhone;

sub support_sector{ 1 }

1; # Magic true value required at end of module
__END__

=head1 NAME

HTTP::MobileAgent::Plugin::Location::Support - Add flag of supporting location fuctions or not to HTTP::MobileAgent


=head1 VERSION

This document describes HTTP::MobileAgent::Plugin::Location::Support version 0.0.2


=head1 SYNOPSIS

  use HTTP::MobileAgent::Plugin::Location::Support;
  
  my $ma = HTTP::MobileAgent->new;
  
  # Is this terminal support any location functions?
  if ($ma->support_location) { ... }
  
  # Is this terminal support gps?
  if ($ma->support_gps) { ... }
  
  # Is this terminal support position from sector?
  if ($ma->support_sector) { ... }
  
  # Is this terminal support i-area?
  if ($ma->support_area) { ... }
  


=head1 DESCRIPTION

HTTP::MobileAgent::Plugin::Location::Support is a plugin module of HTTP::MobileAgent, 
which implements method to check whether terminal supports location function or not.


=head1 CONFIGURATION AND ENVIRONMENT

In DoCoMo and SoftBank, information of supporting gps or not is not include in UserAgent
or HTTP headers.
So, data table of gps supporting terminals will have to be update.
You can set data to environment variable $ENV{DOCOMO_GPSMODELS} and $ENV{SOFTBANK_GPSMODELS},
as string list of terminal name.

Formats are like below:

  $ENV{DOCOMO_GPSMODELS} = <<EOF;
  F661i
  F505iGPS
  D905i
  F905i
  N905i
  P905i
  SH905i
  SO905i
  N905imyu
  F883iES
  D904i
  F904i
  N904i
  P904i
  SH904i
  D903i
  F903i
  N903i
  P903i
  SO903i
  SA800i
  EOF
  
  $ENV{SOFTBANK_GPSMODELS} = <<EOF;
  910T
  810T
  811T
  812T
  813T
  911T
  912T
  V903T
  V904T
  V904SH
  EOF


=head1 DEPENDENCIES

=over

=item L<HTTP::MobileAgent::Plugin::XHTML>

=back


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to C<nene@kokogiko.net>.


=head1 AUTHOR

OHTSUKA Ko-hei  C<< <nene@kokogiko.net> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007, OHTSUKA Ko-hei C<< <nene@kokogiko.net> >>. All rights reserved.

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
