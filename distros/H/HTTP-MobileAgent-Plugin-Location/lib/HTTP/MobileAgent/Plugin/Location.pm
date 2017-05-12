package HTTP::MobileAgent::Plugin::Location;

use warnings;
use strict;
use Carp;
use CGI;
use Class::Data::Inheritable;
use Class::Accessor::Fast;
use HTTP::MobileAgent::Plugin::Location::Support;
use HTTP::MobileAgent::Plugin::Location::LocationObject;
use URI;
use URI::QueryParam;
use URI::Escape;

use version; our $VERSION = qv('0.0.5');
my @accuracy = qw(gps hybrid sector);
my @modes    = qw(gps sector area);
my @methods  = qw(gps sector area);

my %corx = (
    "XHTML" => [
        ' />',
        'lcs="lcs"',
        'z="z"',
    ],
    "CHTML" => [
        '>',
        'lcs',
        'z',
    ],
);

my $escape = {
    "'" => '&#039;',
    '"' => '&quot;',
    '&' => '&amp;',
    '>' => '&gt;',
    '<' => '&lt;',
};

# Inherit
push (@HTTP::MobileAgent::ISA,qw/Class::Data::Inheritable Class::Accessor::Fast/);

# Class property

HTTP::MobileAgent->mk_classdata("_use_area",0);
HTTP::MobileAgent->mk_classdata("_use_geopoint",0);
HTTP::MobileAgent->mk_classdata("_use_geocoordinate",0);

# Object property

HTTP::MobileAgent->mk_accessors(qw/location area err/);

# Initialize

sub import {
    my @ARG = @_;

    my $caller = shift;
    foreach my $arg (@_)
    {
        my $method = "_$arg";
        eval{ HTTP::MobileAgent->$method(1) };
        croak "No such option $arg" if ($@);
    }
}

##########################################
# Base Module

package # hide from PAUSE
       HTTP::MobileAgent;

# Set/get query objext

sub query{
    my $self    = shift;
    my $query   = shift;

    $self->{query} =   $query if ($query);
    $self->{query} ||= ref($self->{_request}) eq "HTTP::MobileAgent::Request::Apache" ? $self->{_request}->{r} : CGI->new;

    $self->{query};
}

# Error set (and return undef)

sub set_err{
    $_[0]->{err} = $_[1];
    return;
}

# "UseArea" option methods for object (can override class setting)

sub use_area{
    my $self = shift;
    $self->{use_area} = $_[0] if (defined($_[0]));
    defined($self->{use_area}) ? $self->{use_area} : $self->_use_area;
}

# General location html descriptor

sub location_description{
    my $self     = shift;
    $self->{err} = undef;
    my $uri      = shift or return $self->set_err("URI value is needed");
    my $desc     = shift or return $self->set_err("Description value is needed");
    my $opt      = shift || {};

    $desc =~ s/([<>&'"])/$escape->{$1}/ge;

    return $self->set_err("Not support any location description") unless ($self->support_location);

    $uri         = ref($uri) ? $uri->clone : URI->new($uri);
    my $method   = uc($opt->{method}) || "ANY";
    my $html     = uc($opt->{html})   || ((!$self->is_airh_phone && $self->xhtml_compliant) ? "XHTML" : "CHTML");

    my @reqmodes = $opt->{mode} ? ($opt->{mode}) : @modes;
    return $self->set_err("Not support $method method location description") if ($method !~ /^(A|ANY|POST|GET)$/);
    return $self->set_err("Not support $html as markup language") if ($html !~ /^[XC]HTML$/);

    foreach my $each (@reqmodes) {
        my $support = "support_$each";
        next unless (eval { $self->$support() });

        my $descriptor ="_${each}_description";
        return $self->$descriptor($uri,$desc,$method,$html);
    }
    
    return $self->set_err("Not support " . $opt->{mode} . " type location description");
}

# Base methods of each location html descriptor

{
    no strict 'refs'; ## no critic
    foreach my $accessor (@modes) {
        *{"HTTP::MobileAgent::_${accessor}_description"} = sub { return $_[0]->set_err("Not suppot $accessor type location description") };
    }
}

# General location parser

sub parse_location{
    my $self = shift;
    $self->{err}      = undef;
    $self->{area}     = undef;

    $self->{location} = $self->_parse_location;
    if ($self->use_area) {
        require HTTP::MobileAgent::Plugin::Location::AreaObject;
        $self->{area} = $self->_parse_area;
    }

    $self->{location};
}

# Base method of location parser

sub _parse_location{ undef }

# Base method of area parser

sub _parse_area{
    my $self = shift;
    if ($self->location) {
        return HTTP::MobileAgent::Plugin::Location::AreaObject->__create_coord($self->location);
    }
}

##########################################
# DoCoMo Module

package # hide from PAUSE
       HTTP::MobileAgent::DoCoMo;

# Method of gps location html descriptor

sub _gps_description{
    my $self = shift;
    my ($uri,$desc,$method,$html) = @_;
    my ($tagend,$lcs,$z) = @{$corx{$html}};

    my $retcode;

    if ($self->is_foma) {
        # FOMA

        if ($method =~ /^A/) {
            # A, ANY

            $retcode =  $uri->canonical;
            $retcode =~ s/&/&amp;/g if ($html eq "XHTML");

            $retcode =  "<a href=\"$retcode\" $lcs>$desc</a>\n";
        } else {
            # POST, GET

            my @query_form = $uri->query_form;
            $uri->query_form([]);

            $retcode =  "<form action=\"" . $uri->canonical . "\" method=\"" . lc($method) . "\" $lcs>\n";
            $retcode .= "<input type=\"submit\" value=\"$desc\"$tagend\n";

            while (my($key,$vals) = splice(@query_form, 0, 2)) {
                $retcode .= "<input type=\"hidden\" name=\"$key\" value=\"$vals\"$tagend\n";
            }
            $retcode .= "</form>\n";
        }
    } else {
        # mova

        # A is not allowed

        return $self->set_err("Not support A method location description") if ($method eq "A");

        # POST, GET, ANY(=POST)

        my @query_form = $uri->query_form;
        $uri->query_form([]);

        $method = "POST" if ($method eq "ANY");

        $retcode =  "<form action=\"" . $uri->canonical . "\" method=\"" . lc($method) . "\">\n";
        $retcode .= "<input type=\"submit\" name=\"navi_pos\" value=\"$desc\"$tagend\n";

        while (my($key,$vals) = splice(@query_form, 0, 2)) {
            $retcode .= "<input type=\"hidden\" name=\"$key\" value=\"$vals\"$tagend\n";
        }
        $retcode .= "</form>\n";
    }

    $retcode;
}

# Method of sector location html descriptor

sub _sector_description{
    my $self = shift;
    my ($uri,$desc,$method,$html) = @_;
    $self->_area_description($uri,$desc,$method,$html,1);
}

# Method of area location html descriptor

sub _area_description{
    my $self = shift;
    my ($uri,$desc,$method,$html,$use_sector) = @_;
    my ($tagend,$lcs,$z) = @{$corx{$html}};

    my $retcode;

    my @query_form = $uri->query_form;
    if (@query_form > 4) {
        # Only 2 parameters are allowed

        @query_form = @query_form[0..3];
        $self->set_err("Only 2 parameters allowed but over it. Over parameters are discarded");
    }
    $uri->query_form([]);

    my @docomo_form = (
        ecode => "OPENAREACODE",
        msn   => "OPENAREAKEY",
        nl    => $uri->canonical,
    );

    my $count = 0;
    while (my($key,$vals) = splice(@query_form, 0, 2)) {
        my $argval = "$key=$vals";
        $count++;
        push (@docomo_form,"arg$count",$argval);
    }
    push (@docomo_form,"posinfo",1) if ($use_sector);

    if ($method eq "A") {
        # A

        $uri = URI->new("http://w1m.docomo.ne.jp/cp/iarea");
        $uri->query_form(\@docomo_form);

        $retcode =  $uri->canonical;
        $retcode =~ s/&/&amp;/g if ($html eq "XHTML");

        $retcode =  "<a href=\"$retcode\">$desc</a>\n";
    } else {
        # POST, GET, ANY(=POST)

        $method = "POST" if ($method eq "ANY");

        $retcode =  "<form action=\"http://w1m.docomo.ne.jp/cp/iarea\" method=\"" . lc($method) . "\">\n";
        $retcode .= "<input type=\"submit\" value=\"$desc\"$tagend\n";

        while (my($key,$vals) = splice(@docomo_form, 0, 2)) {
            $retcode .= "<input type=\"hidden\" name=\"$key\" value=\"$vals\"$tagend\n";
        }
        $retcode .= "</form>\n";
    }

    $retcode;
}

# Method of location parser

sub _parse_location{
    my $self = shift;
    my $q = $self->query;
    my $loc;

    if ($q->param("pos")) {   
        # mova gps parser

        $q->param("pos") =~ /^(N|S)([\d\.]+)(W|E)([\d\.]+)$/;
        my $lat = (($1 eq 'S') ? "-" : "").$2;
        my $long = (($3 eq 'W') ? "-" : "").$4;

        $loc = HTTP::MobileAgent::Plugin::Location::LocationObject->__create_coord($lat,$long,'wgs84','gpsone');
        $loc->accuracy($accuracy[3 - $q->param("X-acc")]);
        $loc->mode("gps");
    } elsif ($q->param("lat") && $q->param("lon")) {
        # For FOMA gps 

        my $lat = $q->param("lat");
        my $long = $q->param("lon");

        $loc = HTTP::MobileAgent::Plugin::Location::LocationObject->__create_coord($lat,$long,'wgs84','gpsone');
        $loc->accuracy($accuracy[3 - $q->param("x-acc")]);
        $loc->mode("gps");
    } elsif ($q->param("LAT") && $q->param("LON")) {
        # For FOMA sector(extended i-area) parser

        my $lat = $q->param("LAT");
        my $long = $q->param("LON");

        $loc = HTTP::MobileAgent::Plugin::Location::LocationObject->__create_coord($lat,$long,'wgs84','gpsone');
        $loc->accuracy($accuracy[3 - $q->param("XACC")]);
        $loc->mode("sector");
    }
    $loc;
}

# Method of area parser

sub _parse_area{
    my $self = shift;
    my $q = $self->query;
    if ($q->param("AREACODE")) {
        # sector or i-area

        return HTTP::MobileAgent::Plugin::Location::AreaObject->create_iarea($q->param("AREACODE"));
    } else {
        # gps

        return $self->SUPER::_parse_area;
    }
}

##########################################
# EZWeb Module

package # hide from PAUSE
       HTTP::MobileAgent::EZweb;

# Method of gps location html descriptor

sub _gps_description{
    my $self = shift;
    my ($uri,$desc,$method,$html) = @_;
    my ($tagend,$lcs,$z) = @{$corx{$html}};

    # POST is not allowed
    return $self->set_err("Not support POST method location description") if ($method eq "POST");

    my $retcode;
    

    my @query_form = $uri->query_form;
    if (@query_form) {
        # Parameters are not allowed

        $self->set_err("Parameters are not allowed, so they are discarded");
    }
    $uri->query_form([]);

    @query_form = (
        url    => $uri->canonical,
        ver    => 1,
        datum  => 0,
        unit   => 0,
        acry   => 0,
        number => 0,
    );

    if ($method =~ /^A/) {
        # A, ANY

        $uri = URI->new("device:gpsone");
        $uri->query_form(\@query_form);

        $retcode =  $uri->canonical;
        $retcode =~ s/&/&amp;/g if ($html eq "XHTML");

        $retcode =  "<a href=\"$retcode\">$desc</a>\n";
    } else {
        # GET

        $retcode =  "<form action=\"device:gpsone\" method=\"get\">\n";
        $retcode .= "<input type=\"submit\" value=\"$desc\"$tagend\n";

        while (my($key,$vals) = splice(@query_form, 0, 2)) {
            $retcode .= "<input type=\"hidden\" name=\"$key\" value=\"$vals\"$tagend\n";
        }
        $retcode .= "</form>\n";
    }

    $retcode;
}

# Method of sector location html descriptor

sub _sector_description{
    my $self = shift;
    my ($uri,$desc,$method,$html) = @_;
    my ($tagend,$lcs,$z) = @{$corx{$html}};

    # POST is not allowed
    return $self->set_err("Not support POST method location description") if ($method eq "POST");

    my $retcode;


    my @query_form = $uri->query_form;
    if (@query_form) {
        # Parameters are not allowed

        $self->set_err("Parameters are not allowed, so they are discarded");
    }
    $uri->query_form([]);

    @query_form = (
        url    => $uri->canonical,
    );

    if ($method =~ /^A/) {
        # A, ANY

        $uri = URI->new("device:location");
        $uri->query_form(\@query_form);

        $retcode =  $uri->canonical;
        $retcode =~ s/&/&amp;/g if ($html eq "XHTML");

        $retcode =  "<a href=\"$retcode\">$desc</a>\n";
    } else {
        # GET

        $retcode =  "<form action=\"device:location\" method=\"get\">\n";
        $retcode .= "<input type=\"submit\" value=\"$desc\"$tagend\n";

        while (my($key,$vals) = splice(@query_form, 0, 2)) {
            $retcode .= "<input type=\"hidden\" name=\"$key\" value=\"$vals\"$tagend\n";
        }
        $retcode .= "</form>\n";
    }

    $retcode;
}

# Method of location parser

sub _parse_location{
    my $self = shift;
    my $q = $self->query;
    my $loc;

    if (($q->param("lat")) && ($q->param("lon"))) {
        $loc = HTTP::MobileAgent::Plugin::Location::LocationObject->__create_coord($q->param("lat"),$q->param("lon"),'wgs84','gpsone');
        if (defined($q->param("fm"))) {
            # gps

            $loc->accuracy($accuracy[$q->param("fm") < 2 ? $q->param("fm") : 2]);
            $loc->mode("gps");
        } else {
            # sector

            $loc->accuracy($accuracy[2]);
            $loc->mode("sector");
        }
    }
    $loc;
}

##########################################
# SoftBank Module

package # hide from PAUSE
       HTTP::MobileAgent::Vodafone;

# Method of gps location html descriptor

sub _gps_description{
    my $self = shift;
    my ($uri,$desc,$method,$html,$cell) = @_;
    my ($tagend,$lcs,$z) = @{$corx{$html}};

    my $mode = $cell ? 'cell' : 'gps';

    my $retcode;

    if ($method =~ /^A/) {
        # A, ANY

        my $query = $uri->query;
        $uri->query_form([]);

        $retcode =  "location:$mode?url=" . $uri->canonical;
        $retcode .= "&$query" if ($query);
        $retcode =~ s/&/&amp;/g if ($html eq "XHTML");

        $retcode =  "<a href=\"$retcode\">$desc</a>\n";
    } else {
        # POST, GET

        my @query_form = $uri->query_form;
        $uri->query_form([]);
        @query_form = (
            url    => $uri->canonical,
            @query_form,
        );

        $retcode =  "<form action=\"location:$mode\" method=\"" . lc($method) . "\">\n";
        $retcode .= "<input type=\"submit\" value=\"$desc\"$tagend\n";

        while (my($key,$vals) = splice(@query_form, 0, 2)) {
            $retcode .= "<input type=\"hidden\" name=\"$key\" value=\"$vals\"$tagend\n";
        }
        $retcode .= "</form>\n";
    }

    $retcode;
}

# Method of sector location html descriptor

sub _sector_description{
    my $self = shift;
    my ($uri,$desc,$method,$html) = @_;
    my ($tagend,$lcs,$z) = @{$corx{$html}};

    my $retcode;

    if ($self->is_type_3gc) {
        # For 3G

        $retcode = $self->_gps_description($uri,$desc,$method,$html,1);
    } else {
        # For 2G

        if ($method =~ /^A/) {
            # A, ANY

            $retcode =  $uri->canonical;
            $retcode =~ s/&/&amp;/g if ($html eq "XHTML");

            $retcode =  "<a href=\"$retcode\" $z>$desc</a>\n";
        } else {
            # POST, GET

            my @query_form = $uri->query_form;
            $uri->query_form([]);

            $retcode =  "<form action=\"" . $uri->canonical . "\" method=\"" . lc($method) . "\" $z>\n";
             $retcode .= "<input type=\"submit\" value=\"$desc\"$tagend\n";

            while (my($key,$vals) = splice(@query_form, 0, 2)) {
                $retcode .= "<input type=\"hidden\" name=\"$key\" value=\"$vals\"$tagend\n";
            }
            $retcode .= "</form>\n";
        }
    }

    $retcode;
}

# Method of location parser

sub _parse_location{
    my $self = shift;
    my $q = $self->query;
    my $h = $self->get_header('x-jphone-geocode');
    my $loc;

    if ($q->param("pos")) {
        # 3G gps, sector parser

        $q->param("pos") =~ /^(N|S)([\d\.]+)(W|E)([\d\.]+)$/;
        my $lat = (($1 eq 'S') ? "-" : "").$2;
        my $long = (($3 eq 'W') ? "-" : "").$4;
        my $geo = $q->param("geo") eq 'itrf' ? 'wgs84' : $q->param("geo");

        $loc = HTTP::MobileAgent::Plugin::Location::LocationObject->__create_coord($lat,$long,$geo,'gpsone');
        $loc->accuracy($accuracy[3 - $q->param("x-acr")]);
        $loc->mode($q->param("x-acr") == 1 ? "sector" : "gps");
    } elsif ($h) {
        # 2G sector parser

        my ($lat,$long,$addr) = split(/%1A/,$h);

        if (($lat =~ /^0+$/) || ($long =~ /^0+$/)) {
            # Bad data

            return $self->set_err("Bad data error");
        } else {
            $lat =~ s/^(\d{2,3})(\d{2})(\d{2})$/$1.$2.$3.0/;
            $long =~ s/^(\d{2,3})(\d{2})(\d{2})$/$1.$2.$3.0/;
            $loc = HTTP::MobileAgent::Plugin::Location::LocationObject->__create_coord($lat,$long,'tokyo','gpsone');
            $loc->accuracy($loc->mode("sector"));
        }
    }
    $loc;
}

##########################################
# WILLCOM Module

package # hide from PAUSE
       HTTP::MobileAgent::AirHPhone;

# Method of sector location html descriptor

sub _sector_description{
    my $self = shift;
    my ($uri,$desc,$method,$html) = @_;

    # POST, GET are not allowed
    return $self->set_err("Not support $method method location description") if ($method =~ /^(POST|GET)$/);

    my $retcode;
    my $ah_uri = URI->new("");

    my $query = $uri->query;

    my @query_form = $uri->query_form;
    $uri->query_form([]);

    $retcode =  "http://location.request/dummy.cgi?my=" . URI::Escape::uri_escape($uri->canonical) . "&pos=\$location";
    $retcode .= "&$query" if ($query);
    $retcode =~ s/&/&amp;/g if ($html eq "XHTML");

    $retcode =  "<a href=\"$retcode\">$desc</a>\n";

    $retcode;
}

# Method of location parser

sub _parse_location{
    my $self = shift;
    my $q = $self->query;
    my $loc;

    if ($q->param("pos")) {
        $q->param("pos") =~ /^(N|S)([\d\.]+)(W|E)([\d\.]+)$/;
        my $lat = (($1 eq 'S') ? "-" : "").$2;
        my $long = (($3 eq 'W') ? "-" : "").$4;

        if (($lat =~ /^[90\.]+$/) || ($long =~ /^[90\.]+$/)) {
            return $self->set_err("Bad data error");
        } else {
            $loc = HTTP::MobileAgent::Plugin::Location::LocationObject->__create_coord($lat,$long,'tokyo','gpsone');
            $loc->accuracy($loc->mode("sector"));
        }
    }
    $loc;
}

1; # Magic true value required at end of module
__END__

=head1 NAME

HTTP::MobileAgent::Plugin::Location - Add location fuctions to HTTP::MobileAgent


=head1 VERSION

This document describes HTTP::MobileAgent::Plugin::Location version 0.0.3


=head1 SYNOPSIS

  use HTTP::MobileAgent::Plugin::Location;
  
  my $ma = HTTP::MobileAgent->new;
  
  # Add query request object (L<CGI>,L<Apache::Request>,L<Catalyst::Request>...)
  # If not added, B<H::MA> make L<CGI> object automatically.
  
  $ma->query($q);


  # If you want to get location html description, you do as below
  
  my $uri  = "http://example.com/location/callback?param1=a&param2=b"; # String or URI object
  my $desc = "Push this button to get location!";                      # Description on location link
  my $opt  = {                                                         # All optional
    method => "get",    # "a", "post" or "get". default is different by carrer and generation.
    mode   => "sector", # "gps", "sector" or "area". default is most precise mode of terminal.
    html   => "xhtml",  # "chtml" or "xhtml". xhtml compliant terminal's default is xhtml, other is chtml.
  };
  
  my $desc = $ma->location_description($uri,$desc,$opt) or warn $ma->err;
  

  # If you want to parse lat-long location from query, you do as below
  
  $ma->parse_location;
  
  # After do that, you can get L<HTTP::MobileAgent::Plugin::Location::LocationObject::LG> object by
  # B<location> property.
  # L<HTTP::MobileAgent::Plugin::Location::LocationObject::LG> is subclass of L<Location::GeoTool>,
  # and see mode detail in L<HTTP::MobileAgent::Plugin::Location::LocationObject>'s pod.
  
  my $loc = $ma->location;
  warn $ma->err if (!$loc && $ma->err);
  
  # B<location> property return undef if location information is not included in query or location information
  # is invalid.
  # If undef returns, check B<err> method.
  # If B<err> is undef, query not include location information.

  # You can use L<Geo::Coordinates::Converter> instead of L<Location::GeoTool> as lat-long location obect.
  # If you want to do so, check L<HTTP::MobileAgent::Plugin::Location::LocationObject::GCC>.


  # If you want to parse not only lat-long object but i-Area object, you import this module as
  
  use HTTP::MobileAgent::Plugin::Location qw(use_area);
  
  # Or, if you want to parse i-Area arbeitery, set B<use_area> property to true.
  
  $ma->use_area(1);
  
  # After doing above and calling B<parse_location> method, you can get
  # L<HTTP::MobileAgent::Plugin::Location::AreaObject> by B<area> property.
  
  $ma->parse_location;
  my $area = $ma->area;
  
  # L<HTTP::MobileAgent::Plugin::Location::AreaObject> is subclass of L<Location::Area::DoCoMo::iArea>,
  # and see mode detail in L<HTTP::MobileAgent::Plugin::Location::AreaObject>'s pod.


=head1 DEPENDENCIES

=over

=item L<HTTP::MobileAgent::Plugin::XHTML>

=item L<CGI>

=item L<Class::Data::Inheritable>

=item L<Class::Accessor::Fast>

=item L<URI>

=item L<URI::QueryParam>

=item L<URI::Escape>

=item L<HTTP::MobileAgent::Plugin::Location::Support>

=item L<HTTP::MobileAgent::Plugin::Location::LocationObject>

=item L<HTTP::MobileAgent::Plugin::Location::AreaObject>

=back


=head1 AUTHOR

OHTSUKA Ko-hei  C<< <nene@kokogiko.net> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007, OHTSUKA Ko-hei C<< <nene@kokogiko.net> >>. 

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
