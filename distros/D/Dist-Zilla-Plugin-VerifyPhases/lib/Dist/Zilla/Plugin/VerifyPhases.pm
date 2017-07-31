use strict;
use warnings;
package Dist::Zilla::Plugin::VerifyPhases; # git description: v0.015-3-g33016d6
# vim: set ts=8 sts=4 sw=4 tw=115 et :
# ABSTRACT: Compare data and files at different phases of the distribution build process
# KEYWORDS: plugin distribution configuration phase verification validation

our $VERSION = '0.016';

use Moose;
with
    'Dist::Zilla::Role::BeforeBuild',
    'Dist::Zilla::Role::FileGatherer',
    'Dist::Zilla::Role::EncodingProvider',
    'Dist::Zilla::Role::FilePruner',
    'Dist::Zilla::Role::FileMunger',
    'Dist::Zilla::Role::AfterBuild',
    'Dist::Zilla::Role::BeforeRelease',
    'Dist::Zilla::Role::Releaser',
    'Dist::Zilla::Role::AfterRelease';
use Moose::Util 'find_meta';
use Digest::MD5 'md5_hex';
use List::Util 1.33 qw(none any);
use Term::ANSIColor 3.00 'colored';
use Storable 'dclone';
use Test::Deep::NoTest qw(cmp_details deep_diag);
use namespace::autoclean;

# filename => [ { object => $file_object, content => $checksummed_content } ]
my %all_files;

