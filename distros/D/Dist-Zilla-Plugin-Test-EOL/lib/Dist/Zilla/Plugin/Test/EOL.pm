use strict;
use warnings;
package Dist::Zilla::Plugin::Test::EOL; # git description: 0.18-26-gf608025
# vim: set ts=8 sts=4 sw=4 tw=115 et :
# ABSTRACT: Author tests making sure correct line endings are used
# KEYWORDS: plugin test testing author development whitespace newline linefeed formatting

our $VERSION = '0.19';

use Moose;
use Path::Tiny;
use Sub::Exporter::ForMethods 'method_installer';
use Data::Section 0.004 # fixed header_re
    { installer => method_installer }, '-setup';
use Moose::Util::TypeConstraints 'role_type';
use namespace::autoclean;

with
    'Dist::Zilla::Role::FileGatherer',
    'Dist::Zilla::Role::FileMunger',
    'Dist::Zilla::Role::TextTemplate',
    'Dist::Zilla::Role::FileFinderUser' => {
        method          => 'found_files',
        finder_arg_names => [ 'finder' ],
        default_finders => [ ':InstallModules', ':ExecFiles', ':TestFiles' ],
    },
    'Dist::Zilla::Role::PrereqSource',
;

has trailing_whitespace => (
    is      => 'ro',
    isa     => 'Bool',
    default => 1,
);

has filename => (
    is => 'ro', isa => 'Str',
    lazy => 1,
    default => sub { return 'xt/author/eol.t' },
);

has files => (
    isa => 'ArrayRef[Str]',
    traits => ['Array'],
    handles => { files => 'elements' },
    lazy => 1,
    default => sub { [] },
);

has _file_obj => (
    is => 'rw', isa => role_type('Dist::Zilla::Role::File'),
);

sub mvp_multivalue_args { 'files' }
sub mvp_aliases { return { file => 'files' } }

around dump_config => sub
{
    my ($orig, $self) = @_;
    my $config = $self->$orig;

    $config->{+__PACKAGE__} = {
        trailing_whitespace => $self->trailing_whitespace ? 1 : 0,
        filename => $self->filename,
        finder => [ sort @{ $self->finder } ],
        blessed($self) ne __PACKAGE__ ? ( version => $VERSION ) : (),
    };
    return $config;
};

sub gather_files
{
    my $self = shift;

    require Dist::Zilla::File::InMemory;

    $self->add_file(
        $self->_file_obj(
            Dist::Zilla::File::InMemory->new(
                name => $self->filename,
                content => ${$self->section_data('__TEST__')},
            )
        )
    );

    return;
}

sub munge_files
{
    my $self = shift;

    my @filenames = map { path($_->name)->relative('.')->stringify }
        grep { not ($_->can('is_bytes') and $_->is_bytes) }
        @{ $self->found_files };
    push @filenames, $self->files;

    $self->log_debug('adding file ' . $_) foreach @filenames;

    my $file = $self->_file_obj;
    $file->content(
        $self->fill_in_string(
            $file->content,
            {
                dist => \($self->zilla),
                plugin => \$self,
                filenames => [ sort @filenames ],
                trailing_ws => \$self->trailing_whitespace,
            },
        )
    );

    return;
}

sub register_prereqs
{
    my $self = shift;
    $self->zilla->register_prereqs(
        {
            phase => 'develop',
            type  => 'requires',
        },
        'Test::More' => '0.88',
        'Test::EOL' => '0',
    );
}

__PACKAGE__->meta->make_immutable;
1;

