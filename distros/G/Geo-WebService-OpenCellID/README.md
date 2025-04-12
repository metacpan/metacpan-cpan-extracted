# NAME

Geo::WebService::OpenCellID - Perl API for the opencellid.org database

# SYNOPSIS

    use Geo::WebService::OpenCellID;
    my $gwo=Geo::WebService::OpenCellID->new(key=>$apikey);
    my $point=$gwo->cell->get(mcc=>$country,
                              mnc=>$network,
                              lac=>$locale,
                              cellid=>$cellid);
    printf "Lat:%s, Lon:%s\n", $point->latlon;

# DESCRIPTION

Perl Interface to the database at http://www.opencellid.org/

# USAGE

# CONSTRUCTOR

## new

    my $obj = Geo::WebService::OpenCellID->new(
                                               key=>"myapikey",                   #default
                                               url=>"http://www.opencellid.org/", #default
                                              );

# METHODS

## key

Sets and returns the API key.

## url

Sets and returns the URL.  Defaults to http://www.opencellid.org/

## cell

Returns a [Geo::WebService::OpenCellID::cell](https://metacpan.org/pod/Geo%3A%3AWebService%3A%3AOpenCellID%3A%3Acell) object.

## measure

Returns a [Geo::WebService::OpenCellID::measure](https://metacpan.org/pod/Geo%3A%3AWebService%3A%3AOpenCellID%3A%3Ameasure) object.

# METHODS (INTERNAL)

## call

Calls the web service.

    my $data=$gwo->call($method_path, $response_class, %parameters);

## data\_xml

Returns a data structure given xml

    my $ref =$gwo->data_xml();

# COPYRIGHT

Copyright (c) 2025 Michael R. Davis

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

# SEE ALSO

[URI](https://metacpan.org/pod/URI), [LWP::Simple](https://metacpan.org/pod/LWP%3A%3ASimple), [XML::Simple](https://metacpan.org/pod/XML%3A%3ASimple)
