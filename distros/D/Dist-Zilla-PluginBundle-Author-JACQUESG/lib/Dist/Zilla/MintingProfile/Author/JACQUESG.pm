package Dist::Zilla::MintingProfile::Author::JACQUESG;
$Dist::Zilla::MintingProfile::Author::JACQUESG::VERSION = '0.02';
use strict;
use warnings;

use Moose;
with 'Dist::Zilla::Role::MintingProfile::ShareDir';

=head1 NAME

Dist::Zilla::MintingProfile::Author::JACQUESG - Minting profile used by JACQUESG

=head1 VERSION

version 0.02

=head1 SYNOPSIS

    $ dzil new -P Author::JACQUESG Some::Module

=head1 DESCRIPTION

B<Dist::Zilla::MintingProfile::Author::JACQUESG> is the L<Dist::Zilla> minting
profile used by JACQUESG.

=head1 AUTHOR

Jacques Germishuys <jacquesg@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright 2020 Jacques Germishuys.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Dist::Zilla::MintingProfile::Author::JACQUESG
