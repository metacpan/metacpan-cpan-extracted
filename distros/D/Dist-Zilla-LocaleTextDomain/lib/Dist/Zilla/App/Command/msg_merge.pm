package Dist::Zilla::App::Command::msg_merge;

# ABSTRACT: Merge localization strings into translation catalogs

use Dist::Zilla::App -command;
use strict;
use warnings;
use Path::Class;
use Dist::Zilla::Plugin::LocaleTextDomain;
use File::Basename;
use Moose;
use IPC::Run3;
use File::Copy;
use File::Find::Rule;
use namespace::autoclean;

our $VERSION = '0.90';

with 'Dist::Zilla::Role::PotFile';

sub command_names { qw(msg-merge) }

sub abstract { 'merge localization strings into translation catalogs' }

sub usage_desc { '%c %o <language_code> [<language_code> ...]' }

sub opt_spec {
    return (
        [ 'xgettext|x=s'         => 'location of xgttext utility'      ],
        [ 'msgmerge|m=s'         => 'location of msgmerge utility'     ],
        [ 'encoding|e=s'         => 'character encoding to be used'    ],
        [ 'pot-file|pot|p=s'     => 'pot file location'                ],
        [ 'copyright-holder|c=s' => 'name of the copyright holder'     ],
        [ 'bugs-email|b=s'       => 'email address for reporting bugs' ],
        [ 'backup!'              => 'back up files before merging'     ],
    );
}

sub validate_args {
    my ($self, $opt, $args) = @_;

    require IPC::Cmd;
    my $xget = $opt->{xgettext} ||= 'xgettext' . ($^O eq 'MSWin32' ? '.exe' : '');
    $self->zilla->log_fatal(
        qq{Cannot find "$xget": Are the GNU gettext utilities installed?}
    ) unless IPC::Cmd::can_run($xget);

    my $merge = $opt->{msgmerge} ||= 'msgmerge' . ($^O eq 'MSWin32' ? '.exe' : '');
    $self->zilla->log_fatal(
        qq{Cannot find "$merge": Are the GNU gettext utilities installed?}
    ) unless IPC::Cmd::can_run($merge);

    if (my $enc = $opt->{encoding}) {
        require Encode;
        $self->zilla->log_fatal(qq{"$enc" is not a valid encoding})
            unless Encode::find_encoding($enc);
    } else {
        $opt->{encoding} = 'UTF-8';
    }
}

sub _po_files {
    my ( $self, $plugin ) = @_;
    require File::Find::Rule;
    my $lang_ext = $plugin->lang_file_suffix;
    return File::Find::Rule->file->name("*.$lang_ext")->in($plugin->lang_dir);
}

sub execute {
    my ($self, $opt, $args) = @_;

    my $dzil   = $self->zilla;
    my $plugin = $self->zilla->plugin_named('LocaleTextDomain')
        or $dzil->log_fatal('LocaleTextDomain plugin not found in dist.ini!');
    my $lang_dir = $plugin->lang_dir;
    my $lang_ext = '.' . $plugin->lang_file_suffix;
    my $pot_file = $self->pot_file( %{ $opt } );

    my @pos = @{ $args } ? @{ $args } : $self->_po_files( $plugin );
    $plugin->log_fatal("No language catalog files found") unless @pos;

    my @cmd = (
        $opt->{msgmerge},
        qw(--quiet --update),
        '--backup=' . ($opt->{backup} ? 'simple' : 'none'),
    );

    my $log = sub { $plugin->log(@_) };
    for my $file (@pos) {
        $plugin->log("Merging gettext strings into $file");
        run3 [@cmd, $file, $pot_file], undef, $log, $log;
        $plugin->log_fatal("Cannot merge into $file") if $?;
    }
}

1;
__END__

=head1 Name

Dist::Zilla::App::Command::msg_merge - Merge localization strings into translation catalogs

=head1 Synopsis

In F<dist.ini>:

  [LocaleTextDomain]
  textdomain = My-App
  lang_dir = po

On the command line:

  dzil msg-init fr de

Later, after adding or modifying localizations strings:

  dzil msg-merge

=head1 Description

This command merges localization strings into translation catalog files. The
strings are merged from a L<GNU
gettext|http://www.gnu.org/software/gettext/>-style language translation
template, which can be created by the L<C<msg-scan>
command|Dist::Zilla::App::Command::msg_merge>. If no template file is found or
can be found, the Perl sources will be scanned to create a temporary one.

This command relies on the settings from the L<C<LocaleTextDomain>
plugin|Dist::Zilla::Plugin::LocaleTextDomain> for its settings, and requires
that the GNU gettext utilities be available.

=head2 Options

=head3 C<--xgettext>

The location of the C<xgettext> program, which is distributed with
L<GNU gettext|http://www.gnu.org/software/gettext/>. Defaults to just
C<xgettext> (or C<xgettext.exe> on Windows), which should work if it's in your
path. Not used if C<--pot-file> is specified.

=head3 C<--msgmerge>

The location of the C<msgmerge> program, which is distributed with L<GNU
gettext|http://www.gnu.org/software/gettext/>. Defaults to just C<msgmerge>
(or C<msgmerge.exe> on Windows), which should work if it's in your path.

=head3 C<--encoding>

The encoding to assume the Perl modules are encoded in. Defaults to C<UTF-8>.

=head3 C<--pot-file>

The name of the template file to use to merge the message catalogs. If not
specified, C<$lang_dir/$textdomain.pot> will be used if it exists. Otherwise,
a temporary template file will be created by scanning the Perl sources.

=head3 C<--copyright-holder>

Name of the application copyright holder. Defaults to the copyright holder
defined in F<dist.ini>. Used only to generate a temporary template file.

=head3 C<--bugs-email>

Email address to which translation bug reports should be sent. Defaults to the
email address of the first distribution author, if available. Used only to
generate a temporary template file.

=head3 C<--backup>

Back up each language file before merging it. The backup files will have the
suffix F<~>.

=head1 Author

David E. Wheeler <david@justatheory.com>

=head1 Copyright and License

This software is copyright (c) 2012-2013 by David E. Wheeler.

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.

=cut
