#
# This file is part of Dist-Zilla-Role-ContributorSource
#
# This software is Copyright (c) 2014 by Chris Weyl.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
package Dist::Zilla::Role::ContributorSource;
BEGIN {
  $Dist::Zilla::Role::ContributorSource::AUTHORITY = 'cpan:RSRCHBOY';
}
# git description: e2f262d
$Dist::Zilla::Role::ContributorSource::VERSION = '0.001';

# ABSTRACT: Something that finds and provides contributors.

use Moose::Role;
use namespace::autoclean;


requires 'contributors';


!!42;

__END__

=pod

=encoding UTF-8

=for :stopwords Chris Weyl

=head1 NAME

Dist::Zilla::Role::ContributorSource - Something that finds and provides contributors.

=head1 VERSION

This document describes version 0.001 of Dist::Zilla::Role::ContributorSource - released April 25, 2014 as part of Dist-Zilla-Role-ContributorSource.

=head1 SYNOPSIS

    # in your Dist::Zilla thing...
    with 'Dist::Zilla::Role::ContributorSource';

    sub contributors { ... }

=head1 DESCRIPTION

A simple interface role to define what plugins provide information about the
contributors to the distribution, much as L<Dist::Zilla::Role::PrereqSource>
does for distribution prerequisites.

=head1 REQUIRED METHODS

=head2 contributors

Returns a list of the contributors sourced by this... thing.  The list should
be comprised of L<Dist::Zilla::Stash::Contributors::Contributor> objects.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Dist::Zilla::Stash::Contributors>

=back

=head1 SOURCE

The development version is on github at L<http://https://github.com/RsrchBoy/dist-zilla-role-contributorsource>
and may be cloned from L<git://https://github.com/RsrchBoy/dist-zilla-role-contributorsource.git>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/RsrchBoy/dist-zilla-role-contributorsource/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Chris Weyl <cweyl@alumni.drew.edu>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Chris Weyl.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999

=cut
