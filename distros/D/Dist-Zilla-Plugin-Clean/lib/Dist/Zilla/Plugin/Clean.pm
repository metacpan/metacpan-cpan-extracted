package Dist::Zilla::Plugin::Clean;
{
  $Dist::Zilla::Plugin::Clean::VERSION = '0.07';
}

use strict;
use warnings;

use Moose;

with 'Dist::Zilla::Role::AfterRelease';

=head1 NAME

Dist::Zilla::Plugin::Clean - Clean after release

=head1 VERSION

version 0.07

=head1 SYNOPSIS

In your F<dist.ini>:

    [Clean]

=head1 DESCRIPTION

B<Dist::Zilla::Plugin::Clean> is a simple L<Dist::Zilla> plugin thet cleans the
working directory (just like C<dzil clean>) after a release.

=cut

sub after_release {
	my $self = shift;

	$self -> log('cleaning working directory');
	$self -> zilla -> clean;
}

=head1 AUTHOR

Alessandro Ghedini <alexbio@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Alessandro Ghedini.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

no Moose;

__PACKAGE__ -> meta -> make_immutable;

1; # End of Dist::Zilla::Plugin::Clean
