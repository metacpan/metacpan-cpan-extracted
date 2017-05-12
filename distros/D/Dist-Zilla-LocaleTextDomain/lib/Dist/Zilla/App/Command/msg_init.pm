package Dist::Zilla::App::Command::msg_init;

# ABSTRACT: Add language translation catalogs to a dist

use Dist::Zilla::App -command;
use strict;
use warnings;
use Path::Class;
use Dist::Zilla::Plugin::LocaleTextDomain;
use Moose;
use IPC::Run3;
use File::Find::Rule;
use namespace::autoclean;

our $VERSION = '0.90';

with 'Dist::Zilla::Role::PotFile';

sub command_names { qw(msg-init) }

sub abstract { 'add language translation files to a distribution' }

sub usage_desc { '%c %o <language_code> [<language_code> ...]' }

sub opt_spec {
    return (
        [ 'xgettext|x=s'         => 'location of xgttext utility'      ],
        [ 'msginit|i=s'          => 'location of msginit utility'      ],
        [ 'encoding|e=s'         => 'character encoding to be used'    ],
        [ 'pot-file|pot|p=s'     => 'pot file location'                ],
        [ 'copyright-holder|c=s' => 'name of the copyright holder'     ],
        [ 'bugs-email|b=s'       => 'email address for reporting bugs' ],
    );
}

sub validate_args {
    my ($self, $opt, $args) = @_;

    require IPC::Cmd;
    my $xget = $opt->{xgettext} ||= 'xgettext' . ($^O eq 'MSWin32' ? '.exe' : '');
    $self->zilla->log_fatal(
        qq{Cannot find "$xget": Are the GNU gettext utilities installed?}
    ) unless IPC::Cmd::can_run($xget);

    my $init = $opt->{msginit} ||= 'msginit' . ($^O eq 'MSWin32' ? '.exe' : '');
    $self->zilla->log_fatal(
        qq{Cannot find "$init": Are the GNU gettext utilities installed?}
    ) unless IPC::Cmd::can_run($init);

    if (my $enc = $opt->{encoding}) {
        require Encode;
        $self->zilla->log_fatal(qq{"$enc" is not a valid encoding})
            unless Encode::find_encoding($enc);
    } else {
        $opt->{encoding} = 'UTF-8';
    }

    $self->usage_error('dzil msg-init takes one or more arguments')
        if @{ $args } < 1;

    require Locale::Language;
    require Locale::Country;

    for my $lang ( @{ $args } ) {
        my ($name, $enc) = split /[.]/, $lang, 2;
        if ($enc) {
            require Encode;
            $self->zilla->log_fatal(qq{"$enc" is not a valid encoding})
                unless Encode::find_encoding($enc);
        }

        my ($lang, $country) = split /[-_]/, $name;
        $self->zilla->log_fatal(qq{"$lang" is not a valid language code})
            unless Locale::Language::code2language($lang);
        if ($country) {
            $self->zilla->log_fatal(qq{"$country" is not a valid country code})
                unless Locale::Country::code2country($country);
        }
    }
}

sub execute {
    my ($self, $opt, $args) = @_;

    my $dzil   = $self->zilla;
    my $plugin = $self->zilla->plugin_named('LocaleTextDomain')
        or $dzil->log_fatal('LocaleTextDomain plugin not found in dist.ini!');
    my $lang_dir = $plugin->lang_dir;
    my $lang_ext = '.' . $plugin->lang_file_suffix;
    my $pot_file = $self->pot_file( %{ $opt } );

    my @cmd = (
        $opt->{msginit},
        '--input=' . $pot_file,
        '--no-translator',
    );

    my $log = sub { $plugin->log(@_) };
    for my $lang (@{ $args }) {
        # Strip off encoding.
        (my $name = $lang) =~ s/[.].+$//;
        my $dest = $lang_dir->file( $name . $lang_ext );
        $plugin->log_fatal("$dest already exists") if -e $dest;
        run3 (
            [@cmd,  "--locale=$lang", '--output-file=' . $dest],
            undef, $log, $log
        );
        $plugin->log_fatal("Cannot generate $dest") if $?;
    }
}

1;
__END__

=head1 Name

Dist::Zilla::App::Command::msg_init - Add language translation catalogs to a dist

=head1 Synopsis

In F<dist.ini>:

  [LocaleTextDomain]
  textdomain = My-App
  lang_dir = po

On the command line:

  dzil msg-init fr

=head1 Description

This command initializes and adds one or more
L<GNU gettext|http://www.gnu.org/software/gettext/>-style language catalogs to
your distribution. It can either use an existing template file (such as can be
created with the L<C<msg-scan>|Dist::Zilla::App::Command::msg_init> command)
or will scan your distribution's Perl modules directly to create the catalog.
It relies on the settings from the
L<C<LocaleTextDomain> plugin|Dist::Zilla::Plugin::LocaleTextDomain> for its
settings, and requires that the GNU gettext utilities be available.

=head2 Options

=head3 C<--xgettext>

The location of the C<xgettext> program, which is distributed with
L<GNU gettext|http://www.gnu.org/software/gettext/>. Defaults to just
C<xgettext> (or C<xgettext.exe> on Windows), which should work if it's in your
path. Not used if C<--pot-file> points to an existing template file.

=head3 C<--msginit>

The location of the C<msginit> program, which is distributed with L<GNU
gettext|http://www.gnu.org/software/gettext/>. Defaults to just C<msginit>
(or C<msginit.exe> on Windows), which should work if it's in your path.

=head3 C<--encoding>

The encoding to assume the Perl modules are encoded in. Defaults to C<UTF-8>.

=head3 C<--pot-file>

The name of the template file to use to generate the message catalogs. If not
specified, C<$lang_dir/$textdomain.pot> will be used if it exists. Otherwise,
a temporary template file will be created by scanning the Perl sources.

=head3 C<--copyright-holder>

Name of the application copyright holder. Defaults to the copyright holder
defined in F<dist.ini>. Used only to generate a temporary template file.

=head3 C<--bugs-email>

Email address to which translation bug reports should be sent. Defaults to the
email address of the first distribution author, if available. Used only to
generate a temporary template file.

=head1 Author

David E. Wheeler <david@justatheory.com>

=head1 Copyright and License

This software is copyright (c) 2012-2013 by David E. Wheeler.

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.

=cut
