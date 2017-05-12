use strict;
package DigitalOcean::Account;
use Mouse;

#ABSTRACT: Represents an Account object in the DigitalOcean API


has droplet_limit => ( 
    is => 'ro',
    isa => 'Num',
);


has email => ( 
    is => 'ro',
    isa => 'Str',
);


has uuid => ( 
    is => 'ro',
    isa => 'Str',
);


has email_verified => ( 
    is => 'ro',
    isa => 'Bool',
);


__PACKAGE__->meta->make_immutable();

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DigitalOcean::Account - Represents an Account object in the DigitalOcean API

=head1 VERSION

version 0.16

=head1 SYNOPSIS

    FILL ME IN   

=head1 DESCRIPTION

FILL ME IN

=head1 METHODS

=head2 droplet_limit

The total number of droplets the user may have

=head2 email

The email the user has registered for Digital Ocean with

=head2 uuid

The universal identifier for this user

=head2 email_verified

If true, the user has verified their account via email. False otherwise.

=head2 id

=head1 AUTHOR

Adam Hopkins <srchulo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Adam Hopkins.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
