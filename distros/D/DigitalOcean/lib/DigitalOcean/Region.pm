use strict;
package DigitalOcean::Region;
use Mouse;

#ABSTRACT: Represents a Region object in the DigitalOcean API

has slug => ( 
    is => 'ro',
    isa => 'Undef|Str',
);

has name => ( 
    is => 'ro',
    isa => 'Str',
);

has sizes => (
    is => 'ro',
    isa => 'ArrayRef[Str]',
    default => sub { [] },
);

has available => ( 
    is => 'ro',
    isa => 'Bool',
);

has features => (
    is => 'ro',
    isa => 'ArrayRef[Str]',
    default => sub { [] },
);


__PACKAGE__->meta->make_immutable();

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DigitalOcean::Region - Represents a Region object in the DigitalOcean API

=head1 VERSION

version 0.17

=head1 SYNOPSIS

    FILL ME IN   

=head1 DESCRIPTION

FILL ME IN

=head1 METHODS

=head2 id

=head1 AUTHOR

Adam Hopkins <srchulo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Adam Hopkins.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
