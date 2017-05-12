package Log::Tree::RequiredLogger;
$Log::Tree::RequiredLogger::VERSION = '0.18';
our $AUTHORITY = 'cpan:TEX';
# ABSTRACT: role providing a required logger attribute

use 5.010_000;
use mro 'c3';
use feature ':5.10';

use Moose::Role;
use namespace::autoclean;

# use IO::Handle;
# use autodie;
# use MooseX::Params::Validate;
# use Carp;
# use English qw( -no_match_vars );
# use Try::Tiny;

# extends ...
# has ...
has 'logger' => (
    'is'    => 'ro',
    'isa'   => 'Log::Tree',
    'required'  => 1,
    'handles' => [qw(log)],
);
# with ...
# initializers ...
# requires ...

# your code here ...

no Moose::Role;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::Tree::RequiredLogger - role providing a required logger attribute

=head1 DESCRIPTION

This is a role which provides a required logger attribute
top it's consuming class.

=head1 NAME

Log::Tree::Logger - Role for a mandatory logger.

=head1 AUTHOR

Dominik Schulz <dominik.schulz@gauner.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Dominik Schulz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
