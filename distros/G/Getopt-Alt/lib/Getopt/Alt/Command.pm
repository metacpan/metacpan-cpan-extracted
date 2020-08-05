package Getopt::Alt::Command;

# Created on: 2010-03-25 18:04:47
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use Moose;
use version;
use Carp;
use English qw/ -no_match_vars /;

our $VERSION = version->new('0.5.4');

has cmd => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);
has module => (
    is  => 'ro',
    isa => 'Str',
);
has method => (
    is      => 'ro',
    isa     => 'Str',
    default => 'run',
);
has run => (
    is  => 'ro',
    isa => 'CodeRef',
);
has options => (
    is  => 'rw',
    isa => 'ArrayRef[Getopt::Alt::Option]',
);

around BUILDARGS => sub {
    my ($orig, $class, @params) = @_;
    my %param =
          @params == 1 && ref $params[0] eq 'HASH' ? %{ $params[0] }
        : @params == 1 && ref $params[0] ne 'HASH' ? ( cmd => $params[0] )
        :                                            @params;

    return $class->$orig(%param);
};

1;

__END__

=head1 NAME

Getopt::Alt::Command - Base for sub commands

=head1 VERSION

This documentation refers to Getopt::Alt::Command version 0.5.4.


=head1 SYNOPSIS

   use Getopt::Alt::Command;

   # Brief but working code example(s) here showing the most common usage(s)
   # This section will be as far as many users bother reading, so make it as
   # educational and exemplary as possible.


=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS


=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT


=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems to Ivan Wills (ivan.wills@gmail.com).

Patches are welcome.

=head1 AUTHOR

Ivan Wills - (ivan.wills@gmail.com)

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2010 Ivan Wills (14 Mullion Close, Hornsby Heights, NSW Australia 2077).
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.  This program is
distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut
