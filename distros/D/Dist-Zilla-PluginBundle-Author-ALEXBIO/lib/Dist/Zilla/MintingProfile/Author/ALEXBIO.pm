package Dist::Zilla::MintingProfile::Author::ALEXBIO;
{
  $Dist::Zilla::MintingProfile::Author::ALEXBIO::VERSION = '2.07';
}

use strict;
use warnings;

use Moose;
with 'Dist::Zilla::Role::MintingProfile::ShareDir';

=head1 NAME

Dist::Zilla::MintingProfile::Author::ALEXBIO - Minting profile used by ALEXBIO

=head1 VERSION

version 2.07

=head1 SYNOPSIS

    $ dzil new -P Author::ALEXBIO Some::Module

=head1 DESCRIPTION

B<Dist::Zilla::MintingProfile::Author::ALEXBIO> is the L<Dist::Zilla> minting
profile used by ALEXBIO.

=head1 AUTHOR

Alessandro Ghedini <alexbio@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Alessandro Ghedini.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Dist::Zilla::MintingProfile::Author::ALEXBIO
