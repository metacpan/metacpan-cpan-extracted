use 5.008;
use strict;
use warnings;

package Dist::Zilla::Plugin::Test::Synopsis;
# ABSTRACT: Author tests for synopses
our $VERSION = '2.000007'; # VERSION
use Moose;
extends 'Dist::Zilla::Plugin::InlineFiles';
with 'Dist::Zilla::Role::PrereqSource';



# Register the test prereqs as "develop requires"
# so they will be listed in "dzil listdeps --author"
sub register_prereqs {
    my ($self) = @_;

    $self->zilla->register_prereqs(
        {
            type  => 'requires',
            phase => 'develop',
        },
        'Test::Synopsis' => '0',
    );
}


__PACKAGE__->meta->make_immutable;
no Moose;
1;

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Test::Synopsis - Author tests for synopses

=head1 VERSION

version 2.000007

=for test_synopsis BEGIN { die "SKIP: synopsis isn't perl code" }

=head1 SYNOPSIS

In C<dist.ini>:

    [Test::Synopsis]

=head1 DESCRIPTION

This is an extension of L<Dist::Zilla::Plugin::InlineFiles>, providing the
following file:

  xt/author/synopsis.t - a standard Test::Synopsis test

=head1 AVAILABILITY

The project homepage is L<http://metacpan.org/release/Dist-Zilla-Plugin-Test-Synopsis/>.

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<https://metacpan.org/module/Dist::Zilla::Plugin::Test::Synopsis/>.

=head1 SOURCE

The development version is on github at L<http://github.com/doherty/Dist-Zilla-Plugin-Test-Synopsis>
and may be cloned from L<git://github.com/doherty/Dist-Zilla-Plugin-Test-Synopsis.git>

=head1 BUGS AND LIMITATIONS

You can make new bug reports, and view existing ones, through the
web interface at L<https://github.com/doherty/Dist-Zilla-Plugin-Test-Synopsis/issues>.

=head1 AUTHORS

=over 4

=item *

Marcel Grünauer <marcel@cpan.org>

=item *

Mike Doherty <doherty@cpan.org>

=item *

Olivier Mengué <dolmen@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Mike Doherty.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__
___[ xt/author/synopsis.t ]___
#!perl

use Test::Synopsis;

all_synopsis_ok();