# returns the filename and index under which the provided file can be found
sub _search_all_files
{
    my ($self, $file) = @_;

    for my $filename (keys %all_files)
    {
        foreach my $index (0 .. $#{$all_files{$filename}})
        {
            return ($filename, $index) if $all_files{$filename}[$index]{object} == $file;
        }
    }
}

#sub mvp_multivalue_args { qw(skip) }
has skip_file => (
    isa => 'ArrayRef[Str]',
    traits => [ 'Array' ],
    handles => { skip_file => 'elements' },
    init_arg => undef,   # do not allow in configs just yet
    lazy => 1,
    default => sub { [ qw(Makefile.PL Build.PL) ] },
);

has skip_distmeta => (
    isa => 'ArrayRef[Str]',
    traits => [ 'Array' ],
    handles => { skip_distmeta => 'elements' },
    init_arg => undef,   # do not allow in configs just yet
    lazy => 1,
    default => sub { [ qw(x_static_install) ] },
);

my %zilla_constructor_args;

sub BUILD
{
    my $self = shift;
    my $zilla = $self->zilla;
    my $meta = find_meta($zilla);

    # no phases have been run yet, so we can effectively capture the initial
    # state of the zilla object (and determine its construction args)
    %zilla_constructor_args = map {
        my $attr = $meta->find_attribute_by_name($_);
        $attr && $attr->has_value($zilla) ? ( $_ => $attr->get_value($zilla) ) : ()
    } qw(name version release_status abstract main_module authors distmeta _license_class _copyright_holder _copyright_year);
}

# no reason to include configs - this plugin does not alter the build output
around dump_config => sub
{
    my ($orig, $self) = @_;
    my $config = $self->$orig;

    my $data = {
        blessed($self) ne __PACKAGE__ ? ( version => $VERSION ) : (),
    };
    $config->{+__PACKAGE__} = $data if keys %$data;

    return $config;
};

sub before_build
{
    my $self = shift;

    # adjust plugin order so that we are always last!
    my $plugins = $self->zilla->plugins;
    @$plugins = ((grep { $_ != $self } @$plugins), $self);

    $self->log_debug('---- this is the last before_build plugin ----');
}

sub gather_files
{
    my $self = shift;

    my $zilla = $self->zilla;
    my $meta = find_meta($zilla);

    foreach my $attr_name (qw(name version release_status abstract main_module authors distmeta))
    {
        next if exists $zilla_constructor_args{$attr_name};
        my $attr = $meta->find_attribute_by_name($attr_name);
        $self->_alert($attr_name . ' has already been calculated by end of file gathering phase')
            if $attr and $attr->has_value($zilla);
    }

    # license is created from some private attrs, which may have been provided
    # at construction time
    $self->_alert('license has already been calculated by end of file gathering phase')
        if any {
            not exists $zilla_constructor_args{$_}
                and $meta->find_attribute_by_name($_)->has_value($zilla)
        } qw(_license_class _copyright_holder _copyright_year);

    # all files should have been added by now. save their filenames/objects
    foreach my $file (@{$zilla->files})
    {
        push @{ $all_files{$file->name} }, {
            object => $file,
            # encoding can change; don't bother capturing it yet
            # content can change; don't bother capturing it yet
        };
    }

    $self->log_debug('---- this is the last gather_files plugin ----');
}

# since last phase,
# new files added: not ok
# files removed: not ok
# files renamed: not ok
# encoding changed: ok to now; no from now on
# contents: ignore
sub set_file_encodings
{
    my $self = shift;

    # since the encoding attribute is SetOnce, if we force all the builders to
    # fire now, we can guarantee they won't change later
    foreach my $file (@{$self->zilla->files})
    {
        foreach my $entry (@{ $all_files{$file->name} })
        {
            $entry->{encoding} = $file->encoding if $entry->{object} eq $file;
        }
    }

    $self->log_debug('---- this is the last set_file_encodings plugin ----');
}

# since last phase,
# new files added: not ok
# files removed: ok to now; not ok from now on
# files renamed: not ok
# encoding changed: not ok
# contents: ignore
sub prune_files
{
    my $self = shift;

    # remove all still-existing files from our tracking list
    foreach my $file (@{$self->zilla->files})
    {
        my ($filename, $index) = $self->_search_all_files($file);
        if ($filename and defined $index)
        {
            # file has been renamed - an odd time to do this
            $self->_alert('file has been renamed after file gathering phase: \'' . $file->name
                    . "' (originally '$filename', " . $file->added_by . ')')
                if $filename ne $file->name;

            splice @{ $all_files{$filename} }, $index, 1;
            next;
        }

        $self->_alert('file has been added after file gathering phase: \'' . $file->name
            . '\' (' . $file->added_by . ')');
    }

    # anything left over has been removed, but this is okay by a file pruner

    # capture full file list all over again.
    %all_files = ();
    foreach my $file (@{$self->zilla->files})
    {
        push @{ $all_files{$file->name} }, {
            object => $file,
            encoding => $file->encoding,
            content => undef,   # content can change; don't bother capturing it yet
        };
    }

    $self->log_debug('---- this is the last prune_files plugin ----');
}

my $distmeta;

# since last phase,
# new files added: not ok
# files removed: not ok
# files renamed: allowed
# encoding changed: not ok
# record contents: ok to now; not ok from now on
# distmeta changed: ok to now; not ok from now on
# no prerequisites have been added yet
sub munge_files
{
    my $self = shift;

    # remove all still-existing files from our tracking list
    foreach my $file (@{$self->zilla->files})
    {
        my ($filename, $index) = $self->_search_all_files($file);
        if ($filename and defined $index)
        {
            # the file may have been renamed - but this is okay by a file munger
            splice @{ $all_files{$filename} }, $index, 1;
            next;
        }

        # this is a new file we haven't seen before.
        $self->_alert('file has been added after file gathering phase: \'' . $file->name
            . '\' (' . $file->added_by . ')');
    }

    # now report on any files added earlier that were removed.
    foreach my $filename (keys %all_files)
    {
        $self->_alert('file has been removed after file pruning phase: \'' . $filename
                . '\' (' . $_->{object}->added_by . ')')
            foreach @{ $all_files{$filename} };
    }

    # capture full file list all over again, recording contents now.
    %all_files = ();
    foreach my $file (@{$self->zilla->files})
    {
        # don't force FromCode files to calculate early; it might fire some
        # lazy attributes prematurely
        push @{ $all_files{$file->name} }, {
            object => $file,
            encoding => $file->encoding,
            content => ( $file->isa('Dist::Zilla::File::FromCode')
                ? 'content ignored'
                : md5_hex($file->encoded_content) ),
        };
    }

    # verify that nothing has tried to read the prerequisite data yet
    # (only possible when the attribute is lazily built)
    my $prereq_attr = find_meta($self->zilla)->find_attribute_by_name('prereqs');
    $self->_alert('prereqs have already been read from after munging phase!')
         if Dist::Zilla->VERSION >= 5.024 and $prereq_attr->has_value($self->zilla);

    # verify no prerequisites have been provided yet
    # (it would be highly unlikely for distmeta not to be populated yet, but
    # force it anwyay so we have something to compare to later)
    $distmeta = dclone($self->zilla->distmeta);
    if (exists $distmeta->{prereqs})
    {
        require Data::Dumper;
        $self->_alert('prereqs have been improperly included with distribution metadata:',
            Data::Dumper->new([ $distmeta->{prereqs} ])->Indent(2)->Terse(1)->Sortkeys(1)->Dump,
        );
        delete $distmeta->{prereqs};
    }

    $self->log_debug('---- this is the last munge_files plugin ----');
}

# since last phase,
# new files added: not ok
# files removed: not ok
# files renamed: not ok
# change contents: not ok
# distmeta has not changed
sub after_build
{
    my $self = shift;

    foreach my $file (@{$self->zilla->files})
    {
        my ($filename, $index) = $self->_search_all_files($file);
        if (not $filename or not defined $index)
        {
            $self->_alert('file has been added after file gathering phase: \'' . $file->name
                . '\' (' . $file->added_by . ')');
            next;
        }

        if ($filename ne $file->name)
        {
            $self->_alert('file has been renamed after munging phase: \'' . $file->name
                . "' (originally '$filename', " . $file->added_by . ')');
            splice @{ $all_files{$filename} }, $index, 1;
            next;
        }

        # we give FromCode files a bye, since there is a good reason why their
        # content at file munging time is incomplete
        $self->_alert('content has changed after munging phase: \'' . $file->name
            # this looks suspicious; we ought to have separate added_by,
            # changed_by attributes
                . '\' (' . $file->added_by . ')')
            if not $file->isa('Dist::Zilla::File::FromCode')
                and none { $file->name eq $_ } $self->skip_file
                and $all_files{$file->name}[$index]{content} ne md5_hex($file->encoded_content);

        delete $all_files{$file->name};
    }

    foreach my $filename (keys %all_files)
    {
        $self->_alert('file has been removed after file pruning phase: \'' . $filename
                . '\' (' . $_->{object}->added_by . ')')
            foreach @{ $all_files{$filename} };
    }

    # check distmeta, minus prereqs
    my $new_distmeta = dclone($self->zilla->distmeta);
    delete $new_distmeta->{prereqs};
    foreach my $ignore_key ($self->skip_distmeta)
    {
        $distmeta->{$ignore_key} = Test::Deep::ignore;
        delete $distmeta->{$ignore_key} if not exists $new_distmeta->{$ignore_key};
    }
    my ($ok, $stack) = cmp_details($new_distmeta, $distmeta);
    if (not $ok)
    {
        chomp(my $error = deep_diag($stack));
        $self->_alert('distribution metadata has been altered after munging phase!', $error);
    }

    $self->log_debug('---- this is the last after_build plugin ----');
}

sub before_release {
    shift->log_debug('---- this is the last before_release plugin ----');
}

sub release
{
    my $self = shift;

    # perform the check that we just neutered in Dist::Zilla::Dist::Builder::release
    Carp::croak("you can't release without any Releaser plugins")
        if @{ $self->zilla->plugins_with(-Releaser) } <= 1;

    $self->log_debug('---- this is the last release plugin ----');
}

sub after_release {
    shift->log_debug('---- this is the last after_release plugin ----');
}

sub _alert
{
    my $self = shift;
    $self->log(colored(join(' ', @_), 'bright_red'));
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::VerifyPhases - Compare data and files at different phases of the distribution build process

=head1 VERSION

version 0.016

=head1 SYNOPSIS

At the end of your F<dist.ini>:

    [VerifyPhases]

=head1 DESCRIPTION

This plugin runs in multiple L<Dist::Zilla> phases to check what actions have
taken place so far.  Its intent is to find any plugins that are performing
actions outside the appropriate phase, so they can be fixed.

Running at the end of the C<-FileGatherer> phase, it verifies that the
following distribution properties have not yet been populated/calculated, as
they usually depend on having the full complement of files added to the
distribution, with known encodings:

=over 4

=item *

name

=item *

version

=item *

release_status

=item *

abstract

=item *

main_module

=item *

license

=item *

authors

=item *

metadata

=back

Running at the end of the C<-EncodingProvider> phase, it forces all encodings
to be built (by calling their lazy builders), to use their C<SetOnce> property
to ensure that no subsequent phase attempts to alter a file encoding.

Running at the end of the C<-FilePruner> phase, it verifies that no additional
files have been added to the distribution, nor renamed, since the
C<-FileGatherer> phase.

Running at the end of the C<-FileMunger> phase, it verifies that no additional
files have been added to nor removed from the distribution, nor renamed, since
the C<-FilePruner> phase; and that no prerequisites have yet been provided.
Additionally, it verifies that the prerequisite list has not yet been read
from, when possible.

Running at the end of the C<-AfterBuild> phase, the full state of all files
are checked: files may not be added, removed, renamed nor had their content
change. Additionally, it verifies that no distribution metadata (with the
exception of prerequisites) has changed since the end of the C<-FileMunger>
phase.

=for stopwords FromCode

Currently, L<FromCode|Dist::Zilla::File::FromCode> files are not checked for
content, as interesting side effects can occur if their content subs are run
before all content is available (for example, other lazy builders can run too
early, resulting in incomplete or missing data).

=for Pod::Coverage BUILD before_build gather_files set_file_encodings prune_files munge_files after_build
before_release release after_release

=head1 SEE ALSO

=over 4

=item *

L<Dist::Zilla::Plugin::ReportPhase>

=item *

L<Dist::Zilla::App::Command::dumpphases>

=back

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-VerifyPhases>
(or L<bug-Dist-Zilla-Plugin-VerifyPhases@rt.cpan.org|mailto:bug-Dist-Zilla-Plugin-VerifyPhases@rt.cpan.org>).

There is also a mailing list available for users of this distribution, at
L<http://dzil.org/#mailing-list>.

There is also an irc channel available for users of this distribution, at
L<C<#distzilla> on C<irc.perl.org>|irc://irc.perl.org/#distzilla>.

I am also usually active on irc, as 'ether' at C<irc.perl.org>.

=head1 AUTHOR

Karen Etheridge <ether@cpan.org>

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Karen Etheridge.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
