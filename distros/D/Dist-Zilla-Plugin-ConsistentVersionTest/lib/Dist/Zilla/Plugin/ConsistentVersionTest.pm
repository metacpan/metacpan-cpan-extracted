#
# This file is part of Dist-Zilla-Plugin-ConsistentVersionTest
#
# This software is copyright (c) 2010 by Dave Rolsky.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package Dist::Zilla::Plugin::ConsistentVersionTest;
our $AUTHORITY = 'cpan:RSRCHBOY';
# git description: 091ea5c
$Dist::Zilla::Plugin::ConsistentVersionTest::VERSION = '0.03';

use strict;
use warnings;

use Test::ConsistentVersion;

use Moose;

extends 'Dist::Zilla::Plugin::InlineFiles';
with 'Dist::Zilla::Role::PrereqSource';


sub register_prereqs {
    my $self = shift @_;

    $self->zilla->register_prereqs(
        { phase => 'develop' },
        'Test::ConsistentVersion' => 0,
    );

    return;
}

no Moose;

__PACKAGE__->meta->make_immutable;

1;

# ABSTRACT: Adds a release test to ensure that all modules have the same $VERSION

=pod

=encoding UTF-8

=for :stopwords Dave Rolsky Chris Weyl

=head1 NAME

Dist::Zilla::Plugin::ConsistentVersionTest - Adds a release test to ensure that all modules have the same $VERSION

=head1 VERSION

This document describes version 0.03 of Dist::Zilla::Plugin::ConsistentVersionTest - released April 01, 2017 as part of Dist-Zilla-Plugin-ConsistentVersionTest.

=head1 SYNOPSIS

In your F<dist.ini>:

  [ConsistentVersionTest]

=head1 DESCRIPTION

This is an extension of L<Dist::Zilla::Plugin::InlineFiles>, providing the
following files

  xt/release/consistent-version.t

=head1 METHODS

=head2 register_prereqs

Registers a 'develop' phase requirement for L<Test::ConsistentVersion> with the
L<Dist::Zilla> object.

=head1 DONATIONS

If you'd like to thank me (the author, Dave Rolsky) for the work I've done on
this module, please consider making a "donation" to me via PayPal. I spend a
lot of free time creating free software, and would appreciate any support
you'd care to offer.

Please note that B<I am not suggesting that you must do this> in order for me
to continue working on this particular software. I will continue to do so,
inasmuch as I have in the past, for as long as it interests me.

Similarly, a donation made in this way will probably not make me work on this
software much more, unless I get so many donations that I can consider working
on free software full time, which seems unlikely at best.

To donate, log into PayPal and send money to autarch@urth.org or use the
button on this page: L<http://www.urth.org/~autarch/fs-donation.html>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/RsrchBoy/Dist-Zilla-Plugin-ConsistentVersionTest/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 CONTRIBUTOR

=for stopwords Chris Weyl

Chris Weyl <rsrchboy@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Dave Rolsky.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__
___[ xt/release/consistent-version.t ]___
use strict;
use warnings;

use Test::More;

eval "use Test::ConsistentVersion";
plan skip_all => "Test::ConsistentVersion required for this test"
    if $@;

Test::ConsistentVersion::check_consistent_versions();