#pod =pod
#pod
#pod =head1 DESCRIPTION
#pod
#pod Generate an author L<Test::EOL>.
#pod
#pod This is an extension of L<Dist::Zilla::Plugin::InlineFiles>, providing
#pod the file F<xt/author/eol.t>, a standard L<Test::EOL> test.
#pod
#pod =head1 CONFIGURATION OPTIONS
#pod
#pod This plugin accepts the following options:
#pod
#pod =head2 C<trailing_whitespace>
#pod
#pod If this option is set to a true value,
#pod C<< { trailing_whitespace => 1 } >> will be passed to
#pod L<Test::EOL/all_perl_files_ok>. It defaults to C<1>.
#pod
#pod What this option is going to do is test for the lack of trailing whitespace at
#pod the end of the lines (also known as "trailing space").
#pod
#pod =head2 C<finder>
#pod
#pod =for stopwords FileFinder
#pod
#pod This is the name of a L<FileFinder|Dist::Zilla::Role::FileFinder> for finding
#pod files to check.  The default value is C<:InstallModules>,
#pod C<:ExecFiles> (see also L<Dist::Zilla::Plugin::ExecDir>) and C<:TestFiles>;
#pod this option can be used more than once.
#pod
#pod Other predefined finders are listed in
#pod L<Dist::Zilla::Role::FileFinderUser/default_finders>.
#pod You can define your own with the
#pod L<[FileFinder::ByName]|Dist::Zilla::Plugin::FileFinder::ByName> plugin.
#pod
#pod =head2 C<file>
#pod
#pod a filename to also test, in addition to any files found
#pod earlier. This option can be repeated to specify multiple additional files.
#pod
#pod =head2 C<filename>
#pod
#pod The filename of the test to add - defaults to F<xt/author/test-eol.t>.
#pod
#pod =for Pod::Coverage mvp_multivalue_args mvp_aliases gather_files munge_files register_prereqs
#pod
#pod =head1 ACKNOWLEDGMENTS
#pod
#pod This module is a fork of L<Dist::Zilla::Plugin::EOLTests> and was originally
#pod written by Florian Ragwitz. It was forked because the Test:: namespace
#pod is preferred for test modules, and because I would prefer to have EOL tests
#pod be Author tests.
#pod
#pod =head1 SEE ALSO
#pod
#pod =for :list
#pod * Test::EOL
#pod
#pod =cut

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Test::EOL - Author tests making sure correct line endings are used

=head1 VERSION

version 0.19

=head1 DESCRIPTION

Generate an author L<Test::EOL>.

This is an extension of L<Dist::Zilla::Plugin::InlineFiles>, providing
the file F<xt/author/eol.t>, a standard L<Test::EOL> test.

=head1 CONFIGURATION OPTIONS

This plugin accepts the following options:

=head2 C<trailing_whitespace>

If this option is set to a true value,
C<< { trailing_whitespace => 1 } >> will be passed to
L<Test::EOL/all_perl_files_ok>. It defaults to C<1>.

What this option is going to do is test for the lack of trailing whitespace at
the end of the lines (also known as "trailing space").

=head2 C<finder>

=for stopwords FileFinder

This is the name of a L<FileFinder|Dist::Zilla::Role::FileFinder> for finding
files to check.  The default value is C<:InstallModules>,
C<:ExecFiles> (see also L<Dist::Zilla::Plugin::ExecDir>) and C<:TestFiles>;
this option can be used more than once.

Other predefined finders are listed in
L<Dist::Zilla::Role::FileFinderUser/default_finders>.
You can define your own with the
L<[FileFinder::ByName]|Dist::Zilla::Plugin::FileFinder::ByName> plugin.

=head2 C<file>

a filename to also test, in addition to any files found
earlier. This option can be repeated to specify multiple additional files.

=head2 C<filename>

The filename of the test to add - defaults to F<xt/author/test-eol.t>.

=for Pod::Coverage mvp_multivalue_args mvp_aliases gather_files munge_files register_prereqs

=head1 ACKNOWLEDGMENTS

This module is a fork of L<Dist::Zilla::Plugin::EOLTests> and was originally
written by Florian Ragwitz. It was forked because the Test:: namespace
is preferred for test modules, and because I would prefer to have EOL tests
be Author tests.

=head1 SEE ALSO

=over 4

=item *

Test::EOL

=back

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-Test-EOL>
(or L<bug-Dist-Zilla-Plugin-Test-EOL@rt.cpan.org|mailto:bug-Dist-Zilla-Plugin-Test-EOL@rt.cpan.org>).

There is also a mailing list available for users of this distribution, at
L<http://dzil.org/#mailing-list>.

There is also an irc channel available for users of this distribution, at
L<C<#distzilla> on C<irc.perl.org>|irc://irc.perl.org/#distzilla>.

=head1 AUTHORS

=over 4

=item *

Florian Ragwitz <rafl@debian.org>

=item *

Caleb Cushing <xenoterracide@gmail.com>

=item *

Karen Etheridge <ether@cpan.org>

=back

=head1 CONTRIBUTORS

=for stopwords Olivier Mengué Shlomi Fish

=over 4

=item *

Olivier Mengué <dolmen@cpan.org>

=item *

Shlomi Fish <shlomif@shlomifish.org>

=back

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2010 by Florian Ragwitz <rafl@debian.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__
___[ __TEST__ ]___
use strict;
use warnings;

# this test was generated with {{ ref $plugin }} {{ $plugin->VERSION }}

use Test::More 0.88;
use Test::EOL;

my @files = (
{{ join(",\n", map { "    '" . $_ . "'" } map { s/'/\\'/g; $_ } @filenames) }}
);

eol_unix_ok($_, { trailing_whitespace => {{ $trailing_ws }} }) foreach @files;
done_testing;
