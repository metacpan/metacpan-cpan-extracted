use strict;
package DigitalOcean::Snapshot;
use Mouse;

#ABSTRACT: Represents a Snapshot object in the DigitalOcean API

has DigitalOcean => ( 
    is => 'rw',
    isa => 'DigitalOcean',
);

has id => ( 
    is => 'ro',
    isa => 'Num',
);

has name => ( 
    is => 'ro',
    isa => 'Str',
);

has type => ( 
    is => 'ro',
    isa => 'Str',
);

has distribution => ( 
    is => 'ro',
    isa => 'Str',
);

has slug => ( 
    is => 'ro',
    isa => 'Undef|Str',
);

has public => ( 
    is => 'ro',
    isa => 'Bool',
);

has regions => ( 
    is => 'ro',
    isa => 'ArrayRef[Str]',
);

has min_disk_size => (
    is => 'ro',
    isa => 'Num',
);


__PACKAGE__->meta->make_immutable();

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DigitalOcean::Snapshot - Represents a Snapshot object in the DigitalOcean API

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
