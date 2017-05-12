package Exobrain::Intent::Tweet;

use v5.10.0;

use Moose;
use Method::Signatures;
use Exobrain::Types::Twitter qw( TweetStr );

# ABSTRACT: Intent message for twitter
our $VERSION = '1.04'; # VERSION

method summary() { return $self->tweet; }

BEGIN { with 'Exobrain::Intent'; }

payload tweet          => ( isa => TweetStr           );

# Actually this is an Int, but they get pretty large. Transmitting
# them as strings means we don't have to care about 32/64-bit issues.
payload in_response_to => ( isa => 'Str', required => 0 );

1;

__END__

=pod

=head1 NAME

Exobrain::Intent::Tweet - Intent message for twitter

=head1 VERSION

version 1.04

=head1 AUTHOR

Paul Fenwick <pjf@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Paul Fenwick.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
