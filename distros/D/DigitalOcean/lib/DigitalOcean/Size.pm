use strict;
package DigitalOcean::Size;
use Mouse;

#ABSTRACT: Represents a Size object in the DigitalOcean API


has slug => ( 
    is => 'ro',
    isa => 'Str',
);


has available => ( 
    is => 'ro',
    isa => 'Bool',
);


has transfer => ( 
    is => 'ro',
    isa => 'Num',
);


has price_monthly => ( 
    is => 'ro',
    isa => 'Num',
);


has price_hourly => ( 
    is => 'ro',
    isa => 'Num',
);


has memory => ( 
    is => 'ro',
    isa => 'Num',
);


has vcpus => ( 
    is => 'ro',
    isa => 'Num',
);


has disk => ( 
    is => 'ro',
    isa => 'Num',
);


has regions => ( 
    is => 'ro',
    isa => 'ArrayRef[Str]',
);


__PACKAGE__->meta->make_immutable();

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DigitalOcean::Size - Represents a Size object in the DigitalOcean API

=head1 VERSION

version 0.17

=head1 SYNOPSIS

    FILL ME IN   

=head1 DESCRIPTION

FILL ME IN

=head1 METHODS

=head2 slug

A human-readable string that is used to uniquely identify each size.

=head2 available

This is a boolean value that represents whether new Droplets can be created with this size.

=head2 transfer

The amount of transfer bandwidth that is available for Droplets created in this size. This only counts traffic on the public interface. The value is given in terabytes.

=head2 price_monthly

This attribute describes the monthly cost of this Droplet size if the Droplet is kept for an entire month. The value is measured in US dollars.

=head2 price_hourly

This describes the price of the Droplet size as measured hourly. The value is measured in US dollars.

=head2 memory

The amount of RAM allocated to Droplets created of this size. The value is represented in megabytes.

=head2 vcpus

The number of virtual CPUs allocated to Droplets of this size.

=head2 disk

The amount of disk space set aside for Droplets of this size. The value is represented in gigabytes.

=head2 regions

An array containing the region slugs where this size is available for Droplet creates.

=head2 id

=head1 AUTHOR

Adam Hopkins <srchulo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Adam Hopkins.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
