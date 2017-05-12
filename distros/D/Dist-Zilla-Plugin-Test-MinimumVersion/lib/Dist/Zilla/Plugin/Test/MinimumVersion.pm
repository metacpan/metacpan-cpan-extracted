use 5.008;
use strict;
use warnings;

package Dist::Zilla::Plugin::Test::MinimumVersion;
# ABSTRACT: Release tests for minimum required versions
our $VERSION = '2.000007'; # VERSION

use Moose;
extends 'Dist::Zilla::Plugin::InlineFiles';
with 'Dist::Zilla::Role::TextTemplate',
    'Dist::Zilla::Role::PrereqSource',
    ;

sub register_prereqs {
    my $self = shift @_;

    $self->zilla->register_prereqs(
        { phase => 'develop' },
        'Test::MinimumVersion' => 0,
    );

    return;
}

has max_target_perl => (
    is => 'ro',
    isa => 'Str',
    predicate => 'has_max_target_perl',
);

around add_file => sub {
    my ($orig, $self, $file) = @_;
    $self->$orig(
        Dist::Zilla::File::InMemory->new({
            name => $file->name,
            content => $self->fill_in_string(
                $file->content,
                { (version => $self->max_target_perl)x!!$self->has_max_target_perl }
            ),
        })
    );
};

__PACKAGE__->meta->make_immutable;
no Moose;
1;

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Test::MinimumVersion - Release tests for minimum required versions

=head1 VERSION

version 2.000007

=for test_synopsis BEGIN { die "SKIP: Synopsis isn't Perl code" }

=for Pod::Coverage register_prereqs

=head1 SYNOPSIS

In C<dist.ini>:

    [Test::MinimumVersion]
    max_target_perl = 5.10.1

=head1 DESCRIPTION

This is an extension of L<Dist::Zilla::Plugin::InlineFiles>, providing a
L<Test::MinimumVersion> test:

  xt/release/minimum-version.t - a standard Test::MinimumVersion test

You should provide the highest perl version you want to require as
C<target_max_version>. If you accidentally use perl features that are newer
than that version number, then the test will fail, and you can go change
whatever bumped up the minimum perl version required.

=head1 AVAILABILITY

The project homepage is L<http://metacpan.org/release/Dist-Zilla-Plugin-Test-MinimumVersion/>.

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<https://metacpan.org/module/Dist::Zilla::Plugin::Test::MinimumVersion/>.

=head1 SOURCE

The development version is on github at L<http://github.com/doherty/Dist-Zilla-Plugin-Test-MinimumVersion>
and may be cloned from L<git://github.com/doherty/Dist-Zilla-Plugin-Test-MinimumVersion.git>

=head1 BUGS AND LIMITATIONS

You can make new bug reports, and view existing ones, through the
web interface at L<https://github.com/doherty/Dist-Zilla-Plugin-Test-MinimumVersion/issues>.

=head1 AUTHORS

=over 4

=item *

Mike Doherty <doherty@cpan.org>

=item *

Marcel Grünauer <marcel@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Mike Doherty.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__
___[ xt/release/minimum-version.t ]___
#!perl

use Test::More;

eval "use Test::MinimumVersion";
plan skip_all => "Test::MinimumVersion required for testing minimum versions"
  if $@;
{{ $version
    ? "all_minimum_version_ok( qq{$version} );"
    : "all_minimum_version_from_metayml_ok();"
}}
