package Exobrain::Measurement::DirectMessage;

use Moose;
use Method::Signatures;

# ABSTRACT: A direct message of any sort
our $VERSION = '1.08'; # VERSION

# Declare that we will have a summary attribute. This is to make
# our roles happy.
sub summary;

# This needs to happen at begin time so it can add the 'payload'
# keyword.

# TODO: Should this *really* be a ::Social ?

BEGIN { with 'Exobrain::Measurement::Social'; }


# A summary *must* be provided
has summary => (
    isa => 'Str', is => 'ro', required => 1,
);

# Direct messages are to me, unless set otherwise.
has '+private' => ( default => 1 );
has '+to_me'   => ( default => 1 );

1;

__END__

=pod

=head1 NAME

Exobrain::Measurement::DirectMessage - A direct message of any sort

=head1 VERSION

version 1.08

=head1 DESCRIPTION

Requires everything from Measurement::Social

=head1 AUTHOR

Paul Fenwick <pjf@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Paul Fenwick.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
