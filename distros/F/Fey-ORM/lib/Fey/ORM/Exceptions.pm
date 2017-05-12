package Fey::ORM::Exceptions;

use strict;
use warnings;

our $VERSION = '0.47';

use Fey::Exceptions;

my %E;

BEGIN {
    %E = (
        'Fey::Exception::NoSuchRow' => {
            description => 'No row was found for a specified key.',
            isa         => 'Fey::Exception',
            alias       => 'no_such_row',
        },
    );
}

use Exception::Class (%E);

Fey::Exception->Trace(1);

use Sub::Exporter -setup =>
    { exports => [ map { $_->{alias} || () } values %E ] };

1;

# ABSTRACT: Defines exceptions used for Fey::ORM

__END__

=pod

=head1 NAME

Fey::ORM::Exceptions - Defines exceptions used for Fey::ORM

=head1 VERSION

version 0.47

=head1 SYNOPSIS

  use Fey::ORM::Exceptions qw( no_such_row );

=head1 DESCRIPTION

This module defines the exceptions which are used by the core Fey
classes.

=head1 EXCEPTIONS

Loading this module defines the exception classes using
C<Exception::Class>. This module also exports subroutines which can be
used as a shorthand to throw a specific type of exception.

=head2 Fey::ORM::Exceptions

Cannot find a row in a given table matching the given values

=head2 no_such_row()

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 - 2015 by Dave Rolsky.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
