use strict;
package DigitalOcean::Network;
use Mouse;

#ABSTRACT: Represents a Network object in the DigitalOcean API

has ip_address => ( 
    is => 'ro',
    isa => 'Str',
);

has netmask => ( 
    is => 'ro',
    isa => 'Str',
);

has gateway => ( 
    is => 'ro',
    isa => 'Str',
);

has type => ( 
    is => 'ro',
    isa => 'Str',
);


__PACKAGE__->meta->make_immutable();

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DigitalOcean::Network - Represents a Network object in the DigitalOcean API

=head1 VERSION

version 0.16

=head1 SYNOPSIS

    FILL ME IN   

=head1 DESCRIPTION

FILL ME IN

=head1 METHODS

=head2 id

=head1 AUTHOR

Adam Hopkins <srchulo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Adam Hopkins.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
