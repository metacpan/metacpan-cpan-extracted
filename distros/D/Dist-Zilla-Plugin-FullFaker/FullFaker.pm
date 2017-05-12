package Dist::Zilla::Plugin::FullFaker;

# $Id: FullFaker.pm 48 2015-07-01 06:38:25Z stro $

use strict;
use warnings;
use Moose;

extends qw[Dist::Zilla::Plugin::FakeFaker];

sub gather_files {
  return;
}

__PACKAGE__->meta->make_immutable;

no Moose;

BEGIN {
  $Dist::Zilla::Plugin::FullFaker::VERSION = '1.002';
}

1;

=head1 NAME

Dist::Zilla::Plugin::FullFaker - using existing Makefile.PL from other gatherer

=head1 SYNOPSIS

# in dist.ini

[FullFaker]

=head1 DESCRIPTION

Dist::Zilla::Plugin::FullFaker is a L<Dist::Zilla> plugin for those situations
when you want to use L<Dist::Zilla::Plugin::FakeFaker> but you have another
gatherer that added your C<Makefile.PL> file.

Instead of specifying C<[FakeFaker]> in one's C<dist.ini>, specify
C<[FullFaker]>

=head1 AUTHOR

Serguei Trouchelle <stro@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2015 by Serguei Trouchelle

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

