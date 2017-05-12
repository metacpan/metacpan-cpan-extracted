package Exobrain::Types::Twitter;
use strict;
use warnings;

# ABSTRACT: Exobrain types for use in Twitter communications
our $VERSION = '1.04'; # VERSION

use MooseX::Types -declare => [qw(
    TweetStr
)];

use MooseX::Types::Moose qw(Str);

subtype TweetStr,
    as Str,
    where { length($_) <= 140 }
;

1;

__END__

=pod

=head1 NAME

Exobrain::Types::Twitter - Exobrain types for use in Twitter communications

=head1 VERSION

version 1.04

=head1 AUTHOR

Paul Fenwick <pjf@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Paul Fenwick.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
