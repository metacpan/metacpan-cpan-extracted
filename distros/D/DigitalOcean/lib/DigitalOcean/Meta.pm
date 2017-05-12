use strict;
package DigitalOcean::Meta;
use Mouse;

#ABSTRACT: Represents a Meta object in the DigitalOcean API

has total => ( 
    is => 'ro',
    isa => 'Num',
);

#last HTTP::Response. 


__PACKAGE__->meta->make_immutable();

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DigitalOcean::Meta - Represents a Meta object in the DigitalOcean API

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
