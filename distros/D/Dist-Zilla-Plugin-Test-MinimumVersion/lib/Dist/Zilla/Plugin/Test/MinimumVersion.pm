use 5.008;
use strict;
use warnings;

package Dist::Zilla::Plugin::Test::MinimumVersion; # git description: v2.000010-9-g75411f8
# ABSTRACT: Author tests for minimum required versions

our $VERSION = '2.000011';

use Moose;
with
    'Dist::Zilla::Role::FileGatherer',
    'Dist::Zilla::Role::FileMunger',
    'Dist::Zilla::Role::TextTemplate',
    'Dist::Zilla::Role::PrereqSource';

use Sub::Exporter::ForMethods 'method_installer'; # method_installer returns a sub.
use Data::Section 0.004 # fixed header_re
    { installer => method_installer }, '-setup';
use List::Util 'first';
use Moose::Util::TypeConstraints 'role_type';
use namespace::autoclean;

has max_target_perl => (
    is => 'ro',
    isa => 'Str',
    predicate => 'has_max_target_perl',
);

use constant FILENAME => 'xt/author/minimum-version.t';  # could be configurable, someday..

around dump_config => sub
{
    my ($orig, $self) = @_;
    my $config = $self->$orig;

    $config->{+__PACKAGE__} = +{
        max_target_perl => $self->max_target_perl,
        blessed($self) ne __PACKAGE__ ? ( version => $VERSION ) : (),
    };
    return $config;
};

has _file => (
    is => 'rw', isa => role_type('Dist::Zilla::Role::File'),
);

sub gather_files
{
    my $self = shift;

    require Dist::Zilla::File::InMemory;
    $self->add_file($self->_file(
        Dist::Zilla::File::InMemory->new(
            name => FILENAME,
            content => ${$self->section_data(FILENAME)},
        ))
    );
    return;
}

sub munge_file
{
    my ($self, $file) = @_;

    return unless $file == $self->_file;
    $file->content(
        $self->fill_in_string(
            $file->content,
            { (version => $self->max_target_perl)x!!$self->has_max_target_perl }
        )
    );
    return;
}

#pod =for Pod::Coverage register_prereqs
#pod
#pod =cut

sub register_prereqs {
    my $self = shift;
    $self->zilla->register_prereqs(
        {
            type  => 'requires',
            phase => 'develop',
        },
        'Test::MinimumVersion' => 0,
    );
}

__PACKAGE__->meta->make_immutable;
1;

#pod =head1 SYNOPSIS
#pod
#pod In C<dist.ini>:
#pod
#pod     [Test::MinimumVersion]
#pod     max_target_perl = 5.10.1
#pod
#pod =head1 DESCRIPTION
#pod
#pod =for Pod::Coverage FILENAME gather_files munge_file register_prereqs
#pod
#pod This is an extension of L<Dist::Zilla::Plugin::InlineFiles>, providing a
#pod L<Test::MinimumVersion> test:
#pod
#pod   xt/author/minimum-version.t - a standard Test::MinimumVersion test
#pod
#pod You should provide the highest perl version you want to require as
#pod C<target_max_version>. If you accidentally use perl features that are newer
#pod than that version number, then the test will fail, and you can go change
#pod whatever bumped up the minimum perl version required.
#pod
#pod =cut

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Test::MinimumVersion - Author tests for minimum required versions

=head1 VERSION

version 2.000011

=head1 SYNOPSIS

In C<dist.ini>:

    [Test::MinimumVersion]
    max_target_perl = 5.10.1

=head1 DESCRIPTION

=for Pod::Coverage register_prereqs

=for Pod::Coverage FILENAME gather_files munge_file register_prereqs

This is an extension of L<Dist::Zilla::Plugin::InlineFiles>, providing a
L<Test::MinimumVersion> test:

  xt/author/minimum-version.t - a standard Test::MinimumVersion test

You should provide the highest perl version you want to require as
C<target_max_version>. If you accidentally use perl features that are newer
than that version number, then the test will fail, and you can go change
whatever bumped up the minimum perl version required.

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-Test-MinimumVersion>
(or L<bug-Dist-Zilla-Plugin-Test-MinimumVersion@rt.cpan.org|mailto:bug-Dist-Zilla-Plugin-Test-MinimumVersion@rt.cpan.org>).

There is also a mailing list available for users of this distribution, at
L<http://dzil.org/#mailing-list>.

There is also an irc channel available for users of this distribution, at
L<C<#distzilla> on C<irc.perl.org>|irc://irc.perl.org/#distzilla>.

=head1 AUTHORS

=over 4

=item *

Mike Doherty <doherty@cpan.org>

=item *

Marcel Grünauer <marcel@cpan.org>

=back

=head1 CONTRIBUTORS

=for stopwords Karen Etheridge Marcel Gruenauer Graham Knop Chris Weyl Kent Fredric

=over 4

=item *

Karen Etheridge <ether@cpan.org>

=item *

Marcel Gruenauer <hanekomu@gmail.com>

=item *

Graham Knop <haarg@haarg.org>

=item *

Chris Weyl <cweyl@alumni.drew.edu>

=item *

Kent Fredric <kentfredric@gmail.com>

=back

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2010 by Mike Doherty.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__
___[ xt/author/minimum-version.t ]___
use strict;
use warnings;

use Test::More;
use Test::MinimumVersion;
{{ $version
    ? "all_minimum_version_ok( qq{$version} );"
    : "all_minimum_version_from_metayml_ok();"
}}
