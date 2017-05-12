package Log::Tree::Logger;
$Log::Tree::Logger::VERSION = '0.18';
our $AUTHORITY = 'cpan:TEX';
# ABSTRACT: role providing a lazy initialized logger

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
use Log::Tree;

# extends ...
# has ...
has 'logger' => (
    'is'    => 'ro',
    'isa'   => 'Log::Tree',
    'lazy'  => 1,
    'builder' => '_init_logger',
    'handles' => [qw(log)],
);
# with ...
# initializers ...
sub _init_logger {
    my $self = shift;

    my $Logger = Log::Tree::->new($self->_log_facility());

    return $Logger;
}
# requires ...
requires '_log_facility';

# your code here ...

no Moose::Role;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::Tree::Logger - role providing a lazy initialized logger

=head1 NAME

Log::Tree::Logger - Role for a lazy initialized logger.

=head1 AUTHOR

Dominik Schulz <dominik.schulz@gauner.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Dominik Schulz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
