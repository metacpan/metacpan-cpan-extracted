package Dist::Zilla::Plugin::Test::MixedScripts;

use v5.20;
use warnings;

# ABSTRACT: author tests to ensure there is no mixed Unicode

use Moose;

use List::Util 1.45 qw( uniqstr );
use Path::Tiny;
use Sub::Exporter::ForMethods 'method_installer';
use Data::Section 0.004 { installer => method_installer }, '-setup';
use Dist::Zilla::File::InMemory;
use Moose::Util::TypeConstraints qw( role_type );

use namespace::autoclean;

use experimental qw( postderef signatures );

with
  'Dist::Zilla::Role::FileGatherer',
  'Dist::Zilla::Role::FileMunger',
  'Dist::Zilla::Role::TextTemplate',
  'Dist::Zilla::Role::FileFinderUser' => {
    method           => 'found_files',
    finder_arg_names => ['finder'],
    default_finders  => [ ':InstallModules', ':ExecFiles', ':TestFiles' ],
  },
  'Dist::Zilla::Role::PrereqSource';

our $VERSION = 'v0.2.0';


has filename => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub { return 'xt/author/mixed-unicode-scripts.t' },
);


sub mvp_multivalue_args { qw( files exclude scripts ) }

sub mvp_aliases { return { file => 'files', script => 'scripts' } }


has files => (
    isa => 'ArrayRef[Str]',
    traits => ['Array'],
    handles => { files => 'elements' },
    lazy => 1,
    default => sub { [] },
);


has exclude => (
    is      => 'ro',
    isa     => 'ArrayRef',
    default => sub { [] },
);


has scripts => (
    isa     => 'ArrayRef[Str]',
    traits  => ['Array'],
    handles => { scripts => 'elements' },
    lazy    => 1,
    default => sub { [] },
);


has _file_obj => (
    is  => 'rw',
    isa => role_type('Dist::Zilla::Role::File'),
);

around dump_config => sub( $orig, $self ) {
    my $config = $self->$orig;
    $config->{ +__PACKAGE__ } = {
        filename => $self->filename,
        finder   => [ sort $self->finder->@* ],
        scripts  => [ $self->scripts ],
        blessed($self) ne __PACKAGE__ ? ( version => $VERSION ) : (),
    };
    return $config;
};

sub gather_files($self) {

    $self->add_file(
        $self->_file_obj(
            Dist::Zilla::File::InMemory->new(
                name    => $self->filename,
                content => ${ $self->section_data('__TEST__') },
            )
        )
    );
    return;
}

sub munge_files($self) {

    # Based on Dist::Zilla::Plugin::GatherDir
    my $exclude = qr/\000/;
    $exclude = qr/(?:$exclude)|$_/ for $self->exclude->@*;

    my @filenames = map { path( $_->name )->relative('.')->stringify }
      grep { not( $_->can('is_bytes') and $_->is_bytes ) }
      grep { $_ !~ $exclude }
      $self->found_files->@*;
    push @filenames, $self->files;
    $self->log_debug( 'adding file ' . $_ ) for @filenames;

    my @scripts = $self->scripts;

    my $file = $self->_file_obj;
    $file->content(
        $self->fill_in_string(
            $file->content,
            {
                dist      => \( $self->zilla ),
                plugin    => \$self,
                filenames => [ sort @filenames ],
                scripts   => [ uniqstr @scripts ],
            },
        )
    );
    return;
}

sub register_prereqs($self) {
    $self->zilla->register_prereqs(
        {
            phase => 'develop',
            type  => 'requires',
        },
        'Test2::Tools::Basic' => '1.302200',
        'Test::MixedScripts' => 'v0.3.0',
    );
}

__PACKAGE__->meta->make_immutable;

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Test::MixedScripts - author tests to ensure there is no mixed Unicode

=head1 VERSION

version v0.2.0

=for stopwords Cushing Etheridge Florian Ragwitz Unicode

=head1 SYNOPSIS

