use 5.008;
use strict;
use warnings;

package Dist::Zilla::Plugin::Test::CheckChanges;
# ABSTRACT: Release tests for checking changes
our $VERSION = '2.000004'; # VERSION
use Moose;

extends 'Dist::Zilla::Plugin::InlineFiles';
__PACKAGE__->meta->make_immutable;
no Moose;
1;

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Test::CheckChanges - Release tests for checking changes

=head1 VERSION

version 2.000004

=head1 SYNOPSIS

In C<dist.ini>:

    [Test::CheckChanges]

=head1 DESCRIPTION

This is an extension of L<Dist::Zilla::Plugin::InlineFiles>, providing the
following file:

  xt/release/check-changes.t - a standard Test::CheckChanges test

=head1 AVAILABILITY

The project homepage is L<http://metacpan.org/release/Dist-Zilla-Plugin-Test-CheckChanges/>.

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<https://metacpan.org/module/Dist::Zilla::Plugin::Test::CheckChanges/>.

=head1 SOURCE

The development version is on github at L<http://github.com/doherty/Dist-Zilla-Plugin-Test-CheckChanges>
and may be cloned from L<git://github.com/doherty/Dist-Zilla-Plugin-Test-CheckChanges.git>

=head1 BUGS AND LIMITATIONS

You can make new bug reports, and view existing ones, through the
web interface at L<https://github.com/doherty/Dist-Zilla-Plugin-Test-CheckChanges/issues>.

=head1 AUTHORS

=over 4

=item *

Marcel Grünauer <marcel@cpan.org>

=item *

Mike Doherty <doherty@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Mike Doherty.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__
___[ xt/release/check-changes.t ]___
#!perl

use Test::More;

eval "use Test::CheckChanges";
plan skip_all => "Test::CheckChanges required for testing changes"
  if $@;
ok_changes();
