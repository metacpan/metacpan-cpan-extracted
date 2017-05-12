package Group::Git::Taggers::Node;

# Created on: 2015-04-18 19:09:45
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use Moo;
use strict;
use warnings;
use namespace::autoclean;
use version;
use Carp;
use English qw/ -no_match_vars /;

extends 'Group::Git::Taggers';

our $VERSION = version->new('0.0.2');

sub match {
    my ($self, $project) = @_;

    return -f 'package.json';
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Group::Git::Taggers::Node - Tags repositories as containing NodeJS code for Group::Git

=head1 VERSION

This documentation refers to Group::Git::Taggers::Node version 0.0.2

=head1 SYNOPSIS

   use Group::Git::Taggers::Node;

   # Brief but working code example(s) here showing the most common usage(s)
   # This section will be as far as many users bother reading, so make it as
   # educational and exemplary as possible.


=head1 DESCRIPTION

Looks at a repository and determines if it is a NodeJS repository based weather
it contains a package.json file

=head1 SUBROUTINES/METHODS

=head2 C<match ()>

Returns true if the repository contains a C<package.json> file.

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

Copyright (c) 2015 Ivan Wills (14 Mullion Close, Hornsby Heights, NSW Australia 2077).
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.  This program is
distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut
