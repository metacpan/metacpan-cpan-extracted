package Dist::Zilla::Plugin::SanityTests;
BEGIN {
  $Dist::Zilla::Plugin::SanityTests::AUTHORITY = 'cpan:FLORA';
}
BEGIN {
  $Dist::Zilla::Plugin::SanityTests::VERSION = '0.03';
}
# ABSTRACT: DEPRECATED - Release tests to avoid insanity

use Moose;
use namespace::autoclean;

extends 'Dist::Zilla::Plugin::InlineFiles';


__PACKAGE__->meta->make_immutable;

1;



=pod

=head1 NAME

Dist::Zilla::Plugin::SanityTests - DEPRECATED - Release tests to avoid insanity

=head1 DESCRIPTION

B<NOTE:> This module is deprecated. Please use
L<Dist::Zilla::Plugin::NoTabsTests> and
L<Dist::Zilla::Plugin::EOLTests> instead.

This is an extension of L<Dist::Zilla::Plugin::InlineFiles>, providing
the following files:

=over 4

=item *

xt/release/no_tabs.t

a standard Test::NoTabs test

=item *

xt/release/eol.t

a standard Test::EOL test

=back

=head1 AUTHOR

  Florian Ragwitz <rafl@debian.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Florian Ragwitz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__DATA__
___[ xt/release/no_tabs.t ]___
use strict;
use warnings;
use Test::More;

eval 'use Test::NoTabs';
plan skip_all => 'Test::NoTabs required' if $@;

all_perl_files_ok();

___[ xt/release/eol.t ]___
use strict;
use warnings;
use Test::More;

eval 'use Test::EOL';
plan skip_all => 'Test::EOL required' if $@;

all_perl_files_ok();