In the F<dist.ini> add:

    [Test::MixedScripts]
    ; authordep Test::MixedScripts
    script = Latin
    script = Common

=head1 DESCRIPTION

This generates an author L<Test::MixedScripts>.

This is an extension of L<Dist::Zilla::Plugin::InlineFiles>, providing the file F<xt/author/mixed-unicode-scripts.t> for
testing against mixed Unicode scripts that are potentially confusing or malicious.

For example, the text for the domain names C<< E<0x043e>nE<0x0435>.example.com >> and C<one.example.com> look indistinguishable in many fonts,
but the first one has Cyrillic letters.  If your software interacted with a service on the second domain, then someone
can operate a service on the first domain and attempt to fool developers into using their domain instead.

This might be through a malicious patch submission, or even text from an email or web page that they have convinced a
developer to copy and paste into their code.

=head1 CONFIGURATION OPTIONS

=head2 filename

This is the filename of the test to add. Defaults to F<xt/author/mixed-unicode-scripts.t>.

=head2 finder

This is the name of a C<FileFinder> for finding files to check. The default value is C<:InstallModules>, C<:ExecFiles> (see also
L<Dist::Zilla::Plugin::ExecDir>) and C<:TestFiles>.

This option can be used more than once.

Other predefined finders are listed in "default_finders" in L<Dist::Zilla::Role::FileFinderUser>.
You can define your own with the L<FileFinder::ByName plugin|Dist::Zilla::Plugin::FileFinder::ByName>.

=head2 file

This is a filename to also test, in addition to any files found earlier.

This option can be repeated to specify multiple additional files.

=head2 exclude

This is a regular expression of filenames to exclude.

This option can be repeated to specify multiple patterns.

=head2 script

This specifies the scripts to test for.  If none are specified, it defaults to the defaults for L<Test::MixedScripts>.

=for Pod::Coverage dump_config

=for Pod::Coverage gather_files

=for Pod::Coverage munge_files

=for Pod::Coverage mvp_aliases

=for Pod::Coverage register_prereqs

=head1 KNOWN ISSUES

The default L</finder> does not include XS-related files. You will have to add them manually using the L</file> option,
for example, in the F<dist.ini>:

    [Test::MixedScripts]
    file = XS.xs
    file = XS.c

=head1 SUPPORT

Only the latest version of this module will be supported.

This module requires Perl v5.16 or later.  Future releases may only support Perl versions released in the last ten
years.

=head2 Reporting Bugs and Submitting Feature Requests

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/robrwo/perl-Dist-Zilla-Plugin-Test-MixedScripts/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

If the bug you are reporting has security implications which make it inappropriate to send to a public issue tracker,
then see F<SECURITY.md> for instructions how to report security vulnerabilities.

=head1 SOURCE

The development version is on github at L<https://github.com/robrwo/perl-Dist-Zilla-Plugin-Test-MixedScripts>
and may be cloned from L<git://github.com/robrwo/perl-Dist-Zilla-Plugin-Test-MixedScripts.git>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

This code was based on L<Dist::Zilla::Plugin::Test::EOL> by Florian Ragwitz <rafl@debian.org>, Caleb Cushing
<xenoterracide@gmail.com> and Karen Etheridge <ether@cpan.org>.

=head1 CONTRIBUTOR

=for stopwords Graham Knop

Graham Knop <haarg@haarg.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Robert Rothenberg.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__
___[ __TEST__ ]___
use strict;
use warnings;

# This test was generated with {{ ref $plugin }} {{ $plugin->VERSION }}.

use Test2::Tools::Basic 1.302200;

use Test::MixedScripts qw( file_scripts_ok );

my @scxs = ( {{ join( ", ", map { "'" . $_ . "'" } @scripts ) }} );

my @files = (
{{ join(",\n", map { "    '" . $_ . "'" } map { s/'/\\'/g; $_ } @filenames) }}
);

file_scripts_ok($_, { scripts => \@scxs } ) for @files;

done_testing;
