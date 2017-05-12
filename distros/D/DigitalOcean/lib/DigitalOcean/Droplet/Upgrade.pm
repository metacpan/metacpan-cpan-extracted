use strict;
package DigitalOcean::Droplet::Upgrade;
use Mouse;

#ABSTRACT: Represents a droplet upgrade object in the DigitalOcean API


has droplet_id => ( 
    is => 'ro',
    isa => 'Num',
);


has date_of_migration => ( 
    is => 'ro',
    isa => 'Str',
);


has url => ( 
    is => 'ro',
    isa => 'Str',
);


__PACKAGE__->meta->make_immutable();

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DigitalOcean::Droplet::Upgrade - Represents a droplet upgrade object in the DigitalOcean API

=head1 VERSION

version 0.16

=head1 SYNOPSIS

    FILL ME IN   

=head1 DESCRIPTION

FILL ME IN

=head1 METHODS

=head2 droplet_id

The affected droplet's ID.

=head2 date_of_migration

A time value given in ISO8601 combined date and time format that represents when the migration will occur for the droplet.

=head2 url

A URL pointing to the Droplet's API endpoint. This is the endpoint to be used if you want to retrieve information about the droplet.

=head2 id

=head1 AUTHOR

Adam Hopkins <srchulo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Adam Hopkins.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
