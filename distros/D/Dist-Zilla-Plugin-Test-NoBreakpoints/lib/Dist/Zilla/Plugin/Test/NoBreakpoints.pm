use strict;
use warnings;
package Dist::Zilla::Plugin::Test::NoBreakpoints;
{
  $Dist::Zilla::Plugin::Test::NoBreakpoints::DIST = 'Dist-Zilla-Plugin-Test-NoBreakpoints';
}
# ABSTRACT: Author tests making sure no debugger breakpoints make it to 'released'
# KEYWORDS: plugin test testing author development debug debugger debugging breakpoint breakpoints
$Dist::Zilla::Plugin::Test::NoBreakpoints::VERSION = '0.0.2';
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

has filename => (
    is => 'ro', isa => 'Str',
    lazy => 1,
    default => sub { return 'xt/author/no-breakpoints.t' },
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
         map { $_ => $self->$_ } qw(filename finder),
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
            type  => 'requires',
            phase => 'develop',
        },
        'Test::More' => '0.88',
        'Test::NoBreakpoints' => '0.15',
    );
}

__PACKAGE__->meta->make_immutable;
1;

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Test::NoBreakpoints - Author tests making sure no debugger breakpoints make it to 'released'

=head1 VERSION

version 0.0.2

=head1 DESCRIPTION

Generate an author L<Test::NoBreakpoints>.

This is an extension of L<Dist::Zilla::Plugin::InlineFiles>, providing
the file F<xt/author/no-breakpoints.t>, a standard L<Test::NoBreakpoints> test.

=head1 CONFIGURATION OPTIONS

This plugin accepts the following options:

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

This module was B<heavily> cribbed from L<Dist::Zilla::Plugin::Test::EOL>.

=head1 SEE ALSO

=over 4

=item *

Test::NoBreakpoints

=back

=head1 AUTHOR

Chisel <chisel@chizography.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Chisel Wright.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__
___[ __TEST__ ]___
use strict;
use warnings;

# this test was generated with {{ ref($plugin) . ' ' . $plugin->VERSION }}

use Test::More 0.88;
use Test::NoBreakpoints 0.15;

all_files_no_breakpoints_ok();

done_testing;
