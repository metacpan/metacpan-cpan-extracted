# NAME

Geography::China::Provinces - To retrieve ISO 3166:CN standard Chinese provinces

# SYNOPSIS

    use Geography::China::Provinces;

    my @municipals = Geography::China::Provinces->municipals;

    my @provinces = Geography::China::Provinces->provinces;

    my @autonomous_regions = Geography::China::Provinces->autonomous_regions;

    my @special_admin_regions = Geography::China::Provinces->special_admin_regions;

    my $region = Geography::China::Provinces->iso(11);

# DESCRIPTION

This module helps retrieving ISO standard Chinese provincial level divisions.

# SEE ALSO

[http://en.wikipedia.org/wiki/Provinces\_of\_the\_People's\_Republic\_of\_China](http://en.wikipedia.org/wiki/Provinces_of_the_People&#x27;s_Republic_of_China)

# INTERFACE

## all

    my @regions = Geography::China::Provinces->all;
    #=> Get all regions

## municipals

    my @regions = Geography::China::Provinces->municipals;
    #=> Get all municipal cities

## provinces

    my @regions = Geography::China::Provinces->provinces;
    #=> Get all provinces

## autonomous\_regions

    my @regions = Geography::China::Provinces->autonomous_regions;
    #=> Get all autonomous regions

## special\_admin\_regions

    my @regions = Geography::China::Provinces->special_admin_regions;
    #=> Get all special administrative regions

## areas

    my %areas = Geography::China::Provinces->areas;
    #=> Get Chinese geographic areas as a hash

## area

    my @regions = Geography::China::Provinces->area(1);
    #=> Get regions in area 1

## area\_name

    my @regions = Geography::China::Provinces->area_name('huadong');
    #=> Get regions in area `huadong'

## iso

    my $region = Geography::China::Provinces->iso(11);
    #=> Get region with ISO code 11

## category

    my @regions = Geography::China::Provinces->category('municipality');
    #=> Get municipal regions

# AUTHOR

yowcow  `<yowcow@cpan.org>`

# LICENCE AND COPYRIGHT

Copyright (c) 2011-2014, yowcow `<yowcow@cpan.org>`. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See [perlartistic](https://metacpan.org/pod/perlartistic).
